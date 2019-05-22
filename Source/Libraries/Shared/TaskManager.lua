shared()

local TaskManager = {
    Queue = PriorityQueue:Create();
    RunPerUpdate = 1;
}

function TaskManager:Init()
    RunService.Stepped:Connect(function()
        self:Run(self.RunPerUpdate)
    end)
end

function TaskManager:Add(VDP)
    assert(type(VDP.Data) == "function", "Data type is not function in supplied ValueDataPair!")
    self.Queue:Add(VDP)
end

function TaskManager:Run(Times)
    for _ = 1, Times do
        local Item = self.Queue:Pop()
        if Item then
            Item.Data()
        end
    end
end

return {
    TaskManager = TaskManager;
}