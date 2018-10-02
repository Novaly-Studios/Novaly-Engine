shared()

local CollectionHelper = {}

function CollectionHelper:HasTags(Root, ...)
    for _, Tag in Pairs({...}) do
        if (not CollectionService:HasTag(Root, Tag)) then
            return false
        end
    end
    return true
end

function CollectionHelper:GetDescendantsWithTag(Root, ...)

    local Result = {}

    for _, Object in Pairs(Root:GetDescendants()) do
        if (self:HasTags(Object, ...)) then
            Table.Insert(Result, Object)
        end
    end

    return Result
end

function CollectionHelper:GetChildrenWithTag(Root, ...)

    local Result = {}

    for _, Object in Pairs(Root:GetChildren()) do
        if (self:HasTags(Object, ...)) then
            Table.Insert(Result, Object)
        end
    end

    return Result
end

-- Todo: GetAncestorWithTag

-- More efficient, as this will stop when it finds one
function CollectionHelper:FindFirstDescendantWithTag(Root, ...)
    for _, Object in Pairs(Root:GetDescendants()) do
        if (self:HasTags(Object, ...)) then
            return Object
        end
    end
end

function CollectionHelper:FindFirstChildWithTag(Root, ...)
    for _, Object in Pairs(Root:GetChildren()) do
        if (self:HasTags(Object, ...)) then
            return Object
        end
    end
end

function CollectionHelper:TagHasPrefix(Object, Prefix)

    local PrefixLength = #Prefix

    for _, Tag in Pairs(CollectionService:GetTags(Object)) do
        if (String.Sub(Tag, 1, PrefixLength) == Prefix) then
            return true
        end
    end

    return false
end

function CollectionHelper:RemoveTags(Object)
    for _, Object in Pairs(Object:GetDescendants()) do
        for _, Tag in Pairs(CollectionService:GetTags(Object)) do
            CollectionService:RemoveTag(Object, Tag)
        end
    end
end

function CollectionHelper:GetFirstTagged(Tag)
    return CollectionService:GetTagged(Tag)[1]
end

return {
    Client = {CollectionHelper = CollectionHelper};
    Server = {CollectionHelper = CollectionHelper};
}