local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Configuration = Novarine:Get("Configuration")
local Players = Novarine:Get("Players")
local Communication = Novarine:Get("Communication")
local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")
local DataStructures = Novarine:Get("DataStructures")
local DataStoreService = Novarine:Get("DataStoreService")
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
local Logging = Novarine:Get("Logging")

local ReplicatedData = Replication.ReplicatedData

--local PlayerData                = {}
local Server                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Server.PlayerDataManagement.WaitForDataStore()
    Table.WaitFor(wait, Server, "PlayerDataStore")
end

function Server.PlayerDataManagement.WaitForPlayerDataCallback(Player, Callback)
    assert(type(Callback) == "function")
    Replication:WaitFor("PlayerData", tostring(Player.UserId), Callback)
end

function Server.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    Replication:WaitFor("PlayerData", tostring(Player.UserId), ...)
end

function Server.PlayerDataManagement.GetAttribute(Player, ...)
    return Replication:Get("PlayerData", tostring(Player.UserId), ...)
end

function Server.PlayerDataManagement.WaitForPlayerData(Player)
    return Replication:WaitForYield("PlayerData", tostring(Player.UserId))
end

function Server.PlayerDataManagement.WaitForPlayerDataAttribute(Player, ...)
    return Replication:WaitForYield("PlayerData", tostring(Player.UserId), ...)
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

function Server.PlayerDataManagement.Save(Player)
    Server.PlayerDataManagement.WaitForPlayerDataCallback(Player, function(PlayerData)
        Server.PlayerDataStore:SetAsync(tostring(Player.UserId), Server.PlayerDataManagement.RecursiveSerialise(Table.Clone(PlayerData)))
    end)
end

function Server.PlayerDataManagement.LeaveSave(Player)
    local ID = tostring(Player.UserId)

    Server.PlayerDataManagement.WaitForPlayerDataCallback(Player, function(PlayerData)
        wait(6.5)

        ypcall(function()
            Server.PlayerDataStore:SetAsync(tostring(Player.UserId), Server.PlayerDataManagement.RecursiveSerialise(Table.Clone(PlayerData)))
        end)

        ReplicatedData.PlayerData[ID] = nil
    end)

    --[[Server.PlayerDataStore:UpdateAsync(UserId, function()
        return Serial
    end)]]
end

function Server.Init()
    -- Metamethods are necessary to convert player ID to string when ID < 0

    ReplicatedData.PlayerData = Server.PlayerData

    local function Handle(Player)
        Server.PlayerDataManagement.WaitForDataStore()

        local Success, Data = pcall(function()
            return Server.PlayerDataStore:GetAsync(tostring(Player.UserId))
        end)

        while (Success == false) do
            Success, Data = pcall(function()
                return Server.PlayerDataStore:GetAsync(tostring(Player.UserId))
            end)
            wait(Configuration.pPlayerDataRetry)
        end

        Data = Data or {}
        Server.PlayerDataManagement.RecursiveBuild(Data)

        while (not Communication.TransmissionReady[Player.Name]) do
            wait(0.05)
        end

        ReplicatedData.PlayerData[tostring(Player.UserId)] = Data

        while wait(Configuration.pSaveInterval) do
            if not Player.Parent then break end
            Server.PlayerDataManagement.Save(Player)
        end
    end

    coroutine.wrap(function()

        local function TryGet()
            if (game.PlaceId <= 0) then
                -- Player data manager running in test mode.
                Server.PlayerDataStore = {
                    GetAsync = function(Self, Key)
                        return Self[Key]
                    end;
                    SetAsync = function(Self, Key, Value)
                        Self[Key] = Value
                    end;
                }
                Logging.Debug(1, "Set data store as table")
            else
                Logging.Debug(1, "Set data store as live.")
                Server.PlayerDataStore = DataStoreService:GetDataStore(ReplicatedStorage:FindFirstChild("DataStoreVersion") and ReplicatedStorage.DataStoreVersion.Value or Configuration.pDataStoreVersion)
            end
        end

        while true do
            if pcall(TryGet) then
                break
            end
            wait(Configuration.pDataStoreGetRetrywait)
        end
    end)()

    Players.PlayerAdded:Connect(Handle)
    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.LeaveSave)

    for _, Item in pairs(Players:GetChildren()) do
        coroutine.wrap(Handle)(Item)
    end
end

return Server