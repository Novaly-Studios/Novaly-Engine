local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Configuration = Novarine:Get("Configuration")
local Players = Novarine:Get("Players")
local Communication = Novarine:Get("Communication")
local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")
local DataStructures = Novarine:Get("DataStructures")
local DataStoreService = Novarine:Get("DataStoreService")
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")

local ReplicatedData = Replication.ReplicatedData

--local PlayerData                = {}
local Server                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Server.PlayerDataManagement.WaitForDataStore()
    Table.WaitFor(wait, Server, "PlayerDataStore")
end

function Server.PlayerDataManagement.WaitForPlayerData(Player)
    Server.PlayerDataManagement.WaitForDataStore()
    local TargetData = ReplicatedData.PlayerData[tostring(Player.UserId)]

    while (not TargetData) do
        wait(0.05)
        TargetData = ReplicatedData.PlayerData[tostring(Player.UserId)]
    end

    return TargetData
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

    Server.PlayerDataManagement.WaitForPlayerData(Player)

    local UserId = tostring(Player.UserId)
    local Stripped = Table.Clone(ReplicatedData.PlayerData[UserId]) --Replication.StripReplicatedData(PlayerData[UserId]) -- No longer necessary
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    --[[Server.PlayerDataStore:UpdateAsync(UserId, function()
        Table.printTable(Serial)
        return Serial
    end)]]
    Server.PlayerDataStore:SetAsync(UserId, Serial)
end

function Server.PlayerDataManagement.LeaveSave(Player)

    local UserId = tostring(Player.UserId)
    Server.PlayerDataManagement.WaitForPlayerData(Player)
    local Stripped = Table.Clone(ReplicatedData.PlayerData[UserId]) --Replication.StripReplicatedData(PlayerData[UserId])
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    wait(6.5)

    --[[Server.PlayerDataStore:UpdateAsync(UserId, function()
        return Serial
    end)]]
    Server.PlayerDataStore:SetAsync(UserId, Serial)
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

--[[         coroutine.wrap(function()
            wait(5)
            Table.PrintTable(ReplicatedData.PlayerData[tostring(Player.UserId)])
        end)() ]]

        while wait(Configuration.pSaveInterval) do
            if not Player.Parent then break end
            Server.PlayerDataManagement.Save(Player)
        end
    end

    Players.PlayerAdded:Connect(Handle)

    for _, Item in pairs(Players:GetChildren()) do
        Handle(Item)
    end

    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.LeaveSave)

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
            else
                Server.PlayerDataStore = DataStoreService:GetDataStore(ReplicatedStorage:FindFirstChild("DataStoreVersion") and ReplicatedStorage.DataStoreVersion.Value or Configuration.pDataStoreVersion)
            end
        end

        while (pcall(TryGet) == false) do
            wait(Configuration.pDataStoreGetRetrywait)
        end
    end)()
end

local function WaitForItem(Player, Key)

    local UserId = tostring(Player.UserId)
    local Result = Server.PlayerData[UserId][Key]

    while (Result == nil) do
        wait()
        Result = Server.PlayerData[UserId][Key]
    end

    return Result
end

Server.PlayerDataManagement.WaitForItem = WaitForItem

return Server