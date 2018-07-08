local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Structures = {}
local ClassItems = Classes:GetChildren()

function Structures.ImportClass(Item, Name)

    local Module = Require(Item)
    local ModuleType = Type(Module)

    if (ModuleType == "table" or ModuleType == "userdata") then
        Structures[Name] = Module
        return
    end

    Error("Supplied module did not return a table or userdata.")
end

for Item = 1, #ClassItems do
    local Item = ClassItems[Item]
    local Name = Item.Name
    Log(1, "Importing Class '" .. Name .. "'")
    Structures.ImportClass(Item, Name)
end

Func({
    Client = Structures;
    Server = Structures;
})

return true