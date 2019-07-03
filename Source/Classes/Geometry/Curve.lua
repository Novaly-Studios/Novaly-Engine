local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Math = Novarine:Get("Math")

local Curve = Class:FromName("Curve")

function Curve:Curve(Points)
    return {
        Points = Points;
    }
end

--[[
    Curve.InterpolatePiecewiseCubic

    Used for 'joining' cubic spline interpolations together.

    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
    Parameter [Function] 'InterpolationFunc' - The cubic spline interpolation function (it should take in two tangents formed by two points and two points to interpolate).
--]]

function Curve:InterpolatePiecewiseCubic(Mul, InterpolationFunc, ...)

    local Points = self.Points
    local Forward = Mul * (#Points - 3)

    if (Forward == #Points - 3) then
        Forward = Forward - 0.00000001
    end

    local PointIndex = 2 + math.floor(Forward)

    if (PointIndex ~= 0) then

        local P0 = Points[PointIndex - 1]
        local P1 = Points[PointIndex]
        local P2 = Points[PointIndex + 1]
        local P3 = Points[PointIndex + 2]
        Mul = Forward - (PointIndex - 2)

        return InterpolationFunc(P0, P1, P2, P3, Mul, ...)
    end
end

--[[
    Curve.InterpolateBezier

    Interpolates down a bezier curve.

    Parameter [Number] 'Mul' - A number between 0 and 1 which will represent how far along the curve to travel.
    Parameter [Function] 'LerpFunc' - An optional parameter which will utilise a custom interpolation function with three arguments.
]]

function Curve:InterpolateBezier(Mul, LerpFunc)

    local Points = self.Points
    local Super = {}

    for Point = 1, #Points do
        Super[Point] = Points[Point]
    end

    LerpFunc = LerpFunc or Math.Lerp

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

return Curve