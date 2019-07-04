--[[ local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
Novarine:Initialise()

local Replication = Novarine:Get("Replication")
local Table = Novarine:Get("Table")

wait(1)
Table.PrintTable(Replication.ReplicatedData)
wait(7)
Table.PrintTable(Replication.ReplicatedData) ]]