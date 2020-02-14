local CollectionService = game:GetService("CollectionService")
local CollectiveObjectRegistry = {
    InstanceToComponentCollection = {};
    ComponentToInstanceCollection = {};
    RegisteredObjects = {};
    Registered = {};

    Tests = {};
};

-- @todo Test for applying multiple components, since we just fixed that bug.
-- @todo Propogate component list upwards (in a separate array) for O(d) efficiency.

function CollectiveObjectRegistry:Register(Tag, Components, CreationHandler, DestructionHandler, AncestorTarget)

    if (self.Registered[Tag]) then
        warn(string.format("Tag already registered: '%s'", Tag))
        return
    end

    assert(Tag, "No tag given!")
    assert(Components, "No components given!")
    assert(#Components > 0, "Components list empty!")

    AncestorTarget = AncestorTarget or game
    CreationHandler = CreationHandler or self.StandardConstruct
    DestructionHandler = DestructionHandler or self.StandardDestroy

    local function SetComponentToInstaceCollectionValue(Object, Component, Value)
        local TargetComponentToInstanceCollection = self.ComponentToInstanceCollection[Component] or {}
        TargetComponentToInstanceCollection[Object] = Value
        self.ComponentToInstanceCollection[Component] = TargetComponentToInstanceCollection
    end

    local function HandleObjectCreation(Object)
        if (not AncestorTarget:IsAncestorOf(Object)) then
            return
        end

        local InstanceComponents = self.InstanceToComponentCollection[Object] or {}
        local HadValidComponent = false

        for _, Component in pairs(Components) do
            SetComponentToInstaceCollectionValue(Object, Component, Object)

            local ComponentObject = CreationHandler(Component, Object)

            if ComponentObject then
                ComponentObject._COMPONENT_REF = Component -- TODO: use BaseComponentRefs in singleton instead to assoc component object to class
                InstanceComponents[Component] = ComponentObject
                HadValidComponent = true
            end
        end

        if HadValidComponent then
            self.InstanceToComponentCollection[Object] = InstanceComponents
            self.RegisteredObjects[Object] = true
        end
    end

    local function HandleObjectDestruction(Object)
        if (not AncestorTarget:IsAncestorOf(Object)) then
            return
        end

        if (not self.RegisteredObjects[Object]) then
            return
        end

        local InstanceComponents = self.InstanceToComponentCollection[Object]
        assert(InstanceComponents, string.format("No instance components for object '%s'!", Object:GetFullName()))

        for _, ComponentObject in pairs(InstanceComponents) do
            SetComponentToInstaceCollectionValue(Object, ComponentObject._COMPONENT_REF, nil)
            DestructionHandler(ComponentObject)
        end

        self.InstanceToComponentCollection[Object] = nil
        self.RegisteredObjects[Object] = nil
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
    assert(Object, "No object given!")

    return self.InstanceToComponentCollection[Object]
end

function CollectiveObjectRegistry:GetComponent(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    return self:GetComponents(Object) and self:GetComponents(Object)[ComponentClass] or nil
end

function CollectiveObjectRegistry:WaitForComponent(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = self:GetComponent(Object, ComponentClass)

    while (not Got) do
        Got = self:GetComponent(Object, ComponentClass)
        wait()
    end

    return Got
end

function CollectiveObjectRegistry:WaitForComponentFromDescendant(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = self:GetComponentFromDescendant(Object, ComponentClass)

    while (not Got) do
        Got = self:GetComponentFromDescendant(Object, ComponentClass)
        wait()
    end

    return Got
end

function CollectiveObjectRegistry:GetInstances(ComponentClass)
    assert(ComponentClass, "No component class given!")

    return self.ComponentToInstanceCollection[ComponentClass]
end

function CollectiveObjectRegistry:GetComponentFromDescendant(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    while Object do
        local Component = self:GetComponent(Object, ComponentClass)

        if Component then
            return Component
        end

        Object = Object.Parent
    end
end

-- Constructors and destructors

function CollectiveObjectRegistry.StandardConstruct(Component, Object)
    assert(Component, "No component given!")
    assert(Object, "No object given!")

    return Component.New(Object)
end

function CollectiveObjectRegistry.ComponentConstruct(Component, Object)
    assert(Component, "No component given!")
    assert(Object, "No object given!")

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
        return
    end

    Component:Destroy()
end

-- Tests

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

function CollectiveObjectRegistry.Tests.TestGetComponentFromDescendant(Accept, Fail, OnCleanup)

    local function GetTestClass()
        local TestClass = {}
        TestClass.__index = TestClass

        function TestClass.New()
            return setmetatable({}, TestClass)
        end

        return TestClass
    end

    local TestTag = "Test5"
    local TestClass1 = GetTestClass()
    local TestClass2 = GetTestClass()

    CollectiveObjectRegistry:Register(TestTag, {TestClass1, TestClass2})

    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")

    local SubTestModel = Instance.new("Model")
    SubTestModel.Parent = TestModel

    local SubSubTestModel = Instance.new("Model")
    SubSubTestModel.Parent = TestModel

    OnCleanup(function()
        TestModel:Destroy()
    end)

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(TestModel, TestClass1)) then
        Fail("not inclusive for first object")
    end

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(TestModel, TestClass2)) then
        Fail("not inclusive for second object")
    end

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(SubTestModel, TestClass1)) then
        Fail("did not get first object in sub-model")
    end

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(SubSubTestModel, TestClass2)) then
        Fail("did not get second object in sub-model")
    end

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(SubSubTestModel, TestClass1)) then
        Fail("did not get first object in sub-sub-model")
    end

    if (not CollectiveObjectRegistry:GetComponentFromDescendant(SubTestModel, TestClass2)) then
        Fail("did not get second object in sub-sub-model")
    end

    Accept()
end

function CollectiveObjectRegistry.Tests.TestWaitForComponent(Accept, Fail, OnCleanup)
    local TestClass = {}
    TestClass.__index = TestClass

    function TestClass.New()
        return setmetatable({}, TestClass)
    end

    local TestTag = "Test6"
    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")

    OnCleanup(function()
        TestModel:Destroy()
    end)

    local GotComponent

    coroutine.wrap(function()
        wait(1)
        CollectiveObjectRegistry:Register(TestTag, {TestClass})
    end)()

    coroutine.wrap(function()
        GotComponent = CollectiveObjectRegistry:WaitForComponent(TestModel, TestClass)
    end)()

    if GotComponent then
        Fail("got immediately, should not happen")
    end

    wait(3)

    if (not GotComponent) then
        Fail("did not get component after 3 seconds")
    end

    Accept()
end

return CollectiveObjectRegistry