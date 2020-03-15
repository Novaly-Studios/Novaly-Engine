local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Hierarchy = Class:FromName("Hierarchy") {
    PropertySet = "H_PropertySet";
}

function Hierarchy.new(Structure)

    setmetatable(Structure, {__mode = "k"})

    return {
        Structure = Structure;
        PropertySets = {};
    }
end

function Hierarchy:AddPropertySet(ID, Properties)
    assert(type(Properties) == "table")
    self.PropertySets[ID] = Properties
    return self
end

function Hierarchy:ApplyProperty(Object, Key, Value)
    if (Object[Key] ~= Value) then
        Object[Key] = Value
    end
end

function Hierarchy:ApplyProperties(Object, Properties)
    for Key, Value in pairs(Properties) do
        self:ApplyProperty(Object, Key, Value)
    end
end

function Hierarchy:Apply(Object, Struct)

    local Target = (Struct or self.Structure)

    for Key, Value in pairs(Target) do

        if (type(Key) == "table") then

            local Name = Key[1]
            local ClassType = Key[2]
            local Subordinate = Object:FindFirstChild(Name)

            if (not Subordinate) then
                Subordinate = Instance.new(ClassType)
                Subordinate.Name = Name
            end

            assert(Subordinate:IsA(ClassType), string.format("Object '%s' is not of the specified type '%s' in the Hierarchy", Subordinate.Name, ClassType))
            self:Apply(Subordinate, Value)
            Subordinate.Parent = Object

        elseif (Key == self.PropertySet) then

            local Properties = self.PropertySets[Value]
            assert(Properties, string.format("No property set '%s' exists", Value))
            self:ApplyProperties(Object, Properties)

        elseif (string.find(tostring(Object[Key]), "Signal") and type(Value) == "function") then

            local Func = Value
            local Connection

            Connection = Object[Key]:Connect(function(...)
                if Connection then
                    Func(Struct, Connection, ...)
                end
            end)

            Struct[Key] = {Value}
        else
            self:ApplyProperty(Object, Key, Value)
        end
    end

    return Object
end

return Hierarchy