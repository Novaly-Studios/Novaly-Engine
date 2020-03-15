local CollectionService = game:GetService("CollectionService")

local InstanceReferenceCollection = {
    CreationHandlers = {};
    RemovalHandlers = {};
    Tests = {};
};

InstanceReferenceCollection.__index = InstanceReferenceCollection

function InstanceReferenceCollection.New(Root)
    return setmetatable({
        Root = Root;
        Instances = {};
    }, InstanceReferenceCollection)
end

local function SetCollectionValue(Value)
    return function(Self, Key, Item)
        local Instances = self.Instances
        Instances[Key] = Instances[Key] or {}
        Instances[Key][Item] = Value
    end
end

InstanceReferenceCollection.CreationHandlers.Tag = SetCollectionValue(true)
InstanceReferenceCollection.RemoveHandlers.Tag = SetCollectionValue(nil)
InstanceReferenceCollection.CreationHandlers.Name = SetCollectionValue(true)
InstanceReferenceCollection.RemoveHandlers.Name = SetCollectionValue(nil)

function InstanceReferenceCollection:RegisterTag(Tag)

    local CreationHandler = self.CreationHandlers.Tag
    local RemovalHandlers = self.RemovalHandlers.Tag

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Item)
        if (not self.Root:IsAncestorOf(Item)) then
            return
        end

        CreationHandler(Tag, Item)
    end)

    CollectionService:GetInstanceRemovedSignal(Tag):Connect(function(Item)
        RemovalHandlers(Item)
    end)

    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        Check(Item)
    end
end

function InstanceReferenceCollection:RegisterName(Name)
    local CreationHandler = self.CreationHandlers.Name
    local RemovalHandlers = self.RemovalHandlers.Name

    Root.DescendantAdded:Connect(function(Item)
        if (not self.Root:IsAncestorOf(Item)) then
            return
        end

        if (Item.Name ~= Name) then
            return
        end

        CreationHandler(Item.Name, Item)
    end)

    Root.DescendantRemoved:Connect(function(Item)
        if (Item.Name ~= Name) then
            return
        end

        RemovalHandler(Item.Name, Item)
    end)

    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        Check(Item)
    end
end

return InstanceReferenceCollection