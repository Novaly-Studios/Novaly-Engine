local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

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

Core.Players                    = Svc.Players
Core.Lighting                   = Svc.Lighting
Core.RunService                 = Svc.RunService
Core.AssetService               = Svc.AssetService
Core.TeleportService            = Svc.TeleportService
Core.DataStoreService           = Svc.DataStoreService
Core.UserInputService           = Svc.UserInputService
Core.ReplicatedStorage          = Svc.ReplicatedStorage

Func({
    Client = Core;
    Server = Core;
})

return true