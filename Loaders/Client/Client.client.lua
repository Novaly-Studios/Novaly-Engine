while not _G["Loaded"] do wait() end
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local SunObject = {Position = Vector3.new()}
local Player = Players.LocalPlayer

-- ImageID, Offset, Size, Raycast, Distance, Scale, Rotate
local Flare1 = LensFlare.new("rbxassetid://109801097", 0.3, Vector2.new(75, 75), true, 0, false, true)
local Flare2 = LensFlare.new("rbxassetid://109801097", 0.5, Vector2.new(100, 100), true, 0, false, true)
local Flare3 = LensFlare.new("rbxassetid://109801097", 0.7, Vector2.new(125, 125), true, 0, false, true)

function UpdateSunPosition()

	SunObject.Position = Graphics.Camera.CFrame.p + Lighting:GetSunDirection() * (Player.CameraMaxZoomDistance + 1)

end

RunService.Heartbeat:Connect(UpdateSunPosition)

Graphics.RegisterFlare(
	"SunFlare",
	{
		{SunObject, Flare1},
		{SunObject, Flare2},
		{SunObject, Flare3}
	},
	0.2
)