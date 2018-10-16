shared()

local Event = Class:FromName(script.Name)

function Event:Event()
    return {
        State = {};
        Handlers = {};
        Listeners = {};
    };
end

function Event:Listen(Func)
    local Listeners = self.Listeners
    Listeners[Func] = true
    return setmetatable({
        Disconnect = function()
            Listeners[Func] = nil
        end;
    }, {__index = self})
end

function Event:Connect(Func)
    local Handlers = self.Handlers
    local Index = #Handlers + 1
    Handlers[Index] = Func
    return setmetatable({
        Disconnect = function()
            Handlers[Index] = nil
        end;
    }, {__index = self})
end

function Event:Flush()
    self.Handlers = {}
end

function Event:Update()
    if (self:ShouldFire()) then
        self:Fire()
    end
end

function Event:Fire(...)
    for _, Handler in pairs(self.Handlers) do
        Handler(...)
    end
end

function Event:ShouldFire()
    for Listener in pairs(self.Listeners) do
        if (Listener(self.State)) then
            return true
        end
    end
    return false
end

function Event:Wait(WaitFunc, ...)

    local Fired = false
    local Wait = WaitFunc or SteppedWait
    local Signal = self:Connect(function()
        Fired = true
    end)

    while (not Fired) do
        Wait(...)
    end

    Signal:Disconnect()
    return self
end

return Event