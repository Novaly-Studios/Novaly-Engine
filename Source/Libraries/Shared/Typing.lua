local GetType = typeof or type

local TypeChecker = {
    Types = {};
    Checks = {};
};

function TypeChecker:GetCheck(...)
    local TypeDefinitions = {...}

    return function(...)
        local DataPassedIn = {...}

        --[[
            Check each item in supplied data and ensure it
            is the same as a specified type.
        ]]
        for Index, Item in pairs(TypeDefinitions) do
            if (not self:IsType(DataPassedIn[Index], Item)) then
                return false
            end
        end

        return true
    end
end

function TypeChecker:AddDefinition(Name, Definition)
    assert(GetType(Definition) == "table")
    assert(not self[Name])

    setmetatable(Definition, {
        __tostring = function()
            return "Type:" .. Name
        end;
    })

    self.Types[Name] = Definition
    self[Name] = Definition
end

function TypeChecker:Primitive(Name)
    return setmetatable({_PRIMITIVE = Name}, {
        __tostring = function()
            return "Primitive:" .. Name
        end;
    })
end

function TypeChecker:OneOf(...)
    return setmetatable({_ONE_OF = {...}}, {
        __tostring = function(Self)
            return "OneOf:" .. table.concat(Self._ONE_OF, ",")
        end;
    })
end

function TypeChecker:Optional(TypeDefinition)
    return setmetatable({_OPTIONAL = TypeDefinition}, {
        __tostring = function()
            return "Optional(" .. tostring(TypeDefinition) .. ")"
        end;
    })
end

function TypeChecker:Equivalent(Value)
    return setmetatable({_EQUIVALENT = Value}, {
        __tostring = function()
            return "Equals(" .. tostring(Value) .. ")"
        end;
    })
end

function TypeChecker:Any()
    return setmetatable({_NOT_NULL = true}, {
        __tostring = function()
            return "Any()"
        end;
    })
end

function TypeChecker:Condition(Type, Checker)
    return setmetatable({_TYPE = Type, _CONDITION = Checker}, {
        __tostring = function()
            return "Equals(" .. tostring(Checker) .. ")"
        end;
    })
end

function TypeChecker:IsType(Object, TypeDefinition)

    -- Object is not null
    if (TypeDefinition._NOT_NULL) then
        return (Object ~= nil)
    end

    -- Optional type and nil type are acceptable
    if (TypeDefinition._OPTIONAL and Object == nil) then
        return true
    end

    -- If optional value was not nil, ensure types are equivalent
    if (TypeDefinition._OPTIONAL) then
        return self:IsType(Object, TypeDefinition._OPTIONAL)
    end

    -- Ensure values are equivalent
    if (TypeDefinition._EQUIVALENT) then
        return (Object == TypeDefinition._EQUIVALENT)
    end

    -- Conditions for values and type definitions
    if (TypeDefinition._CONDITION) then
        return (self:IsType(Object, TypeDefinition._TYPE) and TypeDefinition._CONDITION(Object, TypeDefinition))
    end

    -- Check primitives at roots of object are equivalent
    if (TypeDefinition._PRIMITIVE) then
        return GetType(Object) == TypeDefinition._PRIMITIVE
    end

    -- Type could be one of many (type A or type B ... or type X)
    if (TypeDefinition._ONE_OF) then
        for _, SubItem in pairs(TypeDefinition._ONE_OF) do
            if (self:IsType(Object, SubItem)) then
                return true
            end
        end

        return false
    end

    -- If any types mismatch, fail
    -- If anything is not in the type definition, fail
    for Key, SubItem in pairs(Object) do
        local SubTypeDefinition = TypeDefinition[Key]

        if (not SubTypeDefinition) then
            return false
        end

        if (not self:IsType(SubItem, SubTypeDefinition)) then
            return false
        end
    end

    -- If any required fields don't exist, then fail
    for Key, Field in pairs(TypeDefinition) do
        if (not self:IsType(Object[Key], Field)) then
            return false
        end
    end

    -- All conditions passed
    return true
end

function TypeChecker:GetType(Item)
    -- This can be made more efficient
    for Name, Type in pairs(self.Types) do
        if (self:IsType(Item, Type)) then
            return Type, Name
        end
    end

    return false
