local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local CollectionHelper = {}

function CollectionHelper:GetDescendantsWithTag(Root, Tag)

    local Result = {}

    for _, Object in Pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
            Table.Insert(Result, Object)
        end
    end

    return Result
end

-- More efficient, as this will stop when it finds one
function CollectionHelper:FindFirstDescendantWithTag(Root, Tag)
    for _, Object in Pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
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

Func({
    Client = {CollectionHelper = CollectionHelper};
    Server = {CollectionHelper = CollectionHelper};
})

return true