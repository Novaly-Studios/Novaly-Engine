local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local Replication = {
    ReplicatedData = {};
    LoggedTime = 0;
    LoggedCount = 0;
    Unchanging = {};
    Downloaded = {};
};

function Replication:Init()
    local ReplicationFolder = game:GetService("ReplicatedStorage"):WaitForChild("ReplicationFolder")

    Async.Wrap(function()
        while (Async.Wait(1/20)) do
            self:Update(ReplicationFolder, self.ReplicatedData, 0)
        end
    end)()
end

--[[
    Stops client re-searching the whole tree
    each iteration, performance benefit.
]]
function Replication:SetUnchangingKeyAbsolute(Key)
    self.Unchanging[Key] = true
end

function Replication:Update(InstanceRoot, VirtualRoot, Level)

    if (self.Unchanging[InstanceRoot.Name] and self.Downloaded[InstanceRoot.Name]) then
        return
    end

    if (Level == 2) then
        debug.profilebegin("NReplicate(" .. InstanceRoot.Name .. ")")
    end

    --[[
        Remove items which are in the virtual tree
        but not in the Instance tree.
    ]]
    for Key in pairs(VirtualRoot) do
        Key = tostring(Key) -- Account for numerical indices

        if (not InstanceRoot:FindFirstChild(Key)) then
            VirtualRoot[Key] = nil
        end
    end

    --[[
        Update the virtual tree to reflect the Instance
        tree.
    ]]
    for _, Item in pairs(InstanceRoot:GetChildren()) do
        local Key = (tonumber(Item.Name) or Item.Name) -- Account for numerical indices

        if (VirtualRoot[Key]) then
            if (Item.ClassName == "Folder") then
                -- Recurse already existing tree
                self:Update(Item, VirtualRoot[Key], Level + 1)
            else
                -- Change already existing endpoint
                VirtualRoot[Key] = Item.Value
            end
        else
            --[[
                If it has children, it maps to a table and
                is not an end-point.
            ]]
            if (Item.ClassName == "Folder") then
                local Virtual = {}
                VirtualRoot[Key] = Virtual
                -- Recurse to add next layers
                self:Update(Item, Virtual, Level + 1)
            else
                -- Else it's an endpoint and we can map the value
                VirtualRoot[Key] = Item.Value
            end
        end
    end

    self.Downloaded[InstanceRoot.Name] = true

    if (Level == 2) then
        Async.Wait(1/60)
    end
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