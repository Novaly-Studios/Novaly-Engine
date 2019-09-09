local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local CollectionService = Novarine:Get("CollectionService")
local Logging = Novarine:Get("Logging")

local ObjectRegistry = {
    Mappings = {};
};

--[[
    Operates on a tag object and associates the
    result (hopefully an object) with the Instance.
]]
function ObjectRegistry:Register(Tag, Operator, Destructor)
    assert(Tag)

    local Mappings = self.Mappings

    local function HandleRemoving(Item)
        local Target = Mappings[Item]
        assert(Target)

        if Destructor then
            Destructor(Item, Target)
        else
            local DestroyMethod = Target.Destroy

            if DestroyMethod then
                Target:Destroy()
                Logging.Debug(0, string.format("Instance '%s' and associated object successfully destroyed.", Item:GetFullName()))
            else
                warn(string.format("The object '%s' has no Destroy method!", Item:GetFullName()))
            end
        end
    end

    local function HandleAdded(Item)
        Mappings[Item] = Operator(Item)

        Item.Parent.DescendantRemoving:Connect(function(Removing)
            if (Removing == Item) then
                HandleRemoving(Item)
            end
        end)
    end

    CollectionService:GetInstanceAddedSignal(Tag):Connect(HandleAdded)
    --CollectionService:GetInstanceRemovedSignal(Tag):Connect(HandleRemoving)

    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        HandleAdded(Item)
    end
end

--[[
    Gets the virtual object corresponding to the
    target game object, can use a descendant too.
]]
function ObjectRegistry:Get(Object)
    assert(Object)

    local Mappings = self.Mappings

    while (not Mappings[Object]) do
        Object = Object.Parent

        if (Object == nil) then
            return
        end
    end

    return Mappings[Object]
end

return ObjectRegistry