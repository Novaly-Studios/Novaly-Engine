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

function Core.RunServiceWait()
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

Func({
    Client = Core;
    Server = Core;
})

return true