local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Sequencer = Novarine:Get("Sequencer")
local RunService = Novarine:Get("RunService")

local CHECK_ANIMATION_TYPE = "SpringAnimation"
local SpringSequence = Class:FromName(script.Name)

function SpringSequence:SpringSequence()

    local Object = {
        ["Animations"]          = setmetatable({}, {__mode = "k"}); -- A table of spring animation objects
        ["Play"]                = false; -- When true, allows the sequence to step
    }

    return Object
end

-- Adds an animation object to the current sequence
function SpringSequence:AddAnimation(AnimationObject)
    assert(AnimationObject[Class.NameKey] == CHECK_ANIMATION_TYPE,
        string.format("Animation object is an incorrect type (%s)", CHECK_ANIMATION_TYPE))
    self.Animations[AnimationObject] = AnimationObject
    return self
end

-- Removes an animation object from the current sequence
function SpringSequence:RemoveAnimation(AnimationObject)
    self.Animations[AnimationObject] = nil
    return self
end

function SpringSequence:Pause()
    self.Play = false
    return self
end

function SpringSequence:Resume()
    self.Play = true
    return self
end

function SpringSequence:BindOnUpdate(Func)
    self.StepBind = Func
end

function SpringSequence:Wait()
    while (self.Play) do
        RunService.Stepped:Wait()
    end
    return self
end

function SpringSequence:Destroy()
    Sequencer:Deregister(self)
    for Key in pairs(self) do
        self[Key] = nil
    end
end

function SpringSequence:Initialise()
    Sequencer:Register(self)
    return self
end

function SpringSequence:Step()

    if (not self.Play) then
        return
    end

    local StepBind = self.StepBind

    if StepBind then
        StepBind(self)
    end

    for Animation, _ in pairs(self.Animations) do
        Animation:Update()
    end

    return self
end

return SpringSequence