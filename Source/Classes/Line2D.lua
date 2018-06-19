--[[setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Line2D = Class.FromConstructor(script.Name, function(Self, P0, P1)

    self.P0 = P0
    self.P1 = P1

end)

function Line2D:LiesOn(Point)

    local P0 = self.P0
    local P1 = self.P1

    local function Bounds(Index)
        return Math.Min(P0[Index], P1[Index]) <= Point[Index] and
               Point[Index] <= Math.Max(P0[Index], P1[Index])
    end

    return Bounds("X") and Bounds("Y")

end

function Line2D:Orientation(P0, P1, P2)

    P2 = P2 or Vector2.new(0, 0)
    return (P1.Y - P0.Y) * (P2.X - P1.X) - (P1.X - P0.X) * (P2.Y - P1.Y)

end

function Line2D:Intersects(Other)

    local O1 = self:Orientation()

end

return Line2D]]