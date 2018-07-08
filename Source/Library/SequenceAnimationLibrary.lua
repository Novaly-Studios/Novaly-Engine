local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Sequence                          = {}
Sequence.Sequences                      = {}
Sequence.TweeningStyles                 = require(Modules[script.Name].TweeningStyles)
Sequence.Tweeners                       = require(Modules[script.Name].TweeningLibrary)
Sequence.CurrentAnimation               = 0

local SequenceTypeEnum                  = {
    Normal          = 1; -- Will simply run, progress and stop as a normal animation would
    Conditional     = 2; -- Will go forward or backward depending on a function which returns a boolean
}

local AnimationControlPointStateEnum    = {
    Static          = 1; -- Unmoving points
    Dynamic         = 2; -- Moving points
}

local AnimationTypeEnum                 = {
    TwoPoint        = 1; -- Interpolation between two points
    BezierCurve     = 2; -- Many-point bezier curve interpolation
    HermiteSpline   = 3; -- Piecewise hermite spline interpolation
}

--[[
    Sequence.GetUniqueName
    
    Obtains a unique name for a sequence.
]]

function Sequence:GetUniqueName()

    while (Sequence.Sequences[Sequence.CurrentAnimation] ~= nil) do
        Sequence.CurrentAnimation = Sequence.CurrentAnimation + 1
    end

    Sequence.Sequences[Sequence.CurrentAnimation] = true

    return Sequence.CurrentAnimation
end

--[[
    Sequence.Delete
    
    Starts all given animations.
    
    Unlimited string parameters.
]]

function Sequence:Delete(...)
    for Key, Value in next, {...} do
        local TargetSequence = Sequence.Sequences[Value]
        assert(TargetSequence, "Sequence '" .. Value .. "' does not exist!")
        TargetSequence.Running = false
        Sequence.Sequences[Value] = nil
    end
end

--[[
    Sequence.Set
    
    Sets certain values in a sequence.
    
    Parameter [String] 'SequenceName' - The sequence to operate on.
    Parameter [Anything] 'Property' - The property which will be set.
    Parameter [Anything] 'Value' - The value to set.
]]

function Sequence:Set(SequenceName, Property, Value)
    local TargetSequence = Sequence.Sequences[SequenceName]
    
    assert(SequenceName,    "Argument missing: #1 Sequence (sequence name)")
    assert(Property,        "Argument missing: #2 Property (property to change)")
    assert(Value,           "Argument missing: #3 Value (new property value)")
    
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    
    TargetSequence[Property] = Value
end

--[[
    Sequence.Exists
    
    Checks if a sequence exists
    
    Parameter [String] 'SequenceName'
--]]

function Sequence:Exists(SequenceName)
    return Sequence.Sequences[SequenceName] ~= nil
end

--[[
    Sequence.Get
    
    Wraps a sequence table in a metatable with extra functionality.
    
    Parameter [String] 'SequenceName' - The name of the sequence to get.
]]

function Sequence:Get(SequenceName)
    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    return TargetSequence
end

--[[
    Sequence.New
    
    Creates a new sequence of animations.
    
    Parameter [String] 'Name' - The name of the sequence.
    Parameter [Number] 'Time' - The time the whole sequence will run for.
        [Potentially redundant, considering changing to a dynamically calculated time]
    Parameter [Enum.SequenceType] Type - Determines the type of sequence. Default is normal sequence.
    Parameter [Function] Check - Used in conditional sequences.
]]

