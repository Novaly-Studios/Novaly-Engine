local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Players = Novarine:Get("Players")
local Replication = Novarine:Get("Replication")
local ReplicatedData = Replication.ReplicatedData

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Client                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Client.PlayerDataManagement.WaitForPlayerData(Player)
    local Data = Replication.PlayerData[tostring(Player.UserId)]

    while (not Data) do
        Data = Replication.PlayerData[tostring(Player.UserId)]
        wait(0.05)
    end

    return Data
end

function Client.PlayerDataManagement.WaitForMyData()
    while (not Client.PlayerDataManagement.MyData) do
        wait(0.05)
    end

    return Client.PlayerDataManagement.MyData
end

function Client.Init()
    coroutine.wrap(function()
        while (Players.LocalPlayer == nil) do
            wait()
        end

        local LocalPlayer = Players.LocalPlayer
        Client.Player = LocalPlayer

        while (not ReplicatedData.PlayerData) do
            wait(0.05)
        end

        Replication.PlayerData = ReplicatedData.PlayerData

        Client.PlayerDataManagement.PlayerData = Replication.PlayerData
        Client.PlayerDataManagement.WaitForPlayerData(LocalPlayer)
        Client.PlayerDataManagement.MyData = Replication.PlayerData[tostring(LocalPlayer.UserId)]
    end)()
end

local function WaitForItem(Player, Key)

    local UserId = tostring(Player.UserId)
    local Result = Replication.PlayerData[UserId][Key]

    while (Result == nil) do
        wait()
        Result = Replication.PlayerData[UserId][Key]
    end

    return Result
end

Client.PlayerDataManagement.WaitForItem = WaitForItem

return Client