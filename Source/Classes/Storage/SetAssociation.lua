local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")
local Association = Novarine:Get("Association")
local Core = Novarine:Get("Core")

local SetAssociation = Class:FromName(script.Name)

function SetAssociation.New(InitialValue)
    return setmetatable({
        Unordered = {};
        InitialValue = InitialValue;
    }, SetAssociation)
end

function SetAssociation:Relate(Set, Value)

    local Unordered = self.Unordered
    local Rep = {}

    for _ = 1, #Set do
        table.insert(Rep, Set)
    end

    local Permutations = Core.Product(Rep)

    for _, Combination in pairs(Permutations) do
        Association:InternalRelate(Combination, Unordered, Value)
    end
end

function SetAssociation:Get(Set)
    return Association:GetRelationInternal(self.Unordered, Set)
end

return SetAssociation