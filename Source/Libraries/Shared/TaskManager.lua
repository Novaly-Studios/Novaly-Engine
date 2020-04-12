local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local PriorityQueue = Novarine:Get("PriorityQueue")
local RunService = Novarine:Get("RunService")

local TaskManager = {
    Queue = PriorityQueue:Create();
}

function TaskManager:Init() end

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

function TaskManager:AddOnStep(VDP)
    assert(type(VDP.Data) == "function", "Data type is not function in supplied ValueDataPair!")

    return RunService.Stepped:Connect(function()
        self:Add(VDP)
    end)
end

return TaskManager