shared()

local Maths = {}

local Mappings = {
    log         = "Log";
    ldexp       = "LdExp";
    rad         = "Rad";
    cosh        = "CosH";
    random      = "Random";
    frexp       = "FrExp";
    tanh        = "TanH";
    floor       = "Floor";
    max         = "Max";
    sqrt        = "Sqrt";
    modf        = "ModF";
    huge        = "Huge";
    pow         = "Pow";
    atan        = "ATan";
    tan         = "Tan";
    cos         = "Cos";
    sign        = "Sign";
    clamp       = "Clamp";
    log10       = "Log10";
    noise       = "Noise";
    acos        = "ACos";
    abs         = "Abs";
    pi          = "PI";
    sinh        = "SinH";
    asin        = "ASin";
    min         = "Min";
    deg         = "Deg";
    fmod        = "FMod";
    randomseed  = "RandomSeed";
    atan2       = "ATan2";
    ceil        = "Ceil";
    sin         = "Sin";
    exp         = "Exp";
}

local Curve = {}

function Maths.Lerp(P0, P1, Mul)
    return P0 + (P1 - P0) * Mul
end

--[[
    Maths.LerpUDim2

    Linearly interpolates a UDim2 object into another UDim2 object
]]

function Maths.LerpUDim2(P0, P1, m)

    local Lerp = Maths.Lerp

    return UDim2.new(
        Lerp(P0.X.Scale, P1.X.Scale, m),
        Lerp(P0.X.Offset, P1.X.Offset, m),
        Lerp(P0.Y.Scale, P1.Y.Scale, m),
        Lerp(P0.Y.Offset, P1.Y.Offset, m)
    )
end

--[[
    Maths.LerpUDim

    Linearly interpolates a UDim object into another UDim object
]]

function Maths.LerpUDim(P0, P1, m)

    local Lerp = Maths.Lerp

    return UDim.new(
        Lerp(P0.Scale, P1.Scale, m),
        Lerp(P0.Offset, P1.Offset, m)
    )
end

--[[
    Maths.LerpVector2

    Linearly interpolates a Vector2 object into another Vector2 object
]]

function Maths.LerpVector2(P0, P1, m)

    local Lerp = Maths.Lerp

    return Vector2.new(
        Lerp(P0.X, P1.X, m),
        Lerp(P0.Y, P1.Y, m)
    )
end

--[[
    Maths.LerpColor3

    Linearly interpolates a Color3 object into another Color3 object
]]

function Maths.LerpColor3(P0, P1, Mul)
    local Result = Vector3.new(P0.r, P0.g, P0.b):lerp(Vector3.new(P1.r, P1.g, P1.b), Mul)
    return Color3.new(Result.X, Result.Y, Result.Z)
end

--[[
    Maths.NumberToLength

    Strips a decimal number (not an integer) of 'Num' decimal places
]]

function Maths.NumberToLength(Num, Len)
    local Order = 10 ^ (Len - 1)
    return Maths.Floor(Num * Order) / Order
end

--[[
    Maths.CountDigits

    Counts the digits of a decimal or integer
]]

function Maths.CountDigits(Num)
    local Str = tostring(Num)
    return #Str - #Str:gsub("%d", "")
end

--[[
    Maths.StripRoll

    Strips the roll component from a CFrame
--]]

--[[function Maths.StripRoll(CF)
    local
        x, y, z,
        M00, M01, M02,
        M10, M11, M12,
        M20, M21, M22
        = CF:components()

    return CFrame.new(
        x, y, z,
        1, 0, 0,
        0, M11, M12,

    )
end]]

--[[
    Maths.HermiteInterpolate

    Interpolates down a spline given two points and two tangents, as well as the tension and bias of the curve.

    Parameter [Numeric] 'P0' - Point which forms first tangent
    Paremeter [Numeric] 'P1' - First point
    Parameter [Numeric] 'P2' - Second point
    Paremeter [Numeric] 'P3' - Point which forms second tangent
    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
    Parameter [Number] 'Tension' - Tension of the curve.
    Parameter [Number] 'Bias' - Bias of the curve.
]]

function Maths.HermiteInterpolate(P0, P1, P2, P3, Mul, Tension, Bias)

    local Mul0 = (P1 - P0) * (1 + Bias) * (1 - Tension) / 2 + (P2 - P1) * (1 - Bias) * (1 - Tension) / 2
    local Mul1 = (P2 - P1) * (1 + Bias) * (1 - Tension) / 2 + (P3 - P2) * (1 - Bias) * (1 - Tension) / 2
    local Mul2 = Mul ^ 2
    local Mul3 = Mul2 * Mul
    local C0 = 2 * Mul3 - 3 * Mul2 + 1
    local C1 = Mul3 - 2 * Mul2 + Mul
    local C2 = Mul3 - Mul2
    local C3 = -2 * Mul3 + 3 * Mul2

    return C0 * P1 + C1 * Mul0 + C2 * Mul1 + C3 * P2
end

--[[
    Maths.HermiteInterpolateCFrame

    An extension of Maths.HermiteInterpolate which works on CFrames.
]]

function Maths.HermiteInterpolateCFrame(P0, P1, P2, P3, Mul, Tension, Bias)

    local P0P, P1P, P2P, P3P = P0.p, P1.p, P2.p, P3.p
    P0 = Quaternion.FromCFrame(P0)
    P1 = Quaternion.FromCFrame(P1)
    P2 = Quaternion.FromCFrame(P2)
    P3 = Quaternion.FromCFrame(P3)
    local M00, M01, M02, M10, M11, M12, M20, M21, M22 = Maths.HermiteInterpolate(P0, P1, P2, P3, Mul, Tension, Bias):ToRotationMatrix()
    local Position = Maths.HermiteInterpolate(P0P, P1P, P2P, P3P, Mul, Tension, Bias)

    return CFrame.new(Position.X, Position.Y, Position.Z, M00, M01, M02, M10, M11, M12, M20, M21, M22)
