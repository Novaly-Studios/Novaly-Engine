shared()

local SvcLoad           = {
    "Players";
    "Lighting";
    "Workspace";
    "StarterGui";
    "RunService";
    "AssetService";
    "PhysicsService";
    "TeleportService";
    "DataStoreService";
    "UserInputService";
    "ReplicatedStorage";
    "CollectionService";
    "LocalizationService";
    "ContextActionService";
}

local NameSubstitutes   = {
    -- Built-in functions
    ["assert"]          = "Assert";
    ["collectgarbage"]  = "CollectGarbage";
    ["error"]           = "Error";
    ["getfenv"]         = "GetFunctionEnv";
    ["getmetatable"]    = "GetMetatable";
    ["ipairs"]          = "IPairs";
    ["loadstring"]      = "LoadString";
    ["next"]            = "Next";
    ["pairs"]           = "Pairs";
    ["pcall"]           = "ProtectedCall";
    ["print"]           = "Print";
    ["rawequal"]        = "RawEqual";
    ["rawget"]          = "RawGet";
    ["rawset"]          = "RawSet";
    ["require"]         = "Require";
    ["select"]          = "Select";
    ["setfenv"]         = "SetFunctionEnv";
    ["setmetatable"]    = "SetMetatable";
    ["tick"]            = "Tick";
    ["tonumber"]        = "ToNumber";
    ["tostring"]        = "ToString";
    ["type"]            = "Type";
    ["unpack"]          = "Unpack";
    ["warn"]            = "Warn";
    ["wait"]            = "Wait";
    -- Services and objects
    ["Workspace"]       = "workspace";
    ["game"]            = "Game";
}

local Core              = {}
Core.OldPairs           = pairs
Core.OldIPairs          = ipairs

function Core.Sub(F, ...)
    return coroutine.resume(coroutine.create(F), ...)
end

function Core.RenderWait()
    RunService.RenderStepped:Wait()
end

function Core.HeartbeatWait()
    RunService.Heartbeat:Wait()
end

function Core.SteppedWait()
    RunService.Stepped:Wait()
end

function Core.pairs(Object)
    if (type(Object) == "table") then
        return Core.OldPairs(Object.Vars == nil and Object or Object.Vars)
    else
        return Core.OldPairs(Object)
    end
end

function Core.ipairs(Array)
    if (type(Object) == "table") then
        return Core.OldIPairs(Object.Vars == nil and Object or Object.Vars)
    else
        return Core.OldIPairs(Object)
    end
end

function Core.Count(Array)
    local Count = 0
    for Key, Value in pairs(Array) do
        Count = Count + 1
    end
    return Count
end

-- Should probably update this
function Core.TypeChain(...)
    local Result = ""
    for _, Arg in pairs({...}) do
        local ArgType = type(Arg)
        if (not Result:find(ArgType)) then
            Result = Result .. ArgType
        end
    end
    return Result
end

--[[
    'With' Usage:
    local x, y, z = {}, {}, {}
    With(x, y, z)
    {
        Test = 80;
    }
]]

function Core.With(...)
    local Items = {...}
    return setmetatable({}, {__call = function(Self, Append)
        for _, Item in pairs(Items) do
            for Key, Value in pairs(Append) do
                Item[Key] = Value
            end
        end
    end})
end

--[[
    'Map' Usage:
    local New = Map({1, 2, 3}, function(x)
        return x * 2
    end)
]]

function Core.Map(Items, Operator)
    local Result = {}
    for _, Item in pairs(Items) do
        table.insert(Result, Operator(Item))
    end
    return Result
end

--[[
    'Filter' Usage:
    local New = Filter({1, 2, 3, 4, 5}, function(x)
        return x < 4
    end)
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
    'Range' Usage:
    local Test = Range(-3, 3)
]]

function Core.Range(Start, End)
    local Result = {}
    for Index = Start, End do
        Result[Index] = Index
    end
    return Result
end

--[[
    'Reduce' Usage:
    local Sample = {1, 2, 3}
    local Average = Reduce(Sample, function(Total, New, Index, Count, Final)
        return (Final and (Total + New) / Count or Total + New)
    end)
    local Sum = Reduce(Sample, function(Total, New)
        return Total + New
    end)
    print(Sum, Average)
]]

function Core.Reduce(Item, Operator)
    local Result = Item[1]
    local Count = #Item
    for Index = 2, Count do
        Result = Operator(Result, Item[Index], Index, Count, Index == Count)
    end
    return Result
end

--[[
    'GetNaryLoop' Usage:
    GetNaryLoop({1, 10}, {1, 10}, {1, 10})(function(Iters)
        local a, b, c = Iters[1], Iters[2], Iters[3]
        print(a, b, c)
    end)

    Equivalent to...
    for a = 1, 10 do
        for b = 1, 10 do
            for c = 1, 10 do
                print(a, b, c)
            end
        end
    end
]]

function Core.GetNaryLoop(Bounds)

    local Recursive
    local Loops = #Bounds
    local IterValues = {}

    function Recursive(Run, Level)

        local Level = Level or 1
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
    'Product' Usage:
    local Subjects = {
        {1, 2, 3};
        {"x", "y"};
        {3000};
    }
    local Combos = Product(Subjects)
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
    'Switch' Usage:
    Switch("Abc") {
        Xyz = function() print'Xyz' end;
        Abc = function() print'Abc' end;
        Def = function() print'Def' end;
    }
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

for Index = 1, #SvcLoad do
    local Value = SvcLoad[Index]
    Core[Value] = game:GetService(Value)
end

for Key, Value in pairs(NameSubstitutes) do
    Core[Value] = Core[Key] or getfenv()[Key]
end

Core.Svc = setmetatable({}, {
    __index = function(Self, Key)
        return game:GetService(Key)
    end;
    __call = function(Self, Key)
        return Self[Key]
    end;
})

shared({
    Client = Core;
    Server = Core;
})

return true