while not _G["Loaded"] do wait() end
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())
