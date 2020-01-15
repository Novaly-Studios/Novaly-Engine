local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local CollectionService = Novarine:Get("CollectionService")
local Async = Novarine:Get("Async")

local GraphicsLibrary = {}

function GraphicsLibrary:Init()
    Async.Wrap(function()
        for Index, Part in pairs(CollectionService:GetTagged("Graphics:TransparentPart")) do
            local Settings = Part:FindFirstChild("Settings")

            if Settings then
                Settings.InitialTransparency.Value = Part.Transparency
            end

            if (Index % 50 == 0) then
                wait()
            end
        end
    end)()
end

return GraphicsLibrary