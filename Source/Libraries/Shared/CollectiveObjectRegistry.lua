local CollectionService = game:GetService("CollectionService")
local CollectiveObjectRegistry = {
    InstanceToComponentCollection = {};
    ComponentToInstanceCollection = {};
    Registered = {};

    Tests = {};
    Warn = true;
};

function CollectiveObjectRegistry:Register(Tag, Components, CreationHandler, DestructionHandler)

    if (self.Registered[Tag]) then
        warn(string.format("Tag already registered: '%s'", Tag))
        return
    end

    CreationHandler = CreationHandler or self.StandardConstruct
    DestructionHandler = DestructionHandler or self.StandardDestroy

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

    self.Registered[Tag] = true
end

-- Information retrieval

function CollectiveObjectRegistry:GetComponents(Object)
    return self.InstanceToComponentCollection[Object]
end

function CollectiveObjectRegistry:GetComponent(Object, ComponentClass)
    return self:GetComponents(Object) and self:GetComponents(Object)[ComponentClass] or nil
end

function CollectiveObjectRegistry:GetInstances(ComponentClass)
    return self.ComponentToInstanceCollection[ComponentClass]
end

-- Constructors and destructors

function CollectiveObjectRegistry.StandardConstruct(Component, Object)
    return Component.New(Object)
end

function CollectiveObjectRegistry.ComponentConstruct(Component, Object)
    local Parent = Object.Parent
    local Settings = {}

    for _, Item in pairs(Object:GetChildren()) do
        assert(Item:IsA("BaseValue"), string.format("Item '%s' within component is not a Value!", Item:GetFullName()))
        Settings[Item.Name] = Item.Value
    end

    return Component.New(Parent, Settings)
end

function CollectiveObjectRegistry.StandardDestroy(Component)

    if (not Component.Destroy) then
        if (CollectiveObjectRegistry.Warn) then
            warn(string.format("Warning: no Destroy method found for '%s'.", tostring(Component)))
        end

        return
    end

    Component:Destroy()
end

-- Tests

function CollectiveObjectRegistry.Tests.Init()
    CollectiveObjectRegistry.Warn = false
end

function CollectiveObjectRegistry.Tests.Finish()
    CollectiveObjectRegistry.Warn = true
end

function CollectiveObjectRegistry.Tests.TestGetComponent(Accept, Fail, OnCleanup)

    local function GetTestClass()
        local TestClass = {}
        TestClass.__index = TestClass

        function TestClass.New()
            return setmetatable({}, TestClass)
        end

        return TestClass
    end

    local TestTag = "Test1"
    local TestClass1 = GetTestClass()
    local TestClass2 = GetTestClass()

    CollectiveObjectRegistry:Register(TestTag, {TestClass1, TestClass2})

    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")

    OnCleanup(function()
        TestModel:Destroy()
    end)

    if (not CollectiveObjectRegistry:GetComponent(TestModel, TestClass1)) then
        Fail("did not get first object")
    end

    if (not CollectiveObjectRegistry:GetComponent(TestModel, TestClass2)) then
        Fail("did not get second object")
    end

    Accept()
end

function CollectiveObjectRegistry.Tests.TestGetInstances(Accept, Fail, OnCleanup)

    local TestClass = {}
    TestClass.__index = TestClass

    function TestClass.New()
        return setmetatable({}, TestClass)
    end

    local TestTag = "Test2"

    CollectiveObjectRegistry:Register(TestTag, {TestClass})

    local TestModel1 = Instance.new("Model")
    CollectionService:AddTag(TestModel1, TestTag)
    TestModel1.Parent = game:GetService("Workspace")

    local TestModel2 = Instance.new("Model")
    CollectionService:AddTag(TestModel2, TestTag)
    TestModel2.Parent = game:GetService("Workspace")

    OnCleanup(function()
        TestModel1:Destroy()
        TestModel2:Destroy()
    end)

    local Instances = CollectiveObjectRegistry:GetInstances(TestClass)

    if (not Instances) then
        Fail("no Instances obtained")
    end

    local Mappings = {}

    for _, Value in pairs(Instances) do
        Mappings[Value] = true
    end

    if (not Mappings[TestModel1] or not Mappings[TestModel2]) then
        Fail("items are missing")
    end

    Accept()
end

function CollectiveObjectRegistry.Tests.TestGetInstancesCleansUp(Accept, Fail, OnCleanup)

    local TestClass = {}
    TestClass.__index = TestClass

    function TestClass.New()
        return setmetatable({}, TestClass)
    end

    local TestTag = "Test3"
    CollectiveObjectRegistry:Register(TestTag, {TestClass})

    local TestModel1 = Instance.new("Model")
    CollectionService:AddTag(TestModel1, TestTag)
    TestModel1.Parent = game:GetService("Workspace")

    local TestModel2 = Instance.new("Model")
    CollectionService:AddTag(TestModel2, TestTag)
    TestModel2.Parent = game:GetService("Workspace")

    TestModel1:Destroy()

    OnCleanup(function()
        TestModel2:Destroy()
    end)

    local Instances = CollectiveObjectRegistry:GetInstances(TestClass)
    local Mappings = {}

    for _, Value in pairs(Instances) do
        Mappings[Value] = true
    end

    if (Mappings[TestModel1]) then
        Fail("did not clean up")
    end

    if (not Mappings[TestModel2]) then
        Fail("model is missing")
    end

    Accept()
end

function CollectiveObjectRegistry.Tests.TestGetComponentCleansUp(Accept, Fail)

    local function GetTestClass()
        local TestClass = {}
        TestClass.__index = TestClass

        function TestClass.New()
            return setmetatable({}, TestClass)
        end

        return TestClass
    end

    local TestTag = "Test4"
    local TestClass1 = GetTestClass()
    local TestClass2 = GetTestClass()

    CollectiveObjectRegistry:Register(TestTag, {TestClass1, TestClass2})

    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")
    TestModel:Destroy()

    if (CollectiveObjectRegistry:GetComponent(TestModel, TestClass1)) then
        Fail("did not clean up for first item")
    end

    if (CollectiveObjectRegistry:GetComponent(TestModel, TestClass2)) then
        Fail("did not clean up for second item")
    end

    Accept()
end

return CollectiveObjectRegistry