local Svc                   = setmetatable({}, {__index = function(_, Key) return game:GetService(Key) end})

local ReplicatedStorage     = Svc.ReplicatedStorage
local RunService            = Svc.RunService
local Server                = RunService:IsServer()
local Library               = ReplicatedStorage["Library"]

local Env                   = {}
local EnvironmentMT         = {
    
    __index = function(Self, Key)
        
        return Env[Key] or rawget(Self, 1)[Key]
        
    end;
    
}

if Server then

    Env["Assets"] = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder", ReplicatedStorage)

else

    coroutine.resume(coroutine.create(function()

        Env["Assets"] = ReplicatedStorage:WaitForChild("Assets")

    end))

end

Env["Modules"]          = ReplicatedStorage.Modules
Env["Classes"]          = ReplicatedStorage.Classes
Env["Assets"].Name      = "Assets"
Env["OriginalEnv"]      = getfenv()

local function AddPlugin(Plugin)
    
    local Object = (Server and Plugin.Server or Plugin.Client)
    
    if Object["__main"] then

        Object["__main"]

    end

    for Key, Value in next, Object do

        if Key ~= "__main" then
            
            if Env[Key] then

                print("Warning: Library item '" .. Key .. "' being overwritten.")

            end

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