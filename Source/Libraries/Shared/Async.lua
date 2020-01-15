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

return Async