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

local Server = {
    PlayerData = {};
    LastSaveTimes = {};
    PlayerDataManagement = {Saving = {}};
};

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

    Server.PlayerDataManagement.Save(ID) -- TODO: save async instead?

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
    Logging.Debug(5, "Saving data for player %d(%s)...", ID, (Player and Player.Name or "Unknown"))

    local Success = ypcall(function()
        local Data = Server.PlayerData[ID]

        if (not Data) then
            return
        end

        Server.PlayerDataStore:UpdateAsync(ID, function()
            return Server.PlayerDataManagement.RecursiveSerialise(Static.CopyNested(Data))
        end)
    end)

    if (not Success) then
        -- Could be due to bad data type, so check all
        local function Types(Data, List)
            local DataType = typeof(Data)
        
            if (DataType == "table") then
                for _, Item in pairs(Data) do
                    Types(Item, List)
                end
            end
        
            List[DataType] = true
        end

        print("--- Bad save, types in table:")

        local DataTypes = {}
        Types(Server.PlayerData[ID], DataTypes)

        for Type in pairs(DataTypes) do
            print(">" .. Type)
        end

        print("End display. ---")
    end

    Logging.Debug(5, "Successfully saved data for player %d(%s)", ID, (Player and Player.Name or "Unknown"))
    Server.PlayerDataManagement.Saving[ID] = false
end

function Server.PlayerDataManagement.Load(Player)
    local ID = Player.UserId

    Logging.Debug(5, "Attempting to get data for player %d(%s)...", ID, Player.Name)

    local NewData = false
    local DataMigrate = Novarine:Get("DataMigrate")
    local Attempted = Server.PlayerDataStore:GetAsync(ID)

    if (not Attempted) then
        NewData = true
        Attempted = {}
    end

    local Built = Server.PlayerDataManagement.RecursiveBuild(Attempted)
    Logging.Debug(5, "Got data for player %d(%s)", ID, Player.Name)

    if NewData then
        -- No need to migrate new data, just put up latest version
        Built = DataMigrate.Template({})
        Built.Version = #DataMigrate.Versions -- Set to latest version
        Server.PlayerData[ID] = Built
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
    Server.PlayerData[ID] = Built
    Logging.Debug(0, "Migrated data for player %d(%s)", ID, Player.Name)
end

--[[
    @function Server.Init

    Initialises the DataStore.
]]
function Server.Init()
    local DataStore

    ypcall(function()
        local DataStoreVersions = ReplicatedStorage.DataStoreVersions
        local DataStoreTarget = DataStoreVersions:FindFirstChild(game.PlaceId) or DataStoreVersions.Default
        Logging.Debug(0, "Found DataStore version '%s'.", DataStoreTarget.Value)

        DataStore = DataStoreService:GetDataStore(DataStoreTarget.Value --[[ ReplicatedStorage.DataStoreVersion.Value ]])
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
        local Success, Result = ypcall(function()
            Server.PlayerDataManagement.Load(Player)
        end)

        if (not Success) then
            Logging.Debug(0, "Error loading player data: " .. Result)
            -- Todo: warn player
            return
        end

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