local CollectionService = game:GetService("CollectionService")

local ObjectRegistry = {
    Mappings = {};
};

--[[
    Operates on a tag object and associates the
    result (hopefully an object) with the Instance.
]]
function ObjectRegistry:Register(Tag, Operator)
    assert(Tag)

    local Mappings = self.Mappings

    local function Handle(Item)
        Mappings[Item] = Operator(Item)
    end

    CollectionService:GetInstanceAddedSignal(Tag):Connect(Handle)

    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        Handle(Item)
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