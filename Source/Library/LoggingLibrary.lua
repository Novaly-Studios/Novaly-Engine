shared()

-- Todo: reporting to Novaly servers, error detection

local Log = {}

function Log.Log(Level, Str)
    Print(("\t"):rep(Level) .. Str)
end

return {
    Client = Log;
    Server = Log;
}