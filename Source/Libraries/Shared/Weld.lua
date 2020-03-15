local Weld = {}

function Weld.Part(Class, Part0, Part1, C0, C1)

    local Weld = Instance.new(Class, Part0)
    Weld.Part0 = Part0
    Weld.Part1 = Part1

    if (C0 == true and C1 == true) then
        Weld.C0 = Part0.CFrame:inverse()
        Weld.C1 = Part1.CFrame:inverse()
    elseif (C0 == true) then
        Weld.C0 = Part0.CFrame:toObjectSpace(Part1.CFrame)
    elseif (C1 == true) then
        Weld.C1 = Part1.CFrame:toObjectSpace(Part0.CFrame)
    else
        Weld.C0 = C0 or CFrame.new()
        Weld.C1 = C1 or CFrame.new()
    end

    return Weld
end

function Weld.Model(Class, Model, Base)
    for _, Value in pairs(Model:GetChildren()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.Part(Class, Base, Value, Base.CFrame:toObjectSpace(Value.CFrame))
        end
    end
end

function Weld.ModelRecursive(Class, Model, Base)
    for _, Value in pairs(Model:GetDescendants()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.Part(Class, Base, Value, Base.CFrame:toObjectSpace(Value.CFrame))
        end
    end
end

function Weld.ConstrainPart(Part0, Part1)
    local Constraint = Instance.new("WeldConstraint", Part0)
    Constraint.Part0 = Part0
    Constraint.Part1 = Part1
    return Constraint
end

function Weld.ConstrainModel(Model, Base)
    for _, Value in pairs(Model:GetChildren()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.ConstrainPart(Base, Value)
        end
    end
end

function Weld.ConstrainModelRecursive(Model, Base)
    for _, Value in pairs(Model:GetDescendants()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.ConstrainPart(Base, Value)
        end
    end
end

-- Just for some backwards compatibility
Weld.WeldModel = Weld.Model
Weld.WeldPart = Weld.Part

return Weld