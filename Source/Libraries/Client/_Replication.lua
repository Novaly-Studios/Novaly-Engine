local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Static = Novarine:Get("Static")
local Table = Novarine:Get("Table")
local Async = Novarine:Get("Async")

local Replication = {
    LoggedTime = 0;
    LoggedCount = 0;
    Unchanging = {};
    Downloaded = {};
    ReplicatedData = {};
    PathCache = setmetatable({}, {__mode = "k"}); -- Cache of value paths so they don't get re-indexed upward repetitively
};

function Replication:Init()
    local ReplicationFolder = game:GetService("ReplicatedStorage"):WaitForChild("ReplicationFolder")
    self.ReplicationFolder = ReplicationFolder

    -- Perform initial sync 
    local function HandleInstanceNode(Object)
        if (Object:IsA("ValueBase")) then
            local ChangeConnection = Object:GetPropertyChangedSignal("Value"):Connect(function()
                self:ValueHasChanged(Object)
            end)

            local Connection; Connection = Object.AncestryChanged:Connect(function(_, Parent)
                if (Parent ~= nil) then
                    return
                end

                -- Was deleted
                self:NodeHasNegated(Object)
                ChangeConnection:Disconnect()
                Connection:Disconnect()
            end)

            self:NodeHasSpawned(Object, Object.Value)
        elseif (Object:IsA("Folder")) then
            self:NodeHasSpawned(Object, {})
        end
    end

    for _, Value in pairs(ReplicationFolder:GetDescendants()) do
        HandleInstanceNode(Value)
    end

    -- Handle changing values
    ReplicationFolder.DescendantAdded:Connect(HandleInstanceNode)

    --[[ ReplicationFolder.DescendantRemoving:Connect(function(Object)
        self:NodeHasNegated(Object)
    end) ]]
end

function Replication:GetPath(Object)
    local PathCache = self.PathCache

    if (PathCache[Object]) then
        -- Repetitively indexing the Instance's parents takes a lot of time,
        -- so cache each Instance to its path in the internal map. Doesn't
        -- need to account for descendant changes since nothing moves in the tree.
        return PathCache[Object]
    end

    local Path = {}
    local OriginalObject = Object

    while (Object ~= self.ReplicationFolder) do
        table.insert(Path, Object.Name)
        Object = Object.Parent
    end

    local Result = Static.Reverse(Path)
    PathCache[OriginalObject] = Result
    return Result
end

--[[
    Constructs a table path (e.g. if it doesn't already exist)
    in replicated data with a certain path including transformed
    string to numeric keys if applicable.
]]
function Replication:SetPathValue(Path, Value)
    local Replicated = self.ReplicatedData

    -- Find object containing the value
    for Index = 1, #Path - 1 do
        local Key = Path[Index]
        Key = tonumber(Key) or Key

        local SubObject = Replicated[Key]

        -- If this down the path doesn't exist, construct object
        if (SubObject == nil) then
            local Temp = {}
            Replicated[Key] = Temp
            SubObject = Temp
        end

        Replicated = SubObject
    end

    local Final = Path[#Path]
    Final = tonumber(Final) or Final
    Replicated[Final] = Value
end

function Replication:ValueHasChanged(Object)
    local Path = self:GetPath(Object)
    local Value = Object.Value

    self:SetPathValue(Path, Value)
end

function Replication:NodeHasNegated(Object)
    self:SetPathValue(self:GetPath(Object), nil)
end

function Replication:NodeHasSpawned(Object, Value)
    self:SetPathValue(self:GetPath(Object), Value)
end

function Replication:SetUnchangingKeyAbsolute(Key)
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