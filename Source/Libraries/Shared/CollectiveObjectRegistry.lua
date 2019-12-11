local CollectionService = game:GetService("CollectionService")
local CollectiveObjectRegistry = {
    InstanceToComponentCollection = {};
    ComponentToInstanceCollection = {};

};

function CollectiveObjectRegistry:Register(Tag, Components, CreationHandler, DestructionHandler)

    CreationHandler = CreationHandler or function(Component, Object)
        return Component.New(Object)
    end

    DestructionHandler = DestructionHandler or function(Component)
        Component:Destroy()
    end

    local function SetComponentToInstaceCollectionValue(Object, Component, Value)
        local TargetComponentToInstanceCollection = self.ComponentToInstanceCollection[Component] or {}
        TargetComponentToInstanceCollection[Object] = Value
        self.ComponentToInstanceCollection[Component] = TargetComponentToInstanceCollection
    end

    local function HandleObjectCreation(Object)
        local InstanceComponents = {}
        self.InstanceToComponentCollection[Object] = InstanceComponents

        for _, Component in pairs(Components) do
            SetComponentToInstaceCollectionValue(Object, Component, Object)

            local ComponentObject = CreationHandler(Component, Object)
            ComponentObject._COMPONENT_REF = Component -- TODO: use BaseComponentRefs in singleton instead to assoc component object to class
            InstanceComponents[Component] = ComponentObject
        end
    end

    local function HandleObjectDestruction(Object)
        local InstanceComponents = self.InstanceToComponentCollection[Object]

        for _, ComponentObject in pairs(InstanceComponents) do
            SetComponentToInstaceCollectionValue(Object, ComponentObject._COMPONENT_REF, nil)
            DestructionHandler(ComponentObject)
        end

        self.InstanceToComponentCollection[Object] = nil
    end

    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        HandleObjectCreation(Item)
    end

    CollectionService:GetInstanceAddedSignal(Tag):Connect(HandleObjectCreation)
    CollectionService:GetInstanceRemovedSignal(Tag):Connect(HandleObjectDestruction)
end

function CollectiveObjectRegistry:GetComponents(Object)
    return self.InstanceToComponentCollection[Object]
end

function CollectiveObjectRegistry:GetComponent(Object, ComponentClass)
    return self.InstanceToComponentCollection[Object][ComponentClass]
end

function CollectiveObjectRegistry:GetInstances(ComponentClass)
    return self.ComponentToInstanceCollection[ComponentClass]
end

return CollectiveObjectRegistry