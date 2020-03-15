local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local Replication = {
    ReplicatedData = {};
};

function Replication:Init()
    local ReplicationFolder = game:GetService("ReplicatedStorage"):WaitForChild("ReplicationFolder")

    Async.Wrap(function()
        while wait(1/20) do
            self:Update(ReplicationFolder, self.ReplicatedData)
        end
    end)()
end

function Replication:Update(InstanceRoot, VirtualRoot)
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
            if (Item:IsA("Folder")) then
                -- Recurse already existing tree
                self:Update(Item, VirtualRoot[Key])
            else
                -- Change already existing endpoint
                VirtualRoot[Key] = Item.Value
            end
        else
            --[[
                If it has children, it maps to a table and
                is not an end-point.
            ]]
            if (Item:IsA("Folder")) then
                local Virtual = {}
                VirtualRoot[Key] = Virtual
                -- Recurse to add next layers
                self:Update(Item, Virtual)
            else
                -- Else it's an endpoint and we can map the value
                VirtualRoot[Key] = Item.Value
            end
        end
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