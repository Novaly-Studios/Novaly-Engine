local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local SvcLoad           = {
    "Players";
    "Lighting";
    "Workspace";
    "StarterGui";
    "RunService";
    "AssetService";
    "TeleportService";
    "DataStoreService";
    "UserInputService";
    "ReplicatedStorage";
    "CollectionService";
    "LocalizationService";
}

local NameSubstitutes   = {
    ["assert"]          = "Assert";
    ["collectgarbage"]  = "CollectGarbage";
    ["error"]           = "Error";
    ["getfenv"]         = "GetFunctionEnvironment";
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
    ["setfenv"]         = "SetFunctionEnvironment";
    ["setmetatable"]    = "SetMetatable";
    ["tonumber"]        = "ToNumber";
    ["tostring"]        = "ToString";
    ["type"]            = "Type";
    ["unpack"]          = "Unpack";
    ["wait"]            = "Wait";
}

local Core              = {}
Core.OldPairs           = pairs
Core.OldIPairs          = ipairs

function Core.Sub(F, ...)
    return coroutine.resume(coroutine.create(F), ...)
end

function Core.rswait()
    RunService.RenderStepped:wait()
end

function Core.nassert(Condition, Error)
    return assert(not Condition, Error)
end

function Core.wassert(Condition, Warning)
    if not Condition then
        warn(Warning)
    end
end

function Core.passert(Condition, Warning)
    if not Condition then
        print(Warning)
    end
end

function Core.Attribute(Object, Attributes)
    for Key, Value in next, Attributes do
        Object[Key] = Value
    end
end

function Core.pairs(Array)
    return Core.OldPairs(Array.Vars == nil and Array or Array.Vars)
end

function Core.ipairs(Array)
    return Core.OldIPairs(Array.Vars == nil and Array or Array.Vars)
end

function Core.Count(Array)
    local Count = 0
    for Key, Value in next, Array do
        Count = Count + 1
    end
    return Count
end

for Index = 1, #SvcLoad do
    local Value = SvcLoad[Index]
    Core[Value] = game:GetService(Value)
end

for Key, Value in pairs(NameSubstitutes) do
    Core[Value] = Core[Key] or getfenv()[Key]
end

Core.Pairs = Core.pairs
Core.IPairs = Core.ipairs

Func({
    Client = Core;
    Server = Core;
})

return true