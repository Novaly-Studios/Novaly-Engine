local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")

local CollectionService = game:GetService("CollectionService")
local CollectiveObjectRegistry = {
    InstanceToComponentCollection = {}; -- InstanceToComponentCollection = {Instance -> {ComponentInstance1 = true, ComponentInstance2 = true, ...}, ...}
    ComponentToInstanceCollection = {}; -- ComponentToInstanceCollection = {ComponentClass -> {Instance1 = Instance1, Instance2 = Instance2, ...}, ...}
    ComponentClassToComponentCollection = {}; -- ComponentClassToComponentCollection = {ComponentClass -> {ComponentInstance1 = true, ComponentInstance2 = true, ...}, ...}
    BaseComponentRefs = {}; -- BaseComponentRefs = {ComponentInstance1 -> ComponentClass1, ...}
    RegisteredObjects = {};
    Registered = {};

    Tests = {};
};

--[[ coroutine.wrap(function()
    while wait(30) do
        local Counts = {}

        for Item in pairs(CollectiveObjectRegistry.InstanceToComponentCollection) do
            local Components = CollectiveObjectRegistry.GetComponents(Item)
            
            if (not Components) then
                continue
            end

            for _, Component in pairs(Components) do
                Component = Component._COMPONENT_REF
                Counts[tostring(Component)] = (Counts[tostring(Component)] or 0) + 1
            end
        end

        -- Ensure it matches
        local OtherCounts = {}

         -- ComponentClassToComponentCollection = {ComponentClass -> {ComponentInstance1 = true, ComponentInstance2 = true, ...}, ...}
        for ComponentClass, Instances in pairs(CollectiveObjectRegistry.ComponentClassToComponentCollection) do
            for _ in pairs(Instances) do
                OtherCounts[tostring(ComponentClass)] = (OtherCounts[tostring(ComponentClass)] or 0) + 1
            end
        end

        for Key, Value in pairs(OtherCounts) do
            local SameObjectCount = Counts[Key]

            if SameObjectCount then
                assert(SameObjectCount == Value, "Mismatch in count: " .. Key .. " (" .. SameObjectCount .. "/" .. Value .. ")")
            end
        end

        -- Sort and show most used components
        local KVP = {}

        for Key, Value in pairs(Counts) do
            table.insert(KVP, {Key, Value})
        end

        table.sort(KVP, function(Initial, Other)
            return Initial[2] > Other[2]
        end)

        print("Top 10 active components...")

        for Index = 1, 10 do
            local Data = KVP[Index]

            if (not Data) then
                continue
            end

            print(Data[1] .. ": " .. Data[2])
        end

        print("---------------------")
    end
end)() ]]

function CollectiveObjectRegistry.SetComponentToInstanceCollectionValue(Object, ComponentClass, Value, RealComponentInstance)
    -- ComponentToInstanceCollection = {ComponentClass -> {Instance1 = Instance1, Instance2 = Instance2, ...}, ...}
    local TargetComponentToInstanceCollection = CollectiveObjectRegistry.ComponentToInstanceCollection[ComponentClass] or {} -- setmetatable({}, {__mode = "kv"})
    TargetComponentToInstanceCollection[Object] = Value -- ComponentInstance here is = Object always; rename/fix
    CollectiveObjectRegistry.ComponentToInstanceCollection[ComponentClass] = TargetComponentToInstanceCollection

    -- ComponentClassToComponentCollection = {ComponentClass -> {ComponentInstance1 = true, ComponentInstance2 = true, ...}, ...}
    local TargetComponentClassToComponentCollection = CollectiveObjectRegistry.ComponentClassToComponentCollection[ComponentClass] or {}
    TargetComponentClassToComponentCollection[RealComponentInstance] = (Value ~= nil and true or nil)
    CollectiveObjectRegistry.ComponentClassToComponentCollection[ComponentClass] = TargetComponentClassToComponentCollection
end

