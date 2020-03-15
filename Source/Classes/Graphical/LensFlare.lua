local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local LensFlare = Class:FromName(script.Name)

function LensFlare:LensFlare(ImageID, Offset, Size, TransparencyValues, Scale, Rotate)
    return {
        Offset                 = Offset;
        Size                   = Size;
        Centre                 = Size / 2;
        Scale                  = Scale; -- Todo, scale image size with distance
        Rotate                 = Rotate;
        ImageID                = ImageID;
        TransparencyValues     = TransparencyValues;
    }
end

return LensFlare