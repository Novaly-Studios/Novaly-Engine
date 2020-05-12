local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local CollectionService = Novarine:Get("CollectionService")

--[[
    Extends CollectionService with useful methods.

    @module CollectionService Extender
    @alias CollectionHelper
    @author TPC9000
    @todo GetAncestorWithTag method
]]

local CollectionHelper = {
    Cache = setmetatable({}, {__mode = "k"});
    ChildCache = setmetatable({}, {__mode = "k"});
    DescendantCache = setmetatable({}, {__mode = "k"}),
};

--[[
    @function GetDescendantsWithTag

    Finds any descendant objects with specified tag.
    
    @usage
        for _, Item in pairs(CollectionHelper:GetDescendantsWithTag(Workspace, "MakeTransparent")) do
            Item.Transparency = 1
        end

    @param Root The top-level instance to search.
    @param Tag The tag to check for.

    @return A table of items found by the search.
]]
function CollectionHelper:GetDescendantsWithTag(Root, Tag)

    local Result = {}

    for _, Object in pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
            table.insert(Result, Object)
        end
    end

    return Result
end

--[[
    @function GetChildrenWithTag

    Finds any children (not descendants) with
    specified tag.

    @usage
        for _, Item in pairs(CollectionHelper:GetChildrenWithTag(Workspace, "MakeTransparent")) do
            Item.Transparency = 1
        end

    @param Root The top-level instance to search.
    @param Tag The tag to check for.

    @return A table of items found by the search.
]]
function CollectionHelper:GetChildrenWithTag(Root, Tag)

    local Result = {}

    for _, Object in pairs(Root:GetChildren()) do
        if (CollectionService:HasTag(Object, Tag)) then
            table.insert(Result, Object)
        end
    end

    return Result
end

--[[
    @function FindFirstDescendantWithTag

    Finds the first descendant with any given tag.

    @usage
        CollectionHelper:FindFirstDescendantWithTag(Workspace, "MakeThisUniquePartTransparent").Transparency = 1

    @param Root The top-level instance to search.
    @param Tag The tag to check for.

    @return An instance with the specified tag, if one was found.
]]
function CollectionHelper:FindFirstDescendantWithTag(Root, Tag)

    for _, Object in pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
            return Object
        end
    end
end

--[[
    @function FindFirstDescendantWithTagPerformanceCached

    Same as FindFirstDescendantWithTag but is cached once.
    Use for performance-intensive searches where the
    hierarchy cannot change.
]]
function CollectionHelper:FindFirstDescendantWithTagPerformanceCached(Root, Tag)
    local Cache = self.Cache
    local ForThis = Cache[Root]

    if ForThis then
        local ForThisTag = ForThis[Tag]

        if ForThisTag then
            return ForThisTag
        end
    else
        Cache[Root] = {}
    end

    for _, Object in pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
            Cache[Root][Tag] = Object

            local Connection; Connection = Object.Parent.ChildRemoved:Connect(function(Child)
                if (Child == Object) then
                    Cache[Root][Tag] = nil
                end

                Connection:Disconnect()
            end)

            return Object
        end
    end
end

--[[
    @function FindFirstChildWithTagPerformanceCached

    Same as FindFirstChildWithTag but is cached once.
    Use for performance-intensive searches where the
    hierarchy cannot change.
]]
function CollectionHelper:FindFirstChildWithTagPerformanceCached(Root, Tag)
    local Cache = self.ChildCache
    local ForThis = Cache[Root]

    if ForThis then
        local ForThisTag = ForThis[Tag]

        if ForThisTag then
            return ForThisTag
        end
    else
        Cache[Root] = {}
    end

    for _, Object in pairs(Root:GetChildren()) do
        if (CollectionService:HasTag(Object, Tag)) then
            Cache[Root][Tag] = Object

            local Connection; Connection = Object.Parent.ChildRemoved:Connect(function(Child)
                if (Child == Object) then
                    Cache[Root][Tag] = nil
                end

                Connection:Disconnect()
            end)

            return Object
        end
    end
end

--[[
    @function GetDescendantsWithTagPerformanceCached

    Same as GetDescendantsWithTag but is cached once.
    Use for performance-intensive searches where the
    hierarchy cannot change.
]]
function CollectionHelper:GetDescendantsWithTagPerformanceCached(Root, Tag)
    local DescendantCache = self.DescendantCache
    local ForThis = DescendantCache[Root]

    if ForThis then
        local ForThisTag = ForThis[Tag]

        if ForThisTag then
            return ForThisTag
        end
    else
        DescendantCache[Root] = {}
        DescendantCache[Root][Tag] = {}
    end

    for _, Object in pairs(Root:GetDescendants()) do
        if (CollectionService:HasTag(Object, Tag)) then
            local Connection; Connection = Object.Parent.ChildRemoved:Connect(function(Child)
                if (Child == Object) then
                    DescendantCache[Root][Tag] = nil
                end

                Connection:Disconnect()
            end)

            table.insert(DescendantCache[Root][Tag], Object)
        end
    end

    return DescendantCache[Root][Tag]
end

--[[
    @function FindFirstChildWithTag

    Finds the first child with any given tag.

    @usage
        CollectionHelper:FindFirstChildWithTag(Workspace, "MakeThisUniquePartTransparent").Transparency = 1

    @param Root The top-level instance to search.
    @param Tag The tag to check for.

    @return An instance with the specified tag, if one was found.
]]
function CollectionHelper:FindFirstChildWithTag(Root, Tag)

    for _, Object in pairs(Root:GetChildren()) do
        if (CollectionService:HasTag(Object, Tag)) then
            return Object
        end
    end
end

--[[
    @function TagHasPrefix

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
    @function RemoveTags

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
    @function GetFirstTagged

    Returns the first item in the game with a given tag.
    Useful for finding unique items.

    @param Tag The tag to search for.
    @return Any item found with the given tag.
]]
function CollectionHelper:GetFirstTagged(Tag)
    return CollectionService:GetTagged(Tag)[1]
end

return CollectionHelper