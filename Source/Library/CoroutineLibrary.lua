local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Original = OriginalEnv["coroutine"]

local Coroutine = setmetatable({}, {__index = function(Self, Key)
    return rawget(Self, Key) or Original[Key]
end})

local Mappings = {
    create = "Create";
    resume = "Resume";
    running = "Running";
    status = "Status";
    wrap = "Wrap";
    yield = "Yield";
}

Table.ApplyKeyMapping(Coroutine, Mappings)

Func({
    Client = {coroutine = Coroutine, Coroutine = Coroutine};
    Server = {coroutine = Coroutine, Coroutine = Coroutine};
})

return true