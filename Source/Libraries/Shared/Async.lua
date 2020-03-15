--[[
    Contains helper functions to wrap existing Roblox APIs in promises.
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Promise = Novarine:Get("Promise")

local Async = {}

--[[
    @function Async.WaitForChild

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
    @function Async.Delay

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
    @function Async.Wrap

    Uses coroutine.wrap or accurate traceback
    for a coroutine. The latter is faster and
    runs in non-debug mode.

    @tparam Call Function The function to wrap.
    @return A function which will begin the wrapped function.
]]
function Async.Wrap(Call)
    if (Novarine.DebugMode) then
        local BindableEvent = Instance.new("BindableEvent")
        BindableEvent.Event:Connect(Call)

        return function(...)
            BindableEvent:Fire(...)
            BindableEvent:Destroy()
        end
    end

    return coroutine.wrap(Call)
end

--[[
    @function Async.Await

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

--[[ function Async.AwaitItem(Table, TargetKey)

    local Item = Table[TargetKey]

    if Item then
        return Item
    end

    local Metatable = getmetatable(Table)
    local NewIndex = Metatable.__newindex

    setmetatable(Table, {
        __newindex = function(Self, Key, Value)
            if (Key == TargetKey) then
                Item = Value
                Metatable.__newindex = NewIndex
            end

            return NewIndex(Self, Key, Value)
        end;
    })

    coroutine.wrap(function()
        wait(5)

        if Item then
            return
        end

        warn(string.format("Potential infinite yield on '%s'!\n%s", tostring(Table), debug.traceback()))
    end)()

    coroutine.yield()
    return Item
end ]]

--[[
local YieldNewIndexes = {}

local function WaitForItem(Table, TargetKey)

    local Item = Table[TargetKey]

    if Item then
        return Item
    end

    local Metatable = getmetatable(Table)
    local Running = coroutine.running()

    if (not Metatable) then
        Metatable = {}
        setmetatable(Table, Metatable)
    end

    local OldNewIndex = Metatable.__newindex

    local function NewNewIndex(Self, Key, Value)
        if (Key == TargetKey) then
            Item = Value
            Metatable.__newindex = OldNewIndex
        end

        assert(coroutine.resume(Running))

        if (OldNewIndex and not YieldNewIndexes[OldNewIndex]) then
            print("e ee ee eee", OldNewIndex)
            return OldNewIndex(Self, Key, Value)
        end
    end

    setmetatable(Table, {
        __newindex = NewNewIndex
    })

    print("wry", NewNewIndex)
    YieldNewIndexes[NewNewIndex] = true

    coroutine.wrap(function()
        wait(5)

        if Item then
            return
        end

        warn(string.format("Potential infinite yield on '%s'!\n%s", tostring(Table), debug.traceback()))
    end)()

    coroutine.yield()

    if NewNewIndex then
        YieldNewIndexes[NewNewIndex] = nil
    end

    return Item
end

local Item = {}

coroutine.wrap(function()
    wait(3)
    Item.X = 10
    wait(2)
    Item.Y = 15
end)()

coroutine.wrap(function()
    local X = WaitForItem(Item, "X")
    print("X = ", X)
end)()

coroutine.wrap(function()
    local Y = WaitForItem(Item, "Y")
    print("Y = ", Y)
end)()
]]

return Async