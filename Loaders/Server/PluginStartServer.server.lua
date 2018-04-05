local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Config                = ReplicatedStorage.Configuration
local LoadOrder             = require(Config.LoadOrder)
local ImportFunction        = require(ReplicatedStorage.Novarine)
local Indicator             = game:GetService("RunService"):IsServer() and "Server" or "Client"

require(Config.Config)

for Key, Value in next, LoadOrder do
    
    local Library = ReplicatedStorage.Library:FindFirstChild(Value)
    
    if Library then
        
        local Now = tick()
        require(Library)
        print("[Load Order " .. Key .. "] Library: " .. Library.Name .. " Loaded on " .. Indicator ..
            " (" .. ("%.2f"):format((tick() - Now) * 1000) .. "ms)")
        
    end
    
end

ImportFunction("Complete")