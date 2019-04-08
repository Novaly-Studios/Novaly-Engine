shared()

local Structures = {}
local ClassItems = Classes:GetChildren()

function Structures.ImportClass(Item, Name)

    local Module = require(Item)
    local ModuleType = type(Module)

    if (ModuleType == "table" or ModuleType == "userdata") then
        Structures[Name] = Module
        return
    end

    error("Supplied module did not return a table or userdata.")
end

for Item = 1, #ClassItems do
    Item = ClassItems[Item]
    local Name = Item.Name
    Log(1, "Importing Class '" .. Name .. "'")
    Structures.ImportClass(Item, Name)
end

return Structures