--[[
    Shortens the process of making server RemoteFunction or RemoteEvent
    calls by adding quick access functions.

    @module Communication Libary
    @alias CommunicationLibrary
    @todo Multiple connections using an Event object for RemoteEvents and BindableEvents
    @author TPC9000
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
local Event = Novarine:Get("Event")
local Configuration = Novarine:Get("Configuration")
local Players = Novarine:Get("Players")
local Async = Novarine:Get("Async")

local Server = {
    TransmissionReady = {};
    EventsReady = {};
};
local Binds = {
    Events = {};
    Functions = {}
};

local function BindRemoteEvent(Name, Handler)
    local Events = Binds.Events
    local Found = Events[Name] or Event.New()
    local Connection = Found:Connect(Handler)
    Events[Name] = Found
    return Connection
end

local function BindRemoteFunction(Name, Handler)
    Binds.Functions[Name] = Handler
end

Server.BindRemoteEvent      = BindRemoteEvent
Server.BindRemoteFunction   = BindRemoteFunction

function Server.WaitForTransmissionReady(Player, Callback)

    Async.Wrap(function()
        while (Player.Parent and Server.TransmissionReady[Player.Name] == nil) do
            wait(Configuration.coPollInterval)
        end

        if Player then
            Callback()
        end
    end)()
end

function Server.FireRemoteEvent(Name, Player, ...)
    Server.RemoteEvent:FireClient(Player, Name, ...)
end

function Server.InvokeRemoteFunction(Name, Player, ...)
    return Server.RemoteFunction:InvokeClient(Player, Name, ...)
end

function Server.FireRemoteEventWhenAvailable(Name, Player, ...)
    local Args = ...

    Async.Wrap(function()
        local Ready

        while (Player.Parent) do
            local PlayerEvents = Server.EventsReady[Player.UserId]

            if (not PlayerEvents) then
                PlayerEvents = {}
                Server.EventsReady[Player.UserId] = PlayerEvents
            end

            Ready = PlayerEvents[Name]

            if Ready then
                break
            end

            wait()
        end

        if (not Player.Parent) then
            return
        end

        Server.FireRemoteEvent(Name, Player, Args)
    end)()
end

function Server.Broadcast(...)
    Server.RemoteEvent:FireAllClients(...)
end

function Server.Init()

    local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent") or
                            Instance.new("RemoteEvent", ReplicatedStorage)
    local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction") or
                            Instance.new("RemoteFunction", ReplicatedStorage)
    local ReadyEvent = ReplicatedStorage:FindFirstChild("ReadyEvent") or
                            Instance.new("RemoteEvent", ReplicatedStorage)

    ReadyEvent.Name = "ReadyEvent"

    Server.RemoteEvent = RemoteEvent
    Server.RemoteFunction = RemoteFunction
    Server.ReadyEvent = ReadyEvent

    ReadyEvent.OnServerEvent:Connect(function(Player, Name)
        assert(typeof(Name) == "string")
        Server.EventsReady[Player.UserId] = Server.EventsReady[Player.UserId] or {}
        Server.EventsReady[Player.UserId][Name] = true
    end)

    RemoteEvent.OnServerEvent:Connect(function(Player, Name, ...)

        if not Player then return end
        local Event = Binds.Events[Name]

        if (type(Name) ~= "string") then
            warn("Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
        elseif (Event == nil) then
            warn("Warning, no event '" .. Name .. "' found in event collection.")
        else
            Event:Fire(Player, ...)
        end
    end)

    RemoteFunction.OnServerInvoke = function(Player, Name, ...)

        if not Player then return end
        local Function = Binds.Functions[Name]

        if (type(Name) ~= "string") then
            warn("Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
            return false
        elseif (Function == nil) then
            warn("Warning, no function '" .. Name .. "' found in function collection.")
        else
            return Function(Player, ...)
        end
    end

    Players.PlayerAdded:Connect(function(Player)
        while (Server.InvokeRemoteFunction("Ready", Player) == nil) do
            wait(Configuration.coPollInterval)
        end
        Server.TransmissionReady[Player.Name] = true
    end)
end

return Server