function Sequence:New(Name, Time, Type, Check)
    
    Type = Type or Enum.SequenceType.Normal
    
    assert(Name,    "Argument missing: #1 Name (sequence name)")
    assert(Time,    "Argument missing: #2 Time (sequence time length)")
    assert(Type,    "Argument missing: #3 Type (sequence type)")
    
    local Found = Sequence.Sequences[Name]
    if Found then
        if type(Found) == "table" then
            error("Sequence '" .. Name .. "' already exists!")
        end
    end
    
    local NewSequence = {
        Animations = {};
        Time = Time;
        Name = Name;
        Scalar = 1.0;
        LastScalar = 1.0;
        CurrentTime = 0;
        Type = Type;
        Running = false;
    }
    
    if Type == Enum.SequenceType.Conditional then
        assert(Check, "Argument missing: #4 Check (conditional value to check)")
        NewSequence.Check = Check
    end
    
    Sequence.Sequences[Name] = NewSequence
    
    return Sequence:Get(Name)
end

--[[
    Sequence.NewAnim
    
    Creates a new animation under a sequence.

    Parameter [String] 'SequenceName' - The sequence name to create the animation under.
    Parameter [Enum.AnimationType] 'AnimType' - The type of animation.
    Parameter [Number] 'TimeOnScale' - The time on the greater time scale which the animation will start at.
    Parameter [Userdata] 'Object' - The animation subject.
    Parameter [String] 'Property' - The subject's property which will be changed.
    Parameter [Table] 'Points' - The points on this animation which will be interpolated.
    Parameter [Enum.EasingStyle] 'Style' - The easing style of the animation.
    Parameter [Enum.EasingDirection] 'Direction' - The easing direction of the easing style.
    Parameter [Number] 'Time' - The time the animation will play for.
]]

