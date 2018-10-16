--[[
    Novarine Core Function Library --
    This library provides various core functions.

    @module Core Library
    @alias CoreLibrary
    @author TPC9000
]]

shared()

local SvcLoad           = {
    "Players";
    "Lighting";
    "Workspace";
    "StarterGui";
    "RunService";
    "AssetService";
    "PhysicsService";
    "ReplicatedFirst";
    "TeleportService";
    "DataStoreService";
    "UserInputService";
    "ReplicatedStorage";
    "CollectionService";
    "LocalizationService";
    "ContextActionService";
}

local Core              = {}
Core.OldPairs           = pairs
Core.OldIPairs          = ipairs

--[[
    @deprecated
    @todo Verify that no internal engine functionality still relies on this
]]

function Core.pairs(Object)
    if (type(Object) == "table") then
        return Core.OldPairs(Object.Vars == nil and Object or Object.Vars)
    else
        return Core.OldPairs(Object)
    end
end

--[[
    @deprecated
    @todo Verify that no internal engine functionality still relies on this
]]

function Core.ipairs(Array)
    if (type(Array) == "table") then
        return Core.OldIPairs(Array.Vars == nil and Array or Array.Vars)
    else
        return Core.OldIPairs(Array)
    end
end

--[[
    Count returns the number of elements in a key-value associative
    table or a table with non-adjacent numerical indexes.

    @usage
        print(Count({a = 1, b = 2, 3}))

    @param Items The table of items to count.
    @return The count of table elements.
]]

function Core.Count(Items)
    local Count = 0
    for _ in pairs(Items) do
        Count = Count + 1
    end
    return Count
end

--[[
    TypeChain will create a table of keys denoting the primitive Lua
    types of the input variables. The return format is...
    {["type1"] = true, ["type2"] = true, ...}

    @usage
        local Types = TypeChain(1, "test", Workspace)
        if (Types["userdata"]) then
            print("We know a userdata was passed.")
        end

    @param ... The input objects to test.
    @return A table of values denoting the primitive Lua types of the input variables.
]]

function Core.TypeChain(...)
    local Result = {}
    for _, Item in pairs({...}) do
        Result[type(Item)] = true
    end
    return Result
end

--[[
    With will take a variable amount of objects and return
    a function allowing mutation of properties of those objects.
    Used in combination with curly brackets, this yields a clean
    way of attributing new properties to an object.

    @usage
        local x, y, z = {}, {}, {}
        With(x, y, z)
        {
            Test = 80;
        }

    @param ... Properties to overwrite as strings.
    @return A callable function, accepting a table of desired key-value modifications.
]]

function Core.With(...)
    local Items = {...}
    return function(Append)
        for _, Item in pairs(Items) do
            for Key, Value in pairs(Append) do
                Item[Key] = Value
            end
        end
    end
end

--[[
    Map accepts a table of inputs, operates on those
    inputs using a function and returns a new table of
    processed inputs.

    @usage
        local New = Map({1, 2, 3}, function(x)
            return x * 2
        end)

    @param Items The table containing inputs.
    @param Operator The function which will operate on the inputs.
    @return A table containing the processed inputs.
]]

function Core.Map(Items, Operator)
    local Result = {}
    for _, Item in pairs(Items) do
        table.insert(Result, Operator(Item))
    end
    return Result
end

--[[
    Filter accepts a table of inputs to filter.
    It iterates through these inputs with a
    condition function; items which meet the
    condition are inserted into a new table and
    returned.

    @usage:
        Filter({1, 2, 3, 4, 5}, function(Num)
            return Num < 4
        end)

    @param Items The input items to test.
    @param Assess The condition function which assesses each input.
    @return A table with all filtered objects which met the condition.
]]

function Core.Filter(Items, Assess)
    local Result = {}
    for Key, Item in pairs(Items) do
        if (Assess(Item, Key)) then
            table.insert(Result, Item)
        end
    end
    return Result
end

--[[
    Range enumerates a range of two values x .. y into
    a new table.

    @usage:
        local Test = Range(-3, 3)

    @param Start The lower number of the range.
    @param End The larger number of the range.
    @return A table of the range {Start, ..., End}.
]]

function Core.Range(Start, End)
    local Result = {}
    for Index = Start, End do
        Result[Index] = Index
    end
    return Result
end

--[[
    Reduce will take a table of inputs and operate
    on those inputs such that only one output remains.

    @usage
        local Sample = {1, 2, 3}
        Reduce(Sample, function(Total, New, Index, Count, Final)
            return  (Final and
                    ((Total + New) / Count) or
                    (Total + New))
        end) -- Average
        Reduce(Sample, function(Total, New)
            return Total + New
        end) -- Sum

    @param Items The list of items which will be reduced.
    @param Operator The function which operates on each input.
    @return A single reduced value.
]]