function CollectiveObjectRegistry.Register(Tag, Components, CreationHandler, DestructionHandler, AncestorTarget)

    if (CollectiveObjectRegistry.Registered[Tag]) then
        warn(string.format("Tag already registered: '%s'", Tag))
        return
    end

    assert(Tag, "No tag given!")
    assert(Components, "No components given!")
    assert(#Components > 0, "Components list empty!")

    AncestorTarget = AncestorTarget or game
    CreationHandler = CreationHandler or CollectiveObjectRegistry.StandardConstruct
    DestructionHandler = DestructionHandler or CollectiveObjectRegistry.StandardDestroy

    local function HandleObjectCreation(Object)
        if (not AncestorTarget:IsAncestorOf(Object)) then
            -- Only instantiate if the ancestor of the Instance is correct to the specification
            return
        end

        local InstanceComponents = CollectiveObjectRegistry.InstanceToComponentCollection[Object] or {}
        --local HadValidComponent = false

        for Index = 1, #Components do -- Maintain order

            local Component = Components[Index]
            assert(Component, "No component found at index for " .. Tag .. "!")
            
            if (InstanceComponents[Component]) then
                -- Two or more 'Register' calls could have caused
                --warn("Instance component already assigned: " .. tostring(Component))
                continue
            end

            Async.Spawn(function()
                -- Spawn async because if the creation handler yields then we have a race condition
                -- with setting CollectiveObjectRegistry.InstanceToComponentCollection[Object] for objects with multiple Register calls.
                --local Clock = os.clock()
                local ComponentObject = CreationHandler(Component, Object)

                --[[ if (os.clock() - Clock >= 1/60) then
                    warn("Warning: constructor yielded, therefore Destroy may be called before construction finishes: " .. tostring(Component))
                end ]]

                if ComponentObject then
                    --SetComponentToInstanceCollectionValue(Object, Component, Object)
                    --CollectiveObjectRegistry.SetComponentToInstanceCollectionValue(Object, Component, ComponentObject)
                    --CollectiveObjectRegistry.BaseComponentRefs[ComponentObject] = Component
                    CollectiveObjectRegistry.SetComponentToInstanceCollectionValue(Object, Component, Object, ComponentObject)
                    ComponentObject._COMPONENT_REF = Component -- TODO: use BaseComponentRefs in singleton instead to assoc component object to class
                    InstanceComponents[Component] = ComponentObject
                    --HadValidComponent = true
                    CollectiveObjectRegistry.RegisteredObjects[Object] = true
                end
            end)
        end
        
        CollectiveObjectRegistry.InstanceToComponentCollection[Object] = InstanceComponents
        --if HadValidComponent then
            --CollectiveObjectRegistry.RegisteredObjects[Object] = true
        --end
    end

    local function HandleObjectDestruction(Object)
        if (not AncestorTarget:IsAncestorOf(Object)) then
            return
        end

        if (not CollectiveObjectRegistry.RegisteredObjects[Object]) then
            return
        end

        local InstanceComponents = CollectiveObjectRegistry.InstanceToComponentCollection[Object]
        assert(InstanceComponents, string.format("No instance components for object '%s'!", Object:GetFullName()))

        for _, ComponentObject in pairs(InstanceComponents) do
            --CollectiveObjectRegistry.SetComponentToInstanceCollectionValue(Object, --[[ ComponentObject._COMPONENT_REF ]]assert(CollectiveObjectRegistry.BaseComponentRefs[ComponentObject]), nil)
            CollectiveObjectRegistry.SetComponentToInstanceCollectionValue(Object, ComponentObject._COMPONENT_REF, nil, ComponentObject)
            CollectiveObjectRegistry.BaseComponentRefs[ComponentObject] = nil
            Async.Wrap(DestructionHandler)(ComponentObject)
        end

        CollectiveObjectRegistry.InstanceToComponentCollection[Object] = nil
        CollectiveObjectRegistry.RegisteredObjects[Object] = nil
    end

    -- Issue: this fires and then GetInstanceAddedSignal
    for _, Item in pairs(CollectionService:GetTagged(Tag)) do
        HandleObjectCreation(Item)
    end

    CollectionService:GetInstanceAddedSignal(Tag):Connect(HandleObjectCreation)
    CollectionService:GetInstanceRemovedSignal(Tag):Connect(HandleObjectDestruction)

    CollectiveObjectRegistry.Registered[Tag] = true
end

-- Misc

function CollectiveObjectRegistry.UpFlowExplicitComponent(Origin, ComponentIdentity, Data)
    assert(Origin, "No origin given.")
    assert(Origin.Parent, "Unparented object passed.")

    while (Origin.Parent) do

        local Components = CollectiveObjectRegistry.InstanceToComponentCollection[Origin]

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

function CollectiveObjectRegistry.UpFlow(Origin, Data)
    assert(Origin, "No origin given.")
    assert(Origin.Parent, "Unparented object passed.")

    while (Origin.Parent) do

        local Components = CollectiveObjectRegistry.InstanceToComponentCollection[Origin]

        if Components then
            for _, Target in pairs(Components) do
                assert(Target.ReceiveFlow, "No method defined to receive information.")
                Target:ReceiveFlow(Data)
            end
        end

        Origin = Origin.Parent
    end
end

--[[
    Used for quick efficient collective updates
    of a component type.
]]
function CollectiveObjectRegistry.UpdateAllComponentsOfType(Component)
    for _, Object in pairs(CollectiveObjectRegistry.GetInstances(Component)) do
        local ComponentToUpdate = CollectiveObjectRegistry.GetComponent(Object, Component)

        if (not ComponentToUpdate) then
            continue
        end

        ComponentToUpdate:Update()
    end
end

-- Information retrieval

function CollectiveObjectRegistry.GetComponents(Object)
    assert(Object, "No object given!")

    return CollectiveObjectRegistry.InstanceToComponentCollection[Object]
end

function CollectiveObjectRegistry.GetComponent(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local ComponentsForObject = CollectiveObjectRegistry.GetComponents(Object)
    return ComponentsForObject and ComponentsForObject[ComponentClass] or nil
end

function CollectiveObjectRegistry.WaitForComponent(Object, ComponentClass)
    local Trace = debug.traceback()
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = CollectiveObjectRegistry.GetComponent(Object, ComponentClass)

    coroutine.wrap(function()
        wait(5)

        if (Got == nil) then
            warn(string.format("Potential infinite wait on (\n    Object = '%s';\n    Component = '%s';\n)\n%s",
                                Object:GetFullName(), tostring(ComponentClass), Trace))
        end
    end)()

    local Break

    coroutine.wrap(function()
        wait(60)

        if (Got == nil) then
            Break = true -- Terminate polling loop
            error("Wait timeout.\n" .. Trace)
        end
    end)()

    while (Got == nil and not Break) do
        Got = CollectiveObjectRegistry.GetComponent(Object, ComponentClass)

        if (Object.Parent == nil) then
            -- Prevent infinite waits on objects which are removed
            return
        end

        Async.Wait(1/30)
    end

    return Got
end

function CollectiveObjectRegistry.WaitForComponentUnsafe(Object, ComponentClass)
    local Trace = debug.traceback()
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = CollectiveObjectRegistry.GetComponent(Object, ComponentClass)

    coroutine.wrap(function()
        wait(30)

        if (Got == nil) then
            warn(string.format("Potential infinite wait on (\n    Object = '%s';\n    Component = '%s';\n)\n%s",
                                Object:GetFullName(), tostring(ComponentClass), Trace))
        end
    end)()

    while (Got == nil) do
        Got = CollectiveObjectRegistry.GetComponent(Object, ComponentClass)

        if (Object.Parent == nil) then
            -- Prevent infinite waits on objects which are removed
            return
        end

        Async.Wait(1/30)
    end

    return Got
end

function CollectiveObjectRegistry.WaitForComponentFromDescendant(Object, ComponentClass)
    local Trace = debug.traceback()
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    local Got = CollectiveObjectRegistry.GetComponentFromDescendant(Object, ComponentClass)

    coroutine.wrap(function()
        wait(5)

        if (Got == nil) then
            warn(string.format("Potential infinite wait on (\n    Object = '%s';\n    Component = '%s'\n)\n%s",
                                Object:GetFullName(), tostring(ComponentClass), Trace))
        end
    end)()

    local Break

    coroutine.wrap(function()
        wait(60)

        if (Got == nil) then
            Break = true -- Terminate polling loop
            error("Wait timeout.\n" .. Trace)
        end
    end)()

    while (Got == nil and not Break) do
        Got = CollectiveObjectRegistry.GetComponentFromDescendant(Object, ComponentClass)

        if (Object.Parent == nil) then
            -- Prevent infinite waits on objects which are removed
            return
        end

        Async.Wait(1/30)
    end

    return Got
end

function CollectiveObjectRegistry.GetInstances(ComponentClass)
    assert(ComponentClass, "No component class given!")

    return CollectiveObjectRegistry.ComponentToInstanceCollection[ComponentClass] or {}
end

function CollectiveObjectRegistry.GetComponentsOfClass(ComponentClass)
    assert(ComponentClass, "No component class given!")

    return CollectiveObjectRegistry.ComponentClassToComponentCollection[ComponentClass] or {}
end

function CollectiveObjectRegistry.GetComponentFromDescendant(Object, ComponentClass)
    assert(Object, "No object given!")
    assert(ComponentClass, "No component class given!")

    while Object do
        local Component = CollectiveObjectRegistry.GetComponent(Object, ComponentClass)

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
    assert(Object.Initial, string.format("No 'Initial' found in '%s'!", tostring(Component)))

    Async.Spawn(function()
        Object:Initial()
    end)

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

    CollectiveObjectRegistry.Register(TestTag, {TestClass1, TestClass2})

    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")

    OnCleanup(function()
        TestModel:Destroy()
    end)

    if (not CollectiveObjectRegistry.GetComponent(TestModel, TestClass1)) then
        Fail("did not get first object")
    end

    if (not CollectiveObjectRegistry.GetComponent(TestModel, TestClass2)) then
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

    CollectiveObjectRegistry.Register(TestTag, {TestClass})

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

    local Instances = CollectiveObjectRegistry.GetInstances(TestClass)

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
    CollectiveObjectRegistry.Register(TestTag, {TestClass})

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

    local Instances = CollectiveObjectRegistry.GetInstances(TestClass)
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

    CollectiveObjectRegistry.Register(TestTag, {TestClass1, TestClass2})

    local TestModel = Instance.new("Model")
    CollectionService:AddTag(TestModel, TestTag)
    TestModel.Parent = game:GetService("Workspace")
    TestModel:Destroy()

    if (CollectiveObjectRegistry.GetComponent(TestModel, TestClass1)) then
        Fail("did not clean up for first item")
    end

    if (CollectiveObjectRegistry.GetComponent(TestModel, TestClass2)) then
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

    CollectiveObjectRegistry.Register(TestTag, {TestClass1, TestClass2})

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

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(TestModel, TestClass1)) then
        Fail("not inclusive for first object")
    end

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(TestModel, TestClass2)) then
        Fail("not inclusive for second object")
    end

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(SubTestModel, TestClass1)) then
        Fail("did not get first object in sub-model")
    end

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(SubSubTestModel, TestClass2)) then
        Fail("did not get second object in sub-model")
    end

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(SubSubTestModel, TestClass1)) then
        Fail("did not get first object in sub-sub-model")
    end

    if (not CollectiveObjectRegistry.GetComponentFromDescendant(SubTestModel, TestClass2)) then
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

    CollectiveObjectRegistry.Register(, {TestClass1, TestClass2})

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

    CollectiveObjectRegistry.UpFlow(CollectiveObjectRegistry.GetComponent(TestModel3), DataTC1)
    CollectiveObjectRegistry.UpFlow(CollectiveObjectRegistry.GetComponent(TestModel3), DataTC1)

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