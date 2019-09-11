--[[ local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
Novarine:Init()

local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")

coroutine.wrap(function()
    while wait(1) do
        Table.PrintTable(Replication.ReplicatedData)
    end
end)() ]]