local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")
--[[ local TableDiff = Novarine:Get("TableDiff")
local Static = Novarine:Get("Static") ]]
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local Replication = {
    ReplicatedData = {};
    Constructions = {};
    Unchanging = {};
    Modifiers = {};
    Changed = {};
    
    DataTimeout = 30; -- Timeout on waiting for replication data
    PauseAfterOperations = 3000;
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

function Replication.Constructions.Vector3()
    return Instance.new("Vector3Value")
end

function Replication.Constructions.CFrame()
    return Instance.new("CFrameValue")
end

function Replication.Constructions.Instance()
    return Instance.new("ObjectValue")
end

function Replication.Constructions.number()
    return Instance.new("NumberValue")
end

function Replication.Constructions.string()
    return Instance.new("StringValue")
end

function Replication.Constructions.boolean()
    return Instance.new("BoolValue")
end

function Replication:Init()
    local ReplicationFolder = ReplicatedStorage:FindFirstChild("ReplicationFolder") or Instance.new("Folder")
    ReplicationFolder.Name = "ReplicationFolder"
    ReplicationFolder.Parent = ReplicatedStorage

    --[[ local Diff = TableDiff.New()
    Diff.CurrentState = self.ReplicatedData
    self.Diff = Diff

    local Communication = Novarine:Get("Communication")
    Communication.MakeEvents({"ReplicationUpdate", "ReplicationSync"})

    local function FromPath(Path)
        local Result = {}
    
        for Item in Path:gmatch("[^@]+") do
            table.insert(Result, Item)
        end
    
        return Result
    end

    function Diff.Change(Path, _Old, New)
        Path = FromPath(Path)
        Communication.Broadcast("ReplicationUpdate", Path, New)
    end

    function Diff.Addition(Path, New)
        Path = FromPath(Path)
        Communication.Broadcast("ReplicationUpdate", Path, New)
    end

    function Diff.Removal(Path, _Old)
        Path = FromPath(Path)
        Communication.Broadcast("ReplicationUpdate", Path, nil)
    end

    Communication.BindRemoteEvent("ReplicationSync", function(Player)
        Communication.FireRemoteEvent("ReplicationSync", Player, self.ReplicatedData)
    end) ]]

    Async.Timer(1/60, function(Halt)
        if (ReplicationFolder.Parent) then
            self.UpdateCount = 0
            self:Update(ReplicationFolder, self.ReplicatedData, 0)
        else
            Halt()
        end
    end)
end

--[[
    Stops server mapping the whole tree
    each iteration, performance benefit.
]]
function Replication:SetUnchangingKeyAbsolute(Key)
    self.Unchanging[Key] = true
end

function Replication:Operation()
    self.UpdateCount += 1

    if (self.UpdateCount % Replication.PauseAfterOperations == 0) then
        Async.Wait(1/60)
    end
end

--[[ function Replication:Update()
    self.Diff:Update()
end ]]

--[[
    TODO: copy last, use ObjectEngine to find new values, etc.
]]
function Replication:Update(InstanceRoot, VirtualRoot, Depth)
    --[[
        Create or update values in the Instance
        tree to reflect the virtual tree.
    ]]
    for Key, Value in pairs(VirtualRoot) do
        Key = tostring(Key) -- Account for numerical indices
        -- TODO: numerical indices aren't removed, fix

        if (self.Unchanging[Key] and self.Changed[InstanceRoot.Name]) then
            continue
        end

        --[[ if (Depth == 1) then
            debug.profilebegin("NReplicate(" .. Key .. ")")
        end ]]

        local InstanceObject = InstanceRoot:FindFirstChild(Key)
        self:Operation()

        local TargetType = typeof(Value)

        local TargetModifier = self.Modifiers[TargetType]
        assert(TargetModifier, string.format("No modifier found for type '%s'!", TargetType))

        if InstanceObject then
            --[[
                Instance object exists, so update Instance
                if it's an endpoint or recurse deeper.
            ]]
            if (TargetType == "table") then
                self:Operation()
                self:Update(InstanceObject, Value, Depth + 1)
            else
                TargetModifier(InstanceObject, Value, Depth + 1)
                self:Operation()
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
                self:Operation()

                self:Update(Item, Value)
            else
                local TargetConstructor = self.Constructions[TargetType]
                assert(TargetConstructor, string.format("No constructor found for type '%s'!", TargetType))
                
                local Item = TargetModifier(TargetConstructor(), Value)
                Item.Name = Key
                Item.Parent = InstanceRoot
                self:Operation()
            end
        end

        self.Changed[Key] = true

        --[[ if (Depth == 1) then
            debug.profileend()
            --Async.Wait(1/60)
        end ]]
    end

    --[[
        Remove items which are in the instance tree but not
        in the virtual tree
    ]]
    for _, Value in pairs(InstanceRoot:GetChildren()) do
        self:Operation()

        local Name = Value.Name
        local Key = tonumber(Name) or Name -- Account for numerical indices

        if (self.Unchanging[Key] and self.Changed[InstanceRoot.Name]) then
            continue
        end
        
        if (VirtualRoot[Key] == nil and VirtualRoot[tostring(Key)] == nil) then
            Value:Destroy()
            self:Operation()
        end
    end
end

function Replication:WaitFor(...)
    local Args = {...}
    local Callback = Args[#Args]
    assert(type(Callback) == "function")
    Args[#Args] = nil

    Async.Wrap(function()
        Callback(Table.WaitForTimeout(self.DataTimeout, wait, Replication, "ReplicatedData", unpack(Args)))
    end)()
end

function Replication:WaitForYield(...)
    return Table.WaitForTimeout(self.DataTimeout, wait, Replication, "ReplicatedData", ...)
end

function Replication:Get(...)
    return Table.TryIndex(Replication, "ReplicatedData", ...)
end

return Replication