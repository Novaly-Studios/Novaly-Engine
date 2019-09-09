local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ObjectEngineRaw = Novarine:Get("ObjectEngineRaw")
local RunService = Novarine:Get("RunService")
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Event= Novarine:Get("Event")
local Logging = Novarine:Get("Logging")
local Players = Novarine:Get("Players")
local CustomEnum = Novarine:Get("CustomEnum")
local Static = Novarine:Get("Static")

local Replication = {
    Last = {};
    ReplicatedData = {};
    MonitorInterval = 1/5;
    Handler = ObjectEngineRaw.New();
    Loaded = false;
    ReplicationReady = {};
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

            if (not self.Loaded) then
                Logging.Debug("Received replicate package but not loaded, waiting for loaded...")
            end

            while (not self.Loaded) do
                wait(0.05)
            end

            local Last = self.ReplicatedData

            for Index = 1, #Path - 1 do
                local Key = Path[Index]
                local Next = Last[Key]

                if (Value == nil and not Next) then
                    -- Setting things deeper in the path to nil after container is already nullified can cause inconsistency
                    -- as it creates tables along the way. Thus, since we are not setting anything, we don't need to construct
                    -- as we go along
                    break
                elseif (not Next) then
                    -- Construct tree as we go along based on path
                    -- All points except the endpoint will require a table created
                    Next = {}
                    Last[Key] = Next
                end

                Last = Next
            end

            self.OnUpdate:Fire(Path, Last[Path[#Path]], Value, State)

            if (type(Value) ~= "userdata") then
                print("-------------------------------")
                Table.PrintTable(Path)
                print("Val = ", Value)
                print("-------------------------------")
            end

            Last[Path[#Path]] = Value
            return true
        end)

        Communication.BindRemoteEvent("GetReplicatedData", function(Data, Finished)
            Logging.Debug(0, "Got replicated data.")

            if Finished then
                self.Loaded = true
                Logging.Debug(0, "Loaded replicated data!")
                print("Got -->>")
                Table.PrintTable(self.ReplicatedData)
                print("<<--")
                return
            end

            Logging.Debug(0, "Verifying replicated data...")

            for Key in pairs(self.ReplicatedData) do
                self.ReplicatedData[Key] = nil
            end

            for Key, Value in pairs(Data) do
                self.ReplicatedData[Key] = Value
            end

            Communication.FireRemoteEvent("GetReplicatedData", self.ReplicatedData)
        end)

        Logging.Debug(0, "Send for replicated data...")
        Communication.FireRemoteEvent("GetReplicatedData")
        return
    end

    -- On Server
    coroutine.wrap(function()
        while wait(self.MonitorInterval) do
            self:Diff()
            Communication.Broadcast("GetDataWhole", Replication.ReplicatedData.PlayerData or {})
        end
    end)()

    Communication.BindRemoteEvent("GetReplicatedData", function(Player, Compare)

        if Compare then
            if (Table.Equals(self.ReplicatedData, Compare)) then
                Logging.Debug(0, "Player data fully synced.")
                Communication.FireRemoteEvent("GetReplicatedData", Player, nil, true)
                self.ReplicationReady[Player] = true
                return
            else
                Logging.Debug(0, string.format("Player data maligned for player %s, retrying...", Player.Name))
            end
        end

        print("Sent to " .. Player.Name .. " ----->")
        Table.PrintTable(self.ReplicatedData)
        print("<-----")
        Communication.FireRemoteEvent("GetReplicatedData", Player, self.ReplicatedData)
    end)

    local Handler = self.Handler

    local function IsMixed(Table) -- Determines if a table has both numerical and (hash or ref) keys
        local Types = {}
        local Count = 0

        for Key, Value in pairs(Table) do
            local KeyType = type(Key)

            if (not Types[KeyType]) then
                Count = Count + 1
                Types[KeyType] = true
            end

            if (Types["number"] and Count > 1) then
                return true
            end

            if (type(Value) == "table") then
                if (IsMixed(Value)) then
                    return true
                end
            end
        end

        return false
    end

    -- TODO: record paths we've sent the player and assume the client has cached them so we don't resend the whole path repetitively
    -- Maybe have client receive path ID, then send request to server for path if they don't know of that path
    local function SendUpdate(Path, State)
        -- Send modified path and new value to player
        for _, Player in pairs(Players:GetChildren()) do
            coroutine.wrap(function()
                -- Index the table
                local Value = Table.TryIndex(self.ReplicatedData, unpack(Path)) -- TryIndex because some values can be nullified too

                if (type(Value) == "table" and --[[ Table. ]]IsMixed(Value)) then
                    warn(string.format("FATAL: TABLE HAS MIXED KEYS // ReplicatedData/%s", Static.Reduce1D(Path, function(Current, Append)
                        return Current .. "/" .. Append
                    end, "")))
                else
                    print("Waiting for ok to send")
                    -- Wait until player has established that they will accept data
                    Table.WaitFor(wait, self.ReplicationReady, Player)
                    print("OK to send!")

                    -- Keep trying to resend so long as player exists
                    while (Player and Player.Parent and not Communication.InvokeRemoteFunction("OnReplicate", Player, Path, Value, State)) do
                        wait(1)
                        Logging.Debug(string.format("Player '%s' did not accept data. Retrying...", Player.Name))
                    end
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

function Replication:WaitFor(...)
    local Args = {...}
    local Callback = Args[#Args]
    assert(type(Callback) == "function")
    Args[#Args] = nil

    coroutine.wrap(function()
        Callback(Table.WaitFor(wait, Replication, "ReplicatedData", unpack(Args)))
    end)()
end

function Replication:WaitForYield(...)
    local Data = Table.WaitFor(wait, Replication, "ReplicatedData", ...)
    return Data
end

function Replication:Get(...)
    return Table.TryIndex(Replication, "ReplicatedData", ...)
end

function Replication:Diff()
    self.Handler:Diff(self.Last, self.ReplicatedData)
    self.Last = Table.Clone(self.ReplicatedData)
end

Novarine:Add("ReplicatedData", Replication.ReplicatedData)

return Replication