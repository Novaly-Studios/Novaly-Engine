local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ReplicatedFirst       = game:GetService("ReplicatedFirst")
local ServerScriptService   = game:GetService("ServerScriptService")
local StarterPlayer         = game:GetService("StarterPlayer")
local StarterGui            = game:GetService("StarterGui")
local RunService            = game:GetService("RunService")

local Server                = RunService:IsServer()
local Indicator             = Server and "Server" or "Client"

local Parent                = script.Parent
local Libraries             = Parent:FindFirstChild("Libraries")
local Classes               = Parent:FindFirstChild("Classes")

local ConfigFolder          = Parent.Configuration
local LoadOrder             = require(ConfigFolder.LoadOrder)[Indicator]
local TargetName            = string.format("%sGameLoader", Indicator)

local CachedEnvironments    = {}
local Environment           = {}

local ClassCount            = 1
local LibraryCount          = 1

if Server then
    Environment["Assets"] = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder", ReplicatedStorage)
else
    coroutine.resume(coroutine.create(function()
        Environment["Assets"] = ReplicatedStorage:WaitForChild("Assets")
    end))
end

Environment["Modules"]          = Parent.Modules
Environment["Classes"]          = Parent.Classes
Environment["Assets"].Name      = "Assets"
Environment["OriginalEnv"]      = getfenv()

local function MapEnv(Target)
    for Key, Value in pairs(Environment) do
        Target[Key] = Value
    end
end

local function AddPlugin(Object)

    if (Object["Init"]) then
        Object["Init"]()
    end

    for Key, Value in pairs(Object) do
        if (Key ~= "Init") then
            if (Environment[Key]) then
                print(string.format("\tWarning: Library item '%s' was overwritten.", Key))
            end
            Environment[Key] = Value
        end
    end

    for _, Env in pairs(CachedEnvironments) do
        MapEnv(Env)
    end
end

local function HasParent(Object, Name)
    while Object do
        Object = Object.Parent
        if (Object.Name == Name) then
            return true
        end
    end

    return false
end

local function LoadUtil(Object, PathString)
    local REGEX = "[^%.]+"

    for Node in string.gmatch(PathString, REGEX) do
        if (Node == "*") then
            local Items = {}

            for _, Value in pairs(Object:GetChildren()) do
                table.insert(Items, Value)
            end

            return Items
        end

        Object = Object:FindFirstChild(Node)

        if (not Object) then
            return false
        end
    end

    return {Object}
end

local function Count(Arr)
    local Result = 0
    for _ in pairs(Arr) do
        Result = Result + 1
    end
    return Result
end

setmetatable(shared, {
    __call = function(_, Value)

        if Value then
            local ValueType = type(Value)
            if (ValueType == "table") then
                AddPlugin(Value)
                return
            end
        end

        local Target = getfenv(0)
        MapEnv(Target)
        table.insert(CachedEnvironments, Target)
    end;
})

Environment["CONFIG"] = require(ConfigFolder.Config)
AddPlugin(require(Libraries.Shared.ClassLibrary))

local ClassAdditions = {}

for _, Value in pairs(Classes:GetChildren()) do
    local Outsourced = Value:FindFirstChild("Source")

    if Outsourced then
        Value = Value.Source
    end

    for _, Item in pairs(Value:GetChildren()) do
        local Now = tick()
        local Required = require(Item)
        ClassAdditions[Item.Name] = Required
        print(string.format("[Load Order %d] Class: %s Loaded on %s (%.2fms)",
            ClassCount, Item.Name, Indicator, (tick() - Now) * 1000))
        ClassCount = ClassCount + 1

        if Outsourced then
            local function Constructor(...)
                return Required:Create(...)
            end
            Required.New = Constructor
            Required.new = Constructor
        end
    end
end

AddPlugin(ClassAdditions)

for _, Value in pairs(LoadOrder.Utility) do

    local Library = LoadUtil(Libraries, Value)

    if Library then
        for _, Item in pairs(Library) do
            local Now = tick()
            AddPlugin(require(Item))
            print(string.format("[Load Order %d] Library: %s Loaded on %s (%.2fms)",
                LibraryCount, Item.Name, Indicator, (tick() - Now) * 1000))
            LibraryCount = LibraryCount + 1
        end
    end
end

-- Find game entry points
require(ReplicatedStorage:FindFirstChild(TargetName, true) or
        ServerScriptService:FindFirstChild(TargetName, true) or
        ReplicatedFirst:FindFirstChild(TargetName, true) or
        StarterPlayer:FindFirstChild(TargetName, true) or
        StarterGui:FindFirstChild(TargetName, true))

return true