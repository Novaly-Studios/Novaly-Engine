local ImperativeConnection = require(script.Parent.ImperativeConnection)

local function AsAsync(Callback, ...)
    --coroutine.wrap(Callback)(...)

    local Args = {...}

    local BindableEvent = Instance.new("BindableEvent")

    BindableEvent.Event:Connect(function()
        Callback(unpack(Args))
    end)

    BindableEvent:Fire()
end

local Imperative = {}
Imperative.__index = Imperative

function Imperative.New(Signal, Initial)
    assert(Signal, "No signal given.")
    assert(Initial, "No initial function given.")

    local self = setmetatable({
        Signal = Signal;
        Initial = Initial;
        Connections = {};
        ConnectionCount = 0;
    }, Imperative)

    return self
end

--[[ function Imperative:Flush()
    self.Connections = {}
    self.SignalConnection:Disconnect()
end ]]

function Imperative:Fire(...)
    local Args = {...}

    for Callback, Connection in pairs(self.Connections) do
        AsAsync(Callback, Connection, unpack(Args))
    end
end

function Imperative:Connect(Callback)
    assert(Callback, "No callback given!")

    if (not self.SignalConnection) then
        self.SignalConnection = self.Signal:Connect(function(...)
            self:Fire(...)
        end)
    end

    local ConnectionObject = ImperativeConnection.New(self, Callback)

    self.ConnectionCount += 1
    self.Connections[Callback] = ConnectionObject --true

    AsAsync(function()
        for _, Item in pairs({self.Initial()}) do
            if (ConnectionObject.Disconnected) then
                break
            end

            AsAsync(Callback, ConnectionObject, Item)
        end
    end)

    return ConnectionObject
end

return Imperative