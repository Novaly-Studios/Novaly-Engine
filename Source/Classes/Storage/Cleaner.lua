local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Cleaner = Class:FromName("Cleaner")

function Cleaner:Cleaner()
    return {
        ToProcess = {};
        Index = 1;
        HasCleaned = false;
    };
end

function Cleaner:Add(...)
    for _, Item in pairs({...}) do
        self.ToProcess[self.Index] = Item
        self.Index = self.Index + 1
    end

    if (self.HasCleaned) then
        -- Add after Clean called? Likely result of bad yielding, so clean up whatever is doing this.
        self:Clean()
    end
end

function Cleaner:Clean()
    for Index, Item in pairs(self.ToProcess) do
        local Type = typeof(Item)

        if (Type == "RBXScriptConnection") then
            Item:Disconnect()
        elseif (Type == "table") then
            if (Item.Disconnect) then
                Item:Disconnect()
            end

            if (Item.Destroy) then
                Item:Destroy()
            end
        elseif (Type == "function") then
            Item()
        else
            error("Unsupported type: " .. Type)
        end

        self.ToProcess[Index] = nil
    end

    self.Index = 0
    self.HasCleaned = true
end

return Cleaner