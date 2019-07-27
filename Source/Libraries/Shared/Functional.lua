--[[
    Adds some traditional functional programming concepts.
    Use where possible as this will likely support
    multithreading in future.
]]

local Functional = {}

Functional.ImmutableMT = {
    __newindex = function()
        error("Attempt to mutate static table.")
    end;
}

--[[
    Operates on an input table and produces
    and output table.

    @param Input The target table.
    @param Operator A function to which will operate on each value.

    @usage
        local Items = {
            {Name = "Hat1", Price = 300};
            {Name = "Hat2", Price = 100};
            ...
        }

        local NewItems = Functional.Map(Items, function(Item)
            return {
                Name = Item.Name;
                Price = Items.Price * 2;
            }
        end)
]]

function Functional.Map(Input, Operator)
    local Result = {}

    for Key, Value in pairs(Input) do
        Result[Key] = Operator(Value)
    end

    return Functional.Immutable(Result)
end

--[[
    Operates on an input table and produces
    and output table *with custom keys*.

    @param Input The target table.
    @param Operator A function to which will operate on each value. Must return Key, Value tuple

    @usage
        local Items = {
            {Name = "Hat1", Price = 300};
            {Name = "Hat2", Price = 100};
            ...
        }

        local NewItems = Functional.Map(Items, function(Item)
            return Item.Name .. "|", {
                Name = Item.Name;
                Price = Items.Price * 2;
            }
        end)
]]

function Functional.KMap(Input, Operator)
    local Result = {}

    for _, Value in pairs(Input) do
        local Key, ResultValue = Operator(Value)
        Result[Key] = ResultValue
    end

    return Functional.Immutable(Result)
end

--[[
    Collects some items from an array which satisfy
    a condition.

    @param Input The target table.
    @param Assessment The function to determine whether an item meets a criteria.

    @usage
        local Items = {
            {X = 10, Y = 15};
            {X = 7, Y = 12};
            {X = 90, Y = 14};
        }
        local Filtered = Functional.Filter(Items, function(Object)
            return Object.Y >= 14
        end)
]]

function Functional.Filter(Input, Assessment)
    local Result = {}
    local Index = 1

    for _, Value in pairs(Input) do
        if (Assessment(Value)) then
            Result[Index] = Value
            Index = Index + 1
        end
    end

    return Functional.Immutable(Result)
end

function Functional.Reduce(Input, Operator, InitialValue)
    local DataType = type(Input[1])
    local RunningValue = InitialValue or (
        DataType == "number" and 0 or
        DataType == "table" and {} or
        DataType == "string" and ""
    )

    for Key, Value in pairs(Input) do
        RunningValue = Operator(RunningValue, Value, Key, Input)
    end

    return RunningValue
end

function Functional.Flatten(Input)
    local Result = {}

    for Key, Value in pairs(Input) do
        if (type(Value) == "table") then
            for Key, Value in pairs(Functional.Flatten(Value)) do
                Result[Key] = Value
            end
        else
            Result[Key] = Value
        end
    end

    return Functional.Immutable(Result)
end

function Functional.FlattenNumeric(Input)
    local Result = {}
    local Index = 1

    for _, Value in pairs(Input) do
        if (type(Value) == "table") then
            for _, Value in pairs(Functional.FlattenNumeric(Value)) do
                Result[Index] = Value
                Index = Index + 1
            end
        else
            Result[Index] = Value
            Index = Index + 1
        end
    end

    return Functional.Immutable(Result)
end

function Functional.SatisfiesAll(Table, Assessment)
    for _, Value in pairs(Table) do
        if (not Assessment(Value)) then
            return false
        end
    end

    return true
end

function Functional.SatisfiesOnce(Table, Assessment)
    for _, Value in pairs(Table) do
        if (Assessment(Value)) then
            return true
        end
    end

    return false
end

function Functional.Fuse(Initial, Other)
    local Result = {}

    for Key, Value in pairs(Initial) do
        Result[Key] = Value
    end

    for Key, Value in pairs(Other) do
        Result[Key] = Value
    end

    return Functional.Immutable(Result)
end

function Functional.FuseNumeric(Initial, Other)
    local Result = {}
    local Offset = #Initial

    for Index = 1, Offset do
        Result[Index] = Initial[Index]
    end

    for Index = 1, #Other do
        Result[Offset + Index] = Other[Index]
    end

    return Functional.Immutable(Result)
end

function Functional.Iterate(Table, Operate)
    for Key, Value in pairs(Table) do
        Operate(Key, Value)
    end
end

function Functional.Immutable(Table)
    return setmetatable(Table, Functional.ImmutableMT)
end

return Functional