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

return {
    Coroutine = Coroutine;
}