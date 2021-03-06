local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Sequencer = Novarine:Get("Sequencer")
local RunService = Novarine:Get("RunService")

local CHECK_ANIMATION_TYPE = "Animation"
local Sequence = Class:FromName(script.Name)

function Sequence:Sequence(Properties)

    local Object = {
        Duration = 0.0;  -- The duration of the sequence
        Increment = 1.0;  -- A multiplier on framely time delta
        CurrentTime = 0.0;  -- Current time of the sequence
        TimePercentile = 0.0;  -- A number between 0 and 1 denoting whole sequence progress
        Animations = setmetatable({}, {__mode = "k"}); -- A table of animation objects
        StaticAnimate = false; -- User-signified: only set to true to avoid performance issues when the animation is dependent on a condition and when no dynamic control points are being used
        AutoStop = true;  -- Automatically stops the sequence when done
        Play = false; -- When true, allows the sequence to step
        Name = "Unknown";
    };

    for Key, Value in pairs(Properties) do
        local ValueType = type(Value)
        local DefaultValue = Object[Key]
        assert(DefaultValue ~= nil, string.format("Invalid sequence property '%s'", Key))
        assert(ValueType == type(DefaultValue), string.format("Invalid type for property '%s'", Key))
        Object[Key] = Value
    end

    return Object
end

-- Adds an animation object to the current sequence
function Sequence:AddAnimation(AnimationObject)
    assert(AnimationObject.ClassName == CHECK_ANIMATION_TYPE,
        string.format("Animation object is an incorrect type (%s)", CHECK_ANIMATION_TYPE))
    self.Animations[AnimationObject] = AnimationObject
    return self
end

-- Removes an animation object from the current sequence
function Sequence:RemoveAnimation(AnimationObject)
    self.Animations[AnimationObject] = nil
    return self
end

function Sequence:GetActiveAnimationsAtTime(CurrentTime)

    local Active = setmetatable({}, {__mode = "k"}) --{}

    for Animation in pairs(self.Animations) do
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

    if (self.FinishBind) then
        self.FinishBind()
    end

    for Key in pairs(self) do
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

    local StepBind = self.StepBind
    local PreviousTime = self.CurrentTime
    local CurrentTime = PreviousTime + TimeDelta * self.Increment
    local ClampedTime = math.clamp(CurrentTime, 0, self.Duration)

    if (self.PreviousTime == ClampedTime and self.StaticAnimate and not self.AutoStop) then
        -- Prevents static animations from updating and causing performance issues

        if StepBind then
            StepBind(self)
        end

        return
    end

    local FinishBind = self.FinishBind
    local CurrentAnimations = self:GetActiveAnimationsAtTime(ClampedTime)

    self.PreviousTime = ClampedTime

    if (self.AutoStop) then
        if (CurrentTime < 0 or CurrentTime > self.Duration) then
            self.Play = false

            for Animation, Update in pairs(CurrentAnimations) do
                if Update then
                    Animation.CurrentTime = (self.Increment > 0 and Animation.Duration or 0)
                    Animation:Update()
                end
            end

            if FinishBind then
                FinishBind(self)
            end

            return
        end
    else
        CurrentTime = ClampedTime
    end

    if StepBind then
        StepBind(self)
    end

    local PreviousAnimations = self:GetActiveAnimationsAtTime(PreviousTime)

    for Animation, Active in pairs(CurrentAnimations) do
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
end

return Sequence