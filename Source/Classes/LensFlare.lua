setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local LensFlare = Class.FromPostConstructor(function(Self, ImageID, Offset, Size, TransparencyValues, Scale, Rotate)

    Self.Offset                 = Offset;
    Self.Size                   = Size;
    Self.Centre                 = Size / 2;
    Self.Scale                  = Scale; -- Todo, scale image size with distance
    Self.Rotate                 = Rotate;
    Self.ImageID                = ImageID;
    Self.TransparencyValues     = TransparencyValues;

end)

return LensFlare