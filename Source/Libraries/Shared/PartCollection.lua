local PartCollection = {}

function PartCollection.Scale(Model, Scale)
    assert(Model.PrimaryPart, string.format("No primary part on model '%s'!", Model:GetFullName()))

    for _, Item in pairs(Model:GetDescendants()) do
        if (Item:IsA("BasePart")) then
            local Size = Item.Size * Scale
            Item.CFrame = CFrame.new(Model.PrimaryPart.Position + (Item.Position - Model.PrimaryPart.Position) * Scale) * (Item.CFrame - Item.Position)
            Item.Size = Size
        end
    end
end

function PartCollection.LargestDimension(OfItem)
    if (OfItem:IsA("BasePart")) then
        return math.max(OfItem.Size.X, OfItem.Size.Y, OfItem.Size.Z)
    end

    local Result = 0

    for _, Part in pairs(OfItem:GetDescendants()) do
        Result = math.max(Result, PartCollection.LargestDimension(Part))
    end

    return Result
end

function PartCollection.SmallestDimension(OfItem)
    if (OfItem:IsA("BasePart")) then
        return math.min(OfItem.Size.X, OfItem.Size.Y, OfItem.Size.Z)
    end

    local Result = 0

    for _, Part in pairs(OfItem:GetDescendants()) do
        Result = math.min(Result, PartCollection.LargestDimension(Part))
    end

    return Result
end

return PartCollection