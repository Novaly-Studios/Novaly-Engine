local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

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
    Table.WaitFor(wait, Server, "PlayerDataStore")
end

function Server.PlayerDataManagement.WaitForPlayerData(Player)
    Server.PlayerDataManagement.WaitForDataStore()
    return Table.WaitFor(wait, PlayerData, tostring(Player.UserId))
end

function Server.PlayerDataManagement.RecursiveSerialise(Data)

    for Key, Value in Pairs(Data) do
        if (DataStructures.GetType(Value) == "Color3") then
            Data[Key] = {TYPE = "Color3", Red = Value.r, Green = Value.g, Blue = Value.b}
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
                if (DataType == "Color3") then
                    Data[Key] = Color3.new(Value.Red, Value.Green, Value.Blue)
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
    local Stripped = Replication.StripReplicatedData(PlayerData[UserId])
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    Server.PlayerDataStore:SetAsync(UserId, Serial)
    --Server.PlayerDataStore:SetAsync(UserId .. CONFIG.pBackupSuffix, Stripped)
end

function Server.PlayerDataManagement.LeaveSave(Player)

    local UserId = tostring(Player.UserId)
    Server.PlayerDataManagement.WaitForPlayerData(Player)
    local Stripped = Replication.StripReplicatedData(PlayerData[UserId])
    local Serial = Server.PlayerDataManagement.RecursiveSerialise(Stripped)

    Wait(6.5)

    Server.PlayerDataStore:SetAsync(UserId, Serial)
    --Server.PlayerDataStore:SetAsync(UserId .. CONFIG.pBackupSuffix, Stripped)
end

function Server.Init()

    -- Metamethods are necessary to convert player ID to string when ID < 0

    ReplicatedData.PlayerData = PlayerData
    Server.PlayerData = PlayerData

    Players.PlayerAdded:Connect(function(Player)

        Server.PlayerDataManagement.WaitForDataStore()

        local Success, Data = ProtectedCall(function()
            return Server.PlayerDataStore:GetAsync(tostring(Player.UserId))
        end)

        while (Success == false) do
            Success, Data = ProtectedCall(function()
                return Server.PlayerDataStore:GetAsync(tostring(Player.UserId))
            end)
            Wait(CONFIG.pPlayerDataRetry)
        end

        Data = Data or {
            Check = 0;
        }

        if (Data.Check == 0) then
            local Backup = Server.PlayerDataStore:GetAsync(tostring(Player.UserId) .. CONFIG.pBackupSuffix)
            if Backup then
                if (Backup.Check) then
                    if (Backup.Check > Data.Check) then
                        Log(0, "Abnormal data check found, restoring from backup.")
                        Data = Backup or Data
                    end
                end
            end
        end

        Server.PlayerDataManagement.RecursiveBuild(Data)

        repeat Wait() until TransmissionReady[Player.Name]
        PlayerData[ToString(Player.UserId)] = Data
        Data.Check = Data.Check + 1

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
    return Table.WaitFor(wait, PlayerData, ToString(Player.UserId))
end

function Client.PlayerDataManagement.WaitForMyData()
    return Table.WaitFor(wait, Client.PlayerDataManagement, "MyData")
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
        Client.PlayerDataManagement.MyData = PlayerData[tostring(LocalPlayer.UserId)]
    end)
end

local function WaitForItem(Player, Key)

    local UserId = ToString(Player.UserId)
    local Result = PlayerData[UserId][Key]

    while Result == nil do
        Wait()
        Result = PlayerData[UserId][Key]
    end

    return Result
end

Client.PlayerDataManagement.WaitForItem = WaitForItem
Server.PlayerDataManagement.WaitForItem = WaitForItem

Func({
    Client = Client;
    Server = Server;
})

return true