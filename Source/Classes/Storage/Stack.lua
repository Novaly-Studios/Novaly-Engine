local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

--[[
    @classmod Stack
]]

local Stack = Class:FromName(script.Name)

function Stack:Stack()
    With(self) {
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
    return Item
end

return Stack