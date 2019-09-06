local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ObjectEngineRaw = Novarine:Get("ObjectEngineRaw")
local RunService = Novarine:Get("RunService")
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Event= Novarine:Get("Event")
local Logging = Novarine:Get("Logging")
local Players = Novarine:Get("Players")
local CustomEnum = Novarine:Get("CustomEnum")

local Replication = {
    Last = {};
    ReplicatedData = {};
    MonitorInterval = 1/5;
    Handler = ObjectEngineRaw.New();
    Loaded = false;
}

function Replication:Init()
    CustomEnum:NewCollection("ReplicationState", {
        "Change";
        "Create";
        "Destroy";
    })

    if (RunService:IsClient()) then

        -- Bound function specification: (Path, NewValue, OldValue, ReplicationStateEnum)
        self.OnUpdate = Event.New()

        Communication.BindRemoteFunction("OnReplicate", function(Path, Value, State)

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

            self.OnUpdate:Fire(Path, Last[Path[#Path]], Value, State)

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
            Communication.Broadcast("GetDataWhole", Replication.ReplicatedData.PlayerData or {})
        end
    end)()

    Communication.BindRemoteEvent("GetReplicatedData", function(Player)
        Communication.FireRemoteEvent("GetReplicatedData", Player, self.ReplicatedData)
    end)

    local Handler = self.Handler

    -- TODO: record paths we've sent the player and assume the client has cached them so we don't resend the whole path repetitively
    -- Maybe have client receive path ID, then send request to server for path if they don't know of that path
    local function SendUpdate(Path, State)
        -- Send modified path and new value to player
        for _, Player in pairs(Players:GetChildren()) do
            coroutine.wrap(function()
                -- Wait until player has established that they will accept data
                Table.WaitFor(wait, Communication.TransmissionReady, Player.Name)

                -- Keep trying to resend so long as player exists
                while (Player and Player.Parent and not Communication.InvokeRemoteFunction("OnReplicate", Player, Path, Table.GetValueSequence(self.ReplicatedData, Path), State)) do
                    wait(1)
                    Logging.Debug(string.format("Player '%s' did not accept data. Retrying...", Player.Name))
                end
            end)()
        end
    end

    -- When changes are detected, call SendUpate
    Handler:SetOnCreate(function(_, Path)
        SendUpdate(Path, CustomEnum.ReplicationState.Create)
    end)

    Handler:SetOnDestroy(function(_, Path)
        SendUpdate(Path, CustomEnum.ReplicationState.Destroy)
    end)

    Handler:SetOnDifferent(function(_, Path)
        SendUpdate(Path, CustomEnum.ReplicationState.Change)
    end)

    self.Loaded = true
end

function Replication:Diff()
    self.Handler:Diff(self.Last, self.ReplicatedData)
    self.Last = Table.Clone(self.ReplicatedData)
end

Novarine:Add("ReplicatedData", Replication.ReplicatedData)

return Replication