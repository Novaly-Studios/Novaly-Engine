local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")

local CollectionService = game:GetService("CollectionService")
local CollectiveObjectRegistry = {
    InstanceToComponentCollection = {}; -- Instance -> {Component1 = true, Component2 = true, ...}
    ComponentToInstanceCollection = {}; -- Component Class -> {Component1 = Instance1, Component2 = Instance2, ...}
    RegisteredObjects = {};
    Registered = {};

    Tests = {};
};

--[[ coroutine.wrap(function()
    if (game:GetService("RunService"):IsClient()) then
        return
    end

    while wait(60) do
        local Unparented1 = 0

        for Instance in pairs(CollectiveObjectRegistry.InstanceToComponentCollection) do
            if (not Instance.Parent) then
                Unparented1 = Unparented1 + 1
            end
        end

        print("Unparented1: " .. Unparented1)

        local Unparented2 = 0

        for _, Instances in pairs(CollectiveObjectRegistry.ComponentToInstanceCollection) do
            for _, Instance in pairs(Instances) do
                if (not Instance.Parent) then
                    Unparented2 = Unparented2 + 1
                end
            end
        end

        print("Unparented2: " .. Unparented2)
    end
end)() ]]

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

    local function SetComponentToInstanceCollectionValue(Object, Component, Value)
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

        for Index = 1, #Components do -- Maintain order
            local Component = Components[Index]
            assert(Component, "No component found at index for " .. Tag .. "!")
            SetComponentToInstanceCollectionValue(Object, Component, Object)

            if (InstanceComponents[Component]) then
                --warn("Instance component already assigned: " .. tostring(Component))
                continue
            end

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
            SetComponentToInstanceCollectionValue(Object, ComponentObject._COMPONENT_REF, nil)
            Async.Wrap(DestructionHandler)(ComponentObject)
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

-- Misc

function CollectiveObjectRegistry:UpFlowExplicitComponent(Origin, ComponentIdentity, Data)
    assert(Origin, "No origin given.")
    assert(Origin.Parent, "Unparented object passed.")

    while (Origin.Parent) do

        local Components = self.InstanceToComponentCollection[Origin]

        if Components then
            local Target = Components[ComponentIdentity]

            if Target then
                assert(Target.ReceiveFlow, "No method defined to receive information.")
                Target:ReceiveFlow(Data)
            end
        end

        Origin = Origin.Parent
    end
end

function CollectiveObjectRegistry:UpFlow(Origin, Data)
    assert(Origin, "No origin given.")
    assert(Origin.Parent, "Unparented object passed.")

    while (Origin.Parent) do

        local Components = self.InstanceToComponentCollection[Origin]

        if Components then
            for _, Target in pairs(Components) do
                assert(Target.ReceiveFlow, "No method defined to receive information.")
                Target:ReceiveFlow(Data)
            end
        end

        Origin = Origin.Parent
    end
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
    local Trace = debug.traceback()
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = self:GetComponent(Object, ComponentClass)

    Async.Spawn(function()
        wait(5)

        if (Got == nil) then
            warn(string.format("Potential infinite wait on (\n    Object = '%s';\n    Component = '%s'\n)\n%s",
                                Object:GetFullName(), tostring(ComponentClass), Trace))
        end
    end)

    while (Got == nil) do
        Got = self:GetComponent(Object, ComponentClass)
        wait()
    end

    return Got
end

function CollectiveObjectRegistry:WaitForComponentFromDescendant(Object, ComponentClass)
    local Trace = debug.traceback()
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = self:GetComponentFromDescendant(Object, ComponentClass)

    Async.Spawn(function()
        wait(5)

        if (Got == nil) then
            warn(string.format("Potential infinite wait on (\n    Object = '%s';\n    Component = '%s'\n)\n%s",
                                Object:GetFullName(), tostring(ComponentClass), Trace))
        end
    end)

    while (Got == nil) do
        Got = self:GetComponentFromDescendant(Object, ComponentClass)
        wait()
    end

    return Got
end

function CollectiveObjectRegistry:GetInstances(ComponentClass)
    assert(ComponentClass, "No component class given!")

    return self.ComponentToInstanceCollection[ComponentClass] or {}
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

function CollectiveObjectRegistry.AsyncInitial(Component, InstanceObject)
    local Object = Component.New(InstanceObject)

    Async.Wrap(function()
        Object:Initial()
    end)()

    return Object
end

function CollectiveObjectRegistry.SyncInitial(Component, InstanceObject)
    local Object = Component.New(InstanceObject)
    Object:Initial()
    return Object
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

--[[ function CollectiveObjectRegistry.Tests.TestUpFlow(Accept, Fail, OnCleanup)

    local function GetTestClass()
        local TestClass = {}
        TestClass.__index = TestClass

        function TestClass.New()
            return setmetatable({}, TestClass)
        end

        function TestClass:ReceiveFlow(Data)
            self.Callback(Data)
        end

        return TestClass
    end

    local function TestModel(Parent, Tag)
        local Model = Instance.new("Model")
        CollectionService:AddTag(Model, Tag)
        Model.Parent = Parent
        return Model
    end

    local TestModel1 = TestModel(game:GetService("Workspace"), "Test7")
    local TestModel2 = TestModel(TestModel1, "Test8")
    local TestModel3 = TestModel(TestModel2, "Test9")

    local TestClass1 = GetTestClass()
    local TestClass2 = GetTestClass()

    OnCleanup(function()
        TestModel1:Destroy()
        TestModel2:Destroy()
        TestModel3:Destroy()
    end)

    CollectiveObjectRegistry:Register(, {TestClass1, TestClass2})

    local DataTC1 = {}
    local DataTC2 = {}

    local DataFoundTC1 = {}
    local DataFoundTC2 = {}

    TestClass1.Callback = function(Data)
        DataFoundTC1[Data] = true
    end

    TestClass2.Callback = function(Data)
        DataFoundTC2[Data] = true
    end

    CollectiveObjectRegistry:UpFlow(CollectiveObjectRegistry:GetComponent(TestModel3), DataTC1)
    CollectiveObjectRegistry:UpFlow(CollectiveObjectRegistry:GetComponent(TestModel3), DataTC1)

    if (DataFoundTC1[DataTC1] and DataFoundTC2[DataTC1] and DataFoundTC2[DataTC2]) then
        Accept()
        return
    end

    Fail("invalid data principles")
end ]]

-- TODO: create incremental ID for every object
-- and add object to ID queue. (Server)
-- Then claim data from replication.

return CollectiveObjectRegistry