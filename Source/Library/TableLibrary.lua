local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Table = setmetatable({}, {__index = OriginalEnv["table"]})

local Mappings = {
    setn    = "SetN";
    insert  = "Insert";
    getn    = "GetN";
    foeachi = "ForeachI";
    concat  = "Concat";
    sort    = "Sort";
    remove  = "Remove";
}

function Table.Find(Array, Item)
    for x = 1, #Array do
        if Array[x] == Item then
            return x
        end
    end
    return false
end

function Table.Reverse(Array)
    local Num = #Array
    for Index = 1, Num / 2 do
        local Opposite = Num - Index
        Array[Index], Array[Opposite] = Array[Opposite], Array[Index]
    end
end

function Table.ShallowClone(Array)
    local Result = {}
    for Key, Value in pairs(Array) do
        Result[Key] = Value
    end
    return Result
end

function Table.PrintTable(Item, Tabs)

    local Tabs = Tabs or (function()
        print("BaseTable = {")
        return "\t"
    end)()

    for Key, Value in pairs(Item) do

        local ValueType = type(Value)
        local KeyType = type(Key)

        if (KeyType == "number") then
            Key = ""
        else
            Key = Key .. " = "
        end

        if (ValueType == "table") then
            print(Tabs .. Key .. "{")
            Table.PrintTable(Value, Tabs .. "\t")
            print(Tabs .. "};")
        else
            local Encapsulation = (ValueType == "string" and string.format("\"%s\"", Value) or tostring(Value))
            print(Tabs .. Key .. Encapsulation .. ";")
        end
    end

    if (Tabs == "\t") then
        print("};")
    end
end

function Table.Clone(Array)
    local Result = {}
    for Key, Value in pairs(Array) do
        if type(Value) == "table" then
            Value = Table.Clone(Value)
        end
        Result[Key] = Value
    end
    return Result
end

function Table.GetValueSequence(Arr, Keys)
    for Key = 1, #Keys do
        Arr = Arr[Key]
    end
    return Arr
end

function Table.SetValueSequence(Arr, Keys, Val)
    local Len = #Keys
    for Key = 1, Len - 1 do
        Arr = Arr[Key]
    end
    Arr[Keys[Len]] = Val
end

function Table.CopyAndAppend(Arr, Val)
    local Result = Table.Clone(Arr)
    Result[#Result + 1] = Val
    return Result
end

function Table.MergeKey(Arr1, Arr2)
    for Key, Value in pairs(Arr2) do
        Arr1[Key] = Value
    end
end

function Table.CopyAndMergeKey(Arr1, Arr2)
    local Result = {}
    for Key, Value in pairs(Arr1) do
        Result[Key] = Value
    end
    for Key, Value in pairs(Arr2) do
        Result[Key] = Value
    end
    return Result
end

function Table.MergeNumerical(Arr1, Arr2)
    local Count = #Arr1
    for Iter = 1, #Arr2 do
        Arr1[Count + Iter] = Arr2[Iter]
    end
end

function Table.CopyAndMergeNumerical(Arr1, Arr2)
    local Result = {}
    local Count = #Arr1
    for Iter = 1, Count do
        Result[Iter] = Arr1[Iter]
    end
    for Iter = 1, #Arr2 do
        Result[Count + Iter] = Arr2[Iter]
    end
    return Result
end

function Table.ProtectedForeach(Arr, Func)
    for Key, Value in pairs(Arr) do
        local Success, Result = Sub(Func, Key, Value)
        if not Success then
            print(Result)
        end
    end
end

function Table.ProtectedForeachI(Arr, Func)
    for Index, Value in ipairs(Arr) do
        local Success, Result = Sub(Func, Index, Value)
        if not Success then
            print(Result)
        end
    end
end

function Table.ApplyTemplate(Previous, Template)
    for Key, Value in pairs(Template) do
        local Target = Previous[Key]
        if type(Target) == "table" and type(Value) == "table" then
            Table.ApplyTemplate(Target, Value)
        elseif Target == nil then
            Previous[Key] = Value
        end
    end
end

function Table.Capitalise(Array)
    for Key, Value in pairs(Array) do
        Array[Key:sub(1, 1):upper() .. Key:sub(2)] = Value
    end
end

function Table.WaitFor(YieldFunction, Array, ...)
    local Iter = 1
    for Key, Value in pairs({...}) do
        local Next = Array[Value]
        while (not Next) do
            YieldFunction()
            Iter = Iter + 1
            if (Iter == 150) then
                Warn(String.Format("Possible endless wait on '%s' for property '%s'.", (Array.Name or ToString(Array)), ToString(Value)))
                Warn(debug.traceback())
            end
            Next = Array[Value]
        end
        Array = Next
    end
    return Array
end

function Table.WaitForItem(Array, Key)
    return Table.WaitFor(wait, Array, Key)
end

function Table.ProtectedGet(Array, Key)
    local Success, Result = ProtectedCall(function()
        return Array[Key]
    end)
    return Success, Result
end

Table.ApplyKeyMapping(Table, Mappings)

Func({
    Client = {table = Table, Table = Table};
    Server = {table = Table, Table = Table};
})

return true