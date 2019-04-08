shared()

--[[
    Extends CollectionService with useful methods.

    @module CollectionService Extender
    @alias CollectionHelper
    @author TPC9000
    @todo GetAncestorWithTag method
]]

local CollectionHelper = {}

--[[
    @function CollectionHelper.HasTags

    Determines whether an object has any specified tag(s).

    @usage
        print(CollectionHelper:HasTags(Workspace.Test, "Tag1", "Tag2"))

    @param Object The object to test.
    @param ... Strings denoting tags to test the object for.

    @return A boolean denoting whether the object contained any of the specified tags.
]]

function CollectionHelper:HasTags(Object, ...)

    local Args = {...}
    assert(#Args > 0, "No tags given!")

    for _, Tag in pairs(Args) do
        if (not CollectionService:HasTag(Object, Tag)) then
            return false
        end
    end

    return true
end

--[[
    @function CollectionHelper.GetDescendantsWithTag

    Finds any descendant objects with specified tag(s).

    @usage
        for _, Item in pairs(CollectionHelper:GetDescendantsWithTag(Workspace, "MakeTransparent")) do
            Item.Transparency = 1
        end

    @param Root The top-level instance to search.
    @param ... The tags to check for.

    @return A table of items found by the search.
]]

function CollectionHelper:GetDescendantsWithTag(Root, ...)

    local Result = {}
    assert(#({...}) > 0, "No tags given!")

    for _, Object in pairs(Root:GetDescendants()) do
        if (self:HasTags(Object, ...)) then
            table.insert(Result, Object)
        end
    end

    return Result
end

--[[
    @function CollectionHelper.GetChildrenWithTag

    Finds any children (not descendants) with
    specified tag(s).

    @usage
        for _, Item in pairs(CollectionHelper:GetChildrenWithTag(Workspace, "MakeTransparent")) do
            Item.Transparency = 1
        end

    @param Root The top-level instance to search.
    @param ... The tags to check for.

    @return A table of items found by the search.
]]

function CollectionHelper:GetChildrenWithTag(Root, ...)

    local Result = {}
    assert(#({...}) > 0, "No tags given!")

    for _, Object in pairs(Root:GetChildren()) do
        if (self:HasTags(Object, ...)) then
            table.insert(Result, Object)
        end
    end

    return Result
end

--[[
    @function CollectionHelper.FindFirstDescendantWithTag

    Finds the first descendant with any given tags.

    @usage
        CollectionHelper:FindFirstDescendantWithTag(Workspace, "MakeThisUniquePartTransparent").Transparency = 1

    @param Root The top-level instance to search.
    @param ... The tags to check for.

    @return An instance with the specified tags, if one was found.
]]

function CollectionHelper:FindFirstDescendantWithTag(Root, ...)
    assert(#({...}) > 0, "No tags given!")
    for _, Object in pairs(Root:GetDescendants()) do
        if (self:HasTags(Object, ...)) then
            return Object
        end
    end
end

--[[
    @function CollectionHelper.FindFirstChildWithTag

    Finds the first child with any given tags.

    @usage
        CollectionHelper:FindFirstChildWithTag(Workspace, "MakeThisUniquePartTransparent").Transparency = 1

    @param Root The top-level instance to search.
    @param ... The tags to check for.

    @return An instance with the specified tags, if one was found.
]]

function CollectionHelper:FindFirstChildWithTag(Root, ...)
    assert(#({...}) > 0, "No tags given!")
    for _, Object in pairs(Root:GetChildren()) do
        if (self:HasTags(Object, ...)) then
            return Object
        end
    end
end

--[[
    @function CollectionHelper.TagHasPrefix

    Checks if any tags of an object are prefixed
    by a certain string.

    @usage
        if (CollectionHelper:TagHasPrefix(Workspace.Test, "Car")) then
            Workspace.Test:Destroy()
        end

    @param Object The object whose tags will be tested.
    @param Prefix The prefix string to check for.

    @return A boolean denoting whether the object had any tags prefixed as specified.
]]

function CollectionHelper:TagHasPrefix(Object, Prefix)

    local PrefixLength = #Prefix

    for _, Tag in pairs(CollectionService:GetTags(Object)) do
        if (string.sub(Tag, 1, PrefixLength) == Prefix) then
            return true
        end
    end

    return false
end

--[[
    @function CollectionHelper.RemoveTags

    Removes all tags from a given object.

    @usage
        CollectionHelper:RemoveTags(Workspace.Test)

    @param Object The Instance to remove tags from.
]]

function CollectionHelper:RemoveTags(Object)
    for _, Tag in pairs(CollectionService:GetTags(Object)) do
        CollectionService:RemoveTag(Object, Tag)
    end
end

--[[
    @function CollectionHelper.GetFirstTagged

    Returns the first item in the game with a given tag.
    Useful for finding unique items.

    @param Tag The tag to search for.
    @return Any item found with the given tag.
]]

function CollectionHelper:GetFirstTagged(Tag)
    return CollectionService:GetTagged(Tag)[1]
end

return {
    CollectionHelper = CollectionHelper;
}