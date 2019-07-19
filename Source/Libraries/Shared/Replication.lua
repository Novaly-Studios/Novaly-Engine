local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ObjectEngineRaw = Novarine:Get("ObjectEngineRaw")
local RunService = Novarine:Get("RunService")
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Logging = Novarine:Get("Logging")
local Players = Novarine:Get("Players")

local Replication = {
    -- Public
    ReplicatedData = {}; -- The replicated data table
    MonitorInterval = 1/5; -- How frequently to run a diff on the structure
    -- Private
    Last = {};
    Handler = ObjectEngineRaw.New();
    Loaded = false;
}

function Replication:Init()
    if (RunService:IsClient()) then

        -- A value changes, server sends to client both the tree path and the corresponding value
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

        -- Client must initially synchronise data with server
        Communication.BindRemoteEvent("GetReplicatedData", function(Data)
            for Key, Value in pairs(Data) do
                Logging.Log(1, "Initial Data Replication Key: " .. Key)
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
        Logging.Log(1, "Replicated Data Update Path:")

        for _, Key in pairs(Path) do
            Logging.Log(2, Key)
        end

        for _, Player in pairs(Players:GetChildren()) do
            coroutine.wrap(function()
                Table.WaitFor(wait, Communication.TransmissionReady, Player.Name)
                while (not Communication.InvokeRemoteFunction("OnReplicate", Player, Path, Table.GetValueSequence(self.ReplicatedData, Path))) do
                    wait(1)
                    Logging.Log(string.format("Player '%s' did not accept data. Retrying...", Player.Name))
                end
            end)()
        end
    end

    -- Handle the following events
    Handler:SetOnCreate(SendUpdate)
    Handler:SetOnDestroy(SendUpdate)
    Handler:SetOnDifferent(SendUpdate)

    self.Loaded = true
end

--[[
    Using the ObjectEngine, check which values have changed
    within the tree structure, which have been created, which
    have been destroyed and which are the same. We don't
    need to know which are the same.
]]

function Replication:Diff()
    self.Handler:Diff(self.Last, self.ReplicatedData)
    self.Last = Table.Clone(self.ReplicatedData)
end

Novarine:Add("ReplicatedData", Replication.ReplicatedData)

return Replication
