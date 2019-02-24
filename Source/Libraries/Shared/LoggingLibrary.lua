shared()

-- Todo: reporting to Novaly servers, error detection

local Log = {}

function Log.Log(Level, Str)
    print(("\t"):rep(Level) .. Str)
end

return Log