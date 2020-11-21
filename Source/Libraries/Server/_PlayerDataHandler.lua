local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
local DataStoreService = Novarine:Get("DataStoreService")
local DataStructures = Novarine:Get("DataStructures")
local Communication = Novarine:Get("Communication")
local Replication = Novarine:Get("Replication")
local RunService = Novarine:Get("RunService")
local Logging = Novarine:Get("Logging")
local Players = Novarine:Get("Players")
local Static = Novarine:Get("Static")
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local ReplicatedData = Replication.ReplicatedData
local DataStoreFake

local DataHandler = {
    PlayerData = {};
    LastSaveTimes = {};
    PlayerDataManagement = {Saving = {}};

    SaveInterval = 10;
};

function DataHandler.PlayerDataManagement.WaitForDataStore()
    Table.WaitFor(wait, DataHandler, "PlayerDataStore")
end

function DataHandler.PlayerDataManagement.WaitForPlayerDataCallback(Player, Callback)
    assert(type(Callback) == "function")
    Replication:WaitFor("PlayerData", Player.UserId, Callback)
end

function DataHandler.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    Replication:WaitFor("PlayerData", Player.UserId, ...)
end

function DataHandler.PlayerDataManagement.GetAttribute(Player, ...)
    return Replication:Get("PlayerData", Player.UserId, ...)
end

function DataHandler.PlayerDataManagement.WaitForPlayerData(Player)
    return Replication:WaitForYield("PlayerData", Player.UserId)
end

function DataHandler.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    return Replication:WaitForYield("PlayerData", Player.UserId, ...)
end

function DataHandler.PlayerDataManagement.RecursiveSerialise(Data)

    for Key, Value in pairs(Data) do
        if (DataStructures:CanSerialise(DataStructures:GetType(Value)) and type(Value) == "userdata") then
            Data[Key] = DataStructures:Serialise(Value)
        elseif (type(Value) == "table") then
            DataHandler.PlayerDataManagement.RecursiveSerialise(Value)
        end
    end

    return Data
end

function DataHandler.PlayerDataManagement.RecursiveBuild(Data)

    for Key, Value in pairs(Data) do
        if (type(Value) == "table") then
            local DataType = Value.TYPE
            if DataType then
                if (DataStructures:CanBuild(DataType)) then
                    Data[Key] = DataStructures:Build(Value)
                end
            end
            DataHandler.PlayerDataManagement.RecursiveBuild(Value)
        end
    end

    return Data
end

--[[
    @function DataHandler.LeaveSave

    Saves the data when the player leaves the server.

    @note This is the only time the data saves.
]]
function DataHandler.LeaveSave(Player)
    local ID = Player.UserId

    -- Could still be loading, in which case better to discard,
    -- since player has probable moved to another server by this time
    if (not DataHandler.PlayerData[ID]) then
        return
    end

    DataHandler.Save(ID)

    ReplicatedData.PlayerData[ID] = nil
    DataHandler.PlayerData[ID] = nil

    if DataStoreFake then
        DataHandler.PlayerDataStore[ID] = nil
    end
end

function DataHandler.Save(ID, Player)
    if (DataHandler.PlayerDataManagement.Saving[ID]) then
        return
    end

    DataHandler.PlayerDataManagement.Saving[ID] = true
    Logging.Debug(5, "Saving data for player %d(%s)...", ID, (Player and Player.Name or "Unknown"))

    ypcall(function()
        local Data = DataHandler.PlayerData[ID]

        if (not Data) then
            return
        end

        DataHandler.Lock(ID, function()
            DataHandler.PlayerDataStore:UpdateAsync(ID, function()
                return DataHandler.PlayerDataManagement.RecursiveSerialise(Static.CopyNested(Data))
            end)
        end)
    end)

    Logging.Debug(5, "Successfully saved data for player %d(%s)", ID, (Player and Player.Name or "Unknown"))
    DataHandler.PlayerDataManagement.Saving[ID] = false
end

function DataHandler.PlayerDataManagement.Load(Player)
    local ID = Player.UserId

    Logging.Debug(5, "Attempting to get data for player %d(%s)...", ID, Player.Name)

    local NewData = false
    local DataMigrate = Novarine:Get("DataMigrate")
    local Attempted

    DataHandler.Lock(ID, function()
        Attempted = DataHandler.PlayerDataStore:GetAsync(ID)
    end)

    if (not Attempted) then
        NewData = true
        Attempted = {}
    end

    local Built = DataHandler.PlayerDataManagement.RecursiveBuild(Attempted)
    Logging.Debug(5, "Got data for player %d(%s)", ID, Player.Name)

    if NewData then
        -- No need to migrate new data, just put up latest version
        Built = DataMigrate.Template({})
        Built.Version = #DataMigrate.Versions -- Set to latest version
        DataHandler.PlayerData[ID] = Built
        return
    end

    local NextVersion = (Built.Version or 0) + 1
    local VersionTransitioners = DataMigrate.Versions

    for Index = NextVersion, #VersionTransitioners do
        Built = VersionTransitioners[Index](Built)
        Built.Version = Index
        Logging.Debug(0, "\t-> Version" .. Index)
    end

    Built = DataMigrate.Template(Built)
    DataHandler.PlayerData[ID] = Built
    Logging.Debug(0, "Migrated data for player %d(%s)", ID, Player.Name)
end

--[[
    @function DataHandler.Init

    Initialises the DataStore.
]]
function DataHandler.Init()
    local DataStore

    pcall(function()
        local DataStoreVersions = ReplicatedStorage.DataStoreVersions
        local DataStoreTarget = DataStoreVersions:FindFirstChild(game.PlaceId) or DataStoreVersions.Default
        Logging.Debug(0, "Found DataStore version '%s'.", DataStoreTarget.Value)

        DataStore = DataStoreService:GetDataStore(DataStoreTarget.Value --[[ ReplicatedStorage.DataStoreVersion.Value ]])
        Logging.Debug(0, "Got datastore.")
    end)

    if (not DataStore) then
        Logging.Debug(0, "Could not get DataStore, using fake.")
        DataStoreFake = true
        DataStore = DataHandler.FakeDataStore
    end

    DataHandler.PlayerDataStore = DataStore
    ReplicatedData.PlayerData = DataHandler.PlayerData

    Players.PlayerAdded:Connect(function(Player)
        local Success, Result = pcall(function()
            DataHandler.PlayerDataManagement.Load(Player)
        end)

        if (not Success) then
            Logging.Debug(0, "Error loading player data: " .. Result)
            -- Todo: warn player
            return
        end

        game:BindToClose(function()
            DataHandler.LeaveSave(Player)
        end)

        local Halt; Halt = Async.Timer(DataHandler.SaveInterval, function()
            if (not Player.Parent) then
                Halt()
                return
            end

            DataHandler.Save(Player.UserId)
        end)
    end)

    Players.PlayerRemoving:Connect(DataHandler.LeaveSave)

    Async.Timer(15, function()
        -- Server alive status, for timeout
        DataStore:SetAsync("Game" .. game.JobId, {
            Heartbeat = os.time();
        })
    end)
end

function DataHandler.Lock(UserID)
    DataHandler.PlayerData[ID]
end

DataHandler.FakeDataStore = {
    GetAsync = function(Self, Key)
        return Self[Key]
    end;
    SetAsync = function(Self, Key, Value)
        Self[Key] = Value
    end;
    UpdateAsync = function(Self, Key, Operator)
        Self[Key] = Operator(Self[Key])
    end;
};

return DataHandler