setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Event = Class.FromConstructor(
    
    script.Name,

    function(Self, Condition, DelayFunc)

        Self.Condition = Condition
        Self.DelayFunc = DelayFunc
        Self.EventHandlers = LinkedList.new()
        Self.EventData = {}
        Self.Listening = false

        coroutine.resume(coroutine.create(function()

            while true do

                Self:Update()

            end

        end))

    end
)

function Event:Connect(EventHandler)

    local EventHandlers = self.EventHandlers
    local Node = EventHandlers:PushTail(EventHandler)

    --[[return function()

        EventHandlers:RemoveNode(Node)

    end]]

end

function Event:Destroy()

    self.EventHandlers:Flush()

end

function Event:Fire()

    self.EventHandlers:HeadForeach(function(Handler)

        coroutine.resume(coroutine.create(Handler))

    end)

end

function Event:Update()

    self.DelayFunc()

    -- Don't run if we have no event handlers or are not listening

    if self.EventHandlers:PeekFirst() == nil then

        return

    elseif self.Listening == false then

        return

    end

    local Result = {self.Condition(self.EventData)}

    if Result[1] then

        Result[1] = nil
        self:Fire(unpack(Result))

    end

end

function Event:StartListening()

    self.Listening = true

end

function Event:StopListening()

    self.Listening = false

end

return Event