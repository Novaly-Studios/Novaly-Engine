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

return Async