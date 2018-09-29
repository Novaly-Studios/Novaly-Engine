shared()

local Class = {
    NameKey             = "ClassName";
    ClassRefKey         = "Class";
    SuperclassRefKey    = "Super";
    ConstructorNames    = {"new", "New", "Create"};
    ClassMetatable      = {
        __call = function(self, Static)
            Assert(Type(Static) == "table", "Static vars must be a table.")
            for Key, Value in Pairs(Static) do
                RawSet(self, Key, Value)
            end
            return self
        end;
    };
}

function Class:New(Name, ClassTable)

    local function Constructor(...)

        local Result = SetMetatable({Class = ClassTable}, ClassTable)
        local Func = ClassTable[Name]
        GetFunctionEnv(Func).self = Result

        local Object = Func(Result, ...)

        if Object then
            Table.MergeKey(Result, Object)
        end

        Result[self.ClassRefKey] = ClassTable
        SetMetatable(Result, ClassTable)

        for _, Value in Pairs(Result) do
            if (Type(Value) == "function") then
                GetFunctionEnv(Value).self = Result
            end
        end

        return Result
    end

    for _, Value in Pairs(self.ConstructorNames) do
        ClassTable[Value] = Constructor
    end

    ClassTable[self.NameKey] = Name
    ClassTable["__index"] = ClassTable

    SetMetatable(ClassTable, self.ClassMetatable)

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
        return (RawGet(self, Key) or RawGet(self, "Class")[Key] or Other[Key])
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