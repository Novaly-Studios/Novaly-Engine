local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Players = Novarine:Get("Players")
local Replication = Novarine:Get("Replication")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Client                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Client.PlayerDataManagement.WaitForPlayerDataCallback(Player, Callback)
    assert(type(Callback) == "function")
    Replication:WaitFor("PlayerData", Player.UserId, Callback)
end

function Client.PlayerDataManagement.WaitForMyDataCallback(Callback)
    assert(type(Callback) == "function")
    Replication:WaitFor("PlayerData", Players.LocalPlayer.UserId, Callback)
end

function Client.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    Replication:WaitFor("PlayerData", Player.UserId, ...)
end

function Client.PlayerDataManagement.WaitForMyDataAttribute(...)
    Replication:WaitFor("PlayerData", Players.LocalPlayer.UserId, ...)
end

function Client.PlayerDataManagement.GetAttribute(Player, ...)
    return Replication:Get("PlayerData", Player.UserId, ...)
end

function Client.PlayerDataManagement.GetMyAttribute(...)
    return Replication:Get("PlayerData", Players.LocalPlayer.UserId, ...)
end

function Client.PlayerDataManagement.WaitForPlayerData(Player)
    return Replication:WaitForYield("PlayerData", Player.UserId)
end

function Client.PlayerDataManagement.WaitForMyData()
    return Replication:WaitForYield("PlayerData", Players.LocalPlayer.UserId)
end

function Client.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    return Replication:WaitForYield("PlayerData", Player.UserId, ...)
end

function Client.PlayerDataManagement.WaitForMyDataAttribute(...)
    return Replication:WaitForYield("PlayerData", Players.LocalPlayer.UserId, ...)
end

function Client.Init()
    coroutine.wrap(function()
        while (Players.LocalPlayer == nil) do
            wait()
        end

        local LocalPlayer = Players.LocalPlayer
        Client.Player = LocalPlayer

        while (not Replication.ReplicatedData.PlayerData) do
            wait(0.05)
        end

        coroutine.wrap(function()
            while wait(0.1) do
                Client.PlayerDataManagement.PlayerData = Replication.ReplicatedData.PlayerData
                Client.PlayerData = Replication.ReplicatedData.PlayerData
            end
        end)()

        Client.PlayerDataManagement.WaitForPlayerData(LocalPlayer)
        Client.PlayerDataManagement.MyData = Replication.ReplicatedData.PlayerData[LocalPlayer.UserId]
    end)()
end

return Client