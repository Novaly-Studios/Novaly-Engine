local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local LinkedNode = Novarine:Get("LinkedNode")

local LinkedList = Class:FromName(script.Name)

function LinkedList:LinkedList()
    return {
        FirstNode       = nil;
        PreviousNode    = nil;
        CurrentNode     = nil;
        Count           = 0;
    }
end

function LinkedList:PushTail(Value)

    local FirstNode = self.FirstNode
    local PreviousNode = self.PreviousNode
    local NewNode = LinkedNode.new(PreviousNode, FirstNode, Value)

    if (FirstNode == nil) then
        FirstNode = NewNode
        self.FirstNode = FirstNode
        PreviousNode = NewNode
        self.PreviousNode = PreviousNode
    end

    PreviousNode.Next = NewNode
    FirstNode.Previous = NewNode
    self.PreviousNode = NewNode
    self.Count = self.Count + 1

    return NewNode
end

function LinkedList:PeekPrevious()
    return (self.PreviousNode or {}).Value
end

function LinkedList:PeekFirst()
    return (self.FirstNode or {}).Value
end

function LinkedList:PopHead()

    local FirstNode = self.FirstNode
    local Value = self:PeekFirst()

    if (FirstNode == nil or FirstNode.Next == FirstNode) then
        self:Flush()
    else
        FirstNode = FirstNode.Next
        self.FirstNode = FirstNode
        self.PreviousNode.Next = FirstNode
    end

    return Value
end

function LinkedList:PopTail()

    local PreviousNode = self.PreviousNode
    local Value = self:PeekPrevious()

    if (PreviousNode == nil or PreviousNode.Previous == PreviousNode) then
        self:Flush()
    else
        local FirstNode = self.FirstNode
        PreviousNode = PreviousNode.Previous
        PreviousNode.Next = FirstNode
        FirstNode.Previous = PreviousNode
        self.PreviousNode = PreviousNode
    end

    return Value
end

function LinkedList:Flush()
    self.FirstNode = nil
    self.PreviousNode = nil
    self.Count = 0
end

function LinkedList:HeadForeach(Func)

    local Target = self.FirstNode
    local SubjectNode = Target

    repeat
        Func(SubjectNode.Value)
        SubjectNode = SubjectNode.Next
    until SubjectNode == Target
end

function LinkedList:TailForeach(Func)

    local Target = self.PreviousNode
    local SubjectNode = Target

    repeat
        Func(SubjectNode.Value)
        SubjectNode = SubjectNode.Previous
    until SubjectNode == Target
end

function LinkedList:Next()
    local CurrentNode = self.CurrentNode or self.FirstNode
    self.CurrentNode = CurrentNode.Next
    return CurrentNode.Value
end

return LinkedList