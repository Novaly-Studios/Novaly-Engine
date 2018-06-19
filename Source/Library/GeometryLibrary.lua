local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Geometry = {}

function Geometry:PointIsWithinPolygon(Point, Polygon)

    local Result = false
    local Prev = #Polygon

    for Iter = 1, Prev do
        if (Polygon[Iter].Y < Point.Y and Polygon[Prev].Y >= Point.Y or Polygon[Prev].Y < Point.Y and Polygon[Iter].Y >= Point.Y) then
            if (Polygon[Iter].X + (Point.Y - Polygon[Iter].Y) / (Polygon[Prev].Y - Polygon[Iter].Y) * (Polygon[Prev].X - Polygon[Iter].X) < Point.X) then
                Result = not Result
            end
        end
        Prev = Iter
    end

    return Result
end

function Geometry:StripAxis(Point, ClassRef, ...)

    local Args = {...}
    local Count = #Args

    for Key, Index in pairs(Args) do
        Args[Key] = Point[Index]
    end

    return ClassRef.new(unpack(Args))
end

Func({
    Client = {Geometry = Geometry};
    Server = {Geometry = Geometry};
})

return true