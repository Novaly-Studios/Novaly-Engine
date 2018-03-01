local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

-- Todo: reporting to Novaly servers, error detection

local Log = {}

function Log.Log(Level, Str)

    print(("\t"):rep(Level) .. Str)

end

Func({
	Client = Log;
	Server = Log;
})

return true