local ImperativeConnection = {}
ImperativeConnection.__index = ImperativeConnection

function ImperativeConnection.New(ImperativeParent, Callback)
    return setmetatable({
        Callback = Callback;
        ImperativeParent = ImperativeParent;
        Disconnected = false;
    }, ImperativeConnection)
end

function ImperativeConnection:Disconnect()
    if (self.Disconnected) then
        return
    end

    self.Disconnected = true

    local ImperativeParent = self.ImperativeParent
    local Connections = ImperativeParent.Connections
    Connections[self.Callback] = nil

    local ConnectionCount = ImperativeParent.ConnectionCount
    ConnectionCount -= 1
    ImperativeParent.ConnectionCount = ConnectionCount

    if (ConnectionCount == 0) then
        ImperativeParent.SignalConnection:Disconnect()
        ImperativeParent.SignalConnection = nil
    end
end

return ImperativeConnection