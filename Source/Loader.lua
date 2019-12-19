local Loader                = {}
local Engine                = {}
local Loaded                = {}
local ExtraLocations        = {}

local PreLoad = { -- Modules which must load before others are required e.g. to subscribe to events
    "Communication";
    "Replication";
}
local Services = {
    "ReplicatedStorage", "ReplicatedFirst", "RunService",
    "StarterGui", "Players", "CollectionService", "UserInputService",
    "DataStoreService", "Lighting", "ContextActionService",
    "PhysicsService", "Workspace"
}

local ServerScriptService   = game:GetService("ServerScriptService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ReplicatedFirst       = game:GetService("ReplicatedFirst")
local RunService            = game:GetService("RunService")

local Parent                = script.Parent
local Server                = RunService:IsServer()
local Indicator             = Server and "Server" or "Client"
local Libraries             = Parent:FindFirstChild("Libraries")
local Classes               = Parent:FindFirstChild("Classes")

local GameClient            = ReplicatedFirst:FindFirstChild("GAME_INDICATOR_CLIENT", true)
GameClient                  = (GameClient and GameClient.Parent or ReplicatedFirst)

local GameShared            = ReplicatedFirst:FindFirstChild("GAME_INDICATOR_SHARED", true)
GameShared                  = (GameShared and GameShared.Parent or ReplicatedFirst)

local GameServer            = ServerScriptService:FindFirstChild("GAME_INDICATOR_SERVER", true)
GameServer                  = (GameServer and GameServer.Parent or ServerScriptService)

local DebugMode             = (ReplicatedFirst:FindFirstChild("DEBUG_MODE") and ReplicatedFirst.DEBUG_MODE.Value or false)

Engine["ClientFolder"] = GameClient
Engine["SharedFolder"] = GameShared
Engine["ServerFolder"] = GameServer
Engine["DebugMode"] = DebugMode

function Loader:Get(Name, Tabs)

    local Default = Engine[Name]

    if (Default ~= nil) then
        return Default
    end

    local Module = Server and (
        Libraries.Shared:FindFirstChild(Name, true) or
        Classes:FindFirstChild(Name, true) or
        Libraries.Server:FindFirstChild(Name, true) or
        GameServer:FindFirstChild(Name, true) or
        GameShared:FindFirstChild(Name, true)
    ) or (
        Libraries.Shared:FindFirstChild(Name, true) or
        Classes:FindFirstChild(Name, true) or
        Libraries.Client:FindFirstChild(Name, true) or
        GameClient:FindFirstChild(Name, true) or
        GameShared:FindFirstChild(Name, true)
    )

    if (not Module) then
        for _, Location in pairs(ExtraLocations) do
            local Found = Location:FindFirstChild(Name, true)

            if Found then
                Module = Found
                break
            end
        end
    end

    assert(Module, string.format("No utility or class found with name '%s'!", Name))
    assert(Module.ClassName == "ModuleScript", string.format("'%s' is not a ModuleScript!", Name))

    local Got = require(Module)
    Engine[Name] = Got

    if (not Loaded[Name] and type(Got) == "table") then
        local Time = tick()

        if (Got.Init) then
            Got:Init()
        end

        if DebugMode then
            local Diff = tick() - Time
            local Nanoseconds = Diff * 1e+9
            local Milliseconds = Diff * 1e+3
            local Reported = string.format(("\t"):rep(Tabs or 0) .. "Novarine - Load '%s' : %s (%.2f ns / %.8f ms)", Name, Indicator, Nanoseconds, Milliseconds)

            -- Warn for slow modules
            if (Milliseconds < 16) then
                print(Reported)
            else
                warn(Reported)
            end

            if (Got.Tests) then
                delay(5 + (RunService:IsServer() and 3 or 0), function()
                    -- Delay so the initial debugging output is hopefully completed by then
                    -- Also server waits longer
                    local Tests = {}
                    local Cleanups = {}

                    if (Got.Tests.Init) then
                        Got.Tests.Init()
                    end

                    for TestName, Test in pairs(Got.Tests) do
                        if (TestName ~= "Init" and TestName ~= "Finish") then
                            Tests[TestName] = false

                            coroutine.wrap(Test)(function()
                                Tests[TestName] = string.format("Novarine - Test Passed: '%s'", TestName)
                            end, function(Reason)
                                Tests[TestName] = true
                                error(string.format("Novarine - Test Failed: '%s', Reason: '%s'", TestName, Reason))
                            end, function(CleanupHandler)
                                Cleanups[TestName] = CleanupHandler
                            end)
                        end
                    end

                    local function IsSatisfied()
                        for _, Item in pairs(Tests) do
                            if (not Item) then
                                return false
                            end
                        end

                        return true
                    end

                    coroutine.wrap(function()
                        while (not IsSatisfied()) do
                            RunService.Stepped:Wait()
                        end

                        print(string.format("Novarine: Test Batch for '%s' {", Name))

                        for TestName, Item in pairs(Tests) do
                            if (Item ~= true) then
                                print("    " .. Item)
                            end

                            local Cleanup = Cleanups[TestName]

                            if Cleanup then
                                coroutine.wrap(Cleanup)()
                            end
                        end

                        print("}")

                        if (Got.Tests.Finish) then
                            Got.Tests.Finish()
                        end
                    end)()
                end)
            end
        end

        Loaded[Name] = true
    end

    return Got
end

function Loader:Add(Name, Item)
    if DebugMode then
        print(string.format("Novarine - Add '%s' (%s)", Name, Indicator))
    end
    Engine[Name] = Item
end

function Loader:AddExtraLocation(Location)
    ExtraLocations[Location.Name] = Location
end

function Loader:Init()
    if (self.Initialised) then
        warn("Novarine already initialised!")
        return
    end

    if Server then
        local Assets = ReplicatedStorage:FindFirstChild("Assets")

        if (not Assets) then
            Assets = Instance.new("Folder")
            Assets.Name = "Assets"
            Assets.Parent = ReplicatedStorage
        end

        Engine["Assets"] = Assets

        local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")

        if (not RemoteEvent) then
            RemoteEvent = Instance.new("RemoteEvent")
            RemoteEvent.Name = "RemoteEvent"
            RemoteEvent.Parent = ReplicatedStorage
        end

        local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

        if (not RemoteFunction) then
            RemoteFunction = Instance.new("RemoteFunction")
            RemoteFunction.Name = "RemoteFunction"
            RemoteFunction.Parent = ReplicatedStorage
        end
    else
        coroutine.wrap(function()
            Engine["Assets"] = ReplicatedStorage:WaitForChild("Assets")
        end)()
    end

    Engine["Modules"] = Parent.Modules
    Engine["Configuration"] = require(Parent.Configuration.Config)

    for _, Name in pairs(Services) do
        Engine[Name] = game:GetService(Name)
    end

    if DebugMode then
        print(string.format("Novarine - Initialised (%s)", Indicator))
    end

    for _, Item in pairs(PreLoad) do
        if DebugMode then
            print("Novarine - Preload Tree")
        end
        Loader:Get(Item, 1)
    end

    self.Initialised = true
end

return Loader