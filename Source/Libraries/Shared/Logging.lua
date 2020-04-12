local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Time = Novarine:Get("Time")

local Log = {}

local Indicator = Novarine:Get("RunService"):IsServer() and "Server" or "Client"

--[[
    @function Log

    Logs a formatted message.
]]
function Log.Log(...)
    print("[" .. Indicator .. " | " .. Time.FromSeconds(tick()):TimeString() .. "] " .. string.format(...))
end

--[[
    @function Debug

    Logs a formatted message at a certain level

    @param Level The "verbosity" level beyond which
           messages will begin displaying if exceeded.
]]
function Log.Debug(Level, ...)
    local LogLevel = Novarine:Get("LogLevel")

    if (Level <= LogLevel) then
        Log.Log(...)
    end
end

--[[
    @function Assert

    @param Condition A function that will be invoked.

    @note Should be more efficient than regular assert
    where string formatting is concerned, as not
    formatted until condition causes error.
]]
function Log.Assert(Condition, ...)
    assert(Condition, string.format(...))
end

return Log