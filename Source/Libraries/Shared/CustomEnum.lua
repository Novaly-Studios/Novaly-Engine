--[[
    Allows for the creation of custom Enums.

    @module Enum Library
    @alias EnumLibrary
    @author TPC9000
    @deprecate
]]

local CustomEnums = {}

--[[
    @function New

    Creates a new Enum.

    @usage
        Enum:New("TestEnum", {FirstOption = 0, SecondOption = 100})
        local Test = Enum.TestEnum.Option2

    @param Name The name of the Enum to create.
    @param Values The table of string key to numeric value associations.
]]
function CustomEnums:New(Name, Values)
    assert(Name, "Argument missing: #1 Name (name of Enum)")
    assert(Values, "Argument missing: #2 Values (Enum values)")
    assert(type(Values) == "table", "Argument #2 must be a table.")
    self[Name] = Values
end

--[[
    @function NewCollection

    Creates a new automatically numbered Enum.

    @usage
        Enum:NewCollection("TestEnum", {"Option1", "Option2"})
        local Test = Enum.TestEnum.Option2

    @param Name The name of the Enum to create.
    @param Values The table of string values.
]]
function CustomEnums:NewCollection(Name, Values)
    for Index, Value in pairs(Values) do
        Values[Value] = Index
    end
    CustomEnums:New(Name, Values)
    return CustomEnums
end

return CustomEnums