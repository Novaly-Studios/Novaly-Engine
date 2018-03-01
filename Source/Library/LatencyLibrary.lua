local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Client = {}
local Server = {}

function Client.GetRenderLatency()

    local OldTick = tick()
    RunService.RenderStepped:wait()

    return tick() - OldTick

end

function Client.GetPingLatency()

    local OldTick = tick()
    InvokeFunction("PingLatency")

    return tick() - OldTick

end

function Client.GetServerWait()

    return InvokeFunction("WaitLatency")

end

function c__main()

    BindFunction("PingLatency", function(...)

        return true

    end)

end

function Server.GetClientLatency(Player)

    local OldTick = tick()
    InvokeFunction("PingLatency", Player)

    return tick() - OldTick

end

function s__main()

    BindFunction("PingLatency", function(Player)

        return true

    end)

    BindFunction("WaitLatency", function(Player)

        return wait()

    end)

end

Func({
    Client = {Latency = Client, __main = c__main};
    Server = {Latency = Server, __main = s__main};
})

return true