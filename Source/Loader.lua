local Loader                = {}
local Engine                = {}
local Loaded                = {}

local PreLoad = { -- Modules which must load before others are required e.g. to subscribe to events
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

local GameClient            = ReplicatedFirst:FindFirstChild("GAME_INDICATOR_CLIENT", true).Parent
local GameShared            = ReplicatedFirst:FindFirstChild("GAME_INDICATOR_SHARED", true).Parent
local GameServer            = ServerScriptService:FindFirstChild("GAME_INDICATOR_SERVER", true)

if GameServer then
    GameServer = GameServer.Parent
end

Engine["ClientFolder"] = GameClient
Engine["SharedFolder"] = GameShared
Engine["ServerFolder"] = GameServer

function Loader:Get(Name, Tabs)

    local Default = Engine[Name]

    if Default then
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

    assert(Module, string.format("No utility or class found with name '%s'!", Name))
    assert(Module.ClassName == "ModuleScript", string.format("'%s' is not a ModuleScript!", Name))

    local Got = require(Module)
    Engine[Name] = Got

    if (not Loaded[Name] and type(Got) == "table") then
        local Time = tick()

        if (Got.Init) then
            Got:Init()
        end

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

        Loaded[Name] = true
    end

    return Got
end

function Loader:Add(Name, Item)
    print(string.format("Novarine - Add '%s' (%s)", Name, Indicator))
    Engine[Name] = Item
end

function Loader:Init()
    if (self.Initialised) then
        error("Novarine already initialised!")
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

    -- Find game entry points
    --[[ require(ReplicatedStorage:FindFirstChild(TargetName, true) or
    ServerScriptService:FindFirstChild(TargetName, true) or
    ReplicatedFirst:FindFirstChild(TargetName, true) or
    StarterPlayer:FindFirstChild(TargetName, true) or
    StarterGui:FindFirstChild(TargetName, true)) ]]

    print(string.format("Novarine - Initialised (%s)", Indicator))

    for _, Item in pairs(PreLoad) do
        print("Novarine - Preload Tree")
        Loader:Get(Item, 1)
    end

    self.Initialised = true
end

return Loader