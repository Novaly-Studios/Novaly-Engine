local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Original = OriginalEnv["Enum"]
Enums = setmetatable({}, {__index = function(Self, Key)
	return rawget(Self, Key) or Original[Key]
end})

function Enums.new(Name, Values)
	
	assert(Name, "Argument missing: #1 Name (name of Enum)")
	assert(Values, "Argument missing: #2 Values (Enum values)")
	assert(type(Values) == "table", "Argument #2 must be a table.")
	Enums[Name] = Values
end

Func({
	Client = {Enum = Enums};
	Server = {Enum = Enums};
})

return true