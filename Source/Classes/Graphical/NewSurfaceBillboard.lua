local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local CollectiveObjectRegistry = Novarine:Get("CollectiveObjectRegistry")
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
        RotationOffset = SettingsAsTable.RotationOffset or CFrame.new();
        Graphics = Novarine:Get("Graphics");
        Enabled = true;
    };
end

function NewSurfaceBillboard:Init()
    RunService.RenderStepped:Connect(function()
        debug.profilebegin("SurfaceBillboard")

        --[[ for _, Item in pairs(CollectiveObjectRegistry.GetInstances(NewSurfaceBillboard)) do
            local Component = CollectiveObjectRegistry.GetComponent(Item, NewSurfaceBillboard) ]]
        for Component in pairs(CollectiveObjectRegistry.GetComponentsOfClass(NewSurfaceBillboard)) do
            if (not Component) then
                continue
            end

            if (not Component.Graphics) then
                Component.Graphics = Novarine:Get("Graphics")
            end
    
            Component:Update()
        end

        debug.profileend()
    end)
end

function NewSurfaceBillboard:Initial()
    --[[ self.Connection = RunService.RenderStepped:Connect(function()
        if (not self.Graphics) then
            self.Graphics = Novarine:Get("Graphics")
        end

        self:Update()
    end) ]]

    local Part = self.Part
    local GUI = Part:FindFirstChildWhichIsA("SurfaceGui", true)

    while (not GUI) do
        GUI = Part:FindFirstChildWhichIsA("SurfaceGui", true)
        wait(0.05)
    end

    self.GUI = GUI
end

function NewSurfaceBillboard:Destroy()
    --self.Connection:Disconnect()
    self.Part = nil
end

function NewSurfaceBillboard:Update()
    local Part = self.Part

    if (not Part) then
        --self:Destroy()
        return
    end

    local GUI = self.GUI

    if (not GUI) then
        return
    end

    GUI.Enabled = self.Enabled

    if (not self.Enabled) then
        return
    end

    local Offset = self.Offset
    local Adornee = self.Adornee
    local MaxDistance = self.MaxDistance

    local OffsetPos = (self.OffsetPos or Vector3.new()) + Vector3.new(0, Part.Size.Y / 2, 0)
    local From = (Adornee.CFrame * Offset).Position + OffsetPos
    local To = self.Graphics.Camera.CFrame.Position
    local Distance = (From - To).magnitude

    if (Distance > MaxDistance) then
        GUI.Enabled = false
        return
    end

    if (self.DistanceScale and self.Enabled) then
        local DesiredSize = self.OriginalSize * (Distance * self.DistanceMultiplier) / self.DistanceScale
        Part.Size = Vector3.new(math.clamp(DesiredSize.X, self.MinimumScale * self.OriginalSize.X, self.MaximumScale * self.OriginalSize.X), math.clamp(DesiredSize.Y, self.MinimumScale * self.OriginalSize.Y, self.MaximumScale * self.OriginalSize.Y), self.OriginalSize.Z)
    end

    Part.CFrame = CFrame.new(From, To) * self.RotationOffset
end

return NewSurfaceBillboard