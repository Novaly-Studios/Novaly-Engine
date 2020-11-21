local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Modules = Novarine:Get("Modules")
local Math = Novarine:Get("Math")
local DataStructures = Novarine:Get("DataStructures")

local TweenValue = Class:FromName(script.Name) {
    SingleTransition        = {}; -- Transitions over a defined table of control points
    PiecewiseTransition     = {}; -- Repeated single transitions over an arbitrary table of control points
    NthDegreeTransition     = {}; -- Full, non-pieced transitions over an arbitrary table of control points
    EasingStyles            = require(Modules.TweeningStyles);
};

function TweenValue.SingleTransition:Linear(Points, CurrentTime, Duration)

    local DataType          = self.DataType
    local Data              = self.TransitionerData
    local TimeRatio         = CurrentTime / Duration
    local EasingStyle       = Data.EasingStyle
    local From              = Points[1]
    local To                = Points[2]

    -- Apply easing style to the interpolation percentile
    if EasingStyle then
        TimeRatio = self.EasingStyles[EasingStyle](TimeRatio, 0.0, 1.0, 1.0)
    end

    -- Dynamic values returned from functions in the points table
    if (self.ControlPointsDynamic) then
        From = From()
        To = To()
    end

    assert(From and To, "Point is nil!") --string.format("Point is nil!\n%s", self.Traceback))

    if (DataType == "CFrame") then
        return From:Lerp(To, TimeRatio)
    elseif (DataType == "UDim2") then
        return UDim2.new(
            Math.Lerp(From.X.Scale, To.X.Scale, TimeRatio),
            Math.Lerp(From.X.Offset, To.X.Offset, TimeRatio),
            Math.Lerp(From.Y.Scale, To.Y.Scale, TimeRatio),
            Math.Lerp(From.Y.Offset, To.Y.Offset, TimeRatio)
        )
    elseif (DataType == "Color3") then
        return Color3.new(
            Math.Lerp(From.r, To.r, TimeRatio),
            Math.Lerp(From.g, To.g, TimeRatio),
            Math.Lerp(From.b, To.b, TimeRatio)
        )
    end

    return Math.Lerp(From, To, TimeRatio)
end

function TweenValue.SingleTransition:HermiteSpline(Points, CurrentTime, Duration)

    local DataType          = self.DataType
    local Data              = self.TransitionerData
    local TimeRatio         = CurrentTime / Duration
    local EasingStyle       = Data.EasingStyle
    local Tension           = Data.Tension or 0.5
    local Bias              = Data.Bias or 0.0

    if EasingStyle then
        TimeRatio = self.EasingStyles[EasingStyle](TimeRatio, 0.0, 1.0, 1.0)
    end

    assert(Points[1] and Points[2] and Points[3] and Points[4], --[[ string.format("Point is nil!\n%s", self.Traceback) ]]"Point is nil!")

    if (DataType == "CFrame") then -- Todo: put these handlers in a table
        return Math.HermiteInterpolateCFrame(
            Points[1],
            Points[2],
            Points[3],
            Points[4],
            TimeRatio,
            Tension,
            Bias
        )
    elseif (DataType == "UDim2") then
        return UDim2.new(
            Math.HermiteInterpolate(Points[1].X.Scale, Points[2].X.Scale, Points[3].X.Scale, Points[4].X.Scale, TimeRatio, Tension, Bias),
            Math.HermiteInterpolate(Points[1].X.Offset, Points[2].X.Offset, Points[3].X.Offset, Points[4].X.Offset, TimeRatio, Tension, Bias),
            Math.HermiteInterpolate(Points[1].Y.Scale, Points[2].Y.Scale, Points[3].Y.Scale, Points[4].Y.Scale, TimeRatio, Tension, Bias),
            Math.HermiteInterpolate(Points[1].Y.Offset, Points[2].Y.Offset, Points[3].Y.Offset, Points[4].Y.Offset, TimeRatio, Tension, Bias)
        )
    end

    return Math.HermiteInterpolate(
        Points[1],
        Points[2],
        Points[3],
        Points[4],
        TimeRatio,
        Tension,
        Bias
    )
end