end

TypeChecker:AddDefinition("Userdata", TypeChecker:Primitive("userdata"))
TypeChecker:AddDefinition("Function", TypeChecker:Primitive("function"))
TypeChecker:AddDefinition("Boolean", TypeChecker:Primitive("boolean"))
TypeChecker:AddDefinition("Thread", TypeChecker:Primitive("thread"))
TypeChecker:AddDefinition("String", TypeChecker:Primitive("string"))
TypeChecker:AddDefinition("Number", TypeChecker:Primitive("number"))
TypeChecker:AddDefinition("Table", TypeChecker:Primitive("table"))

if typeof then
    TypeChecker:AddDefinition("RBXConnectionSignal", TypeChecker:Primitive("RBXConnectionSignal"))
    TypeChecker:AddDefinition("PhysicalProperties", TypeChecker:Primitive("PhysicalProperties"))
    TypeChecker:AddDefinition("RBXScriptSignal", TypeChecker:Primitive("RBXScriptSignal"))
    TypeChecker:AddDefinition("NumberSequence", TypeChecker:Primitive("NumberSequence"))
    TypeChecker:AddDefinition("ColorSequence", TypeChecker:Primitive("ColorSequence"))
    TypeChecker:AddDefinition("Vector3int16", TypeChecker:Primitive("Vector3int16"))
    TypeChecker:AddDefinition("Region3int16", TypeChecker:Primitive("Region3int16"))
    TypeChecker:AddDefinition("Vector2int16", TypeChecker:Primitive("Vector2int16"))
    TypeChecker:AddDefinition("PathWaypoint", TypeChecker:Primitive("PathWaypoint"))
    TypeChecker:AddDefinition("NumberRange", TypeChecker:Primitive("NumberRange"))
    TypeChecker:AddDefinition("BrickColor", TypeChecker:Primitive("BrickColor"))
    TypeChecker:AddDefinition("TweenInfo", TypeChecker:Primitive("TweenInfo"))
    TypeChecker:AddDefinition("Instance", TypeChecker:Primitive("Instance"))
    TypeChecker:AddDefinition("Vector3", TypeChecker:Primitive("Vector3"))
    TypeChecker:AddDefinition("Region3", TypeChecker:Primitive("Region3"))
    TypeChecker:AddDefinition("CFrame", TypeChecker:Primitive("CFrame"))
    TypeChecker:AddDefinition("Random", TypeChecker:Primitive("Random"))
    TypeChecker:AddDefinition("Color3", TypeChecker:Primitive("Color3"))
    TypeChecker:AddDefinition("UDim2", TypeChecker:Primitive("UDim2"))
    TypeChecker:AddDefinition("UDim", TypeChecker:Primitive("UDim"))
    TypeChecker:AddDefinition("Axes", TypeChecker:Primitive("Axes"))
end

TypeChecker:AddDefinition("GenericVector3", {
    X = TypeChecker.Types.Number;
    Y = TypeChecker.Types.Number;
    Z = TypeChecker.Types.Number;
})

TypeChecker:AddDefinition("GenericVector2", {
    X = TypeChecker.Types.Number;
    Y = TypeChecker.Types.Number;
})

--[[

--Example:

TypeChecker:AddDefinition("Test", {
    One = TypeChecker.Types.Number;
    Two = TypeChecker.Types.String;
    Three = {
        Four = TypeChecker.Types.Number;
        Five = TypeChecker:Optional(TypeChecker.Types.Number);
    };
})

local Check = TypeChecker:GetCheck(
    TypeChecker.Types.Number,
    TypeChecker:Optional(TypeChecker.Types.String),
    TypeChecker:Optional(TypeChecker.Types.Function),
    TypeChecker.Types.Test,
    TypeChecker:OneOf(
        TypeChecker.Types.Number,
        TypeChecker.Types.String,
        TypeChecker.Types.Boolean
    ),
    TypeChecker:Condition(TypeChecker.Types.Number, function(Value)
        return Value > 10
    end)
)

print(Check(1, "knsgkgdnklgd", function() end, {
    One = 1;
    Two = "2";
    Three = {
        Four = 4;
        Five = 5;
    };
}, true, 11))

]]

return TypeChecker