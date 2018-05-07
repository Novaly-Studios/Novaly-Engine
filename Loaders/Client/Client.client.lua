setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

local SunObject = {Position = Vector3.new()}
local Player = Players.LocalPlayer

-- ImageID, Offset, Size, Scale, Rotate
local Flare1 = LensFlare.new("109801097", 0.3, Vector2.new(75, 75), {1, 0}, true, true)
local Flare2 = LensFlare.new("109801105", 0.5, Vector2.new(100, 100), {1, 0}, true, true)
local Flare3 = LensFlare.new("89777777", 0.7, Vector2.new(125, 125), {1, 0}, true, true)
local FlareCollection1 = LensFlareCollection.new("Sun", 0.15, SunObject, 999)

function UpdateSunPosition()

    if Lighting.ClockTime >= 7 and Lighting.ClockTime <= 18 then
    
        SunObject.Position = Graphics.Camera.CFrame.p + Lighting:GetSunDirection() * 999
    
    else

        SunObject.Position = (Graphics.Camera.CFrame * CFrame.new(0, 0, 10)).p

    end

end

RunService.Heartbeat:Connect(UpdateSunPosition)

FlareCollection1:AddLensFlares(Flare1, Flare2, Flare3)
FlareCollection1:Start()
Graphics.RegisterFlare(FlareCollection1)