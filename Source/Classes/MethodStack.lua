shared()

local MethodStack = Class:FromName(script.Name)

function MethodStack.new()
    return setmetatable({
        InternalStack = Stack.new();
    }, MethodStack)
end

function MethodStack:Push(Object, Key, ...)
    self.InternalStack:Push({Object, Object[Key], {...}})
end

function MethodStack:Next(Iter)
    for _, Item in pairs(self.InternalStack:PopN(Iter)) do
        Item[2](Item[1], unpack(Item[3]))
    end
end

function MethodStack:DoAll()
    local InternalStack = self.InternalStack
    if (InternalStack:IsEmpty()) then
        return
    end
    self:Next(InternalStack.Size)
end

function MethodStack:Flush()
    self.InternalStack:Flush()
end

return MethodStack