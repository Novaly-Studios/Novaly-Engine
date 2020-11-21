-- A collection of useful imperatives related to the Roblox data model

local Imperative = require(script.Parent.Imperative)

local Imperatives = {}

--[[
    Fires for all children, and
    when a child is added.
]]
function Imperatives.ChildAdded(Root)
    return Imperative.New(Root.ChildAdded, function()
        return unpack(Root:GetChildren())
    end)
end

--[[
    Fires for all descendants, and
    when a descendant is added.
]]
function Imperatives.DescendantAdded(Root)
    return Imperative.New(Root.DescendantAdded, function()
        return unpack(Root:GetDescendants())
    end)
end

return Imperatives