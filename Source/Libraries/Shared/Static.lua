local Static = {}

--[[
    Directory:
    - Map
    - KMap
    - Filter
    - Reduce
    - Flatten
    - FlattenNumeric
    - SatisfiesAll
    - SatisfiesOnce
    - Fuse1D
    - FuseNumeric1D
    - FuseNested
    - FuseNumericNested
    - Iterate1D
    - IterateNested
    - Copy1D
    - CopyNested
    - Sort1D
    - Keys1D
    - Values1D
]]

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

        local NewItems = Static.Map(Items, function(Item)
            return {
                Name = Item.Name;
                Price = Items.Price * 2;
            }
        end)
]]

function Static.Map(Input, Operator)
    local Result = {}

    for Key, Value in pairs(Input) do
        Result[Key] = Operator(Value)
    end

    return Result
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

        local NewItems = Static.Map(Items, function(Item)
            return Item.Name .. "|", {
                Name = Item.Name;
                Price = Items.Price * 2;
            }
        end)
]]

function Static.KMap(Input, Operator)
    local Result = {}

    for _, Value in pairs(Input) do
        local Key, ResultValue = Operator(Value)
        Result[Key] = ResultValue
    end

    return Result
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
        local Filtered = Static.Filter(Items, function(Object)
            return Object.Y >= 14
        end)
]]

function Static.Filter(Input, Assessment)
    local Result = {}
    local Index = 1

    for _, Value in pairs(Input) do
        if (Assessment(Value)) then
            Result[Index] = Value
            Index = Index + 1
        end
    end

    return Result
end

--[[
    Reduces a collection of values down to
    a single value.

    @param Input The target table.
    @param Operator A function to which will operate on a value and return a new value.
    @param RunningValue An initial value.

    @usage
        local Numbers = {3, 4, 1, 9, 2}
        local Result = Static.Reduce(Numbers, function(Current, Item)
            return Current + Item
        end, 0)
]]

function Static.Reduce(Input, Operator, RunningValue)
    for Key, Value in pairs(Input) do
        RunningValue = Operator(RunningValue, Value, Key, Input)
    end

    return RunningValue
end

--[[
    Flattens an nth-dimensional hash map into a one-dimensional
    hash map. Recursive.

    @param Input The target table.

    @usage
        local Items = {
            Eee = {
                One = 1;
                Two = 2;
                Aaaa = {
                    Three = 3;
                };
            };
            Four = 4;
        }
        local New = Static.Flatten(Items)
]]

function Static.Flatten(Input)
    local Result = {}

    for Key, Value in pairs(Input) do
        if (type(Value) == "table") then
            for Key, Value in pairs(Static.Flatten(Value)) do
                Result[Key] = Value
            end
        else
            Result[Key] = Value
        end
    end

    return Result
end

--[[
    Flattens an nth-dimensional array (numerical indices)
    into a one-dimensional array.

    @param Input The target table.

    @usage
        local Items = {
            {1, 2, {3, 4}},
            5
        }
        local New = Static.FlattenNumeric(Items)
]]

function Static.FlattenNumeric(Input)
    local Result = {}
    local Index = 1

    for _, Value in pairs(Input) do
        if (type(Value) == "table") then
            for _, Value in pairs(Static.FlattenNumeric(Value)) do
                Result[Index] = Value
                Index = Index + 1
            end
        else
            Result[Index] = Value
            Index = Index + 1
        end
    end

    return Result
end

--[[
    Checks if all items in a table satisfy a condition.

    @param Input The target table.
    @param Assessment A function to assess each item.

    @usage
        local Items = {
            1, 5, 3, 2, 9
        }
        local Satisfied = Static.SatisfiesAll(Items, function(Item)
            return Item >= 1
        end)
]]

function Static.SatisfiesAll(Table, Assessment)
    for _, Value in pairs(Table) do
        if (not Assessment(Value)) then
            return false
        end
    end

    return true
end

--[[
    Checks if at least one item in a table satisfies a condition.

    @param Input The target table.
    @param Assessment A function to assess each item.

    @usage
        local Items = {
            1, 4, 7, 5, 8
        }
        local Satisfied = Static.SatisfiesOnce(Items, function(Item)
            return Item > 5
        end)
]]

function Static.SatisfiesOnce(Table, Assessment)
    for _, Value in pairs(Table) do
        if (Assessment(Value)) then
            return true
        end
    end

    return false
end

--[[
    Joins two one-dimensional hash maps.

    @param Initial The first table to fuse.
    @param Other The second table to fuse.

    @usage
        local Fused = Static.Fuse1D({
            A = 1, B = 2
        }, {
            C = 3, D = 4
        })
]]