function Sequence:NewAnim(SequenceName, AnimType, AnimState, TimeOnScale, Object, Property, Points, Style, Time, ...)
    -- Check and formulate data
    local TargetSequence = Sequence.Sequences[SequenceName]
    
    assert(TargetSequence,  "Sequence '" .. SequenceName .. "' does not exist!")
    assert(SequenceName,    "Argument missing: #1 Sequence (sequence name)")
    assert(AnimType,        "Argument missing: #2 AnimType (animation type)")
    assert(AnimState,       "Argument missing: #3 AnimState (animation control point state)")
    assert(TimeOnScale,     "Argument missing: #4 TimeOnScale (starting time on grand scale)")
    assert(Object,          "Argument missing: #5 Object (instance to animate)")
    assert(Property,        "Argument missing: #6 Property (property of object)")
    assert(Points,          "Argument missing: #7 Points (points to interpolate)")
    assert(Style,           "Argument missing: #8 Style (easing style)")
    assert(Time,            "Argument missing: #9 Time (time of animation)")
    
    TargetSequence.Animations[ #TargetSequence.Animations + 1 ] = {
        AnimType = AnimType;
        Object = Object;
        Property = Property;
        Tweener = Sequence.TweeningStyles[Style];
        ControlPointState = AnimState;
        Time = Time;
        TimeOnScale = TimeOnScale;
        Points = Points;
        LastScalar = 1.0;
        Done = false;
        GotPoints = false;
        Extra = {...};
    }

    local AnimTable, Object = TargetSequence.Animations[ #TargetSequence.Animations ]

    if type(Points) == "function" then
        AnimTable.GotPoints = false
        AnimTable.PointFunction = Points
        AnimTable.Points = nil
        AnimTable.Type = DataStructures:GetType(Points()[1])
    else
        AnimTable.ControlPointState = Enum.AnimationControlPointState.Static
        AnimTable.Type = DataStructures:GetType(Points[1])
    end
end

--[[
    Sequence.PreRender
    
    Calculates the interpolations before the animation
    instead of doing so while the animation is playing.
    
    Parameter [String] 'SequenceName' - The sequence to pre-render.
    Parameter [Number] 'Framerate' - The framerate to pre-render at.
    Parameter [Number] 'WaitAfterIterations' - Determines how many frames will be processed before waiting.
    Parameter [Number] 'WaitTime' - The time to wait.
--]]


function Sequence:PreRender(SequenceName, Framerate, WaitAfterIterations, WaitTime)

    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    
    for AnimTable = 1, #TargetSequence.Animations do

        AnimTable = TargetSequence.Animations[AnimTable]

        local Frames = {}
        local Tweener = AnimTable.Tweener
        local Type = AnimTable.Type
        local Extra = AnimTable.Extra
        local AnimType = AnimTable.AnimType
        local Time = AnimTable.Time
        local Points = (AnimTable.Points == nil and AnimTable.PointFunction() or AnimTable.Points)

        Sub(function()

            for FrameTime = 0, AnimTable.Time * Framerate do
                Frames[FrameTime] = Sequence.Tweeners[Type](AnimType, AnimTable.Tweener, FrameTime / Framerate, Points, Time, Extra)
                if WaitAfterIterations and WaitTime then
                    if FrameTime % WaitAfterIterations == 0 then
                        wait(WaitTime)
                    end
                end
            end

            AnimTable.RenderFrames = true
            AnimTable.Frames = Frames
            AnimTable.PreRenderFramerate = Framerate
        end)
    end
end

--[[
    Sequence.Start
    
    Starts all given animations.
    
    Unlimited string parameters.
]]

function Sequence:Start(...)
    for Key, Value in next, {...} do
        
        local TargetSequence = Sequence.Sequences[Value]
        assert(TargetSequence, "Sequence '" .. Value .. "' does not exist!")
        
        local NewScalar = TargetSequence.Scalar
        local Div = 1
        
        if TargetSequence.LastScalar ~= NewScalar then
            Div = TargetSequence.LastScalar * NewScalar
            TargetSequence.Time = TargetSequence.Time / Div
            TargetSequence.LastScalar = NewScalar
        end
        
        for Key, Value in next, TargetSequence.Animations do
            if Value.LastScalar ~= NewScalar then
                Value.TimeOnScale = Value.TimeOnScale / Div
                Value.Time = Value.Time / Div
                Value.LastScalar = TargetSequence.Scalar
            end
        end
        
        if TargetSequence.Type == Enum.SequenceType.Normal then
            TargetSequence.StartingTick = tick()
        end
        
        TargetSequence.Running = true
    end
end

--[[
    Sequence.Stop
    
    Stops all given animations and resets them.
    
    Unlimited string parameters.
]]

function Sequence:Stop(...)
    for Key, Value in next, {...} do
        local TargetSequence = Sequence.Sequences[Value]
        assert(TargetSequence, "Sequence '" .. Value .. "' does not exist!")
        for Key, Value in next, TargetSequence.Animations do
            Value.GotPoints = nil
            Value.NewPoints = nil
            Value.Done = false
        end
        if TargetSequence.Type == Enum.SequenceType.Normal then
            TargetSequence.StartingTick = nil
        end
        TargetSequence.CurrentTime = 0
        TargetSequence.Running = false
    end
end

--[[
    Sequence.Pause
    
    Pauses all given animations.
    
    Unlimited string parameters.
]]

function Sequence:Pause(...)
    for Key, Value in next, {...} do
        local TargetSequence = Sequence.Sequences[Value]
        assert(TargetSequence, "Sequence '" .. Value .. "' does not exist!")
        assert(TargetSequence.Running, "Sequence already stopped!")
        TargetSequence.Running = false
    end
end

--[[
    Sequence.Wait
    
    Waits until all given sequences are stopped.
    
    Unlimited string parameters.
]]

function Sequence:Wait(...)
    for Key, Value in next, {...} do
        local TargetSequence = Sequence.Sequences[Value]
        assert(TargetSequence, "Sequence '" .. Value .. "' does not exist!")
        while TargetSequence.Running do
            RunService.RenderStepped:wait()
        end
    end
end

--[[
    Sequence.WaitConditional
    
    Waits until all given conditional sequence is at the start or end point.
    
    Parameter [String] 'SequenceName' - The sequence to wait for.
    Parameter [Boolean] 'CheckFor' - True will wait until it hits the end, false will wait until it hits the start.
]]

function Sequence:WaitConditional(SequenceName, CheckFor)
    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    local Point = (CheckFor == true and TargetSequence.Time or 0)
    while TargetSequence.CurrentTime ~= Point do
        RunService.RenderStepped:wait()
    end
end

--[[
    Sequence.WaitForPreRender
    
    Waits until sequence is pre-rendered.
    
    Parameter [String] 'SequenceName' - The sequence to operate on.
]]

function Sequence:WaitForPreRender(SequenceName)
    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    repeat
        RunService.RenderStepped:wait()
    until TargetSequence.RenderFrames == true
end

--[[
    Sequence.IsRunning
    
    Checks if a sequence is running.
    
    Parameter [String] 'SequenceName' - The sequence to check.
]]

function Sequence:IsRunning(SequenceName)
    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    return TargetSequence.Running
end

--[[
    Sequence.Scale
    
    Scales a sequence.
    
    Parameter [String] 'SequenceName' - The sequence to operate on.
    Parameter [Number] 'Scalar' - The new scale of the sequence.
]]

function Sequence:Scale(SequenceName, Scalar)
    local TargetSequence = Sequence.Sequences[SequenceName]
    assert(TargetSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    assert(not TargetSequence.Running, "Cannot scale animation while running!")
    TargetSequence.Scalar = Scalar or 1
end

--[[
    Sequence.UpdateAnimation

    Progresses an individual animation by a certain amount of time.

    Parameter [Table] 'SubjectAnimation' - The animation object.
    Parameter [Number] 'SequenceTimeForward' - The current time the sequence which the animation resides in is at.
]]

function Sequence:UpdateAnimation(SubjectAnimation, SequenceTimeForward)
    
    -- Collect data
    local Forward = SequenceTimeForward - SubjectAnimation.TimeOnScale
    local Tweener = SubjectAnimation.Tweener
    local Time = SubjectAnimation.Time
    local Type = SubjectAnimation.Type
    local Extra = SubjectAnimation.Extra
    local CPS = SubjectAnimation.ControlPointState
    
    local AnimType = SubjectAnimation.AnimType
    local HasFunction = (SubjectAnimation.PointFunction ~= nil)
    local Points = SubjectAnimation.Points
    
    if HasFunction == true then
        if CPS == Enum.AnimationControlPointState.Static and SubjectAnimation.GotPoints == false then
            local NewPoints = SubjectAnimation.PointFunction()
            SubjectAnimation.Points = NewPoints
            SubjectAnimation.GotPoints = true
            Points = NewPoints
        elseif CPS == Enum.AnimationControlPointState.Dynamic then
            local NewPoints = SubjectAnimation.PointFunction()
            SubjectAnimation.Points = NewPoints
            Points = NewPoints
        end
    end
    
    -- Check if pre-rendered interpolations are available
    local Object = SubjectAnimation.Object
    if SubjectAnimation.RenderFrames == true then
        local Found = SubjectAnimation.Frames[Math.Floor(Forward * SubjectAnimation.PreRenderFramerate)]
        if Found then
            SubjectAnimation.Object[SubjectAnimation.Property] = Found
        end
    else
        SubjectAnimation.Object[SubjectAnimation.Property] = Sequence.Tweeners[Type](AnimType, Tweener, Forward, Points, Time, Extra)
    end
end

--[[
    Sequence.Step
    
    Progresses a sequence by a certain amount of time.
    
    Parameter [String] 'Sequence' - The sequence to operate on.
    Parameter [Number] 'Step' - The amount of time forward the sequence is.
]]

function Sequence:Step(SequenceName, Step)
    
    -- Find which animations in a sequence to update and change
    local SubjectSequence = Sequence.Sequences[SequenceName]
    assert(SubjectSequence, "Sequence '" .. SequenceName .. "' does not exist!")
    Step = Step or 0
    
    local CurrentTime = SubjectSequence.CurrentTime
    local SequenceTimeForward = CurrentTime + Step
    local AnimationTable = SubjectSequence.Animations
    SubjectSequence.CurrentTime = SequenceTimeForward
    
    if SubjectSequence.Running then
        -- Iterate through each animation inside the sequence to update them
        for Value = 1, #AnimationTable do
            Value = AnimationTable[Value]
            -- Find temporal endpoint of animation
            local TotalTime = Value.TimeOnScale + Value.Time
            if SequenceTimeForward >= Value.TimeOnScale and SequenceTimeForward <= TotalTime then
                -- If sequence time is in between animation starting and ending time, update animation
                Sequence:UpdateAnimation(Value, SequenceTimeForward)
            end
        end
        if SubjectSequence.Type == SequenceTypeEnum.Normal then
            if (SequenceTimeForward >= SubjectSequence.Time or SubjectSequence.Time - SequenceTimeForward < CONFIG.sConditionalTimeTolerance) then
                -- If a normal sequence is complete, set each animation to end point and stop the sequence
                for Value = 1, #AnimationTable do
                    Value = AnimationTable[Value]
                    if Value.Done == false then
                        Value.Object[Value.Property] = Value.Points[ #Value.Points ]
                        Value.Done = true
                    end
                end
                Sequence:Stop(SequenceName)
            end
        elseif SubjectSequence.Type == SequenceTypeEnum.Conditional then
            for Value = 1, #AnimationTable do
                Value = AnimationTable[Value]
                local TotalTime = Value.TimeOnScale + Value.Time
                if SequenceTimeForward < Value.TimeOnScale then
                    -- If sequence time is less than animation starting time, set to start point
                    Value.Object[Value.Property] = Value.Points[1]
                elseif SequenceTimeForward >= TotalTime then
                    -- If sequence time is greater than animation ending time, set to end point
                    Value.Object[Value.Property] = Value.Points[ #Value.Points ]
                end
            end
        end
    end
end

function ClientInit()
    
    -- Declare Enums
    Enum.new("SequenceType", SequenceTypeEnum)
    Enum.new("AnimationType", AnimationTypeEnum)
    Enum.new("AnimationControlPointState", AnimationControlPointStateEnum)
    
    CONFIG.sConditionalTimeTolerance = 1 / CONFIG._TargetFramerate
    
    -- Main update event
    RunService.RenderStepped:connect(function(Step)
        
        for Name, SubjectSequence in next, Sequence.Sequences do
            
            if SubjectSequence.Running then
                
                if SubjectSequence.Type == Enum.SequenceType.Normal then
                    
                    -- Tick would avoid decimal precision issues as opposed to stepping by Step variable
                    SubjectSequence.CurrentTime = tick() - SubjectSequence.StartingTick
                    Sequence:Step(Name)
                    
                elseif SubjectSequence.Type == Enum.SequenceType.Conditional then
                    
                    local Condition = SubjectSequence.Check()
                    local TotalTime = SubjectSequence.Time
                    local CurrentTime = SubjectSequence.CurrentTime
                    
                    if Condition then
                        local NewTime = CurrentTime + Step
                        local TimeToEnd = TotalTime - CurrentTime
                        if NewTime > TotalTime or TimeToEnd < CONFIG.sConditionalTimeTolerance then
                            NewTime = TotalTime
                        end
                        SubjectSequence.CurrentTime = NewTime
                    else
                        local NewTime = CurrentTime - Step
                        if NewTime < 0 or CurrentTime < CONFIG.sConditionalTimeTolerance then
                            NewTime = 0
                        end
                        SubjectSequence.CurrentTime = NewTime
                    end
                    
                    Sequence:Step(Name)
                    
                end
            end
        end
    end)
end

Func({
    Client = {Sequence = Sequence, Init = ClientInit};
    Server = {};
})

return true