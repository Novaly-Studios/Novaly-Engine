shared()

local Version                   = CONFIG.pVersion
local PlayerData                = {}
local Client                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}
local Server                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Server.PlayerDataManagement.WaitForDataStore()
    Table.WaitFor(Wait, Server, "PlayerDataStore")
end

function Server.PlayerDataManagement.WaitForPlayerData(Player)
    Server.PlayerDataManagement.WaitForDataStore()
    return Table.WaitFor(Wait, PlayerData, ToString(Player.UserId))
end

function Server.PlayerDataManagement.RecursiveSerialise(Data)

    for Key, Value in Pairs(Data) do
        if (DataStructures:CanSerialise(DataStructures:GetType(Value)) and Type(Value) == "userdata") then
            Data[Key] = DataStructures:Serialise(Value)
        elseif (Type(Value) == "table") then
            Server.PlayerDataManagement.RecursiveSerialise(Value)
        end
    end

    return Data
end

function Server.PlayerDataManagement.RecursiveBuild(Data)

    for Key, Value in Pairs(Data) do
        if (Type(Value) == "table") then
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

    local UserId = ToString(Player.UserId)
    local Stripped = Replication.StripReplicatedData(PlayerData[UserId])
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    --[[Server.PlayerDataStore:UpdateAsync(UserId, function()
        Table.PrintTable(Serial)
        return Serial
    end)]]
    Server.PlayerDataStore:SetAsync(UserId, Serial)
end

function Server.PlayerDataManagement.LeaveSave(Player)

    local UserId = ToString(Player.UserId)
    Server.PlayerDataManagement.WaitForPlayerData(Player)
    local Stripped = Replication.StripReplicatedData(PlayerData[UserId])
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    Wait(6.5)

    --[[Server.PlayerDataStore:UpdateAsync(UserId, function()
        return Serial
    end)]]
    Server.PlayerDataStore:SetAsync(UserId, Serial)
end

function Server.Init()

    -- Metamethods are necessary to convert player ID to string when ID < 0

    ReplicatedData.PlayerData = PlayerData
    Server.PlayerData = PlayerData

    Players.PlayerAdded:Connect(function(Player)

        Server.PlayerDataManagement.WaitForDataStore()

        local Success, Data = ProtectedCall(function()
            return Server.PlayerDataStore:GetAsync(ToString(Player.UserId))
        end)

        while (Success == false) do
            Success, Data = ProtectedCall(function()
                return Server.PlayerDataStore:GetAsync(ToString(Player.UserId))
            end)
            Wait(CONFIG.pPlayerDataRetry)
        end

        Data = Data or {}

        Server.PlayerDataManagement.RecursiveBuild(Data)

        repeat Wait() until TransmissionReady[Player.Name]
        PlayerData[ToString(Player.UserId)] = Data

        while Wait(CONFIG.pSaveInterval) do
            if not Player.Parent then break end
            Server.PlayerDataManagement.Save(Player)
        end
    end)

    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.LeaveSave)

    Sub(function()

        local function TryGet()
            Server.PlayerDataStore = Svc("DataStoreService"):GetDataStore(CONFIG.pDataStoreName .. CONFIG.pDataStoreVersion)
        end
        
        TryGet()

        while (Server.PlayerDataStore == nil) do
            TryGet()
            Wait(CONFIG.pDataStoreGetRetryWait)
        end
    end)
end

function Client.PlayerDataManagement.WaitForPlayerData(Player)
    return Table.WaitFor(Wait, PlayerData, ToString(Player.UserId))
end

function Client.PlayerDataManagement.WaitForMyData()
    return Table.WaitFor(Wait, Client.PlayerDataManagement, "MyData")
end

function Client.Init()
    
    while (Players.LocalPlayer == nil) do
        Wait()
    end

    local LocalPlayer = Players.LocalPlayer
    Client.Player = LocalPlayer
    
    repeat Wait() until LocalPlayer.Character ~= nil
    Client.Character = LocalPlayer.Character

    Sub(function()
        Replication.Wait("PlayerData")
        PlayerData = ReplicatedData.PlayerData
        Client.PlayerDataManagement.PlayerData = PlayerData
        Client.PlayerDataManagement.WaitForPlayerData(LocalPlayer)
        Client.PlayerDataManagement.MyData = PlayerData[ToString(LocalPlayer.UserId)]
    end)
end

local function WaitForItem(Player, Key)

    local UserId = ToString(Player.UserId)
    local Result = PlayerData[UserId][Key]

    while (Result == nil) do
        Wait()
        Result = PlayerData[UserId][Key]
    end

    return Result
end

Client.PlayerDataManagement.WaitForItem = WaitForItem
Server.PlayerDataManagement.WaitForItem = WaitForItem

shared({
    Client = Client;
    Server = Server;
})

return true