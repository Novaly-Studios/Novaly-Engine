local Weld = {}

--[[
    Welds two parts together with the standard
    C0 and C1 offsets.

    @param Class The type of the weld e.g. "Weld", "Motor6D"
    @param Part0 The part to weld Part1 to
    @param Part1 The part to be welded onto Part0
    @param C0 CFrame offset, or Boolean to automatically construct this
    @param C1 CFrame offset, or Boolean to automatically construct this

    @usage
        Weld.Part("Weld", Ball, Stick, true)
        Weld.Part("Weld", Block, Gun, CFrame.new(0, 3, 0), CFrame.new(-1.5, 0, 0))
]]

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

--[[
    Welds a model's parts together, to some
    base part.

    @param Class The type of the weld
    @param Model The model to weld
    @param Base The part to weld all other parts onto

    @usage
        Weld.Model("Weld", TestModel, TestModel.Centre)
]]

function Weld.Model(Class, Model, Base)
    for _, Value in pairs(Model:GetChildren()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.Part(Class, Base, Value, Base.CFrame:toObjectSpace(Value.CFrame))
        end
    end
end

--[[
    Constrains two parts together, initialising
    their relative offsets.
]]

function Weld.ConstrainPart(Part0, Part1)
    local Constraint = Instance.new("WeldConstraint", Part0)
    Constraint.Part0 = Part0
    Constraint.Part1 = Part1
    return Constraint
end

--[[
    Constrains a model's parts together, initialising
    their relative offsets.
    
    @param Model The model to constrain
    @param Base The part to constrain all other parts within the model to

    @usage Weld.ConstrainModel(TestModel, TestModel.PrimaryPart)
]]

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
