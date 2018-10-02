shared()

local Class = {
    NameKey             = "ClassName";
    ClassRefKey         = "Class";
    SuperclassRefKey    = "Super";
    ConstructorNames    = {"new", "New", "Create"};
    ClassMetatable      = {
        __call = function(self, Static)
            assert(type(Static) == "table", "Static vars must be a table.")
            for Key, Value in pairs(Static) do
                rawset(self, Key, Value)
            end
            return self
        end;
    };
}

function Class:New(Name, ClassTable)

    local function Constructor(...)

        local Result = setmetatable({Class = ClassTable}, ClassTable)
        local Func = ClassTable[Name]
        GetFunctionEnv(Func).self = Result

        local Object = Func(Result, ...)

        if Object then
            Table.MergeKey(Result, Object)
        end

        Result[self.ClassRefKey] = ClassTable
        setmetatable(Result, ClassTable)

        for _, Value in pairs(Result) do
            if (type(Value) == "function") then
                GetFunctionEnv(Value).self = Result
            end
        end

        return Result
    end

    for _, Value in pairs(self.ConstructorNames) do
        ClassTable[Value] = Constructor
    end

    ClassTable[self.NameKey] = Name
    ClassTable["__index"] = ClassTable

    setmetatable(ClassTable, self.ClassMetatable)

    return ClassTable
end

-- Create class from name
function Class:FromName(Name)
    return self:New(Name, {})
end

-- Create class as an extension of another
function Class:FromExtension(Name, Other)

    local Result = self:FromName(Name)

    Result["__index"] = function(self, Key)
        return (rawget(self, Key) or rawget(self, "Class")[Key] or Other[Key])
    end
    Result[self.SuperclassRefKey] = Other

    return Result
end

-- Check if two classes are of equal type
function Class:IsEquivalentType(Subject, CheckSuperclass)

    local SuperKey = self.SuperclassRefKey
    local NameKey = self.NameKey

    while (Subject[SuperKey]) do
        local NextSuper = Subject[SuperKey]
        if (NextSuper[NameKey] == CheckSuperclass[NameKey]) then
            return true
        end
        Subject = NextSuper
    end

    return false
end

shared({
    Client = {Class = Class};
    Server = {Class = Class};
})

return true