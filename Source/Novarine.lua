local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local RunService            = game:GetService("RunService")

local Server                = RunService:IsServer()
local Library               = ReplicatedStorage.Library

local Loaded                = false

local Environment           = {}
local EnvironmentMT         = {
    __index = function(Self, Key)
        return Environment[Key] or rawget(Self, 1)[Key]
    end;
}

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

local function AddPlugin(Plugin)
    
    local Object = (Server and Plugin.Server or Plugin.Client)
    
    if Object["Init"] then
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
end

return function(Value)

    if Value then
        local TypeStr = type(Value)
        if (TypeStr == "string") then
            if (Value:lower() == "wait") then
                while (Loaded == false) do
                    wait()
                end
            elseif (Value:lower() == "complete") then
                Loaded = true
            end
        elseif (TypeStr == "table") then
            AddPlugin(Value)
            return
        end
    end

    return setmetatable({getfenv(0)}, EnvironmentMT)
end