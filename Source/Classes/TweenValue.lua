setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local TweenValue = Class:FromName(script.Name) {
    SingleTransition        = {}; -- Transitions over a defined table of control points
    PiecewiseTransition     = {}; -- Repeated single transitions over an arbitrary table of control points
    NthDegreeTransition     = {}; -- Full, non-pieced transitions over an arbitrary table of control points
    EasingStyles            = Require(Modules.Sequence.TweeningStyles);
};

function TweenValue.SingleTransition:Linear(Points, CurrentTime, Duration)

    local DataType          = self.DataType
    local Data              = self.TransitionerData
    local TimeRatio         = CurrentTime / Duration
    local EasingStyle       = Data.EasingStyle
    local From              = Points[1]
    local To                = Points[2]
    local Result

    -- Apply easing style to the interpolation percentile
    if EasingStyle then
        TimeRatio = self.EasingStyles[EasingStyle](TimeRatio, 0.0, 1.0, 1.0)
    end

    -- Dynamic values returned from functions in the points table
    if (self.ControlPointsDynamic) then
        From = From()
        To = To()
    end

    if (DataType == "CFrame") then

        local FromQuaternion = Quaternion.FromCFrame(From)
        local ToQuaternion = Quaternion.FromCFrame(To)
        local FromPosition = From.p
        local ToPosition = To.p

        local InterpolatedQuaternion = Math.Lerp(FromQuaternion, ToQuaternion, TimeRatio)
        local InterpolatedPosition = From:Lerp(To, TimeRatio)

        local M00, M01, M02,
              M10, M11, M12,
              M20, M21, M22 = InterpolatedQuaternion:ToRotationMatrix()

        return CFrame.new(InterpolatedPosition.X, InterpolatedPosition.Y, InterpolatedPosition.Z,
                          M00, M01, M02,
                          M10, M11, M12,
                          M20, M21, M22)

    elseif (DataType == "UDim2") then

        From = WrappedUDim2.new(From)
        To = WrappedUDim2.new(To)
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
    local EasingStyle       = Data.EasingStyle
    local SuperEasingStyle  = Data.SuperEasingStyle

    if SuperEasingStyle then
        CurrentTime = self.EasingStyles[SuperEasingStyle](CurrentTime, 0.0, Duration, Duration)
    end

    local TimeRatio         = (CurrentTime * CountLines) / Duration % 1
    local Segment           = Math.Floor(CountLines / Duration * CurrentTime) + 1
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
    local EasingStyle       = Data.EasingStyle
    local SuperEasingStyle  = Data.SuperEasingStyle

    if SuperEasingStyle then
        CurrentTime = self.EasingStyles[SuperEasingStyle](CurrentTime, 0.0, Duration, Duration)
    end

    local function Wrapper(P0, P1, P2, P3, Percentile)
        return self.SingleTransition.HermiteSpline(self, {P0, P1, P2, P3}, Percentile, 1.0)
    end

    return Math.PiecewiseInterpolate(Points, Wrapper, {}, CurrentTime, Duration, 1, NumberRange.new(-2, 1))
end

function TweenValue:TweenValue(TransitionClassificationName, TransitionerName, TargetFramerate, TransitionerData, Points)

    local TransitionClass = TweenValue[TransitionClassificationName]
    Assert(TransitionClass, String.Format("No transition class '%s' exists!", TransitionClassificationName))

    local Transitioner = TransitionClass[TransitionerName]
    Assert(Transitioner, String.Format("No transitioner '%s' found under transition classification '%s'!", TransitionerName, TransitionClassificationName))

    local ControlPointsDynamic = false
    local FirstPoint = Points[1]

    for _, Point in Pairs(Points) do
        if (Type(Point) == "function") then
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
        ControlPointsDynamic    = ControlPointsDynamic;
    }
end

function TweenValue:GetValueAt(CurrentTime, Duration)

    local Frame = Math.Floor(CurrentTime * self.TargetFramerate) -- Access the current frame we are on (e.g. 0.5 seconds through = 30 frames)
    local ComputedPoints = self.ComputedPoints

    -- Dynamic control points disallow framely caching of interpolated values as they cannot be predicted from here
    if (self.ControlPointsDynamic) then
        return self:Transitioner(self.Points, CurrentTime, Duration, self.TransitionerData)
    else
        ComputedPoints[Frame] = ComputedPoints[Frame] or self:Transitioner(self.Points, CurrentTime, Duration, self.TransitionerData)
        return ComputedPoints[Frame]
    end
end

function TweenValue:Destroy()
    for Key in Pairs(self) do
        self[Key] = nil
    end
end

return TweenValue