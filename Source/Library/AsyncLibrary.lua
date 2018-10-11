--[[
    Contains helper functions to wrap existing Roblox APIs in promises.
]]

shared()

local Async = {}

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

return {
    Client = { Async = Async };
    Server = { Async = Async };
}