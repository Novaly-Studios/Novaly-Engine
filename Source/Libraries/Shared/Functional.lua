local Functional = {}

Functional.ImmutableMT = {
    __newindex = function()
        error("Attempt to mutate static table.")
    end;
}

function Functional.Map(Input, Operator)
    local Result = {}

    for Key, Value in pairs(Input) do
        Result[Key] = Operator(Value)
    end

    return Functional.Immutable(Result)
end

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

function Functional.Immutable(Table)
    return setmetatable(Table, Functional.ImmutableMT)
end

return Functional