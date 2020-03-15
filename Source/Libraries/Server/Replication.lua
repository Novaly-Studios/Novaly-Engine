local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local Replication = {
    ReplicatedData = {};
    Constructions = {};
    Modifiers = {};
};

-- Changes an ObjectValue's value
-- May want more advanced modifiers for exotic types in future
local function StandardModifier(Item, Value)
    if (Item.Value ~= Value) then
        Item.Value = Value
    end

    return Item
end

Replication.Modifiers.Color3 = StandardModifier
Replication.Modifiers.Vector3 = StandardModifier
Replication.Modifiers.CFrame = StandardModifier
Replication.Modifiers.Instance = StandardModifier
Replication.Modifiers.boolean = StandardModifier
Replication.Modifiers.number = StandardModifier
Replication.Modifiers.string = StandardModifier
Replication.Modifiers.table = function() end

function Replication.Constructions.Color3()
    return Instance.new("Color3Value")
end

function Replication.Constructions:Vector3()
    return Instance.new("Vector3Value")
end

function Replication.Constructions:CFrame()
    return Instance.new("CFrameValue")
end

function Replication.Constructions:Instance()
    return Instance.new("ObjectValue")
end

function Replication.Constructions:number()
    return Instance.new("NumberValue")
end

function Replication.Constructions:string()
    return Instance.new("StringValue")
end

function Replication.Constructions:boolean()
    return Instance.new("BoolValue")
end

function Replication:Init()
    local ReplicationFolder = ReplicatedStorage:FindFirstChild("ReplicationFolder") or Instance.new("Folder")
    ReplicationFolder.Name = "ReplicationFolder"
    ReplicationFolder.Parent = ReplicatedStorage

    Async.Wrap(function()
        while true do
            if (ReplicationFolder.Parent) then
                self:Update(ReplicationFolder, self.ReplicatedData)
            else
                break
            end

            wait(1/5)
        end
    end)()
end

function Replication:Update(InstanceRoot, VirtualRoot)

    --[[
        Create or update values in the Instance
        tree to reflect the virtual tree.
    ]]
    for Key, Value in pairs(VirtualRoot) do
        Key = tostring(Key) -- Account for numerical indices
        -- TODO: numerical indices aren't removed, fix

        local InstanceObject = InstanceRoot:FindFirstChild(Key)
        local TargetType = typeof(Value)

        local TargetModifier = self.Modifiers[TargetType]
        assert(TargetModifier, string.format("No modifier found for type '%s'!", TargetType))

        if InstanceObject then
            --[[
                Instance object exists, so update Instance
                if it's an endpoint or recurse deeper.
            ]]
            if (TargetType == "table") then
                self:Update(InstanceObject, Value)
            else
                TargetModifier(InstanceObject, Value)
            end
        else
            --[[
                If it doesn't exist, create object if it
                is an end-point, or create folder and
                recurse deeper if it's a table.
            ]]
            if (TargetType == "table") then
                local Item = Instance.new("Folder", InstanceRoot)
                Item.Name = Key
                Item.Parent = InstanceRoot

                self:Update(Item, Value)
            else
                local TargetConstructor = self.Constructions[TargetType]
                assert(TargetConstructor, string.format("No constructor found for type '%s'!", TargetType))

                local Item = TargetModifier(TargetConstructor(), Value)
                Item.Name = Key
                Item.Parent = InstanceRoot
            end
        end
    end

    --[[
        Remove items which are in the instance tree but not
        in the virtual tree
    ]]
    for _, Value in pairs(InstanceRoot:GetChildren()) do
        local Key = (tonumber(Value.Name) or Value.Name) -- Account for numerical indices

        if (VirtualRoot[Key] == nil) then
            Value:Destroy()
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