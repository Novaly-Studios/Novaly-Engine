local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Class = {
    NewMethod = "new";
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

    if ClassPointer then

        -- An instance is being indexed
        return rawget(Self, Key) or ClassPointer[Key]

    else

        -- A class is being indexed
        return rawget(Self, Key)

    end

end

function Class.FromConstructors(PreConstructor, PostConstructor)

    return Class[Class.NewMethod]({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPostConstructor(PostConstructor)

    return Class[Class.NewMethod]({
        PreConstructor = function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPreConstructor(PreConstructor)

    return Class[Class.NewMethod]({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = function() end;
    })

end

Class[Class.NewMethod] = function(StaticTable, InstanceTable)

    --[[
        We need StaticTable to maintain the same
        metatable while being applicable to both
        the class and its instances so that
        metamethods like __eq, __lq, etc work.
    ]]

    StaticTable = StaticTable or {}
    StaticTable.__index = StaticTable.__index or Class.InstanceIndex
    InstanceTable = InstanceTable or {}
    
    local ResultClass = StaticTable

    local function Constructor(...)

        -- ... are constructor arguments
        -- Clone instance table so each instance has a copy

        local NewObject = table.ShallowClone(InstanceTable)
        NewObject.Class = ResultClass

        -- Pre-constructor activates before metamethods, post-constructor after
        NewObject = StaticTable.PreConstructor(NewObject, ...) or NewObject
        setmetatable(NewObject, StaticTable)
        NewObject = StaticTable.PostConstructor(NewObject, ...) or NewObject
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