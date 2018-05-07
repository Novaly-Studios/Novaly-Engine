local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Class = {
    NewMethod = "new";
    TypeName = "CLASS_TYPE";
}

function Class.GetData(Object)

    local Attributes = {}

    for Key, Value in next, Object do

        if type(Value) ~= "function" then

            Attributes[Key] = Value

        end

    end

    return Attributes
    
end

function Class.InstanceIndex(Self, Key)

    local ClassPointer = rawget(Self, "Class")
    local Value = rawget(Self, Key)

    if ClassPointer then

        -- An instance is being indexed
        return Value or ClassPointer[Key]

    end

    -- A class is being indexed
    return Value

end

function Class.FromConstructor(ClassType, Constructor)

    return Class[Class.NewMethod](ClassType, {
        [ClassType] = Constructor or function() end;
    })

end

function Class.FromName(ClassType)

    return Class[Class.NewMethod](ClassType)

end

function Class.InstanceOf(Subject, Other)

    return (Subject[Class.TypeName] == Other[Class.TypeName])

end

function Class.CreateExtension(ClassType, Other)

    local function IndexFunction(Self, Key)

        return Class.InstanceIndex(Self, Key) or Other[Key]

    end

    local ClassMT = {__index = IndexFunction}
    local ClassObject = Class[Class.NewMethod](ClassType, ClassMT, ClassMT)

    return ClassObject

end

Class[Class.NewMethod] = function(ClassType, StaticTable, InstanceTable)

    --[[
        We need StaticTable to maintain the same
        metatable while being applicable to both
        the class and its instances so that
        metamethods like __eq, __lq, etc work.
    ]]

    StaticTable = StaticTable or {}
    StaticTable.__index = StaticTable.__index or Class.InstanceIndex
    InstanceTable = InstanceTable or {}
    StaticTable[Class.TypeName] = ClassType

    local ResultClass = StaticTable

    local function Constructor(...)

        -- ... are constructor arguments
        -- Clone instance table so each instance has a copy

        local NewObject = Table.ShallowClone(InstanceTable)
        NewObject.Class = ResultClass

        setmetatable(NewObject, StaticTable)
        assert(StaticTable[ClassType], "Error: No constructor for class '" .. ClassType .."'!")
        NewObject = StaticTable[ClassType](NewObject, ...) or NewObject
        return NewObject

    end

    setmetatable(ResultClass, StaticTable)
    ResultClass[Class.NewMethod] = Constructor

    return ResultClass

end

Func({
    Client = {Class = Class};
    Server = {Class = Class};
})

return true