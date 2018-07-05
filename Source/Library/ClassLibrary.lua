local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Class = {
    ConstructorNames = {"new", "New"};
}

function Class:New(Name, ClassTable)

    local function Constructor(...)

        local Result = setmetatable({Class = ClassTable}, ClassTable)
        local Func = ClassTable[Name]
        getfenv(Func).Self = Result

        local Object = Func(Result, ...)
        local Final = Object or Result
        Final["Class"] = ClassTable
        setmetatable(Final, ClassTable)

        for Key, Value in pairs(Final) do
            if (type(Value) == "function") then
                getfenv(Value).Self = Final
            end
        end

        return Final
    end

    for _, Value in pairs(self.ConstructorNames) do
        ClassTable[Value] = Constructor
    end

    ClassTable["Name"] = Name
    ClassTable["__index"] = ClassTable

    return ClassTable
end

function Class:FromName(Name)
    return self:New(Name, {})
end

function Class:FromExtension(Name, Other)

    local Result = self:FromName(Name)

    Result["__index"] = function(Self, Key)
        return (rawget(Self, Key) or rawget(Self, "Class")[Key] or Other[Key])
    end
    Result.Super = Other

    return Result
end

Func({
    Client = {Class = Class};
    Server = {Class = Class};
})

return true