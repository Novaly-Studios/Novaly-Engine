shared()

local SetAssociation = Class:FromName(script.Name)

function SetAssociation.New(InitialValue)
    return {
        Unordered       = {};
        Collection      = {};
        InitialValue    = InitialValue;
    }
end

function SetAssociation:Relate(Set, Value)

    local Unordered = self.Unordered
    local Rep = {}

    for _ = 1, #Set do
        table.insert(Rep, Set)
    end

    local Permutations = Product(Rep)

    for _, Combination in pairs(Permutations) do
        Association.InternalRelate(self, Combination, Unordered, Value)
    end

    if (type(Value) == "table") then
        table.insert(self.Collection, Value)
    end
end

function SetAssociation:Compare(...)
    Association.Compare(self, ...)
end

function SetAssociation:Filter(...)
    Association.Filter(self, ...)
end

function SetAssociation:Get(Set)
    return Association:GetRelationInternal(self.Unordered, Set)
end

return SetAssociation