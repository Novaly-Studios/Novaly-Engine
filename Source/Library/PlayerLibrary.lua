local Func = require(game:GetService("ReplicatedStorage").Import)
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

    while Server.PlayerDataStore == nil do

        wait()

    end

end

function Server.PlayerDataManagement.WaitForPlayerData(Player)

    Server.PlayerDataManagement.WaitForDataStore()

    while PlayerData[tostring(Player.UserId)] == nil do

        wait()

    end

end

function Server.PlayerDataManagement.Save(Player)

    Server.PlayerDataManagement.WaitForPlayerData(Player)
    
    local UserId = tostring(Player.UserId)
    local Stripped = Replication.StripReplicatedData(PlayerData[UserId])
    
    Server.PlayerDataStore:SetAsync(UserId, Stripped)
    Server.PlayerDataStore:SetAsync(UserId .. CONFIG.pBackupSuffix, Stripped)

end

function Server.__main()

    -- Metamethods are necessary to convert player ID to string when ID < 0

    ReplicatedData.PlayerData = PlayerData
    Server.PlayerData = PlayerData

    Players.PlayerAdded:Connect(function(Player)

        Server.PlayerDataManagement.WaitForDataStore()

        local Data = Server.PlayerDataStore:GetAsync(tostring(Player.UserId)) or {

            Check = 0;

        }

        if Data.Check == 0 then

            local Backup = Server.PlayerDataStore:GetAsync(tostring(Player.UserId) .. CONFIG.pBackupSuffix)

            if Backup then

                Log(0, "Abnormal data check found, restoring from backup.")
                Data = Backup or Data

            end

        end

        repeat wait() until TransmissionReady[Player.Name]
        PlayerData[tostring(Player.UserId)] = Data
        Data.Check = Data.Check + 1

        while wait(CONFIG.pSaveInterval) do

            if not Player then break end

            Server.PlayerDataManagement.Save(Player)

        end

    end)

    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.Save)

    Sub(function()

        local function TryGet()

            Server.PlayerDataStore = Svc("DataStoreService"):GetDataStore(CONFIG.pDataStoreName .. CONFIG.pDataStoreVersion)

        end
        
        TryGet()

        while Server.PlayerDataStore == nil do

            TryGet()
            wait(CONFIG.pDataStoreGetRetryWait)

        end

    end)

end

function Client.PlayerDataManagement.WaitForPlayerData(Player)

    while PlayerData[tostring(Player.UserId)] == nil do

        wait()

    end

end

function Client.PlayerDataManagement.WaitForMyData()

    while Client.PlayerDataManagement.MyData == nil do

        wait()

    end

end

function Client.__main()
    
    while Players.LocalPlayer == nil do

        wait()

    end

    local LocalPlayer = Players.LocalPlayer
    Client.Player = LocalPlayer
    
    repeat wait() until LocalPlayer.Character ~= nil
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

    local UserId = tostring(Player.UserId)
    local Result = PlayerData[UserId][Key]

    while Result == nil do

        wait()
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