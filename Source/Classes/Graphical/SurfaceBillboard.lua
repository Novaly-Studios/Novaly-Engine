local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local SurfaceBillboard = Class:FromName(script.Name)

function SurfaceBillboard:SurfaceBillboard(Part, Adornee, MaxDistance, Offset)

    if (Part.CanCollide) then
        warn(string.format("Warning: Surface billboard '%s' is CanCollide.", Part.Name))
    end

    if (not Part.Anchored) then
        warn(string.format("Warning: Surface billboard '%s' is not anchored.", Part.Name))
    end

    return {
        Part        = Part;
        Offset      = Offset or CFrame.new(0, 0, 0);
        Adornee     = Adornee;
        MaxDistance = MaxDistance;
        Enabled     = true;
    }
end

function SurfaceBillboard:Update()

    local Part          = self.Part
    local Offset        = self.Offset
    local OffsetPos     = self.OffsetPos or Vector3.new()
    local Adornee       = self.Adornee
    local MaxDistance   = self.MaxDistance
    local GUI           = Part:FindFirstChild("SurfaceGui") or Part:FindFirstChild("SurfaceGUI")

    if (not GUI) then
        return
    end

    local From          = (Adornee.CFrame * Offset).p + OffsetPos
    local To            = Novarine:Get("Graphics").Camera.CFrame.p
    local RelDistance   = (From - To).magnitude

    if (not self.Enabled) then
        GUI.Enabled = false
        return
    end

    if (RelDistance > MaxDistance) then
        GUI.Enabled = false
        return
    end

    GUI.Enabled =  true
    Part.CFrame = CFrame.new(From, To)
end

function SurfaceBillboard:Destroy()
    self.Part = nil
end

return SurfaceBillboard