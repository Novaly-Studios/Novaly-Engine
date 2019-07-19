local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local RunService = Novarine:Get("RunService")

local Timer = {}

--[[
    Runs a function on some interval.

    @param Interval The interval, in seconds
    @param Execute The function to run

    @note If interval is less than 1/30, it will become 1/60
    @note Runs the timer in another coroutine

    @usage
        Timer:On(1/5, function() print("AHHH") end)
        Timer:On(0, function() print("EEEEE") end)
]]

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
        coroutine.wrap(function()
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
