local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

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

function Weld.Model(Class, Model, Base, WeldC1)
    for Key, Value in Pairs(Model:GetChildren()) do
        if (Value ~= Base and Value:IsA("BasePart")) then
            Weld.WeldPart(Class, Base, Value, Base.CFrame:toObjectSpace(Value.CFrame))
        end
    end
end

-- Just for some backwards compatibility
Weld.WeldModel = Weld.Model
Weld.WeldPart = Weld.Part

Func({
    Client = {Weld = Weld};
    Server = {Weld = Weld};
})

return true