end

--[[
    Maths.CubicInterpolate

    Standard cubic spline interpolation through two intermediary points with two tangents.

    Parameter [Numeric] 'P0' - Point which forms first tangent
    Paremeter [Numeric] 'P1' - First point
    Parameter [Numeric] 'P2' - Second point
    Paremeter [Numeric] 'P3' - Point which forms second tangent
    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
]]

function Maths.CubicInterpolate(P0, P1, P2, P3, Mul)

    local Mul2 = Mul ^ 2
    local C0 = P3 - P2 - P0 + P1
    local C1 = P0 - P1 - C0
    local C2 = P2 - P0
    local C3 = P1

    return C0 * Mul * Mul2 + C1 * Mul2 + C2 * Mul + C3
end

--[[
    Maths.Clamp

    Keeps Num within a minimum and maximum numerical boundary.

    Paremeter [Number] 'Num' - The number which will be subject to the clamp.
    Paremeter [Number] 'Min' - The minimum number which Num cannot be less than.
    Parameter [Number] 'Max' - The maximum number which Num cannot be greater than.
]]

function Maths.Clamp(Num, Min, Max)
    return (Num < Min and Min or Num > Max and Max or Num)
end

--[[
    Maths.IsNaN
]]

function Maths.IsNaN(Number)
    return Number ~= Number
end

--[[
    Maths.IsInf
]]

function Maths.IsInf(Number)
    return (Number == Math.Huge or Number == -Math.Huge)
end

--[[
    Curve.InterpolatePiecewiseCubic

    Used for 'joining' cubic spline interpolations together.

    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
    Parameter [Function] 'InterpolationFunc' - The cubic spline interpolation function (it should take in two tangents formed by two points and two points to interpolate).
--]]

function Curve:InterpolatePiecewiseCubic(Mul, InterpolationFunc, ...)


    local Forward = Mul * (#self - 3)

    if Forward == #self - 3 then
        Forward = Forward - 0.00000001
    end

    local PointIndex = 2 + math.floor(Forward)

    if PointIndex ~= 0 then

        local P0 = self[PointIndex - 1]
        local P1 = self[PointIndex]
        local P2 = self[PointIndex + 1]
        local P3 = self[PointIndex + 2]
        Mul = Forward - (PointIndex - 2)

        return InterpolationFunc(P0, P1, P2, P3, Mul, ...)
    end
end

--[[
    Maths.InterpolatePiecewise
]]

function Maths.PiecewiseInterpolate(Points, InterpolateFunction, DefaultArgs, CurrentTime, Duration, Offset, PullRange)

    local Lines = #Points - 1
    local Ratio = CurrentTime / Duration
    local CorrectedRatio = (Ratio * Lines) % 1
    local Segment = Maths.Floor(Lines / Duration * CurrentTime) + 1 + Offset
    local Result = {}

    local Iter = 1

    for Index = PullRange.Min, PullRange.Max do
        Result[Iter] = Points[Maths.Clamp(Segment + Index, 1, Lines + 1)]
        Iter = Iter + 1
    end

    Table.Insert(Result, CorrectedRatio)

    for _, Arg in Pairs(DefaultArgs) do
        Table.Insert(Result, Arg)
    end

    return InterpolateFunction(Unpack(Result))
end

--[[
    Maths.AngleDist

    Returns the shortest distance between two angles
]]

function Maths.AngleDist(Angle0, Angle1)
    local Max = Math.PI * 2
    local DiffAngle = (Angle1 - Angle0) % Max
    return 2 * DiffAngle % Max - DiffAngle
end

--[[
    Maths.AngleLerp

    Linearly interpolates an angle across the shortest path
]]

function Maths.AngleLerp(Angle0, Angle1, Factor)
    return Angle0 + Maths.AngleDist(Angle0, Angle1) * Factor
end

--[[
    Curve.InterpolateBezier

    Interpolates down a bezier curve.

    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
    Parameter [Function] 'LerpFunc' - An optional parameter which will utilise a custom interpolation function with three arguments.
]]

function Curve:InterpolateBezier(Mul, LerpFunc)

    local Super = {}

    for Point = 1, #self do
        Super[Point] = self[Point]
    end

    LerpFunc = LerpFunc or Maths.Lerp

    while (#Super > 1) do
        local New = {}
        for Point = 2, #Super do
            local P0 = Super[Point - 1]
            local P1 = Super[Point]
            New[ #New + 1 ] = LerpFunc(P0, P1, Mul)
        end
        Super = New
    end

    return Super[1]
end

--[[
    Curve.New

    Constructs a new wrapped table storing a multitude of points and an object identifier for integration with DataStructureLibrary.

    Parameter [Table] 'Points' - An array of objects or numbers which MUST support common numerical operators.
--]]

function Curve.New(Points)
    return SetMetatable(Points, {
        __index = function(self, Key)
            return RawGet(self, Key) or Curve[Key]
        end;
    })
end

-- Let's Apply CoolPascalCasing ;)

Table.ApplyKeyMapping(Maths, Mappings, math)

-- Mathematical Constants

Maths["NaN"]            = 0/0
Maths["Inf"]            = 1/0
Maths["Radian"]         = Maths.PI / 180
Maths["Tau"]            = 2 * Maths.PI

local Final = {Math = Maths, Curve = Curve}

return {
    Client = Final;
    Server = Final;
}