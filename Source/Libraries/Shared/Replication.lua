local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ObjectEngineRaw = Novarine:Get("ObjectEngineRaw")
local RunService = Novarine:Get("RunService")
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Logging = Novarine:Get("Logging")
local Players = Novarine:Get("Players")

local Replication = {
    Last = {};
    ReplicatedData = {};
    MonitorInterval = 1/5;
    Handler = ObjectEngineRaw.New();
    Loaded = false;
}

function Replication:Init()
    if (RunService:IsClient()) then
        Communication.BindRemoteFunction("OnReplicate", function(Path, Value)

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
            return true
        end)

        Communication.BindRemoteEvent("GetReplicatedData", function(Data)
            for Key, Value in pairs(Data) do
                Logging.Debug(1, "Initial Data Replication Key: " .. Key)
                self.ReplicatedData[Key] = Value
            end
        end)
        Communication.FireRemoteEvent("GetReplicatedData")

        self.Loaded = true

        return
    end

    -- On Server
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
        Logging.Debug(1, "Replicated Data Update Path:")

        for _, Key in pairs(Path) do
            Logging.Debug(2, Key)
        end

        for _, Player in pairs(Players:GetChildren()) do
            coroutine.wrap(function()
                Table.WaitFor(wait, Communication.TransmissionReady, Player.Name)
                while (not Communication.InvokeRemoteFunction("OnReplicate", Player, Path, Table.GetValueSequence(self.ReplicatedData, Path))) do
                    wait(1)
                    Logging.Debug(string.format("Player '%s' did not accept data. Retrying...", Player.Name))
                end
            end)()
        end
    end

    Handler:SetOnCreate(SendUpdate)
    Handler:SetOnDestroy(SendUpdate)
    Handler:SetOnDifferent(SendUpdate)

    self.Loaded = true
end

function Replication:Diff()
    self.Handler:Diff(self.Last, self.ReplicatedData)
    self.Last = Table.Clone(self.ReplicatedData)
end

Novarine:Add("ReplicatedData", Replication.ReplicatedData)

return Replication