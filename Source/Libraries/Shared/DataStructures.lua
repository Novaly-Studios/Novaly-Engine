--[[
    Allows for the construction, inheritance and typing of classes.

    @module Data Structure and Serialisation Library
    @alias DataStructureLibrary
    @author TPC9000
]]

local DataStructures    = {
    TypeVar             = "TYPE";
}

--[[
    A table of data types and their fields. This is used
    to determine the type of the object.

    @table DataStructures.Built
]]

DataStructures.Built    = {
    Vector2 = {
        x = "number";
        y = "number";
    };
    Vector3 = {
        x = "number";
        y = "number";
        z = "number";
        Cross = "function";
        Dot = "function";
    };
    CFrame = {
        components = "function";
        x = "number";
        y = "number";
        z = "number";
    };
    UDim = {
        Scale = "number";
        Offset = "number";
    };
    UDim2 = {
        X = "userdata";
        Y = "userdata";
    };
    Color3 = {
        r = "number";
        g = "number";
        b = "number";
    };
    Region3 = {
        CFrame = "userdata";
        Size = "userdata";
        ExpandToGrid = "function";
    };
}

--[[
    A table of functions which take an input object
    and return a table representation of that object.

    @table DataStructures.SerialiseFunctions
]]

DataStructures.SerialiseFunctions = {
    Color3 = function(Object)
        return {
            r = Object.r;
            g = Object.g;
            b = Object.b;
        }
    end;
    Vector3 = function(Object)
        return {
            x = Object.X;
            y = Object.Y;
            z = Object.Z;
        }
    end;
    Vector2 = function(Object)
        return {
            x = Object.X;
            y = Object.Y;
        }
    end;
}

--[[
    A table of functions which take a serialised table
    and return a deserialised object from that table.

    @table DataStructures.SerialiseFunctions
]]

DataStructures.BuildFunctions = {
    Color3 = function(Object)
        return Color3.new(
            Object.r,
            Object.g,
            Object.b
        )
    end;
    Vector3 = function(Object)
        return Vector3.new(
            Object.X,
            Object.Y,
            Object.Z
        )
    end;
    Vector2 = function(Object)
        return Vector2.new(
            Object.X,
            Object.Y
        )
    end;
}

--[[
    @function Test

    Tests an object which would likely error when indexed
    with a non-existant property and returns any value found.

    @param Var The object to test.
    @param Property The name of the property to look for.
    @return An obtained value from the object if any is present, or nil.
]]

local function Test(Var, Property)
    local Result, Value = pcall(function()
        return Var[Property]
    end)
    return (Result == false and nil or Value)
end

--[[
    @function DataStructures.GetType

    Returns the type of a userdata defined by the
    defintions in DataStructures.Built. If the type
    of the provided object is anything other than
    a userdata or a table then its primitive type
    is returned.

    @param Var The object to test.
    @return A string denoting the type of the object being tested.

    @todo Recursive definitions.
    @todo Integration with class library.

    DEPRECATED in favour of Typing library.
]]

function DataStructures:GetType(Var)

    local Found = type(Var)

    if (Found ~= "userdata" and Found ~= "table") then
        return Found
    else

        local Prev = 0
        local Found = nil

        for Key, Value in pairs(self.Built) do

            local Count = 0

            for Key, Value in pairs(Value) do
                Count = Count + (type(Test(Var, Key)) == Value and 1 or -1)
            end

            if (Count >= Prev) then
                Found = Key
                Prev = Count
            end
        end

        return (Found ~= "userdata" and Found or "unknown"), Prev
    end
end

--[[
    @function DataStructures.Serialise

    Serialises an object into a single table.

    @param Item The object to serialise.
    @return A serialised table.
]]

function DataStructures:Serialise(Item)

    local ItemType = self:GetType(Item)
    local Handler = self.SerialiseFunctions[ItemType]
    assert(Handler, string.format("No serialisation function exists for %s!", ItemType))

    local Result = Handler(Item)
    Result[self.TypeVar] = ItemType
    return Result
end

--[[
    @function DataStructures.Build

    Builds a serialised object back into
    its full form.

    @param Serialised The serialised table to convert.
    @return The built object.
]]

function DataStructures:Build(Serialised)

    local ItemType = Serialised[self.TypeVar]
    assert(ItemType, "Data passed to this function must be serialised!")

    local BuildFunction = self.BuildFunctions[ItemType]
    assert(BuildFunction, string.format("No build function exists for %s!", ItemType))

    return BuildFunction(Serialised)
end

--[[
    @function DataStructures.CanSerialise

    Determines whether a type serialisation
    exists in the current data.

    @param TypeName The type to check for.
    @return A boolean denoting whether the serialisation function exists.
]]

function DataStructures:CanSerialise(TypeName)
    return (self.SerialiseFunctions[TypeName] == nil and false or true)
end

--[[
    @function DataStructures.CanBuild

    Determines whether an object builder
    exists in the current data.

    @param TypeName The type to check for.
    @return A boolean denoting whether the builder function exists.
]]

function DataStructures:CanBuild(TypeName)
    return (self.BuildFunctions[TypeName] == nil and false or true)
end

return DataStructures