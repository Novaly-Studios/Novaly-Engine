shared()

--[[
    @classmod Stack
]]

local Stack = Class:FromName(script.Name)

function Stack.new()
    return {
        Stack = {};
        Size = 0;
    }
end

function Stack:Push(Value)
    local Size = self.Size + 1
    self.Stack[Size] = Value
    self.Size = Size
end

function Stack:Pop()

    local StackTable = self.Stack
    local Size = self.Size
    assert(self.Size > 0, "Stack is empty!")

    local Item = StackTable[Size]
    StackTable[Size] = nil
    self.Size = Size - 1
    return Item
end

function Stack:PopN(Iter)

    local Size = self.Size
    assert(Size > 0, "Stack is empty!")
    local StackTable = self.Stack
    local Results = {}

    for Index = Size, Size - Iter + 1, -1 do
        if (Index == 0) then
            break
        end
        table.insert(Results, self:Pop())
    end

    return Results
end

function Stack:Flush()
    self:PopN(self.Size)
end

function Stack:IsEmpty()
    return self.Size == 0
end