--[[
    Provides various geometric functions.

    @module Geometry Library
    @alias GeometryLibrary
    @author TPC9000
]]

local Geometry = {}

--[[
    @function PointIsWithinPolygon

    Checks whether a point is within the bounds of a 2D polygon.

    @usage
        local Intersecting = Geometry:PointIsWithinPolygon(
            Vector2.new(5, 5);
            {
                Vector3.new(0, 0);
                Vector3.new(10, 0);
                Vector3.new(0, 10);
                Vector3.new(10, 10);
            }
        )

    @param Point The Vector2 point to check intersection.
    @param Polygon A table of Vector2 points defining the vertices of the polygon.
]]

function Geometry:PointIsWithinPolygon(Point, Polygon)

    assert(typeof(Point) == "Vector2")
    assert(typeof(Polygon) == "table")

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

return Geometry