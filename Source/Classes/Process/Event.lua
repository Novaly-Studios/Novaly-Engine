local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")
local Class = Novarine:Get("Class")

local Event = Class:FromName(script.Name)

function Event:Event()
    return {
        Handlers = {};
    };
end

function Event:Connect(Func)
    local Handlers = self.Handlers
    local Index = #Handlers + 1
    Handlers[Index] = Func

    return {
        Disconnect = function()
            Handlers[Index] = nil
        end;
    }
end

function Event:Flush()
    self.Handlers = {}
end

function Event:Fire(...)
    for _, Handler in pairs(self.Handlers) do
        Async.Wrap(Handler)(...)
    end
end

return Event