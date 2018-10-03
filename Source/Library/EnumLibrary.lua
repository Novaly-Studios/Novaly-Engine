--[[
    Allows for the creation of custom Enums.

    @module Enum Library
    @alias EnumLibrary
    @author TPC9000
]]

shared()

local Enums = SetMetatable({}, {__index = OriginalEnv["Enum"]})

--[[
    @function Enums.New

    Creates a new Enum.

    @usage
        Enum:New("TestEnum", {FirstOption = 0, SecondOption = 100})
        local Test = Enum.TestEnum.Option2

    @param Name The name of the Enum to create.
    @param Values The table of string key to numeric value associations.
]]

function Enums:New(Name, Values)
    Assert(Name, "Argument missing: #1 Name (name of Enum)")
    Assert(Values, "Argument missing: #2 Values (Enum values)")
    Assert(Type(Values) == "table", "Argument #2 must be a table.")
    self[Name] = Values
end

--[[
    @function Enums.NewCollection

    Creates a new automatically numbered Enum.

    @usage
        Enum:NewCollection("TestEnum", {"Option1", "Option2"})
        local Test = Enum.TestEnum.Option2

    @param Name The name of the Enum to create.
    @param Values The table of string values.
]]

function Enums:NewCollection(Name, Values)
    for Index, Value in Pairs(Values) do
        Values[Value] = Index
    end
    Enums:New(Name, Values)
    return Enums
end

return {
    Client = {Enum = Enums};
    Server = {Enum = Enums};
}