--[[ local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
Novarine:Initialise()

local Replication = Novarine:Get("Replication")

Replication.ReplicatedData.Test = {
    A = 1;
    B = {
        C = "abc";
    };
}

repeat wait() until #Novarine:Get("Players"):GetChildren() > 0
wait(5)
Replication.ReplicatedData.Test.A = 20
Replication.ReplicatedData.Test.B.D = {
    E = {
        F = {
            G = 1908489;
        }
    }
} ]]