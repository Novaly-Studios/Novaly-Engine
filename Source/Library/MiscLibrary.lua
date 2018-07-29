local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Misc = {}

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

Func({
    Client = {Misc = Misc};
    Server = {Misc = Misc};
})

return true