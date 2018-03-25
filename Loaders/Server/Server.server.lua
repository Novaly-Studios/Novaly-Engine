while not _G["Loaded"] do wait() end
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

repeat wait() until Players:GetChildren()[1]
local Player = Players:GetChildren()[1]

PlayerDataManagement.WaitForPlayerData(Player)

local Data = PlayerData[tostring(Player.UserId)]
Data.Money = Data.Money or 1000
Data.Money = Data.Money + 1