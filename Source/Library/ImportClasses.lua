local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Structures = {}
local ClassItems = Classes:GetChildren()

function Structures.ImportClass(Item, Name)

    local Module = require(Item)
    local ModuleType = type(Module)

    if ModuleType == "table" or ModuleType == "userdata" then

        Structures[Name] = Module

    else

        error("Supplied module did not return a table or userdata.")

    end

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