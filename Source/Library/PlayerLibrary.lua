local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Version                   = CONFIG.pVersion
local Client                    = {}
local Server                    = {
    PlayerDataManagement        = {};
    PlayerData                  = {};
}

function Server.PlayerDataManagement.WaitForDataStore()

    while not Server.PlayerDataStore do

        wait()

    end

end

function Server.PlayerDataManagement.WaitForPlayerData(Player)

    Server.PlayerDataManagement.WaitForDataStore()

    while Server.PlayerData[tostring(Player.UserId)] == nil do

        wait()

    end

end

function Server.PlayerDataManagement.Save(Player)

    Server.PlayerDataManagement.WaitForPlayerData(Player)
    
    local Stripped = Server.PlayerData[tostring(Player.UserId)]
    local UserId = tostring(Player.UserId)

    Server.PlayerDataStore:SetAsync(UserId, Stripped)
    Server.PlayerDataStore:SetAsync(UserId .. CONFIG.pBackupSuffix, Stripped)

end

function Server.__main()

    -- Metamethods are necessary to convert player ID to string when ID < 0

    Server.PlayerData = Server.PlayerData

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

        Server.PlayerData[tostring(Player.UserId)] = Data
        Data.Check = Data.Check + 1

        while wait(CONFIG.pSaveInterval) do

            if not Player then break end

            Server.PlayerDataManagement.Save(Player)

        end

    end)

    Players.PlayerRemoving:Connect(Server.PlayerDataManagement.Save)

    Sub(function()

        local function TryGet()

            Server.PlayerDataStore = Svc("DataStoreService"):GetDataStore(CONFIG.pDataStoreName)

        end
        
        TryGet()

        while Server.PlayerDataStore == nil do

            TryGet()
            wait(CONFIG.pDataStoreGetRetryWait)

        end

    end)

end

function Client.__main()
    
    while Players.LocalPlayer == nil do

        wait()

    end

    local LocalPlayer = Players.LocalPlayer
    Client.Player = LocalPlayer
    
    repeat wait() until LocalPlayer.Character ~= nil
    Client.Character = LocalPlayer.Character
    
end

Func({
    Client = Client;
    Server = Server;
})

return true