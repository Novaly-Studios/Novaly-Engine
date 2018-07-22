local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Enums = SetMetatable({}, {__index = OriginalEnv["Enum"]})

function Enums:New(Name, Values)
    Assert(Name, "Argument missing: #1 Name (name of Enum)")
    Assert(Values, "Argument missing: #2 Values (Enum values)")
    Assert(Type(Values) == "table", "Argument #2 must be a table.")
    self[Name] = Values
end

function Enums:NewCollection(Name, Values)
    for Index, Value in Pairs(Values) do
        Values[Value] = Index
    end
    Enums.new(Name, Values)
    return Enums
end

Func({
    Client = {Enum = Enums};
    Server = {Enum = Enums};
})

return true