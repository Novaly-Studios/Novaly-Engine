setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local TimeSpring = Class:FromName(script.Name)
local Euler = 2.7182818284590452353602875
 
function TimeSpring:TimeSpring(Properties)

    local Object    = {
        Start       = 0.0;
        Current     = 0.0;
        Velocity    = 0.0;
        Target      = 0.0;
        Compression = 1.0;
        Damping     = 0.2;
        InitialTime = Tick();
    }

    for Key, Value in Pairs(Properties) do
        local ValueType = Type(Value)
        local DefaultValue = Object[Key]
        Assert(DefaultValue ~= nil, String.Format("Invalid spring property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end
 
function TimeSpring:UpdateAt(CurrentTime)

    local Damping       = self.Damping
    local Compression   = self.Compression
    local Target        = self.Target

    local Diff          = (self.Start - Target)
    local Mul           = Math.Sqrt(1 - Damping ^ 2)
    local WaveFeed      = (Mul * Math.Tau * Compression * CurrentTime)

    self.Current = Target + Euler ^ (-Math.Tau * Compression * Damping * CurrentTime) 
            * (Diff * Math.Cos(WaveFeed) + (Damping * Compression * Diff + self.Velocity) / (Compression * Mul) * Math.Sin(WaveFeed))

    return self
end

function TimeSpring:Update()
    return self:UpdateAt(Tick() - self.InitialTime)
end

return TimeSpring