function Core.Reduce(Items, Operator)
    local Result = Items[1]
    local Count = #Items
    for Index = 2, Count do
        -- Operator Call Params: Accumulator, NextItem, CurrentIndex, ItemCount, IsFinal
        Result = Operator(Result, Items[Index], Index, Count, Index == Count)
    end
    return Result
end

--[[
    Through recursion, constructs a nested n-ary loop over
    an arbitrary number of defined ranges, packed in a
    function. Necessary for other functions like Product.

    @usage
        local Loop = GetNaryLoop({{1, 10}, {1, 10}, {1, 10}})
        Loop(function(Iters)
            local a, b, c = Iters[1], Iters[2], Iters[3]
            print(a, b, c)
        end)

    @param Bounds A table containing pairs of ranged values {r0, r1}
    @return A function which calls a provided function with an array containing the current loop values.

    @todo Detect and implement negative increments.
]]

function Core.GetNaryLoop(Bounds)

    local Recursive
    local Loops = #Bounds
    local IterValues = {}

    function Recursive(Run, Level)
        Level = Level or 1
        local TargetBounds = Bounds[Level]

        if (Level > Loops) then
            Run(IterValues)
        else
            for Iter = TargetBounds[1], TargetBounds[2] do
                IterValues[Level] = Iter
                Recursive(Run, Level + 1)
            end
        end
    end

    return Recursive
end

--[[
    Product returns a Cartesian product, or all possible
    permutations, of a collection of table values.

    @usage
        local Subjects = {
            {1, 2, 3};
            {"x", "y"};
            {3000};
        }
        local Combos = Product(Subjects)

    @param Sample The sample table consisting of several sub-tables.
    @return The permutations of the values of the sub-tables.
]]

function Core.Product(Sample)

    local Ranges = {}
    local Pairings = {}

    for Index, Value in pairs(Sample) do
        Ranges[Index] = {1, #Value}
    end

    Core.GetNaryLoop(Ranges)(function(Chain)
        local Pairing = {}
        for Index = 1, #Chain do
            table.insert(Pairing, Sample[Index][Chain[Index]])
        end
        table.insert(Pairings, Pairing)
    end)

    return Pairings
end

--[[
    Switch is a basic implementation of switch statements in Lua.
    These can be used in place of less efficient 'elseif' chains in
    some scenarios.

    @usage
        Switch("Abc") {
            Xyz = function() print'Xyz' end;
            Abc = function() print'Abc' end;
            Def = function() print'Def' end;
        }

    @param Value The value to test against.
    @return A function which accepts a table with key-value pairings from cases to functions.

    @todo Verify performance of Switch vs elseif on small and large data sets
]]

function Core.Switch(Value)
    return function(Cases)
        local Target = Cases[Value] or Cases["Default"]
        local Final = Cases["Finally"]
        if Target then
            Target()
        end
        if Final then
            Final()
        end
    end
end

--[[
    Keys returns a new table with stripped values from an old table.

    @usage
        Keys({
            X = 20;
            Y = 30;
            Z = 40;
        })

    @param Item The table which will be stripped of its values.
    @return The processed table.
]]

function Core.Keys(Item)
    local Result = {}
    for Key in pairs(Item) do
        table.insert(Result, Key)
    end
    return Result
end

--[[
    Values returns a new table with stripped keys from an old table.

    @usage
        Values({
            X = 20;
            Y = 30;
            Z = 40;
        })

    @param Item The table which will be stripped of its keys.
    @return The processed table.
]]

function Core.Values(Item)
    local Result = {}
    for _, Value in pairs(Item) do
        table.insert(Result, Value)
    end
    return Result
end

--[[
    Sub quickly spawns a coroutine from a function and some given
    arbitrary arguments.

    @usage
        Sub(function()
            Workspace:WaitForChild("Test")
        end)

    @param Func The function to use as a coroutine.
    @param ... The arguments to pass the coroutine.
]]

function Core.Sub(Func, ...)
    return coroutine.wrap(Func)(...)
end

--[[
    Fairly self-explanatory functions
    @todo: Move or deprecate
]]

function Core.RenderWait()
    RunService.RenderStepped:Wait()
end

function Core.HeartbeatWait()
    RunService.Heartbeat:Wait()
end

function Core.SteppedWait()
    RunService.Stepped:Wait()
end

for Index = 1, #SvcLoad do
    local Value = SvcLoad[Index]
    Core[Value] = game:GetService(Value)
end

Core.Svc = setmetatable({}, {
    __index = function(self, Key)
        return game:GetService(Key)
    end;
    __call = function(self, Key)
        return self[Key]
    end;
})

Core.workspace = game:GetService("Workspace") -- Failsafe if workspace ever gets deprecated

return {
    Client = Core;
    Server = Core;
}