local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local SimpleSpring = Class:FromName(script.Name)

function SimpleSpring:SimpleSpring(Start, Target, Constant, Decay)
	return {
		Current 	= Start;
		Velocity 	= Start - Start;
		Decay 		= 1.0 - Decay;
		Constant 	= Constant;
		Target 		= Target;
	}
end

function SimpleSpring:Update()
	local Current = self.Current
	local Velocity = self.Velocity

	self.Dist = (self.Target - Current)
	self.Velocity = (Velocity * self.Decay) + (self.Dist * self.Constant)
	self.Current = (Current + Velocity)

	return self
end

return SimpleSpring