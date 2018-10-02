shared()

local SurfaceBillboard = Class:FromName(script.Name)

function SurfaceBillboard:SurfaceBillboard(Part, Adornee, MaxDistance, Offset)

    if (Part.CanCollide) then
        warn(String.Format("Warning: Surface billboard '%s' is CanCollide.", Part.Name))
    end

    if (not Part.Anchored) then
        warn(String.Format("Warning: Surface billboard '%s' is not anchored.", Part.Name))
    end

    return {
        GUI         = Part:FindFirstChild("SurfaceGui") or Part:FindFirstChild("SurfaceGUI");
        Part        = Part;
        Offset      = Offset or CFrame.new(0, 0, 0);
        Adornee     = Adornee;
        MaxDistance = MaxDistance;
    }
end

function SurfaceBillboard:Update()

    local GUI           = self.GUI
    local Part          = self.Part
    local Offset        = self.Offset
    local Adornee       = self.Adornee
    local MaxDistance   = self.MaxDistance
    local From          = (Adornee.CFrame * Offset).p
    local To            = Graphics.Camera.CFrame.p
    local RelDistance   = (From - To).magnitude

    if (RelDistance > MaxDistance) then
        GUI.Enabled = false
        return
    end

    Part.CFrame = CFrame.new(From, To)
end

function SurfaceBillboard:Destroy()
    self.Part = nil
end

return SurfaceBillboard