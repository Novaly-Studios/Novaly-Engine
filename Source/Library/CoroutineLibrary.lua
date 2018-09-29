shared()

local Coroutine = {}

local Mappings = {
    create 	= "Create";
    resume 	= "Resume";
    running = "Running";
    status 	= "Status";
    wrap 	= "Wrap";
    yield 	= "Yield";
}

Table.ApplyKeyMapping(Coroutine, Mappings, coroutine)

shared({
    Client = {Coroutine = Coroutine};
    Server = {Coroutine = Coroutine};
})

return true