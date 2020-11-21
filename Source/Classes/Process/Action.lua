local Action = {}
Action.__index = Action

function Action.New(Required)
    return setmetatable({
        Awaiting = {}; -- List of coroutines awaiting
        Required = Required;
        Release = Instance.new("BindableEvent");
        _IsAction = true;
    }, Action)
end

--[[
    Enforces that the Action has not
    yet completed.
]]
function Action:_CheckFinished()
    assert(not self.Result, "Action already finished!")
end

--[[
    Checks all the required handlers
    are present.
]]
function Action:_CheckRequired()
    for _, Name in pairs(self.Required) do
        assert(self[Name], string.format("Handler not found: '%s'!", Name))
    end
end

--[[
    Resumes all awaiting threads.
]]
function Action:_OnYield()
    --[[ for _, Thread in pairs(self.Awaiting) do
        assert(coroutine.resume(Thread))
    end ]]

    self.Release:Fire()
end

--[[
    Awaits the result of the Action.
]]
function Action:Await()
    if (not self.Result) then
        --[[ table.insert(self.Awaiting, coroutine.running())
        coroutine.yield() ]]
        self.Release.Event:Wait()
    end

    return unpack(self.Result)
end

--[[
    Initiates the Action asynchronously.
]]
function Action:Async()
    self:_CheckFinished() -- Run only once
    self:_CheckRequired()

    local GotBranch

    -- Returns final result
    local function Yield(...)
        assert(not self.Result, "Yield called twice!")
        self.Result = {...}
        self:_OnYield()
    end

    -- Branches off into a sub-handler and pass any relevant args
    local function Branch(Branch, ...)
        assert(not GotBranch, "Branch called twice!")
        GotBranch = true

        local Handler = self[Branch]
        assert(Handler, string.format("No handler set up for '%s'!", Branch))
        Handler(Yield, ...)
    end

    -- Initiate the process
    local BindableEvent = Instance.new("BindableEvent")
    BindableEvent.Event:Connect(function()
        if (self.InitialCallback) then
            -- For callback, send the Branch function over
            self.Initial(Branch, unpack(self.PassedArgs))
        else
            -- For return, take returned values and pass to Branch
            Branch(self.Initial(unpack(self.PassedArgs)))
        end
    end)
    BindableEvent:Fire()
    BindableEvent:Destroy()

    return self
end

--[[
    Alternative syntax style for
    the handlers.

    @usage
        WaitForChild(...)
            :On("Success", function() end)
            :On("Unhandled", function() end)
            ...
]]
function Action:On(Name, Handler)
    assert(Name, "No name given!")
    assert(Handler, "No handler given!")
    assert(type(Handler) == "function", "Handler must be a function.")

    self[Name] = Handler
    return self
end

--[[
    Awaits for all Actions given
    to finish.
]]
function Action.AwaitAll(...)
    local Results = {}

    for Index, Arg in pairs({...}) do
        assert(type(Arg) == "table" and Arg._IsAction,
            string.format("Argument '%d' not an Action.", Index))

        table.insert(Results, {Arg:Await()})
    end

    return Results
end

--[[
    Wraps a function such that it will
    produce a new Action when called
    every time. Passed initial 'Func'
    will return a branch and extra params
    to pass to the branching function.
]]
function Action.Wrap(Func, ...)
    local Required = {...}
    assert(Func, "No function given!")
    assert(type(Func) == "function", "Function arg is not a function!")

    return function(...)
        local New = Action.New(Required)
        New.PassedArgs = {...}
        New.InitialCallback = false
        New.Initial = Func
        New.Required = Required
        return New
    end
end

--[[
    Wraps a function such that it will
    produce a new Action when called
    every time.
]]
function Action.WrapCallback(Func, ...)
    local Required = {...}
    assert(Func, "No function given!")
    assert(type(Func) == "function", "Function arg is not a function!")

    return function(...)
        local New = Action.New(Required)
        New.PassedArgs = {...}
        New.InitialCallback = true
        New.Initial = Func
        New.Required = Required
        return New
    end
end

return Action