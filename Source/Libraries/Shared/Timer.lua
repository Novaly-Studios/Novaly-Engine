local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local RunService = Novarine:Get("RunService")
local Async = Novarine:Get("Async")

local Timer = {}

function Timer:On(Interval, Execute)
    local Running = true

    if (Interval < 1/30) then
        assert(RunService:IsClient(), "Server cannot execute operations this fast!")
        local Connection; Connection = RunService.Stepped:Connect(function()
            if (not Running) then
                Connection:Disconnect()
                return
            end
            Execute()
        end)
    else
        Async.Wrap(function()
            while wait(Interval) do
                if (not Running) then
                    return
                end
                Execute()
            end
        end)()
    end

    return function()
        Running = false
    end
end

return Timer