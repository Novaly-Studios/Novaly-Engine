local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Math = Novarine:Get("Math")

local Line = Class:FromName(script.Name)

function Line:Line(Start, End)
    return {
        Start   = Start;
        End     = End;
    };
end

function Line:Intersection(Line1)

    local Line0     = self

    local Start0    = Line0.Start
    local End0      = Line0.End
    local Start1    = Line1.Start
    local End1      = Line1.End

    local DiffCross = (Start0.x - End0.x) * (Start1.y - End1.y) - (Start0.y - End0.y) * (Start1.x - End1.x)
    local CrossL0   = Start0.x * End0.y - Start0.y * End0.x
    local CrossL1   = Start1.x * End1.y - Start1.y * End1.x

    return Vector2.new(
        (CrossL0 * (Start1.x - End1.x) - (Start0.x - End0.x) * CrossL1) / DiffCross,
        (CrossL0 * (Start1.y - End1.y) - (Start0.y - End0.y) * CrossL1) / DiffCross
    )
end

function Line:Intersects(Line1)

    local IntersectionVector = self:Intersection(Line1)
    local X = IntersectionVector.X
    local Y = IntersectionVector.Y

    return (not (Math.IsInf(X) or Math.IsInf(Y) or Math.IsNaN(X) or Math.IsNaN(Y))), IntersectionVector
end

return Line