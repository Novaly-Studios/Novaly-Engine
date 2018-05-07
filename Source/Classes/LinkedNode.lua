setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local LinkedNode = Class.FromConstructor(script.Name, function(Self, Previous, Next, Value)
    
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