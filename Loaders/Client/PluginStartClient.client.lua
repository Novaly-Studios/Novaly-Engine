ReplicatedStorage = game:GetService("ReplicatedStorage")
Config = ReplicatedStorage.Configuration
LoadOrder = require(Config.LoadOrder)
CSString = game:GetService("RunService"):IsServer() and "Server" or "Client"

require(ReplicatedStorage.Import)
print("Engine Handler Loaded...")

require(Config.Config)
print("Configurations Loaded...")

for Key, Value in next, LoadOrder do
    
    local Library = ReplicatedStorage.Library:FindFirstChild(Value)
    
    if Library then
        
        local Now = tick()
        require(Library)
        print("[Load Order " .. Key .. "] Library: " .. Library.Name .. " Loaded on " .. CSString ..
            " (" .. ("%.2f"):format((tick() - Now) * 1000) .. "ms)")
        
    end
    
end

_G["Loaded"] = true