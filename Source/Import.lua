local Svc                   = setmetatable({}, {__index = function(_, Key) return game:GetService(Key) end})

local ReplicatedStorage     = Svc.ReplicatedStorage;
local RunService            = Svc.RunService;
local Server                = RunService:IsServer();
local Library               = ReplicatedStorage["Library"]

local Env                   = {}
local EnvironmentMT         = {
    
    __index = function(Self, Key)
        
        return Env[Key] or rawget(Self, 1)[Key]
        
    end;
    
}

Env["Assets"]           = ReplicatedStorage.Assets or Instance.new("Folder", ReplicatedStorage)
Env["Modules"]          = ReplicatedStorage.Modules
Env["Classes"]          = ReplicatedStorage.Classes
Env["Assets"].Name      = "Assets"
Env["OriginalEnv"]      = getfenv()

local function AddPlugin(Plugin)
    
    local Object = (Server and Plugin.Server or Plugin.Client)
    
    for Key, Value in next, Object do

        if Key == "__main" then
            
            Value()
            
        else
            
            Env[Key] = Value
            
        end
        
    end
    
end

return function(Plugin)
    
    if Plugin then
        
        AddPlugin(Plugin)
        
    else
        
        return setmetatable({getfenv(0)}, EnvironmentMT)
        
    end
    
end