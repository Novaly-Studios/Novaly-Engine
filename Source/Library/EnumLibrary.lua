shared()

local Enums = setmetatable({}, {__index = OriginalEnv["Enum"]})

function Enums:New(Name, Values)
    assert(Name, "Argument missing: #1 Name (name of Enum)")
    assert(Values, "Argument missing: #2 Values (Enum values)")
    assert(type(Values) == "table", "Argument #2 must be a table.")
    self[Name] = Values
end

function Enums:NewCollection(Name, Values)
    for Index, Value in pairs(Values) do
        Values[Value] = Index
    end
    Enums:New(Name, Values)
    return Enums
end

shared({
    Client = {Enum = Enums};
    Server = {Enum = Enums};
})

return true