-- Todo: reporting to Novaly servers, error detection

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Time = Novarine:Get("Time")
local RunService = Novarine:Get("RunService")

local Log = {}
local Indicator = RunService:IsServer() and "Server" or "Client"

function Log.Log(Level, Str)
    print("[" .. Indicator .. " | " .. Time.FromSeconds(tick()):TimeString() .. "]" .. ("\t"):rep(Level) .. Str)
end

return Log