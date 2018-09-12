shared()

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

shared({
    Client = {Misc = Misc};
    Server = {Misc = Misc};
})

return true