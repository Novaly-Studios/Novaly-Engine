local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Cleaner = Class:FromName("Cleaner")

function Cleaner:Cleaner()
    return {
        ToProcess = {};
        Index = 1;
    };
end

function Cleaner:Add(Item)
    self.ToProcess[self.Index] = Item
    self.Index = self.Index + 1
end

function Cleaner:Clean()
    for Index, Item in pairs(self.ToProcess) do
        local Type = typeof(Item)

        if (Type == "RBXScriptSignal") then
            Item:Disconnect()
        elseif (Type == "table") then
            if (Item.Disconnect) then
                Item:Disconnect()
            end

            if (Item.Destroy) then
                Item:Destroy()
            end
        end

        self.ToProcess[Index] = nil
    end

    self.Index = 0
end

return Cleaner