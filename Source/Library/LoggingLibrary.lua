local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

-- Todo: reporting to Novaly servers, error detection

local Log = {}

function Log.Log(Level, Str)
    Print(("\t"):rep(Level) .. Str)
end

Func({
    Client = Log;
    Server = Log;
})

return true