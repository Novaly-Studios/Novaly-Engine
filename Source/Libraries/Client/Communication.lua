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

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Client = {}

local function BindRemoteEvent(Name, Handler)
    local Found = RemoteEvents:WaitForChild(Name)
    Client.ReadyEvent:FireServer(Name)
    return Found.OnClientEvent:Connect(Handler)
end

local function BindRemoteFunction(Name, Handler)
    local Found = RemoteFunctions:WaitForChild(Name)
    Found.OnClientInvoke = Handler

    return function()
        Found.OnClientInvoke = nil
    end
end

Client.BindRemoteEvent = BindRemoteEvent
Client.BindRemoteFunction = BindRemoteFunction

function Client.FireRemoteEvent(Name, ...)
    RemoteEvents:WaitForChild(Name):FireServer(...)
end

function Client.InvokeRemoteFunction(Name, ...)
    return RemoteFunctions:WaitForChild(Name):InvokeServer(...)
end

function Client.Init()
    local ReadyEvent = ReplicatedStorage:WaitForChild("ReadyEvent")
    Client.ReadyEvent = ReadyEvent

    Client.BindRemoteFunction("Ready", function()
        return true
    end)
end

return Client