--[[
    Contains helper functions to wrap existing Roblox APIs in promises.
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Promise = Novarine:Get("Promise")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()
local WaitEvent = RunService.Heartbeat

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
    local Profile

    if (type(Call) == "string") then
        Profile = Call
        Call = Args[1]
    end

    BindableEvent.Event:Connect(function()
        if Profile then
            debug.profilebegin(Profile)
        end

        Call(unpack(Args))

        if Profile then
            debug.profileend()
        end
    end)

    BindableEvent:Fire()
    BindableEvent:Destroy()
    --coroutine.wrap(Call)(...)
end

--[[
    @function Wrap

    Uses accurate traceback; acts as a
    replacement for coroutine.wrap.

    @tparam Call Function The function to wrap.
    @return A function which will begin the wrapped function.
]]
function Async.Wrap(Call, Name)    
    return function(...)
        if Name then
            Async.Spawn(Name, Call, ...)
            return
        end

        Async.Spawn(Call, ...)
    end

    --return coroutine.wrap(Call)
end

--[[
    @function Timer

    Creates a synchronised, blockable timer loop.
    Useful for UI updating and such.

    @tparam Interval Number How long to wait between calls.
    @tparam Call Function The function to call.
    @tparam Name[opt] Name of the label in microprofiler.

    @return A function to stop the timer.
]]
function Async.Timer(Interval, Call, Name)
    if Name then
        Name = Name .. "(" .. math.floor(Interval * 100) / 100 .. ")"
    end

    local Running = true

    local function Halt()
        Running = false
    end

    local LastTime = tick()

    Async.Spawn(function()
        while Running do
            if Name then
                debug.profilebegin(Name)
            end

            local CurrentTime = tick()
            Call(CurrentTime - LastTime)

            if Name then
                debug.profileend()
            end

            Async.Wait(Interval)
            LastTime = CurrentTime
        end
    end)

    return Halt
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

function Async.Wait(Time)
    Time = Time or 1/30

    local InitialTime = tick()

    if (Time <= (1/60 + 0.001)) then
        WaitEvent:Wait()
        return true
    end

    while (tick() - InitialTime < Time) do
        WaitEvent:Wait()
    end

    return true
end

return Async