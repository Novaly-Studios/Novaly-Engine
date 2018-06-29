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
    ["pairs"]            = "Pairs";
    ["ipairs"]           = "IPairs";
    ["wait"]             = "Wait";
    ["assert"]           = "Assert";
    ["pcall"]            = "ProtectedCall";
    ["getfenv"]          = "GetFunctionEnvironment";
    ["getmetatable"]     = "GetMetatable";
    ["setmetatable"]     = "SetMetatable";
    ["next"]             = "Next";
    ["print"]            = "Print";
    ["type"]             = "Type";
    ["tonumber"]         = "ToNumber";
    ["tostring"]         = "ToString";
    ["unpack"]           = "Unpack";
    ["error"]            = "Error";
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

for Key, Value in next, NameSubstitutes do
    Core[Value] = Core[Key] or getfenv()[Key]
end

Core.Pairs = Core.pairs
Core.IPairs = Core.ipairs

Func({
    Client = Core;
    Server = Core;
})

return true