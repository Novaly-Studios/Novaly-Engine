local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Math = Novarine:Get("Math")

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
        InitialTime = tick();
    }

    for Key, Value in pairs(Properties) do
        local DefaultValue = Object[Key]
        assert(DefaultValue ~= nil, string.format("Invalid spring property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end

function TimeSpring:UpdateAt(CurrentTime)

    local Damping       = self.Damping
    local Compression   = self.Compression
    local Target        = self.Target

    local Diff          = (self.Start - Target)
    local Mul           = math.sqrt(1 - Damping ^ 2)
    local WaveFeed      = (Mul * Math.Tau * Compression * CurrentTime)

    self.Current = Target + Euler ^ (-Math.Tau * Compression * Damping * CurrentTime)
            * (Diff * math.cos(WaveFeed) + (Damping * Compression * Diff + self.Velocity) / (Compression * Mul) * math.sin(WaveFeed))

    return self
end

function TimeSpring:Update()
    return self:UpdateAt(tick() - self.InitialTime)
end

return TimeSpring