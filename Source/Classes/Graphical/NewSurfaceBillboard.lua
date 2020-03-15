local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local RunService = Novarine:Get("RunService")
local Class = Novarine:Get("Class")
local Misc = Novarine:Get("Misc")

local NewSurfaceBillboard = Class:FromName(script.Name)

function NewSurfaceBillboard:NewSurfaceBillboard(Part)
    if (Part.CanCollide) then
        warn(string.format("Warning: Surface billboard '%s' is CanCollide.", Part.Name))
    end

    if (not Part.Anchored) then
        warn(string.format("Warning: Surface billboard '%s' is not anchored.", Part.Name))
    end

    local Settings = Part:FindFirstChild("Settings")
    assert(Settings, string.format("No settings found for '%s'!", Part:GetFullName()))

    local SettingsAsTable = Misc:TableFromTreeValues(Settings)

    return {
        Part = Part;
        OriginalSize = Part.Size;
        Offset = SettingsAsTable.Offset or CFrame.new(0, 0, 0);
        OffsetPos = SettingsAsTable.OffsetPos or Vector3.new(0, 0, 0);
        Adornee = SettingsAsTable.Adornee or Part.Parent;
        MaxDistance = SettingsAsTable.MaxDistance or 750;
        MaximumScale = SettingsAsTable.MaximumScale or 15;
        MinimumScale = SettingsAsTable.MinimumScale or 1.5;
        DistanceScale = SettingsAsTable.DistanceScale;
        DistanceMultiplier = SettingsAsTable.DistanceMultiplier or 0.5;
    };
end

function NewSurfaceBillboard:Initial()
    self.Connection = RunService.Stepped:Connect(function()
        self:Update()
    end)
end

function NewSurfaceBillboard:Destroy()
    self.Connection:Disconnect()
end

function NewSurfaceBillboard:Update()
    local Part = self.Part

    if (not self.Part) then
        self:Destroy()
        return
    end

    local Offset = self.Offset
    local Adornee = self.Adornee
    local MaxDistance = self.MaxDistance
    local GUI = Part:FindFirstChildWhichIsA("SurfaceGui", true)

    if (not GUI) then
        return
    end

    local OffsetPos = (self.OffsetPos or Vector3.new()) + Vector3.new(0, Part.Size.Y / 2, 0)
    local From = (Adornee.CFrame * Offset).Position + OffsetPos
    local To = Novarine:Get("Graphics").Camera.CFrame.Position
    local Distance = (From - To).magnitude

    if (Distance > MaxDistance) then
        GUI.Enabled = false
        return
    end

    if (self.DistanceScale) then
        local DesiredSize = self.OriginalSize * (Distance * self.DistanceMultiplier) / self.DistanceScale
        Part.Size = Vector3.new(math.clamp(DesiredSize.X, self.MinimumScale * self.OriginalSize.X, self.MaximumScale * self.OriginalSize.X), math.clamp(DesiredSize.Y, self.MinimumScale * self.OriginalSize.Y, self.MaximumScale * self.OriginalSize.Y), self.OriginalSize.Z)
    end

    GUI.Enabled =  true
    Part.CFrame = CFrame.new(From, To)
end

function NewSurfaceBillboard:Destroy()
    self.Part = nil
end

return NewSurfaceBillboard