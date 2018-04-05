setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

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

return CircularBuffer