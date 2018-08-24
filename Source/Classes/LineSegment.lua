setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local LineSegment = Class:FromName(script.Name)

function LineSegment:LineSegment(Start, End)
    return {
        Start   = Start;
        End     = End;
    };
end

function LineSegment:PointLiesOn(Point)

    local Start = self.Start
    local End = self.End

    if (Point.x <= Math.Max(Start.x, End.x) and
        Point.x >= Math.Min(Start.x, End.x) and
        Point.y <= Math.Max(Start.y, End.y) and
        Point.y >= Math.Min(Start.y, End.y)) then
        return true
    end

    return false
end

function LineSegment:Orientation(P0, P1, P2)

end

function LineSegment:Intersection(Line1)

    local Line0     = self

    local Start0    = Line0.Start
    local End0      = Line0.End
    local Start1    = Line1.Start
    local End1      = Line1.End


end

function LineSegment:Intersects(Line1)

    

    return 
end

return LineSegment