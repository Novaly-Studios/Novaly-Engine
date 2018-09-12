shared()

local Coroutine = SetMetatable({}, {__index = OriginalEnv["coroutine"]})

local Mappings = {
    create 	= "Create";
    resume 	= "Resume";
    running = "Running";
    status 	= "Status";
    wrap 	= "Wrap";
    yield 	= "Yield";
}

Table.ApplyKeyMapping(Coroutine, Mappings)

shared({
    Client = {coroutine = Coroutine, Coroutine = Coroutine};
    Server = {coroutine = Coroutine, Coroutine = Coroutine};
})

return true