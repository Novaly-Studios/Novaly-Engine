--[[
    Contains helper functions to wrap existing Roblox APIs in promises.
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Promise = Novarine:Get("Promise")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Async = {}

--[[
    @function WaitForChild

    Wrapper around Instance:WaitForChild() that uses Promises.

    @tparam Instance Parent The instance to search inside of
    @tparam string Name The name of the instance you want to yield for
    @tparam int[opt] Timeout The amount of time to wait before we give up and
        reject the Promise

    @return A Promise that resolves when Parent[Name] exists.

    @usage
        Async.WaitForChild(workspace, "Part")
            :andThen(function(Part)
                print(Part:GetFullName()) -- workspace.Part
            end)

        -- With timeout
        Async.WaitForChild(workspace, "Part", 2)
            :andThen(function(Part)
                print("Found the part!"")
            end)
            :catch(function()
                print("workspace.Part wasn't found in time!")
            end)
]]
function Async.WaitForChild(Parent, Name, Timeout)
    return Promise.new(function(Resolve, Reject)
        spawn(function()
            local OK, Result = pcall(function()
                return Parent:WaitForChild(Name, Timeout)
            end)

            if OK and Result then
                Resolve(Result)
            else
                Reject()
            end
        end)
    end)
end

--[[
    @function Delay

    Simple delay-callback function to replace
    Roblox's questionable delay.

    @tparam Time Number The time to wait before callback in seconds.
    @tparam Callback Function The callback function.

    @usage
        Async.Delay(2.5, function()
            print("HHHHHHHHHHH")
        end)
]]
function Async.Delay(Time, Callback)
    Async.Wrap(function()
        wait(Time)
        Callback()
    end)()
end

--[[
    @function Spawn
    
    Immediately spawns a function with
    correct tracebacks.
]]
function Async.Spawn(Call, ...)
    local Args = {...}
    local BindableEvent = Instance.new("BindableEvent")

    BindableEvent.Event:Connect(function()
        Call(unpack(Args))
    end)

    BindableEvent:Fire()
    BindableEvent:Destroy()
end

--[[
    @function Wrap

    Uses accurate traceback; acts as a
    replacement for coroutine.wrap.

    @tparam Call Function The function to wrap.
    @return A function which will begin the wrapped function.
]]
function Async.Wrap(Call)    
    return function(...)
        Async.Spawn(Call, ...)
    end

    --return coroutine.wrap(Call)
end

--[[
    @function Await

    Waits for callback-based APIs to finish.

    @tparam Operation Function The function to wait on.

    @return The arguments passed to the callback.
]]
function Async.Await(Operation)
	local Running = coroutine.running()
	local Returns

	coroutine.wrap(Operation)(function(...)
		Returns = ...
		assert(coroutine.resume(Running))
	end)

	coroutine.yield()
	return Returns
end

--[[
    @function CWait

    Conditionally waits, whereby if the condition
    function returns false or nil the waiting
    will terminate.

    @tparam Time number The time to wait for.
    @tparam Condition[opt='whatever'] function The assessment function.
    @tparam Event string[opt='RenderStepped'] A granular wait event name of RunService.
]]
function Async.CWait(Time, Condition, Event)
    Time = Time or 1/30

    local InitialTime = tick()
    local AwaitEvent = IsServer and Async.ServerWait or RunService[Event or "Stepped"]

    Condition = Condition or function()
        return true
    end

    while (tick() - InitialTime < Time) do
        if (not Condition()) then
            break
        end

        AwaitEvent:Wait(Time)
    end

    return true
end

function Async.Wait(Time, Event)
    Time = Time or 1/30

    local InitialTime = tick()
    local AwaitEvent = IsServer and Async.ServerWait or RunService[Event or "Stepped"]

    if (Time <= 1/59) then
        AwaitEvent:Wait()
    else
        while (tick() - InitialTime < Time) do
            AwaitEvent:Wait(Time)
        end
    end

    return true
end

Async.ServerWait = {
    Wait = function()
        wait()
    end;
};

return Async