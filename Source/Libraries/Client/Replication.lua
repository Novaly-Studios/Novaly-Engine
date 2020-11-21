local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Communication = Novarine:Get("Communication")
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")
local Core = Novarine:Get("Core")

local Replication = {
    ReplicatedData = {};
    ChangedEventsUpwardsPropogate = {};
    ChangedEvents = {};
};

function Replication:Init()
    Communication.BindRemoteEvent("ReplicationSync", function(Data)
        -- Deep copy since we don't want to change while recursing
        local function DeepCopyWithNumericalKeys(Item)
            local Result = {}
        
            for Key, Value in pairs(Item) do
                Key = tonumber(Key) or Key

                if (type(Value) == "table") then
                    Result[Key] = DeepCopyWithNumericalKeys(Value)
                    continue
                end

                Result[Key] = Value
            end
        
            return Result
        end

        for Key, Value in pairs(DeepCopyWithNumericalKeys(Data)) do
            self.ReplicatedData[Key] = Value
        end
    end)

    --[[
        The server has sent a path in the table to update,
        and a corresponding value. This will index down the
        path, set the value, and fire any events associated
        with that path changing.
    ]]
    Communication.BindRemoteEvent("ReplicationUpdate", function(Path, Value)
        debug.profilebegin("NReplicate(" .. Path[#Path] .. ")")

        -- Set value corresponding to the given path
        self:SetReplicationValue(Path, Value)

        --[[ -- Fire singular events
        local SingularEvent = self.ChangedEvents[table.concat(Path, ".")]

        if SingularEvent then
            SingularEvent:Fire(Value)
        end

        -- Fire upwards propogated events (i.e. to all tables which
        -- contain this value directly or in an indirect sub-table)
        if (Core.Count(self.ChangedEventsUpwardsPropogate) == 0) then
            debug.profileend()
            return
        end

        local RunningPath = {}
        local Updates = {}

        for Index = 1, #Path do
            table.insert(RunningPath, Path[Index])

            local PropogatedEvent = self.ChangedEventsUpwardsPropogate[table.concat(RunningPath, ".")]

            if PropogatedEvent then
                table.insert(Updates, PropogatedEvent)
            end
        end

        -- "Propogate upwards" pattern, starting with the exact thing which was changed
        for Index = #Updates, 1, -1 do
            Updates[Index]:Fire(Value)
        end

        -- TODO: top level GetChangedEvent({""}) trigger
        debug.profileend() ]]
    end)

    Communication.FireRemoteEvent("ReplicationSync")

    local Player = Novarine:Get("Player")

    Player.Chatted:Connect(function(Msg)
        if (Msg == "data") then
            Table.Print(self.ReplicatedData)
        end
    end)
end

function Replication:GetChangedEventUpwardsPropogate(Path)
    local PathString = table.concat(Path, ".")
    local Target = self.ChangedEventsUpwardsPropogate[PathString]

    if (not Target) then
        Target = Instance.new("BindableEvent")
        self.ChangedEventsUpwardsPropogate[PathString] = Target
    end

    return Target
end

function Replication:SetReplicationValue(Path, Value)
    local Last = self.ReplicatedData

    for Index = 1, #Path - 1 do
        local Key = Path[Index]
        Key = tonumber(Key) or Key

        local Next = Last[Key]

        if (Next == nil or type(Next) ~= "table") then
            Next = {}
            Last[Key] = Next
        end

        Last = Next
    end
    
    local LastKey = Path[#Path]
    LastKey = tonumber(LastKey) or LastKey
    Last[LastKey] = Value
end

function Replication:SetUnchangingKeyAbsolute(_Key)
    -- Deprecated
end

function Replication:WaitFor(...)
    local Args = {...}
    local Callback = Args[#Args]
    assert(type(Callback) == "function")
    Args[#Args] = nil

    Async.Wrap(function()
        Callback(Table.WaitFor(wait, Replication, "ReplicatedData", unpack(Args)))
    end)()
end

function Replication:WaitForYield(...)
    return Table.WaitFor(wait, Replication, "ReplicatedData", ...)
end

function Replication:Get(...)
    return Table.TryIndex(Replication, "ReplicatedData", ...)
end

return Replication