function Static.Fuse1D(Initial, Other)
    local Result = {}

    for Key, Value in pairs(Initial) do
        Result[Key] = Value
    end

    for Key, Value in pairs(Other) do
        Result[Key] = Value
    end

    return Result
end

--[[
    Joins two one-dimensional arrays.

    @param Initial The first table.
    @param Other The second table.

    @usage
        local Items1 = {}
        local Items2 = {}
]]

function Static.FuseNumeric1D(Initial, Other)
    local Result = {}
    local Offset = #Initial

    for Index = 1, Offset do
        Result[Index] = Initial[Index]
    end

    for Index = 1, #Other do
        Result[Offset + Index] = Other[Index]
    end

    return Result
end

--[[
    Merges two nth-dimensional tables.

    @param Initial The first table to merge.
    @param Other The second table to merge.

    @usage
        local New = Static.FuseNested({
            X = {
                A = 10;
            };
        }, {
            X = {
                B = 20;
            };
            C = 30;
        })
]]

function Static.FuseNested(Initial, Other)
    local Result = {}

    for Key, Value in pairs(Other) do
        local InitialValue = Initial[Key]

        if (type(Value) == "table" and type(InitialValue) == "table") then
            Result[Key] = Static.FuseNested(Value, InitialValue)
        else
            Result[Key] = Value
        end
    end

    for Key, Value in pairs(Initial) do
        local OtherValue = Other[Key]

        if (type(Value) == "table" and type(OtherValue) == "table") then
            Result[Key] = Static.FuseNested(Value, OtherValue)
        else
            Result[Key] = Value
        end
    end

    return Result
end

--[[
    Iterates over a one-dimensional table.

    @param Table The target table.
    @param Operate The function to operate on the item.

    @usage
        Static.Iterate1D({1, 2, 3}, function(Key, Value)
            print(Key, Value)
        end)
]]

function Static.Iterate1D(Table, Operate)
    for Key, Value in pairs(Table) do
        Operate(Key, Value)
    end
end

--[[
    Iterates over an nth-dimensional table.

    @param Table The target table.
    @param Operate The function to operate on the item.

    @usage
        Static.IterateNested({1, 2, {3, 4}, 5}, function(Key, Value)
            print(Key, Value)
        end)
]]

function Static.IterateNested(Table, Operate)
    for Key, Value in pairs(Table) do
        if (type(Value) == "table") then
            Operate(Key, Value)
            Static.IterateNested(Value, Operate)
        else
            Operate(Key, Value)
        end
    end
end

--[[
    Copies the first level of a table.

    @param Table The table to clone.

    @usage
        local Items = {A = 2, B = 4, C = 6}
        local New = Static.Copy1D(Items)
]]

function Static.Copy1D(Table)
    local Result = {}

    for Key, Value in pairs(Table) do
        Result[Key] = Value
    end

    return Result
end

--[[
    Copies all levels of a table.

    @param Table The table to clone.

    @usage
        local Items = {A = {B = 2}}
        local New = Static.CopyNested(Items)
]]

function Static.CopyNested(Table)
    local Result = {}

    for Key, Value in pairs(Table) do
        if (type(Value) == "table") then
            Result[Key] = Static.CopyNested(Value)
        else
            Result[Key] = Value
        end
    end

    return Result
end

--[[
    Sorts a flat copy of a table.

    @param Table The target table.
    @param Assessment A function passed to table.sort.

    @usage
        local Items = {
            {Value = 20};
            {Value = 30};
            {Value = 10};
        }
        local Sorted = Static.Sort1D(Items, function(Subject, Other)
            return Subject.Value > Other.Value
        end)
]]

function Static.Sort1D(Table, Assessment)
    local Result = Static.Copy1D(Table)
    table.sort(Result, Assessment)
    return Result
end

--[[
    Obtains the (numeric or otherwise) keys of a table.

    @param Table The target table.

    @usage
        local Target = {
            A = true;
            B = true;
            C = true;
        }
        local Keys = Static.Keys1D(Target)
]]

function Static.Keys1D(Table)
    local Keys = {}
    local Index = 1

    for Key in pairs(Table) do
        Keys[Index] = Key
        Index = Index + 1
    end

    return Keys
end

--[[
    Obtains the values of a table.

    @param Table The target table.

    @usage
        local Target = {"A", "B", C = "C"}
        local Values = Static.Values1D(Target)
]]

function Static.Values1D(Table)
    local Values = {}
    local Index = 1

    for _, Value in pairs(Table) do
        Values[Index] = Value
        Index = Index + 1
    end

    return Values
end

return Static