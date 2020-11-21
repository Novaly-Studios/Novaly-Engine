local InstanceWeakTable = {}

function InstanceWeakTable:__newindex(Object, Value)
    rawset(self, Object, Value)

    local Connection; Connection = Object.AncestryChanged:connect(function()
        if (Object.Parent == nil) then
            rawset(self, Object, nil)
            Connection:Disconnect()
        end
    end)
end

return function()
    return setmetatable({}, InstanceWeakTable)
end