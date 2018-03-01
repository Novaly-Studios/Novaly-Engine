local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local TestClass = Class.FromPostConstructor(function(Self, Value)
    
    Self.Value = Value
    
end)

function TestClass:GetValue()

	return self.Value

end

function TestClass:SetValue(Value)

	self.Value = Value

end

function TestClass:__eq(Other)

	return self:GetValue() == Other:GetValue()

end

function TestClass:GetAnother()

	return TestClass.new(85)

end

return TestClass