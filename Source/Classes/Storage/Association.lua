local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Association = Class:FromName(script.Name)

function Association.New(InitialValue)
    return {
        Ordered         = {};
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

return Association