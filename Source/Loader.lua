local Loader                = {}
local Engine                = {}
local Loaded                = {}

local Services = {
    "ReplicatedStorage", "ReplicatedFirst", "RunService",
    "StarterGui", "Players", "CollectionService", "UserInputService",
    "DataStoreService", "Lighting", "ContextActionService"
}

local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local RunService            = game:GetService("RunService")

local Parent                = script.Parent
local Server                = RunService:IsServer()
local Indicator             = Server and "Server" or "Client"
local Libraries             = Parent:FindFirstChild("Libraries")
local Classes               = Parent:FindFirstChild("Classes")

function Loader:Get(Name)

    -- Should only be used for debugging
    if (Name == "*") then
        for _, Item in pairs(Classes:GetDescendants()) do
            if (Item:IsA("ModuleScript") and Item.Parent.Name ~= "Tests") then
                Loader:Get(Item.Name)
            end
        end

        for _, Item in pairs(Libraries.Shared:GetDescendants()) do
            if (Item:IsA("ModuleScript")) then
                Loader:Get(Item.Name)
            end
        end

        if Server then
            for _, Item in pairs(Libraries.Server:GetDescendants()) do
                if (Item:IsA("ModuleScript")) then
                    Loader:Get(Item.Name)
                end
            end
        else
            for _, Item in pairs(Libraries.Client:GetDescendants()) do
                if (Item:IsA("ModuleScript")) then
                    Loader:Get(Item.Name)
                end
            end
        end

        return
    end

    local Default = Engine[Name]

    if Default then
        return Default
    end

    local Module = Server and
        (Libraries.Shared:FindFirstChild(Name, true) or
        Classes:FindFirstChild(Name, true) or
        Libraries.Server:FindFirstChild(Name, true)) or
    (Libraries.Shared:FindFirstChild(Name, true) or
    Classes:FindFirstChild(Name, true) or
    Libraries.Client:FindFirstChild(Name, true))

    assert(Module, string.format("No utility or class found with name '%s'!", Name))
    assert(Module.ClassName == "ModuleScript", string.format("'%s' is not a ModuleScript!", Name))

    local Got = require(Module)
    Engine[Name] = Got

    if (not Loaded[Name]) then
        local Time = tick()

        if (Got.Init) then
            Got:Init()
        end

        local Diff = tick() - Time
        local Nanoseconds = Diff * 1e+9
        local Milliseconds = Diff * 1e+3
        local Reported = string.format("Novarine - Load '%s' : %s (%.2f ns / %.8f ms)", Name, Indicator, Nanoseconds, Milliseconds)

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

function Loader:Initialise()
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
end

return Loader