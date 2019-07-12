local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local InputDrag = Class:FromName(script.Name)

function InputDrag:InputDrag(Damping)
    return {
        Damping = 1 - (Damping or 0.2);
    }
end

function InputDrag:SetVectorMonitor(Monitor)
    local Value = Monitor()
    self.VectorMonitor = Monitor
    self.Velocity = Value - Value -- Zero-vector
end

function InputDrag:SetActiveMonitor(Monitor)
    self.ActiveMonitor = Monitor
end

function InputDrag:SetUpdateHandler(Handler)
    self.UpdateHandler = Handler
end

function InputDrag:Reset()
    self.LastPosition = nil
end

function InputDrag:Update()
    if (self.ActiveMonitor()) then
        if (not self.LastPosition) then -- Set up initial position
            self.LastPosition = self.VectorMonitor()
        end
    else
        self:Damp()
        return
    end

    local NewPosition = self.VectorMonitor()
    local Diff = NewPosition - self.LastPosition
    self.Velocity = self.Velocity + Diff
    self:Damp()
    self.LastPosition = NewPosition
end

function InputDrag:Damp()
    self.Velocity = self.Velocity * self.Damping
    self.UpdateHandler(self.Velocity)
end

return InputDrag