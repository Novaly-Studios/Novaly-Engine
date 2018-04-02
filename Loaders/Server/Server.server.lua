while not _G["Loaded"] do wait() end
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

repeat wait() until Players:GetChildren()[1]
local Player = Players:GetChildren()[1]

PlayerDataManagement.WaitForPlayerData(Player)

PlayerData[tostring(Player.UserId)] = {
    Check = 1;
    Money = 3000;
    Ayy = {
        Value = "Str";
        Numeric = 353425.124;
    };
}