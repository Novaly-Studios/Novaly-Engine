setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())
local AsyncOperationQueue = Class:FromName(script.Name)

function AsyncOperationQueue:AsyncOperationQueue(Handler)
    Assert(Handler)
    return {
        Handler = Handler;
        Queue = LinkedList.New();
    }
end

function AsyncOperationQueue:Add(...)
    local Queue = self.Queue
    for _, Item in Pairs({...}) do
        Queue:PushTail(Item)
    end
end

function AsyncOperationQueue:Next(Count)

    local Handler = self.Handler
    local Queue = self.Queue

    for Iter = 1, Count or 1 do
        if (Queue:PeekFirst()) then
            Coroutine.Wrap(Handler)(Queue, Queue:Next(), Iter)
        else
            return true
        end
    end
end

return AsyncOperationQueue