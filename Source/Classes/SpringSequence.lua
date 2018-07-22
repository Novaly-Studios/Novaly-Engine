setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local CHECK_ANIMATION_TYPE = "SpringAnimation"
local SpringSequence = Class:FromName(script.Name)

function SpringSequence:SpringSequence(Properties)

    local Object = {
        ["Animations"]          = SetMetatable({}, {__mode = "k"}); -- A table of spring animation objects
        ["Play"]                = false; -- When true, allows the sequence to step
    }

    return Object
end

-- Adds an animation object to the current sequence
function SpringSequence:AddAnimation(AnimationObject)
    Assert(AnimationObject[Class.NameKey] == CHECK_ANIMATION_TYPE, 
        String.Format("Animation object is an incorrect type (%s)", CHECK_ANIMATION_TYPE))
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
    for Key in Pairs(self) do
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

    local PreviousTime = self.CurrentTime
    local StepBind = self.StepBind

    if StepBind then
        StepBind(self)
    end

    for Animation, Active in Pairs(self.Animations) do
        Animation:Update()
    end

    return self
end

return SpringSequence