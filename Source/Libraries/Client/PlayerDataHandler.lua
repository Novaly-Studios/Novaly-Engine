local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Players = Novarine:Get("Players")
local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")
local ReplicatedData = Replication.ReplicatedData

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local PlayerData                = {}
local Client                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Client.PlayerDataManagement.WaitForPlayerData(Player)
    return Table.WaitFor(wait, PlayerData, tostring(Player.UserId))
end

function Client.PlayerDataManagement.WaitForMyData()
    return Table.WaitFor(wait, Client.PlayerDataManagement, "MyData")
end

function Client.Init()
    coroutine.wrap(function()
        while (Players.LocalPlayer == nil) do
            wait()
        end

        local LocalPlayer = Players.LocalPlayer
        Client.Player = LocalPlayer

        Replication.Wait("PlayerData")
        PlayerData = ReplicatedData.PlayerData

        Client.PlayerDataManagement.PlayerData = PlayerData
        Client.PlayerDataManagement.WaitForPlayerData(LocalPlayer)
        Client.PlayerDataManagement.MyData = PlayerData[tostring(LocalPlayer.UserId)]
    end)()
end

local function WaitForItem(Player, Key)

    local UserId = tostring(Player.UserId)
    local Result = PlayerData[UserId][Key]

    while (Result == nil) do
        wait()
        Result = PlayerData[UserId][Key]
    end

    return Result
end

Client.PlayerDataManagement.WaitForItem = WaitForItem

return Client