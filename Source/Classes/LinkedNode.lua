local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local LinkedNode = Class.FromPostConstructor(function(Self, Previous, Next, Value)
    
    Self.Value = Value
    Self.Next = Next
    Self.Previous = Previous
    
end)

function LinkedNode:SetNext(Next)
    
    self.Next = Next
    
end

function LinkedNode:SetPrevious(Previous)
    
    self.Previous = Previous
    
end

function LinkedNode:SetValue(Value)

    self.Value = Value

end

return LinkedNode