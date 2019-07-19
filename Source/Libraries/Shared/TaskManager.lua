local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local PriorityQueue = Novarine:Get("PriorityQueue")
local RunService = Novarine:Get("RunService")

local TaskManager = {
    Queue = PriorityQueue:Create();
}

function TaskManager:Init() end

--[[
    Adds a task to the TaskManager with a corresponding
    priority.

    @usage
        TaskManager:Add(ValueDataPair.New(1, function()
            print("One")
        end))
        TaskManager:Add(ValueDataPair.New(8, function()
            print("Eight")
        end))
    @param VDP A ValueDataPair object.        
]]

function TaskManager:Add(VDP)
    assert(type(VDP.Data) == "function", "Data type is not function in supplied ValueDataPair!")
    self.Queue:Add(VDP)
end

--[[
    Runs the next n tasks with the highest priority.
    Will run no tasks if the priority queue is empty.

    @usage
        TaskManager:Run(5)
    @param Times The amount of tasks to run.
]]

function TaskManager:Run(Times)
    for _ = 1, Times do
        local Item = self.Queue:Pop()
        if Item then
            Item.Data()
        end
    end
end

--[[
    Adds a task each render step. Useful for graphical
    tasks.

    @usage
        See TaskManager.Add
]]

function TaskManager:AddOnStep(VDP)
    assert(type(VDP.Data) == "function", "Data type is not function in supplied ValueDataPair!")
    return RunService.Stepped:Connect(function()
        self:Add(VDP)
    end)
end

return TaskManager
