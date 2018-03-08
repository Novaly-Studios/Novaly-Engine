local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local LensFlare = Class.FromPostConstructor(function(Self, ImageID, Offset, Size, Raycast, Distance, Scale, Rotate)
    
    Self.IsFlare    = true
    Self.ImageID    = "rbxassetid://" .. ImageID
    Self.Offset     = Offset
    Self.Size       = Size
    Self.HalfSize   = Size / 2
    Self.Raycast    = Raycast
    Self.Distance   = Distance
    Self.Scale      = Scale -- Todo, scale image size with distance
    Self.Rotate     = Rotate -- Todo, rotate image around adornee

end)

return LensFlare