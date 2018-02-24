local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Class = {}

function Class.NewIndexHandler(Self, Key, Value)

    rawget(Self, Key, Value)

end

Class.InstanceMetatable = {

    __index = function(Self, Key)

        return rawget(Self, Key) or rawget(Self, "Class")[Key]

    end;

}

function Class.new(StaticTable, InstanceTable)

    StaticTable = StaticTable or {}

    local ResultClass = StaticTable
    InstanceTable = InstanceTable or {}
    ResultClass.Instances = {}

    local function Constructor(...)

        -- ... are constructor arguments
        -- Clone instance table so each instance has a copy

        local NewObject = table.ShallowClone(InstanceTable)
        NewObject.Class = ResultClass

        -- Pre-constructor activates before metamethods

        StaticTable.PreConstructor(NewObject, ...)
        setmetatable(NewObject, Class.InstanceMetatable)

        for Key, Value in next, StaticTable do

            getmetatable(NewObject)[Key] = Value

        end

        -- Post-constructor activates after metamethods

        StaticTable.PostConstructor(NewObject, ...)
        table.insert(ResultClass.Instances, NewObject)

        return NewObject

    end

    ResultClass.new = Constructor

    return ResultClass

end

function Class.FromConstructors(PreConstructor, PostConstructor)

    return Class.new({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPostConstructor(PostConstructor)

    return Class.new({
        PreConstructor = function() end;
        PostConstructor = PostConstructor or function() end;
    })

end

function Class.FromPreConstructor(PreConstructor)

    return Class.new({
        PreConstructor = PreConstructor or function() end;
        PostConstructor = function() end;
    })

end

function Class.__main()

    local ClassItems = Classes:GetChildren()

    for Item = 1, #ClassItems do

        local Item = ClassItems[Item]
        Structures[Item.Name] = require(Item)

    end

end

return {
    Client = {Class = Class};
    Server = {Class = Class};
}