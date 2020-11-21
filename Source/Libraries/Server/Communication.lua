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
local Configuration = Novarine:Get("Configuration")
local Players = Novarine:Get("Players")
local Async = Novarine:Get("Async")

local Server = {
    TransmissionReady = {};
    EventsReady = {};
};

local function BindRemoteEvent(Name, Handler)
    local RemoteEvent = Server.RemoteEvents:FindFirstChild(Name)

    if (not RemoteEvent) then
        RemoteEvent = Instance.new("RemoteEvent")
        RemoteEvent.Parent = Server.RemoteEvents
        RemoteEvent.Name = Name
    end

    return RemoteEvent.OnServerEvent:Connect(Handler)
end

local function BindRemoteFunction(Name, Handler)
    local RemoteFunction = Server.RemoteFunctions:FindFirstChild(Name)

    if (not RemoteFunction) then
        RemoteFunction = Instance.new("RemoteFunction")
        RemoteFunction.Parent = Server.RemoteFunctions
        RemoteFunction.Name = Name
    end

    RemoteFunction.OnServerInvoke = Handler

    return function()
        RemoteFunction.OnServerInvoke = nil
    end
end

Server.BindRemoteEvent = BindRemoteEvent
Server.BindRemoteFunction = BindRemoteFunction

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

function Server.MakeEvents(Names)
    for _, Name in pairs(Names) do
        if (not Server.RemoteEvents:FindFirstChild(Name)) then
            local RemoteEvent = Instance.new("RemoteEvent")
            RemoteEvent.Parent = Server.RemoteEvents
            RemoteEvent.Name = Name
        end
    end
end

function Server.MakeFunctions(Names)
    for _, Name in pairs(Names) do
        if (not Server.RemoteFunctions:FindFirstChild(Name)) then
            local RemoteFunction = Instance.new("RemoteFunction")
            RemoteFunction.Parent = Server.RemoteFunctions
            RemoteFunction.Name = Name
        end
    end
end

function Server.FireRemoteEvent(Name, Player, ...)
    local RemoteEvent = Server.RemoteEvents:FindFirstChild(Name)

    if (not RemoteEvent) then
        RemoteEvent = Instance.new("RemoteEvent")
        RemoteEvent.Parent = Server.RemoteEvents
        RemoteEvent.Name = Name
    end

    RemoteEvent:FireClient(Player, ...)
end

function Server.InvokeRemoteFunction(Name, Player, ...)
    local RemoteFunction = Server.RemoteFunctions:FindFirstChild(Name)

    if (not RemoteFunction) then
        RemoteFunction = Instance.new("RemoteFunction")
        RemoteFunction.Parent = Server.RemoteFunctions
        RemoteFunction.Name = Name
    end

    return RemoteFunction:InvokeClient(Player, ...)
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

function Server.Broadcast(Name, ...)
    Server.RemoteEvents:WaitForChild(Name):FireAllClients(...)
end

function Server.Init()

    local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
    local ReadyEvent = ReplicatedStorage:FindFirstChild("ReadyEvent") or
                            Instance.new("RemoteEvent", ReplicatedStorage)

    ReadyEvent.Name = "ReadyEvent"
    Server.ReadyEvent = ReadyEvent
    Server.RemoteEvents = RemoteEvents
    Server.RemoteFunctions = RemoteFunctions

    ReadyEvent.OnServerEvent:Connect(function(Player, Name)
        assert(typeof(Name) == "string")
        Server.EventsReady[Player.UserId] = Server.EventsReady[Player.UserId] or {}
        Server.EventsReady[Player.UserId][Name] = true
    end)

    Players.PlayerAdded:Connect(function(Player)
        while (Server.InvokeRemoteFunction("Ready", Player) == nil) do
            wait(Configuration.coPollInterval)
        end

        Server.TransmissionReady[Player.Name] = true
    end)
end

return Server