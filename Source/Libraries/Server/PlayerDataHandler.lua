local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Players = Novarine:Get("Players")
local Communication = Novarine:Get("Communication")
local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")
local DataStructures = Novarine:Get("DataStructures")
local DataStoreService = Novarine:Get("DataStoreService")
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
local RunService = Novarine:Get("RunService")
local Logging = Novarine:Get("Logging")
local Async = Novarine:Get("Async")

local ReplicatedData = Replication.ReplicatedData
local DataStoreFake

--local PlayerData                = {}
local Server                    = {
    PlayerDataManagement        = {Saving = {}};
    PlayerData                  = {};
    LastSaveTimes               = {};
}

function Server.PlayerDataManagement.WaitForDataStore()
    Table.WaitFor(wait, Server, "PlayerDataStore")
end

function Server.PlayerDataManagement.WaitForPlayerDataCallback(Player, Callback)
    assert(type(Callback) == "function")
    Replication:WaitFor("PlayerData", Player.UserId, Callback)
end

function Server.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    Replication:WaitFor("PlayerData", Player.UserId, ...)
end

function Server.PlayerDataManagement.GetAttribute(Player, ...)
    return Replication:Get("PlayerData", Player.UserId, ...)
end

function Server.PlayerDataManagement.WaitForPlayerData(Player)
    return Replication:WaitForYield("PlayerData", Player.UserId)
end

function Server.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    return Replication:WaitForYield("PlayerData", Player.UserId, ...)
end

function Server.PlayerDataManagement.RecursiveSerialise(Data)

    for Key, Value in pairs(Data) do
        if (DataStructures:CanSerialise(DataStructures:GetType(Value)) and type(Value) == "userdata") then
            Data[Key] = DataStructures:Serialise(Value)
        elseif (type(Value) == "table") then
            Server.PlayerDataManagement.RecursiveSerialise(Value)
        end
    end

    return Data
end

function Server.PlayerDataManagement.RecursiveBuild(Data)

    for Key, Value in pairs(Data) do
        if (type(Value) == "table") then
            local DataType = Value.TYPE
            if DataType then
                if (DataStructures:CanBuild(DataType)) then
                    Data[Key] = DataStructures:Build(Value)
                end
            end
            Server.PlayerDataManagement.RecursiveBuild(Value)
        end
    end

    return Data
end

--[[
    @function Server.PlayerDataManagement.LeaveSave

    Saves the data when the player leaves the server.

    @note This is the only time the data saves.
]]
function Server.PlayerDataManagement.LeaveSave(Player)
    local ID = Player.UserId

    -- Could still be loading, in which case better to discard,
    -- since player has probable moved to another server by this time
    if (not Server.PlayerData[ID]) then
        return
    end

    Server.PlayerDataManagement.Save(ID)

    ReplicatedData.PlayerData[ID] = nil
    Server.PlayerData[ID] = nil

    if DataStoreFake then
        Server.PlayerDataStore[ID] = nil
    end
end

function Server.PlayerDataManagement.Save(ID, Player)
    if (Server.PlayerDataManagement.Saving[ID]) then
        return
    end

    Server.PlayerDataManagement.Saving[ID] = true
    Logging.Debug(0, "Saving data for player %d(%s)...", ID, (Player and Player.Name or "Unknown"))

    Server.PlayerDataStore:UpdateAsync(ID, function()
        return Server.PlayerData[ID]
    end)

    Logging.Debug(0, "Successfully saved data for player %d(%s)", ID, (Player and Player.Name or "Unknown"))
    Server.PlayerDataManagement.Saving[ID] = false
end

function Server.PlayerDataManagement.Load(Player)
    local ID = Player.UserId

    Logging.Debug(0, "Attempting to get data for player %d(%s)...", ID, Player.Name)
    Server.PlayerData[ID] = Server.PlayerDataStore:GetAsync(ID) or {}
    Logging.Debug(0, "Got data for player %d(%s)", ID, Player.Name)
end

--[[
    @function Server.Init

    Initialises the DataStore.
]]
function Server.Init()
    local DataStore

    ypcall(function()
        DataStore = DataStoreService:GetDataStore(ReplicatedStorage.DataStoreVersion.Value)
        Logging.Debug(0, "Got datastore.")
    end)

    if (not DataStore) then
        Logging.Debug(0, "Could not get DataStore, using fake.")
        DataStoreFake = true
        DataStore = Server.FakeDataStore
    end

    Server.PlayerDataStore = DataStore
    ReplicatedData.PlayerData = Server.PlayerData

    Players.PlayerAdded:Connect(function(Player)
        Server.PlayerDataManagement.Load(Player)

        game:BindToClose(function()
            Server.PlayerDataManagement.LeaveSave(Player)
        end)

        local Halt; Halt = Async.Timer(10, function()
            if (not Player.Parent) then
                Halt()
                return
            end

            Server.PlayerDataManagement.Save(Player.UserId)
        end)
    end)

    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.LeaveSave)
end

Server.FakeDataStore = {
    GetAsync = function(Self, Key)
        return Self[Key]
    end;
    SetAsync = function(Self, Key, Value)
        Self[Key] = Value
    end;
    UpdateAsync = function(Self, Key, Operator)
        Self[Key] = Operator(Self[Key])
    end;
}

return Server