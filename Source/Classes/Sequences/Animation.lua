local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Animation = Class:FromName(script.Name)

function Animation:Animation(Properties, Transitions)

    local Object = {
        Target = game;  -- Target instance to animate
        Duration = 0.0;  -- The duration of the animation
        StartTime = 0.0;  -- Time in the sequence at which this animation will begin
        CurrentTime = 0.0;  -- Current time of the animation
    }

    for Key, Value in pairs(Properties) do
        local DefaultValue = Object[Key]
        assert(DefaultValue ~= nil, string.format("Invalid animation property '%s'", Key))
        Object[Key] = Value
    end

    assert(Transitions, "No TweenValue transitions provided!")
    assert(Object.Target ~= game, "No target found!")
    Object.EndTime = Object.StartTime + Object.Duration
    Object.Transitions = Transitions
    Object.LastProperties = {}

    return Object
end

function Animation:Update()
    for Property, Transition in pairs(self.Transitions) do
        local Value = Transition:GetValueAt(self.CurrentTime, self.Duration)

        if (self.LastProperties[Property] ~= Value) then
            self.Target[Property] = Value
            self.LastProperties[Property] = Value
        end
    end

    return self
end

function Animation:Destroy()
    for Key in pairs(self) do
        self[Key] = nil
    end
end

return Animation