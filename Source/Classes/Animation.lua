setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Animation = Class:FromName(script.Name)

function Animation:Animation(Properties, Transitions)

    local Object = {
        ["Target"]              = Workspace;  -- Target instance to animate
        ["Duration"]            = 0.0;  -- The duration of the animation
        ["StartTime"]           = 0.0;  -- Time in the sequence at which this animation will begin
        ["CurrentTime"]         = 0.0;  -- Current time of the animation
    }

    for Key, Value in Pairs(Properties) do
        local ValueType = Type(Value)
        local DefaultValue = Object[Key]
        Assert(DefaultValue ~= nil, String.Format("Invalid animation property '%s'", Key))
        Assert(ValueType == Type(DefaultValue), String.Format("Invalid type for property '%s'", Key))
        Object[Key] = Value
    end

    Assert(Transitions, "No TweenValue transitions provided!")
    Object["EndTime"] = Object.StartTime + Object.Duration
    Object["Transitions"] = Transitions

    return Object
end

function Animation:Update()
    for Property, Transition in Pairs(self.Transitions) do
        self.Target[Property] = Transition:GetValueAt(self.CurrentTime, self.Duration)
    end
    return self
end

function Animation:Destroy()
    for Key in Pairs(self) do
        self[Key] = nil
    end
end

return Animation