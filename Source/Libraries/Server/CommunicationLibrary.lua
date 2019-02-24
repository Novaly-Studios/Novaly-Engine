--[[
    Shortens the process of making server RemoteFunction or RemoteEvent
    calls by adding quick access functions.

    @module Communication Libary
    @alias CommunicationLibrary
    @todo Multiple connections using an Event object for RemoteEvents and BindableEvents
    @author TPC9000
]]

shared()

local Server = {
    TransmissionReady = {};
}
local Binds = {
    Events = {};
    Functions = {}
}

local function BindRemoteEvent(Name, Handler)
    local Events = Binds.Events
    local Found = Events[Name] or Event.New()
    Found:Connect(Handler)
    Events[Name] = Found
end

local function BindRemoteFunction(Name, Handler)
    Binds.Functions[Name] = Handler
end

Server.BindRemoteEvent      = BindRemoteEvent
Server.BindRemoteFunction   = BindRemoteFunction

function Server.WaitForTransmissionReady(Player)

    local Tries = 0

    while (Server.TransmissionReady[Player.Name] == nil) do

        wait(CONFIG.coPollInterval)
        Tries = Tries + 1

        if (Tries == CONFIG.coMaxTries) then
            error("Max transmission attempts reached for player " .. Player.Name .. "!")
            return
        end
    end
end

function Server.FireRemoteEvent(Name, Player, ...)
    Server.RemoteEvent:FireClient(Player, Name, ...)
end

function Server.InvokeRemoteFunction(Name, Player, ...)
    return Server.RemoteFunction:InvokeClient(Player, Name, ...)
end

function Server.Broadcast(...)
    Server.RemoteEvent:FireAllClients(...)
end

function Server.Init()

    local RemoteEvent       = ReplicatedStorage:FindFirstChild("RemoteEvent") or
                            Instance.new("RemoteEvent", ReplicatedStorage)
    local RemoteFunction    = ReplicatedStorage:FindFirstChild("RemoteFunction") or
                            Instance.new("RemoteFunction", ReplicatedStorage)
    Server.RemoteEvent      = RemoteEvent
    Server.RemoteFunction   = RemoteFunction

    RemoteEvent.OnServerEvent:Connect(function(Player, Name, ...)

        if not Player then return end
        local Event = Binds.Events[Name]

        if (type(Name) ~= "string") then
            Log(0, "Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
        elseif (Event == nil) then
            Log(0, "Warning, no event '" .. Name .. "' found in event collection.")
        else
            Event:Fire(Player, ...)
        end
    end)

    RemoteFunction.OnServerInvoke = function(Player, Name, ...)

        if not Player then return end
        local Function = Binds.Functions[Name]

        if (type(Name) ~= "string") then
            Log(0, "Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
            return false
        elseif (Function == nil) then
            Log(0, "Warning, no function '" .. Name .. "' found in function collection.")
        else
            return Function(Player, ...)
        end
    end

    Players.PlayerAdded:Connect(function(Player)
        while (Server.InvokeRemoteFunction("Ready", Player) == nil) do
            wait(CONFIG.coPollInterval)
        end
        Server.TransmissionReady[Player.Name] = true
    end)
end

return Server