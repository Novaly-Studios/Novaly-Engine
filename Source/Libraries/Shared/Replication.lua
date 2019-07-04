local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ObjectEngineRaw = Novarine:Get("ObjectEngineRaw")
local RunService = Novarine:Get("RunService")
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Logging = Novarine:Get("Logging")

local Replication = {
    Last = {};
    ReplicatedData = {};
    MonitorInterval = 1/5;
    Handler = ObjectEngineRaw.New();
}

function Replication:Init()
    if (RunService:IsClient()) then
        Communication.BindRemoteEvent("OnReplicate", function(Path, Value)
            local Last = self.ReplicatedData

            for Index = 1, #Path - 1 do
                local Key = Path[Index]
                local Next = Last[Key]

                if (not Next) then
                    Next = {}
                    Last[Key] = Next
                end

                Last = Next
            end

            Last[Path[#Path]] = Value
        end)

        Communication.BindRemoteEvent("GetReplicatedData", function(Data)
            for Key, Value in pairs(Data) do
                self.ReplicatedData[Key] = Value
            end
        end)
        Communication.FireRemoteEvent("GetReplicatedData")

        return
    end

    coroutine.wrap(function()
        while wait(self.MonitorInterval) do
            self:Diff()
        end
    end)()

    Communication.BindRemoteEvent("GetReplicatedData", function(Player)
        Communication.FireRemoteEvent("GetReplicatedData", Player, self.ReplicatedData)
    end)

    local Handler = self.Handler

    local function SendUpdate(_, Path)
        Logging.Log(1, "Replicated Data Update Path:")

        for _, Key in pairs(Path) do
            Logging.Log(2, Key)
        end

        Communication.Broadcast("OnReplicate", Path, Table.GetValueSequence(self.ReplicatedData, Path))
    end

    Handler:SetOnCreate(SendUpdate)
    Handler:SetOnDestroy(SendUpdate)
    Handler:SetOnDifferent(SendUpdate)
end

function Replication:Diff()
    self.Handler:Diff(self.Last, self.ReplicatedData)
    self.Last = Table.Clone(self.ReplicatedData)
end

Novarine:Add("ReplicatedData", Replication.ReplicatedData)

return Replication