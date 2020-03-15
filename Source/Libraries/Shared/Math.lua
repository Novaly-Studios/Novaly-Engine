local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Quaternion = Novarine:Get("Quaternion")

local Maths = {}

function Maths.Lerp(P0, P1, Mul)
    return P0 + (P1 - P0) * Mul
end

--[[
    @function LerpUDim2

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
    @function LerpUDim

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
    @function LerpVector2

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
    @function LerpColor3

    Linearly interpolates a Color3 object into another Color3 object
]]

function Maths.LerpColor3(P0, P1, Mul)
    local Result = Vector3.new(P0.r, P0.g, P0.b):lerp(Vector3.new(P1.r, P1.g, P1.b), Mul)
    return Color3.new(Result.X, Result.Y, Result.Z)
end

--[[
    @function NumberToLength

    Strips a decimal number (not an integer) of 'Num' decimal places
]]

function Maths.NumberToLength(Num, Len)
    local Order = 10 ^ (Len - 1)
    return math.floor(Num * Order) / Order
end

--[[
    @function CountDigits

    Counts the digits of a decimal or integer
]]

function Maths.CountDigits(Num)
    local Str = tostring(Num)
    return #Str - #Str:gsub("%d", "")
end

--[[
    @function StripRoll

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
    @function HermiteInterpolate

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
    @function HermiteInterpolateCFrame

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
    @function CubicInterpolate

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
    @function Clamp

    Keeps Num within a minimum and maximum numerical boundary.

    Paremeter [Number] 'Num' - The number which will be subject to the clamp.
    Paremeter [Number] 'Min' - The minimum number which Num cannot be less than.
    Parameter [Number] 'Max' - The maximum number which Num cannot be greater than.
]]

function Maths.Clamp(Num, Min, Max)
    return (Num < Min and Min or Num > Max and Max or Num)
end

--[[
    @function IsNaN
]]

function Maths.IsNaN(Number)
    return Number ~= Number
end

--[[
    @function IsInf
]]

function Maths.IsInf(Number)
    return (Number == math.huge or Number == -math.huge)
end

--[[
    @function Maths.InterpolatePiecewise
]]

function Maths.PiecewiseInterpolate(Points, InterpolateFunction, DefaultArgs, CurrentTime, Duration, Offset, PullRange)

    local Lines = #Points - 1
    local Ratio = CurrentTime / Duration
    local CorrectedRatio = (Ratio * Lines) % 1
    local Segment = math.floor(Lines / Duration * CurrentTime) + 1 + Offset
    local Result = {}

    local Iter = 1

    for Index = PullRange.Min, PullRange.Max do
        Result[Iter] = Points[math.clamp(Segment + Index, 1, Lines + 1)]
        Iter = Iter + 1
    end

    table.insert(Result, CorrectedRatio)

    for _, Arg in pairs(DefaultArgs) do
        table.insert(Result, Arg)
    end

    return InterpolateFunction(unpack(Result))
end

--[[
    @function Maths.AngleDist

    Returns the shortest distance between two angles
]]

function Maths.AngleDist(Angle0, Angle1)
    local Max = math.pi * 2
    local DiffAngle = (Angle1 - Angle0) % Max
    return 2 * DiffAngle % Max - DiffAngle
end

--[[
    @function Maths.AngleLerp

    Linearly interpolates an angle across the shortest path
]]

function Maths.AngleLerp(Angle0, Angle1, Factor)
    return Angle0 + Maths.AngleDist(Angle0, Angle1) * Factor
end

-- Mathematical Constants

Maths["NaN"]            = 0/0
Maths["Inf"]            = 1/0
Maths["Radian"]         = math.pi / 180
Maths["Tau"]            = 2 * math.pi

return Maths