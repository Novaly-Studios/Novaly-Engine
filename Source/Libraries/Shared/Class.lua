--[[
    Allows for the construction, inheritance and typing of classes.

    @module Class Library
    @alias ClassLibrary
    @author TPC9000
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Static = Novarine:Get("Static")
local Table = Novarine:Get("Table")

local Class = {
    NameKey             = "ClassName";
    ClassRefKey         = "Class";
    SuperclassRefKey    = "Super";
    ConstructorNames    = {"new", "New", "Create"};
    ClassMetatable      = {
        __call = function(self, Static)
            assert(type(Static) == "table", "Static vars must be a table.")
            for Key, Value in pairs(Static) do
                rawset(self, Key, Value)
            end
            return self
        end;
    };
}

--[[
    @function Class.New

    Constructs a new class with a given
    name and a table of static variables.

    @usage
        local Test = Class:New("Test", {Static = 300})
        function Test:Test(Var)
            self.Var = Var
        end
        function Test:Compute()
            return self.Var * self.Static
        end
        print(Test.New(20):Compute())

    @param Name The name of the class, used as its type.
    @param ClassTable The table of static class data.

    @return The class metatable.
]]

function Class:New(Name, ClassTable)

    ClassTable = ClassTable or {}

    local function Constructor(...)

        local Result = setmetatable({Class = ClassTable}, ClassTable)
        local Func = ClassTable[Name]
        --getfenv(Func).self = Result

        local Object = Func(Result, ...)

        if Object then
            Table.MergeKey(Result, Object)
        end

        Result[self.ClassRefKey] = ClassTable
        setmetatable(Result, ClassTable)

--[[         for _, Value in pairs(Result) do
            if (type(Value) == "function") then
                getfenv(Value).self = Result
            end
        end ]]

        return Result
    end

    for _, Value in pairs(self.ConstructorNames) do
        ClassTable[Value] = Constructor
    end

    ClassTable[self.NameKey] = Name
    ClassTable["__index"] = ClassTable

    setmetatable(ClassTable, self.ClassMetatable)

    return ClassTable
end

--[[
    @function Class.FromExtension

    Creates a class as an extension of another.

    @usage
        local Class1 = Class:New("Class1") {
            A = 2;
        }
        local Class2 = Class:FromExtension("Class2", Class1) {
            B = 3;
        }
        function Class2:Test()
            print(self.A * self.B)
        end

    @param Name The name of the class being created.
    @param Other The class being extended.

    @return The extended class.
]]

function Class:FromExtension(Name, Other)

    local Result = self:FromName(Name)

    Result["__index"] = function(self, Key)
        return (rawget(self, Key) or rawget(self, "Class")[Key] or Other[Key])
    end
    Result[self.SuperclassRefKey] = Other

    return Result
end

--[[
    @function Class.IsEquivalentType

    Checks if two objects are of equal type.

    @usage
        local Class1 = Class:New("Class1") {}

    @param Subject The first class or object which will be checked.
    @param CheckSuperclass The second class or object which will be checked.

    @return A boolean denoting whether the two classes or objects are of the same type.
]]

function Class:IsEquivalentType(Subject, CheckSuperclass)

    local SuperKey = self.SuperclassRefKey
    local NameKey = self.NameKey

    while (Subject[SuperKey]) do
        local NextSuper = Subject[SuperKey]
        if (NextSuper[NameKey] == CheckSuperclass[NameKey]) then
            return true
        end
        Subject = NextSuper
    end

    return false
end

--[[
    @function Class.DeclarativeState

    Constructs a class maker which supports methods
    with a declarative state. Can make some scenarios
    easier than regular classes, but are less performant.

    @usage
        local Player = Class:DeclarativeState()

        function Player:AddMoney(Money)
            self:Update({
                Money = (self.State.Money or 0) + Money;
            })
        end

        function Player:SetName(Name)
            self:Update({
                Name = Name;
            })
        end

        local Player1 = Player.New({
            Name = "Unspecified";
            Money = 0;
        })
        Player1:SetName("Player1")
        Player1:AddMoney(12)
        Player1:AddMoney(5)
]]

function Class:DeclarativeState()
    local BaseClass = {}

    function BaseClass:Update(State)
        self.State = Static.FuseNested(State, self.State)
    end

    local function Constructor(State)
        return setmetatable({
            State = State or {};
        }, {__index = BaseClass})
    end

    for _, Value in pairs(self.ConstructorNames) do
        BaseClass[Value] = Constructor
    end

    BaseClass.New = Constructor
    BaseClass.Create = Constructor

    return BaseClass
end

--[[
    @deprecate Use Class.New instead
    @todo Replace all Class.FromName with Class.New
]]
Class.FromName = Class.New

return Class