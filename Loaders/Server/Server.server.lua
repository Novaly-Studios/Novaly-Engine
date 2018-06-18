setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

repeat wait() until Players:GetChildren()[1]
local Player = Players:GetChildren()[1]

PlayerDataManagement.WaitForPlayerData(Player)

PlayerData[tostring(Player.UserId)] = {
    Check = 1;
    Money = 3000;
    Ayy = {
        Value = "Str";
        Numeric = 353425.124;
        Colour = Color3.new(1, 0, 0);
    };
}