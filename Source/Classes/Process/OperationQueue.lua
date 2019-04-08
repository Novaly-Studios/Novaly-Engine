shared()

local OperationQueue = Class:FromName(script.Name)

function OperationQueue:OperationQueue(Handler)
    assert(Handler)
    return {
        Handler = Handler;
        Queue = LinkedList.New();
    }
end

function OperationQueue:Add(...)
    local Queue = self.Queue
    for _, Item in pairs({...}) do
        Queue:PushTail(Item)
    end
end

function OperationQueue:Next(Count)

    local Handler = self.Handler
    local Queue = self.Queue

    for Iter = 1, Count or 1 do
        if (Queue:PeekFirst()) then
            Handler(Queue:Next(), Queue, Iter)
        else
            return true
        end
    end
end

return OperationQueue