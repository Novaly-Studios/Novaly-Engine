local Functional = {}

function Functional.InstanceType(Type)
    return function(Instance)
        return Instance:IsA(Type)
    end
end

return Functional