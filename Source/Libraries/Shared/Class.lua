--[[
    Basic class construction library.

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
    ConstructorNames    = {"new", "New", "Create"};
    ClassMetatable      = {
        __call = function(self, Global)
            assert(type(Global) == "table", "Global vars must be a table.")

            for Key, Value in pairs(Global) do
                rawset(self, Key, Value)
            end

            return self
        end;
    };
}

--[[
    @function New

    Constructs a new class with a given
    name and a table of global variables.

    @usage
        local Test = Class:New("Test") {
            Global = 300
        };

        function Test:Test(Var)
            self.Var = Var
        end

        function Test:Compute()
            return self.Var * self.Global
        end

        print(Test.New(20):Compute())

    @param Name The name of the class, used as its type.
    @param ClassTable The table of global class data.

    @return The class metatable.
]]
function Class:New(Name, ClassTable)

    ClassTable = ClassTable or {}

    local function Constructor(...)

        local Result = setmetatable({Class = ClassTable}, ClassTable)
        local Func = ClassTable[Name]

        local Object = Func(Result, ...)

        if Object then
            Table.MergeKey(Result, Object)
        end

        Result[self.ClassRefKey] = ClassTable

        function Result:__tostring()
            local Stringed = Name .. " (\n"

            for Key, Item in pairs(self) do
                Stringed = Stringed .. "    " .. tostring(Key) .. " = " .. tostring(Item) .. ";\n"
            end

            return Stringed .. "\n)"
        end

        setmetatable(Result, ClassTable)

        return Result
    end

    for _, Value in pairs(self.ConstructorNames) do
        ClassTable[Value] = Constructor
    end

    ClassTable[self.NameKey] = Name
    ClassTable.__index = ClassTable

    setmetatable(ClassTable, Static.Fuse1D(self.ClassMetatable, {
        __tostring = function()
            return "Class (" .. Name .. ")"
        end
    }))

    return ClassTable
end

--[[
    @deprecate Use Class.New instead
    @todo Replace all Class.FromName with Class.New
]]
Class.FromName = Class.New

return Class