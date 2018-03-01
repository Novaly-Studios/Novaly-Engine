local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Quaternion = Class.FromPostConstructor(function(Self, W, X, Y, Z)

    Self.W = W
    Self.X = X
    Self.Y = Y
    Self.Z = Z

end)

function Quaternion.Neg(Subject)

    return Quaternion.new(Subject.W, -Subject.X, -Subject.Y, -Subject.Z)

end

function Quaternion.Norm(Subject)

    return math.sqrt((Subject * Quaternion.Neg(Subject)).W)

end

function Quaternion.Sgn(Subject)

    local Norm = Quaternion.Norm(Subject)
    return Norm == 0 and Quaternion.New(0, 0, 0, 0) or Subject / Norm

end

function Quaternion.Arg(Subject)

    local Norm = Quaternion.Norm(Subject)
    return Norm == 0 and 0 or math.acos(Subject.W / Norm)

end

function Quaternion.Exp(Subject)

    local Diff = (Subject - Quaternion.Neg(Subject)) / 2
    local Norm = Quaternion.Norm(Diff)
    return math.exp(Subject.W) * Quaternion.FromVector(math.cos(Norm), (Quaternion.Sgn(Diff) * math.sin(Norm)):ToVector3())

end

function Quaternion.Qln(Subject)

    local Diff = (Subject - Quaternion.Neg(Subject)) / 2
    local Norm = Quaternion.Norm(Subject)
    return Quaternion.FromVector(math.log(Norm), (Quaternion.Sgn(Diff) * Quaternion.Arg(Subject)):ToVector3())

end

function Quaternion:ToVector3()

    return Vector3.new(self.X, self.Y, self.Z)

end

function Quaternion:ToRotationMatrix()

    local Norm = Quaternion.Norm(self)
    local s = Norm == 0 and 0 or 2 / Norm
    local xx, yy, zz = s * self.X * self.X, s * self.Y * self.Y, s * self.Z * self.Z
    local wx, wy, wz = s * self.W * self.X, s * self.W * self.Y, s * self.W * self.Z
    local xy, xz, yz = s * self.X * self.Y, s * self.X * self.Z, s * self.Y * self.Z

    return  1 - yy - zz, xy - wz, xz + wy,
            xy + wz, 1 - xx - zz, yz - wx,
            xz - wy, yz + wx, 1 - xx - yy

end

function Quaternion:__tostring()

    return self.W .. ", " .. self.X .. ", " .. self.Y .. ", " .. self.Z

end

function Quaternion:__unm()

    return -1 * self

end

function Quaternion:__add(Other)

    return Quaternion.new(
        self.W + Other.W,
        self.X + Other.X,
        self.Y + Other.Y,
        self.Z + Other.Z
    )

end

function Quaternion:__sub(Other)

    return self + Other * - 1

end

function Quaternion:__mul(Other)

    if type(Other) == "number" then

        return Quaternion.new(self.W * Other, self.X * Other, self.Y * Other, self.Z * Other)

    elseif type(self) == "number" then

        return Quaternion.new(self * Other.W, self * Other.X, self * Other.Y, self * Other.Z)

    else

        local W1, W2 = self.W, Other.W
        local Vec1, Vec2 = self:ToVector3(), Other:ToVector3()
        
        return Quaternion.FromVector(
            W1 * W2 - Vec1:Dot(Vec2),
            W1 * Vec2 + W2 * Vec1 + Vec1:Cross(Vec2)
        )

    end

end

function Quaternion:__div(Other)

    return self * Other ^ -1

end

function Quaternion:__pow(Other)

    return Quaternion.Exp(Other * Quaternion.Qln(self))

end

function Quaternion.FromVector(W, Vec)

    return Quaternion.new(W, Vec.x, Vec.y, Vec.z)

end

function Quaternion.FromCFrame(CFObject)

    local _, _, _, M00, M01, M02, M10, M11, M12, M20, M21, M22 = CFObject:components()
    local Sum = M00 + M11 + M22

    if Sum > 0 then

        local r = math.sqrt(1 + Sum)
        local s = 0.5 / r
        return Quaternion.new(0.5 * r, (M21 - M12) * s, (M02 - M20) * s, (M10 - M01) * s)

    else

        if M00 > M11 and M00 > M12 then

            local r = math.sqrt(1 + M00 - M11 - M22)
            local s = 0.5 / r
            return Quaternion.new((M21 - M12) * s, 0.5 * r, (M01 + M10) * s, (M02 + M20) * s)

        elseif M11 > M00 and M11 > M22 then

            local r = math.sqrt(1 - M00 + M11 - M22)
            local s = 0.5 / r
            return Quaternion.new((M02 - M20) * s, (M01 + M10) * s, 0.5 * r, (M12 + M21) * s)

        else

            local r = math.sqrt(1 - M00 - M11 + M22)
            local s = 0.5 / r
            return Quaternion.new((M10 - M01) * s, (M02 + M20) * s, (M12 + M21) * s, 0.5 * r)

        end

    end

end

return Quaternion