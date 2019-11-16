local Stack = {}
Stack.__index = Stack

function Stack.New()
    return setmetatable({
        Items = {};
        Index = 0;
    }, Stack)
end

function Stack:Push(Item)
    local Index = self.Index + 1
    self.Items[Index] = Item
    self.Index = Index
end

function Stack:Pop()
    local Current = self:Top()
    local Index = self.Index
    assert(Index > 0, "No more items left!")
    self.Items[Index] = nil
    self.Index = Index - 1
    return Current
end

function Stack:Top()
    return self.Items[self.Index]
end

function Stack:AsArray()
    local Result = {}

    for Index = 1, self.Index do
        Result[Index] = self.Items[Index]
    end

    return Result
end

return Stack