function TweenValue.PiecewiseTransition:Linear(Points, CurrentTime, Duration)

    local Data              = self.TransitionerData
    local CountLines        = #Points - 1
    local SuperEasingStyle  = Data.SuperEasingStyle

    if SuperEasingStyle then
        CurrentTime = self.EasingStyles[SuperEasingStyle](CurrentTime, 0.0, Duration, Duration)
    end

    local TimeRatio         = (CurrentTime * CountLines) / Duration % 1
    local Segment           = math.floor(CountLines / Duration * CurrentTime) + 1
    local From              = Points[Segment]
    local To                = Points[Segment + 1]

    self.SubTransition      = self.SingleTransition.Linear

    if To then
        return self:SubTransition({From, To}, TimeRatio, 1)
    else
        return From
    end
end

function TweenValue.PiecewiseTransition:HermiteSpline(Points, CurrentTime, Duration)

    local Data              = self.TransitionerData
    local SuperEasingStyle  = Data.SuperEasingStyle

    if SuperEasingStyle then
        CurrentTime = self.EasingStyles[SuperEasingStyle](CurrentTime, 0.0, Duration, Duration)
    end

    local function Wrapper(P0, P1, P2, P3, Percentile)
        return self.SingleTransition.HermiteSpline(self, {P0, P1, P2, P3}, Percentile, 1.0)
    end

    return Math.PiecewiseInterpolate(Points, Wrapper, {}, CurrentTime, Duration, 1, NumberRange.new(-2, 1))
end

function TweenValue:Change()
    -- Todo: return new copied TweenValue with user-specified changes
end

function TweenValue:TweenValue(TransitionClassificationName, TransitionerName, TargetFramerate, TransitionerData, Points)

    local TransitionClass = TweenValue[TransitionClassificationName]
    assert(TransitionClass, string.format("No transition class '%s' exists!", TransitionClassificationName))

    local Transitioner = TransitionClass[TransitionerName]
    assert(Transitioner, string.format("No transitioner '%s' found under transition classification '%s'!", TransitionerName, TransitionClassificationName))

    local ControlPointsDynamic = false
    local FirstPoint = Points[1]

    for _, Point in pairs(Points) do
        if (type(Point) == "function") then
            ControlPointsDynamic = true
            break
        end
    end

    if ControlPointsDynamic then
        FirstPoint = FirstPoint()
    end

    self.DataType = DataStructures:GetType(FirstPoint)

    return {
        ComputedPoints          = {};
        TransitionClass         = {};
        Points                  = Points;
        Transitioner            = Transitioner;
        TargetFramerate         = TargetFramerate;
        TransitionerData        = TransitionerData;
        TargetFramerateTime     = 1 / TargetFramerate;
        ControlPointsDynamic    = ControlPointsDynamic;
        --Traceback               = debug.traceback(); -- Used for error reporting so we can trace back to where sequences were constructed

        -- For performance with non dynamic control points
        FirstPoint = Points[1];
        SecondPoint = Points[2];
    };
end

function TweenValue:GetValueAt(CurrentTime, Duration)

    -- Dynamic control points disallow framely caching of interpolated values as they cannot be predicted from here
    if (self.ControlPointsDynamic) then
        return self:Transitioner(self.Points, CurrentTime, Duration, self.TransitionerData)
    elseif (CurrentTime < self.TargetFramerateTime) then -- Low inaccurate times (0.0004 etc) can cause first frame to be cached, so this solves that issue
        return self.FirstPoint
    elseif (CurrentTime == Duration) then
        return self.SecondPoint
    else
        local Frame = math.floor(CurrentTime * self.TargetFramerate + 0.5) -- Access the current frame we are on (e.g. 0.5 seconds through = 30 frames)
        local ComputedPoints = self.ComputedPoints
        local UniquePoints = ComputedPoints[Duration]
    
        -- Durations differ, so too will framely caching
        if UniquePoints then
            ComputedPoints = UniquePoints
        else
            local Points = {}
            ComputedPoints[Duration] = Points
            ComputedPoints = Points
        end

        ComputedPoints[Frame] = ComputedPoints[Frame] or self:Transitioner(self.Points, CurrentTime, Duration, self.TransitionerData)

        return ComputedPoints[Frame]
    end
end

function TweenValue:Destroy()
    for Key in pairs(self) do
        self[Key] = nil
    end
end

return TweenValue