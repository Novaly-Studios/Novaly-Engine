-- Todo: reporting to Novaly servers, error detection

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Time = Novarine:Get("Time")
local RunService = Novarine:Get("RunService")

local Log = {}
local Indicator = RunService:IsServer() and "Server" or "Client"

function Log.Log(Level, ...)
    print("[" .. Indicator .. " | " .. Time.FromSeconds(tick()):TimeString() .. "]" .. ("\t"):rep(Level) .. string.format(...))
end

function Log.Debug(...)
    if (Novarine:Get("DebugMode")) then
        Log.Log(...)
    end
end

function Log.Assert(Condition, ...)
    assert(Condition, string.format(...))
end

return Log