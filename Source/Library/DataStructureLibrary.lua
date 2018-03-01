local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local DataStructures    = {}

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

function Test(Var, Property)

    local Result, Value = pcall(function() return Var[Property] end)
    return Result == false and nil or Value

end

function DataStructures.GetType(Var)

    local Found = type(Var)

    if Found ~= "userdata" then

        return Found

    else

        local Prev = 0
        local Found = nil

        for Key, Value in next, DataStructures.Built do

            local Count = 0

            for Key, Value in next, Value do

                Count = Count + (type(Test(Var, Key)) == Value and 1 or -1)

            end

            if Count >= Prev then

                Found = Key
                Prev = Count
                
            end

        end

        return Found ~= "userdata" and Found or "unknown", Prev

    end

end

Func({
    Client = {DataStructures = DataStructures};
    Server = {DataStructures = DataStructures};
})

return true