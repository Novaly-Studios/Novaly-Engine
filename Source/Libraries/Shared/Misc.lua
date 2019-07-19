local Misc = {}

--[[
    Recursively constructs a Lua hierarchy from
    a Roblox Instance. Useful for settings within
    Instances. Only obtains Value Instances like
    StringValue, CFrameValue, etc..

    @param Root The Instance to read.

    @usage
        local Settings = Misc:TableFromTreeValues(TestInstance.Settings)
        print(Settings.Count)
        print(Settings.Greetings)
        print(Settings.Dialogue.Page1.Text)
]]

function Misc:TableFromTreeValues(Root)

    local Result = {}

    for _, Object in pairs(Root:GetChildren()) do
        if (Object:IsA("ValueBase")) then
            Result[Object.Name] = Object.Value
        else
            Result[Object.Name] = self:TableFromTreeValues(Object)
        end
    end

    return Result
end

return Misc
