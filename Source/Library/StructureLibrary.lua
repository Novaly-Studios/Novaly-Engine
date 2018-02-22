-- Import here

local Class = {}

function ShallowClone(Array)

    local Result = {}

    for Key, Value in next, Array do

        Result[Key] = Value

    end

    return Result

end

function Class.NewIndexHandler(Self, Key, Value)

    rawget(Self, Key, Value)

end

Class.InstanceMetatable = {

    __index = function(Self, Key)

        return rawget(Self, Key) or rawget(Self, "Class")[Key]

    end;

}

function Class.new(StaticTable, InstanceTable)

    StaticTable = StaticTable or {}

    local ResultClass = StaticTable
    InstanceTable = InstanceTable or {}
    ResultClass.Instances = {}

    local function Constructor(...)

        -- ... are constructor arguments
        -- Clone instance table so each instance has a copy

        local NewObject = ShallowClone(InstanceTable)
        NewObject.Class = ResultClass

        -- Pre-constructor activates before metamethods

        StaticTable.PreConstructor(NewObject, ...)
        setmetatable(NewObject, Class.InstanceMetatable)

        for Key, Value in next, StaticTable do

            getmetatable(NewObject)[Key] = Value

        end

        -- Post-constructor activates after metamethods

        StaticTable.PostConstructor(NewObject, ...)
        table.insert(ResultClass.Instances, NewObject)

        return NewObject

    end

    ResultClass.new = Constructor

    return ResultClass

end

function Class.FromConstructors(PreConstructor, PostConstructor)

    return Class.new({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPostConstructor(PostConstructor)

    return Class.new({
        PreConstructor = function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPreConstructor(PreConstructor)

    return Class.new({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = function() end;
    })

end

-- Circular Buffer

local CircularBuffer = Class.FromPostConstructor(function(Self, MaxElements)

    Self.MaxElements = MaxElements
    Self.CurrentElement = 0
    Self.Array = {}

end)

function CircularBuffer:GetCircularIndex(Index)

    return Index % self.MaxElements + 1

end

function CircularBuffer:Set(Index, Value)
    
    self.Array[self:GetCircularIndex(Index)] = Value

end

function CircularBuffer:Push(Value)

    local CurrentElement = self.CurrentElement

    if CurrentElement == self.MaxElements then

        CurrentElement = 0

    end

    self.Array[CurrentElement + 1] = Value
    self.CurrentElement = CurrentElement + 1

end

function CircularBuffer:Get(Index)

    return self.Array[self:GetCircularIndex(Index)]

end

function CircularBuffer:GetItems()

    return self.Array

end

function CircularBuffer:__index(Key)

    return self.Array[Key] or Class.IndexHandler(self, Key)

end

-- Linked List

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

-- Events

local Event = Class.FromPostConstructor(

    function(Self, Condition, DelayFunc)

        Self.Condition = Condition
        Self.DelayFunc = DelayFunc
        Self.EventHandlers = LinkedList.new()
        Self.EventData = {}
        Self.Listening = false

        coroutine.resume(coroutine.create(function()

            while true do

                Self:Update()

            end

        end))

    end
)

function Event:Connect(EventHandler)

    local EventHandlers = self.EventHandlers
    local Node = EventHandlers:PushTail(EventHandler)

    --[[return function()

        EventHandlers:RemoveNode(Node)

    end]]

end

function Event:Fire()

    self.EventHandlers:HeadForeach(function(Handler)

        coroutine.resume(coroutine.create(Handler))

    end)

end

function Event:Update()

    self.DelayFunc()

    -- Don't run if we have no event handlers or are not listening

    if self.EventHandlers:PeekFirst() == nil then

        return

    elseif self.Listening == false then

        return

    end

    local Result = {self.Condition(self.EventData)}

    if Result[1] then

        Result[1] = nil
        self:Fire(unpack(Result))

    end

end

function Event:StartListening()

    self.Listening = true

end

function Event:StopListening()

    self.Listening = false

end

local Structures = {
    Class = Class; 
    Stack = Stack;
    CircularBuffer = CircularBuffer;
    LinkedNode = LinkedNode;
    LinkedList = LinkedList;
    Event = Event;
}

return {
    Client = Structures;
    Server = Structures;
}