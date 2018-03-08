local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Mutual            = {}
local Client            = {}
local Server            = {
    TransmissionReady   = {};
}
local Binds             = {
    Events              = {};
    Functions           = {};
}

function Mutual.BindRemoteEvent(Name, Handler)

    Binds.Events[Name] = Handler

end

function Mutual.BindRemoteFunction(Name, Handler)

    Binds.Functions[Name] = Handler

end

function Client.FireRemoteEvent(...)

    Client.RemoteEvent:FireServer(...)

end

function Client.InvokeRemoteFunction(...)

    return Client.RemoteFunction:InvokeServer(...)

end

function Client.__main()

    local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
    Client.RemoteEvent = RemoteEvent
    Client.RemoteFunction = RemoteFunction

    RemoteEvent.OnClientEvent:Connect(function(Name, ...)

        local Event = Binds.Events[Name]

        if type(Name) ~= "string" then

            Log(0, "Warning, server has sent an empty or non-string request name.")
        
        elseif Event == nil then

            Log(0, "Warning, no event '" .. Name .. "' found in event collection.")

        else

            Event(...)

        end

    end)
    
    RemoteFunction.OnClientInvoke = function(Name, ...)

        local Function = Binds.Functions[Name]

        if type(Name) ~= "string" then

            Log(0, "Warning, servers has sent an empty or non-string request name.")
            return false

        elseif Function == nil then

            Log(0, "Warning, no function '" .. Name .. "' found in function collection.")

        else

            return Function(...)

        end

    end

    Client.BindRemoteFunction("Ready", function()

        return true

    end)

end

function Server.WaitForTransmissionReady(Player)

    local Tries = 0

    while Server.TransmissionReady[Player.Name] == nil do

        wait(CONFIG.coPollInterval)

        Tries = Tries + 1

        if Tries == CONFIG.coMaxTries then

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

function Server.__main()

    local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent") or
                        Instance.new("RemoteEvent", ReplicatedStorage)
    local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction") or
                        Instance.new("RemoteFunction", ReplicatedStorage)

    Server.RemoteEvent = RemoteEvent
    Server.RemoteFunction = RemoteFunction

    RemoteEvent.OnServerEvent:Connect(function(Player, Name, ...)

        if not Player then return end
        local Event = Binds.Events[Name]
          
        if type(Name) ~= "string" then

            Log(0, "Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
        
        elseif Event == nil then

            Log(0, "Warning, no event '" .. Name .. "' found in event collection.")

        else

            Event(Player, ...)

        end

    end)
    
    RemoteFunction.OnServerInvoke = function(Player, Name, ...)

        if not Player then return end
        local Function = Binds.Functions[Name]

        if type(Name) ~= "string" then

            Log(0, "Warning, client " .. Player.Name .. " has sent an empty or non-string request name.")
            return false

        elseif Function == nil then

            Log(0, "Warning, no function '" .. Name .. "' found in function collection.")

        else

            return Function(Player, ...)

        end

    end

    Players.PlayerAdded:Connect(function(Player)

        while Server.InvokeRemoteFunction("Ready", Player) == nil do

            wait(CONFIG.coPollInterval)

        end

        Server.TransmissionReady[Player.Name] = true

    end)

end

for Key, Value in next, Mutual do

    Client[Key] = Value
    Server[Key] = Value

end

Func({
    Client = Client;
    Server = Server;
})

return true