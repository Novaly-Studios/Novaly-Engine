local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local LinkedNode = Class:FromName(script.Name)

function LinkedNode:LinkedNode(Previous, Next, Value)
    return {
        Value       = Value;
        Next        = Next;
        Previous    = Previous;
    }
end

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