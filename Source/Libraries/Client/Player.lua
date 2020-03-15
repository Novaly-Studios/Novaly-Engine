local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Players = Novarine:Get("Players")
local RunService = Novarine:Get("RunService")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Player = Players.LocalPlayer

while (not Player) do
    RunService.Stepped:Wait()
    Player = Players.LocalPlayer
end

return Player