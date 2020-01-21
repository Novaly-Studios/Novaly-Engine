local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local SpringAnimation = Class:FromName(script.Name)

function SpringAnimation:SpringAnimation(Properties, Springs)

    local Object = {
        Target = workspace;    -- Target instance to animate
        Springs = Springs;      -- Springs (per property)
    }

    for Key, Value in pairs(Properties) do
        local DefaultValue = Object[Key]
        assert(DefaultValue ~= nil, string.format("Invalid animation property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end

function SpringAnimation:Update()

    local Target = self.Target

    for Property, Spring in pairs(self.Springs) do
        Target[Property] = Spring:Update().Current
    end

    return self
end

function SpringAnimation:Destroy()
    for Key in pairs(self) do
        self[Key] = nil
    end
end

return SpringAnimation