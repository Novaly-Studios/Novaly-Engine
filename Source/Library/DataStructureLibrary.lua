shared()

local DataStructures    = {
    TypeVar             = "TYPE";
}

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

DataStructures.BuildFunctions = {
    Color3 = function(Object)
        return {
            Object.r;
            Object.g;
            Object.b;
        }
    end;
    Vector3 = function(Object)
        return {
            Object.X;
            Object.Y;
            Object.Z;
        }
    end;
    Vector2 = function(Object)
        return {
            Object.X;
            Object.Y;
        }
    end;
}

function Test(Var, Property)
    local Result, Value = ProtectedCall(function()
        return Var[Property]
    end)
    return (Result == false and nil or Value)
end

function DataStructures:GetType(Var)

    local Found = Type(Var)

    if (Found ~= "userdata") then
        return Found
    else

        local Prev = 0
        local Found = nil

        for Key, Value in Pairs(self.Built) do

            local Count = 0

            for Key, Value in Pairs(Value) do
                Count = Count + (Type(Test(Var, Key)) == Value and 1 or -1)
            end

            if (Count >= Prev) then
                Found = Key
                Prev = Count
            end
        end

        return (Found ~= "userdata" and Found or "unknown"), Prev
    end
end

function DataStructures:Serialise(Item)

    local ItemType = self:GetType(Item)
    local Handler = self.SerialiseFunctions[ItemType]
    Assert(Handler, String.Format("No serialisation function exists for %s!", ItemType))

    local Result = Handler(Item)
    Result[self.TypeVar] = ItemType
    return Result
end

function DataStructures:Build(Serialised)

    local ItemType = Serialised[self.TypeVar]
    Assert(ItemType, "Data passed to this function must be serialised!")

    local Class = GetFunctionEnv()[ItemType]
    Assert(Class, String.Format("No class exists under the name %s!", ItemType))

    local BuildFunction = self.BuildFunctions[ItemType]
    Assert(BuildFunction, String.Format("No build function exists for %s!", ItemType))

    return Class.new(Unpack(BuildFunction(Serialised)))
end

function DataStructures:CanSerialise(TypeName)
    return (self.SerialiseFunctions[TypeName] == nil and false or true)
end

function DataStructures:CanBuild(TypeName)
    return (self.BuildFunctions[TypeName] == nil and false or true)
end

shared({
    Client = {DataStructures = DataStructures};
    Server = {DataStructures = DataStructures};
})

return true