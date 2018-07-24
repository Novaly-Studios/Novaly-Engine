setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local CHECK_ANIMATION_TYPE = "Animation"
local Sequence = Class:FromName(script.Name)

function Sequence:Sequence(Properties)

    local Object = {
        ["Duration"]            = 0.0;  -- The duration of the sequence
        ["Increment"]           = 1.0;  -- A multiplier on framely time delta
        ["CurrentTime"]         = 0.0;  -- Current time of the sequence
        ["TimePercentile"]      = 0.0;  -- A number between 0 and 1 denoting whole sequence progress
        ["Animations"]          = SetMetatable({}, {__mode = "k"}); -- A table of animation objects
        ["AutoStop"]            = true;  -- Automatically stops the sequence when done
        ["Play"]                = false; -- When true, allows the sequence to step
    }

    for Key, Value in Pairs(Properties) do
        local ValueType = Type(Value)
        local DefaultValue = Object[Key]
        Assert(DefaultValue ~= nil, String.Format("Invalid sequence property '%s'", Key))
        Assert(ValueType == Type(DefaultValue), String.Format("Invalid type for property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end

-- Adds an animation object to the current sequence
function Sequence:AddAnimation(AnimationObject)
    Assert(AnimationObject[Class.NameKey] == CHECK_ANIMATION_TYPE, 
        String.Format("Animation object is an incorrect type (%s)", CHECK_ANIMATION_TYPE))
    self.Animations[AnimationObject] = AnimationObject
    return self
end

-- Removes an animation object from the current sequence
function Sequence:RemoveAnimation(AnimationObject)
    self.Animations[AnimationObject] = nil
    return self
end

function Sequence:GetActiveAnimationsAtTime(CurrentTime)

    local Active = {}

    for Animation in Pairs(self.Animations) do
        if (CurrentTime >= Animation.StartTime) then
            if (CurrentTime <= Animation.EndTime) then
                Active[Animation] = true
            else
                Active[Animation] = false
            end
        end
    end

    return Active
end

function Sequence:Pause()
    self.Play = false
    return self
end

function Sequence:Resume()
    self.Play = true
    return self
end

function Sequence:BindOnFinish(Func)
    self.FinishBind = Func
    return self
end

function Sequence:BindOnUpdate(Func)
    self.StepBind = Func
    return self
end

function Sequence:Wait()
    while (self.Play) do
        RunService.Stepped:Wait()
    end
    return self
end

function Sequence:Destroy()
    Sequencer:Deregister(self)
    for Key in Pairs(self) do
        self[Key] = nil
    end
end

function Sequence:Initialise()
    Sequencer:Register(self)
    return self
end

function Sequence:Step(TimeDelta)

    if (not self.Play) then
        return
    end

    local PreviousTime = self.CurrentTime
    local FinishBind = self.FinishBind
    local StepBind = self.StepBind
    local CurrentTime = PreviousTime + TimeDelta * self.Increment

    if (self.AutoStop) then
        if (CurrentTime < 0 or CurrentTime > self.Duration) then
            self.Play = false
            if FinishBind then
                FinishBind(self)
            end
            return
        end
    else
        CurrentTime = Math.Clamp(CurrentTime, 0, self.Duration)
    end

    if StepBind then
        StepBind(self)
    end

    local PreviousAnimations = self:GetActiveAnimationsAtTime(PreviousTime)
    local CurrentAnimations = self:GetActiveAnimationsAtTime(CurrentTime)

    for Animation, Active in Pairs(CurrentAnimations) do
        if Active then
            Animation.CurrentTime = CurrentTime - Animation.StartTime
            Animation:Update()
        else
            -- If the animation has just finished, update at end for numerical accuracy
            if (PreviousAnimations[Animation] == true) then
                Animation.CurrentTime = Animation.Duration
                Animation:Update()
            end
        end
    end

    self.CurrentTime = CurrentTime
    return self
end

return Sequence