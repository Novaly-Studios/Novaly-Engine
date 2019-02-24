shared()

local GraphicsLibrary = {}

function GraphicsLibrary:Init()
    coroutine.wrap(function()
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