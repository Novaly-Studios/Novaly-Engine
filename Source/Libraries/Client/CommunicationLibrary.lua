--[[
    Shortens the process of making server RemoteFunction or RemoteEvent
    calls by adding quick access functions.

    @module Communication Libary
    @alias CommunicationLibrary
    @todo Multiple connections using an Event object for RemoteEvents and BindableEvents
    @author TPC9000
]]

shared()

local Client = {}
local Binds = {
    Events = {};
    Functions = {}
}

local function BindRemoteEvent(Name, Handler)
    local Events = Binds.Events
    local Found = Events[Name] or Event.New()
    Found:Connect(Handler)
    Events[Name] = Found
    return Found
end

local function BindRemoteFunction(Name, Handler)
    Binds.Functions[Name] = Handler
end

Client.BindRemoteEvent      = BindRemoteEvent
Client.BindRemoteFunction   = BindRemoteFunction

function Client.FireRemoteEvent(...)
    Client.RemoteEvent:FireServer(...)
end

function Client.InvokeRemoteFunction(...)
    return Client.RemoteFunction:InvokeServer(...)
end

function Client.Init()

    local RemoteEvent       = ReplicatedStorage:WaitForChild("RemoteEvent")
    local RemoteFunction    = ReplicatedStorage:WaitForChild("RemoteFunction")
    Client.RemoteEvent      = RemoteEvent
    Client.RemoteFunction   = RemoteFunction

    RemoteEvent.OnClientEvent:Connect(function(Name, ...)

        local Event = Binds.Events[Name]

        if (type(Name) ~= "string") then
            Log(0, "Warning, server has sent an empty or non-string request name.")
        elseif (Event == nil) then
            Log(0, "Warning, no event '" .. Name .. "' found in event collection.")
        else
            Event:Fire(...)
        end
    end)

    RemoteFunction.OnClientInvoke = function(Name, ...)

        local Function = Binds.Functions[Name]

        if (type(Name) ~= "string") then
            Log(0, "Warning, servers has sent an empty or non-string request name.")
            return false
        elseif (Function == nil) then
            Log(0, "Warning, no function '" .. Name .. "' found in function collection.")
        else
            return Function(...)
        end
    end

    Client.BindRemoteFunction("Ready", function()
        return true
    end)
end

return Client