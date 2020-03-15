local Misc = {
    TableFromTreeValuesCache = {};
}

function Misc:TableFromTreeValues(Root)

    local Cache = self.TableFromTreeValuesCache

    if (Cache[Root]) then
        return Cache[Root]
    end

    local Result = {}

    for _, Object in pairs(Root:GetChildren()) do
        if (Object:IsA("ValueBase")) then
            Result[Object.Name] = Object.Value
        else
            Result[Object.Name] = self:TableFromTreeValues(Object)
        end
    end

    Cache[Root] = Result

    return Result
end

return Misc