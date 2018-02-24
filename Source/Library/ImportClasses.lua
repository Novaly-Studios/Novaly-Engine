local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Structures = {}
local ClassItems = Classes:GetChildren()

for Item = 1, #ClassItems do

    local Item = ClassItems[Item]
    Structures[Item.Name] = require(Item)

end

return {
	Client = Structures;
	Server = Structures;
}