setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Spring = Class:FromName(script.Name)

function Spring:Spring(Start, Target, Constant, Decay)
    return
    {
        Current     = Start;
        Velocity    = Start - Start;
        Decay       = 1.0 - Decay;
        Constant    = Constant;
        Target      = Target;
    }
end

function Spring:Update()

    local Current   = self.Current
    local Dist      = self.Target - Current
    local Velocity  = self.Velocity * self.Decay + Dist * self.Constant

    self.Current    = Current + Velocity
    self.Velocity   = Velocity
    self.Dist       = Dist
end

return Spring