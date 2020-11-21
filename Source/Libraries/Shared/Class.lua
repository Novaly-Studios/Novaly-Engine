--[[
    Basic class construction library.

    @module Class Library
    @alias ClassLibrary
    @author TPC9000
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Table = Novarine:Get("Table")

local Class = {
    ClassMetatable  = {
        __call = function(self, Global)
            assert(type(Global) == "table", "Global vars must be a table.")

            for Key, Value in pairs(Global) do
                rawset(self, Key, Value)
            end

            return self
        end;
        __tostring = function(self)
            return "Class (" .. self.ClassName .. ")"
        end;
    };
};

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

        --[[ function Result.__tostring()
            return Name .. "(Object)"
        end ]]

        setmetatable(Result, ClassTable)

        return Result
    end

    ClassTable.New = Constructor
    ClassTable.ClassName = Name
    ClassTable.__index = ClassTable

    setmetatable(ClassTable, self.ClassMetatable)
    return ClassTable
end

--[[
    @deprecate Use Class.New instead
    @todo Replace all Class.FromName with Class.New
]]
Class.FromName = Class.New

return Class