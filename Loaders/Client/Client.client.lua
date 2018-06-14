setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

local Player = Players.LocalPlayer
local PlrData = PlayerDataManagement.WaitForMyData()
print'a'
print(Table.WaitFor(wait, PlrData, "Ayy", "Value"))
print'b'