repeat wait() until _G["Loaded"]
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

print(Time.GetCurrentTime(tick()))
print(Date.GetCurrentDate(tick()))