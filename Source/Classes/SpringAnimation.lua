shared()

local SpringAnimation = Class:FromName(script.Name)

function SpringAnimation:SpringAnimation(Properties, Springs)

    local Object = {
        ["Target"]      = Workspace;    -- Target instance to animate
        ["Springs"]     = Springs;      -- Springs (per property)
    }

    for Key, Value in Pairs(Properties) do
        local ValueType = Type(Value)
        local DefaultValue = Object[Key]
        Assert(DefaultValue ~= nil, String.Format("Invalid animation property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end

function SpringAnimation:Update()

    local Target = self.Target

    for Property, Spring in Pairs(self.Springs) do
        Target[Property] = Spring:Update().Current
    end

    return self
end

function SpringAnimation:Destroy()
    for Key in Pairs(self) do
        self[Key] = nil
    end
end

return SpringAnimation