local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ServerScriptService   = game:GetService("ServerScriptService")
local StarterPlayer         = game:GetService("StarterPlayer")
local StarterGui            = game:GetService("StarterGui")
local RunService            = game:GetService("RunService")

local Server                = RunService:IsServer()
local ConfigFolder          = ReplicatedStorage.Configuration
local LoadOrder             = require(ConfigFolder.LoadOrder)

local Indicator             = Server and "Server" or "Client"
local TargetName            = string.format("%sGameLoader", Indicator)

local CachedEnvironments    = {}

local Environment           = {}

if Server then
    Environment["Assets"] = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder", ReplicatedStorage)
else
    coroutine.resume(coroutine.create(function()
        Environment["Assets"] = ReplicatedStorage:WaitForChild("Assets")
    end))
end

Environment["Modules"]          = ReplicatedStorage.Modules
Environment["Classes"]          = ReplicatedStorage.Classes
Environment["Assets"].Name      = "Assets"
Environment["OriginalEnv"]      = getfenv()

local function MapEnv(Target)
    for Key, Value in pairs(Environment) do
        Target[Key] = Value
    end
end

local function AddPlugin(Plugin)

    local Object = (Server and Plugin.Server or Plugin.Client)

    if (Object["Init"]) then
        Object["Init"]()
    end

    for Key, Value in pairs(Object) do
        if (Key ~= "Init") then
            if (Environment[Key]) then
                print("\tWarning: Library item '" .. Key .. "' being overwritten.")
            end
            Environment[Key] = Value
        end
    end

    for _, Env in pairs(CachedEnvironments) do
        MapEnv(Env)
    end
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

for Key, Value in pairs(LoadOrder) do
    local Library = ReplicatedStorage.Library:FindFirstChild(Value)
    if Library then
        local Now = tick()
        require(Library)
        print("[Load Order " .. Key .. "] Library: " .. Library.Name .. " Loaded on " .. Indicator ..
            " (" .. ("%.2f"):format((tick() - Now) * 1000) .. "ms)")
    end
end

require(ReplicatedStorage:FindFirstChild(TargetName, true) or
        ServerScriptService:FindFirstChild(TargetName, true) or
        StarterPlayer:FindFirstChild(TargetName, true) or
        StarterGui:FindFirstChild(TargetName, true))

return true