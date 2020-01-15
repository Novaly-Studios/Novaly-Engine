--[[
    @module Table Extender

    @alias Table
]]

local Table = {}

--[[
    @function Table.IndexOf

    Returns the index of a specific item in a table.

    @usage
        print(Table.IndexOf({"x", "y", "z"}, "y"))

    @param Items The table to search.
    @param Find The value to find.

    @return The index of the found item, or false if not found.
]]

function Table.IndexOf(Items, Find)
    for Index = 1, #Items do
        if (Items[Index] == Find) then
            return Index
        end
    end
    return false
end

--[[
    @function Table.Reverse

    Returns a reversed form of a numeric index table.

    @usage
        Table.Reverse({3, 2, 1})

    @param Items The table to reverse.
    @return The reversed table.
]]

function Table.Reverse(Items)
    local Num = #Items
    for Index = 1, Num / 2 do
        local Opposite = Num - Index
        Items[Index], Items[Opposite] = Items[Opposite], Items[Index]
    end
end

--[[
    @function Table.ShallowClone

    Clones the top-level values of each table.
    Sub-objects will still be referenced, not
    cloned.

    @usage
        local Test = Table.ShallowClone({"a", "b", "c"})

    @param Items The table to shallow clone.
    @return The shallow-cloned table.
]]

function Table.ShallowClone(Items)
    local Result = {}
    for Key, Value in pairs(Items) do
        Result[Key] = Value
    end
    return Result
end

--[[
    @function Table.PrintTable

    Recursively prints a table's key-value structure.

    @usage
        Table.PrintTable({
            {1, 2, 3};
            {s = "Test"};
        })

    @param Item The table to print.
    @param Tabs Internal; the indent accumulator.
]]

function Table.PrintTable(Item)
    print(Table.ToString(Item))
end

function Table.DeepCount(Data)
    local Result = 0

    for _, Value in pairs(Data) do
        if (type(Value) == "table") then
            Result = Result + Table.DeepCount(Value)
        end
        Result = Result + 1
    end

    return Result
end

function Table.ToString(Item, Tabs)

    local Result = ""

    Tabs = Tabs or (function()
        Result = Result .. "BaseTable = {\n"
        return (" "):rep(4)
    end)()

    for Key, Value in pairs(Item) do

        local ValueType = type(Value)
        local KeyType = type(Key)

        local ReportString = (KeyType ~= "number")
        local Join = ReportString and "\"" or ""
        Key = "[" .. Join .. tostring(Key) .. Join .. "]" .. " = "

        if (ValueType == "table") then
            Result = Result .. Tabs .. Key .. "{\n"
            Result = Result .. Table.ToString(Value, Tabs .. (" "):rep(4))
            Result = Result .. Tabs .. "};\n"
        else
            local Encapsulation = (ValueType == "string" and string.format("\"%s\"", Value) or tostring(Value))
            Result = Result .. Tabs .. Key .. Encapsulation .. ";\n"
        end
    end

    if (Tabs == (" "):rep(4)) then
        Result = Result .. "};\n"
    end

    return Result
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
        Arr = Arr[Keys[Key]]
    end
    return Arr
end

function Table.SetValueSequence(Arr, Keys, Val)
    local Len = #Keys
    for Key = 1, Len - 1 do
        Arr = Arr[Keys[Key]]
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

function Table.ApplyKeyMapping(Array, Append, From)
    for Key, Value in pairs(Append) do
        Array[Value] = From[Key]
    end
end

function Table.ApplyValueMapping(Array, Append, From)
    for Key, Value in pairs(Append) do
        Array[Key] = From[Value]
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

function Table.TryIndex(Target, ...)
    assert(Target)

    local Value = Target
    local Args = {...}

    for _, Key in pairs(Args) do
        Value = Value[Key]

        if (Value == nil) then
            return nil, Key
        end
    end

    return Value, Args[#Args]
end

function Table.WaitFor(YieldFunction, Target, ...)

    if (YieldFunction == wait) then
        YieldFunction = function()
            wait(0.05)
        end
    end

    local Value, LastKey = Table.TryIndex(Target, ...)
    local MissCount = 0

    while (not Value) do
        MissCount = MissCount + 1

        if (MissCount == 60) then
            warn(string.format("Possible endless wait on '%s' for property '%s'.", tostring(Target), tostring(LastKey)))
            warn(debug.traceback())
        end

        YieldFunction()
        Value, LastKey = Table.TryIndex(Target, ...)
    end

    return Value
end

function Table.WaitForNoReIndex(YieldFunction, Array, ...)
    for _, Value in pairs({...}) do
        local Next = Array[Value]
        local Warned = false
        local Iter = 1

        while (not Next) do
            YieldFunction()
            Iter = Iter + 1

            if (Iter == 150) then
                Warned = true
                warn(string.format("Possible endless wait on '%s' for property '%s'.", (Array.Name or tostring(Array)), tostring(Value)))
                warn(debug.traceback())
            end

            Next = Array[Value]
        end

        if Warned then
            warn(string.format("Warned wait for '%s' property '%s' completed.", (Array.Name or tostring(Array)), tostring(Value)))
        end

        Array = Next
    end

    return Array
end

function Table.WaitForItem(Array, Key)
    return Table.WaitFor(wait, Array, Key)
end

function Table.ProtectedGet(Array, Key)
    local Success, Result = pcall(function()
        return Array[Key]
    end)
    return Success, Result
end

function Table.GetPath(Object, FetchItemsMethod, PathString)

    for Node in string.gmatch(PathString, "[^%.]+") do

        if (Node == "*") then
            local Items = {}
            local Method = Object[FetchItemsMethod]
            for _, Value in pairs(Method and Method(Object) or Object) do
                table.insert(Items, Value)
            end
            return Items
        end

        Object = Object[Node]
        assert(Object, string.format("Path item '%s' not found!", Node))

    end

    return Object
end

function Table.Equals(Initial, Other)
    if (Initial == nil or Other == nil) then
        return false
    end

    for Key, Value in pairs(Initial) do
        local OtherValue = Other[Key]

        if (OtherValue == nil) then
            return false
        end

        if (type(Value) ~= type(OtherValue)) then
            return false
        end

        if (type(Value) == "table") then
            if (not Table.Equals(Value, OtherValue)) then
                return false
            end
        elseif (Value ~= OtherValue) then
            return false
        end
    end

    return true
end

local function Mixed(Table, Path) -- Determines if a table has both numerical and (hash or ref) keys
    local Types = {}
    local Count = 0
    Path = Path or {}

    for Key, Value in pairs(Table) do
        local KeyType = type(Key)

        if (not Types[KeyType]) then
            Count = Count + 1
            Types[KeyType] = true
        end

        if (Types["number"] and Count > 1) then
            for Key in pairs(Table) do
                if (type(Key) == "number") then
                    Path[#Path + 1] = Key
                    break
                end
            end

            return true, Path
        end

        if (type(Value) == "table") then
            Path[#Path + 1] = Key

            if (Mixed(Value, Path)) then
                return true, Path
            end
        end
    end

    return false, Path
end

Table.Mixed = Mixed -- Don't change, for some reason recursive call mucks up otherwise

return Table