setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local LinkedList = Class.FromPostConstructor(function(Self)
    
    Self.FirstNode = nil
    Self.PreviousNode = nil
    Self.Count = 0
    
end)

function LinkedList:PushTail(Value)

    local FirstNode = self.FirstNode
    local PreviousNode = self.PreviousNode
    local NewNode = LinkedNode.new(PreviousNode, FirstNode, Value)

    if FirstNode == nil then

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

    --[[
        Premise: cut off the head
        of the linked list, wrap
        the front to back and back
        to front.
    ]]

    local FirstNode = self.FirstNode
    local Value = self:PeekFirst()

    if FirstNode == nil or FirstNode.Next == FirstNode then

        -- Reset linked list if there is no next
        self:Flush()

    else

        FirstNode = FirstNode.Next
        self.FirstNode = FirstNode
        self.PreviousNode.Next = FirstNode

    end

    return Value

end

function LinkedList:PopTail()

    --[[
        Premise: cut off the tail
        of the linked list, wrap
        the front to back and back
        to front.
    ]]

    local PreviousNode = self.PreviousNode
    local Value = self:PeekPrevious()

    if PreviousNode == nil or PreviousNode.Previous == PreviousNode then

        -- Reset linked list if there is no previous
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

return LinkedList