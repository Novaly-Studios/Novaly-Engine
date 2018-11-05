shared()

local Association = Class:FromName(script.Name)

function Association.New(InitialValue)
    return {
        Ordered         = {};
        Collection      = {};
        InitialValue    = InitialValue;
    }
end

function Association:InternalRelate(Sequence, Values, Value)
    for Index = 1, #Sequence do
        local Key = Sequence[Index]
        local New = Values[Key] or {}
        New.Value = New.Value or self.InitialValue
        Values[Key] = New
        Values = New
    end
    if (type(Value) == "table") then
        table.insert(self.Collection, Value)
    end
    Values["Value"] = Value
end

function Association:GetRelationInternal(Subject, Values)
    local Last = Subject[Values[1]]
    for Index = 2, #Values do
        if (not Last) then
            return self.InitialValue
        end
        Last = Last[Values[Index]]
    end
    return (Last and Last.Value or self.InitialValue)
end

function Association:Relate(Sequence, Value)
    self:InternalRelate(Sequence, self.Ordered, Value)
end

function Association:Get(Sequence)
    return self:GetRelationInternal(self.Ordered, Sequence)
end

function Association:Compare(Condition, Activation)

    local Collection = self.Collection

    local function TryIndex(Item, ...)
        local Args = {...}
        return pcall(function()
            local Last = Args[1]
            for Index = 2, #Args do
                Last = Last[Index]
            end
            return Last
        end)
    end

    for _, Item in pairs(Product({Collection, Collection})) do

        local Subject = Item[1]
        local Other = Item[2]

        if (Subject ~= Other) then
            if (Condition(Subject, Other)) then
                Activation(Subject, Other)
            end
        end
    end
end

function Association:Filter(Condition, Activation)

    local Results = {}

    for _, Item in pairs(self.Collection) do
        if (not Results[Item]) then
            if (Condition(Item)) then
                Results[Item] = true
                Activation(Item)
            end
        end
    end
end

return Association