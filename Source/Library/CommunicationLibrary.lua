local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Client            = {}
local Server            = {}
local BroadcastRules    = {}
local BroadcastFunc     = {}

function Client.FireEvent(Name, ...)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    local Event = Events[Name]
    if Event:IsA("RemoteEvent") then
        Event:FireServer(...)
    elseif Event:IsA("BindableEvent") then
        Event:Fire(...)
    end
end

function Server.FireEvent(Name, ...)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    local Event = Events[Name]
    if Event:IsA("RemoteEvent") then
        Event:FireClient(...)
    elseif Event:IsA("BindableEvent") then
        Event:Fire(...)
    end
end

function Client.InvokeFunction(Name, ...)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    local Function = Functions[Name]
    if Function:IsA("RemoteFunction") then
        return Function:InvokeServer(...)
    elseif Function:IsA("BindableFunction") then
        Function:Invoke(...)
    end
end

function Server.InvokeFunction(Name, ...)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    local Function = Functions[Name]
    if Function:IsA("RemoteFunction") then
        return Function:InvokeClient(...)
    elseif Function:IsA("BindableFunction") then
        Function:Invoke(...)
    end
end

function Client.BindEvent(Name, EventFunction)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    local Event = Events[Name]
    Event.OnClientEvent:connect(EventFunction)
end

function Server.BindEvent(Name, EventFunction)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    local Event = Events[Name]
    Event.OnServerEvent:connect(EventFunction)
end

function BindEventB(Name, Func)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    Events[Name].Event = Func
end

function BindFunctionB(Name, Func)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    Function[Name].Invoke = Func
end

function Client.BindFunction(Name, InvokeFunction)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    local Function = Functions[Name]
    Function.OnClientInvoke = InvokeFunction
end

function Server.BindFunction(Name, InvokeFunction)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    local Function = Functions[Name]
    Function.OnServerInvoke = InvokeFunction
end

function Server.InvokeAllClients(Name, ...)
    assert(Functions:FindFirstChild(Name), "Could not find function '" .. Name .. "'")
    local Function = Functions[Name]
    for Key, Value in next, game:GetService("Players"):GetChildren() do
        Function:InvokeClient(Value, ...)
    end
end

function Server.FireAllClients(Name, ...)
    assert(Events:FindFirstChild(Name), "Could not find event '" .. Name .. "'")
    Events[Name]:FireAllClients(...)
end

function Server.AddBroadcastRule(Name, Func)
    local Rule = BroadcastRules[Name] or {}
    Rule[#Rule + 1] = Func
    BroadcastRules = Rule
end

function Client.Broadcast(Name, ...)
    Server.FireEvent("Broadcast", ...)
end

function Client.ConnectBroadcastFunction(Name, Func)
    BroadcastFunc[Name] = Func
end

function Client.DisconnectBroadcastFunction(Name)
    BroadcastFunc[Name] = nil
end

--[[Server.BindEvent("Broadcast", function(Player, ...)
    local Args = {...}
    if Args[1] ~= nil then
        if type(Args[1]) == "string" then
            for Item = 1, #BroadcastRules do
                if BroadcastRules[Item](...) == false then
                    return
                end
            end
            Server.FireAllClients(...)
        end
    end
end)]]

Client.BindEventB = BindEventB
Server.BindEventB = BindEventB

Client.BindFunctionB = BindFunctionB
Server.BindFunctionB = BindFunctionB

Func({
    Client = Client;
    Server = Server;
})

return true