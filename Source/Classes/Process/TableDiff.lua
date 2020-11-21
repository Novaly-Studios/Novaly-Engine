local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")

local TableDiff = {}
TableDiff.__index = TableDiff

function TableDiff.New()
    return setmetatable({
        LastState = {};
        CurrentState = {};
        ExcludeKeys = {};
        PauseAfterSteps = 10000;
        Count = 0;
    }, TableDiff);
end

local function DeepCopy(Item)
    local Result = {}

    for Key, Value in pairs(Item) do
        if (type(Value) == "table") then
            Result[Key] = DeepCopy(Value)
            continue
        end

        Result[Key] = Value
    end

    return Result
end

function TableDiff:Step()
    self.Count += 1

    if (self.Count == self.PauseAfterSteps) then
        debug.profileend()
        Async.Wait(1/60)
        debug.profilebegin("Differentiate")
        self.Count = 0
    end
end

function TableDiff:Build(NewStateRoot, LastStateRoot, Path, LookForRemoval)
    if ((NewStateRoot == nil) and LastStateRoot) then
        self.Removal(Path, LastStateRoot)
        return
    end

    if LookForRemoval then
        return
    end

    if (NewStateRoot and (LastStateRoot == nil)) then
        self.Addition(Path, NewStateRoot)
        return
    end
    
    if (typeof(NewStateRoot) == "table" and typeof(LastStateRoot) == "table") then
        local ExcludeKeys = self.ExcludeKeys

        for Key, Value in pairs(NewStateRoot) do
            if (ExcludeKeys[Key]) then
                continue
            end

            self:Step()

            local NewPath = Path .. "@" .. Key
            self:Build(Value, LastStateRoot[Key], NewPath, false)
        end

        for Key, Value in pairs(LastStateRoot) do
            if (ExcludeKeys[Key]) then
                continue
            end

            self:Step()

            local NewPath = Path .. "@" .. Key
            -- Only look for removals from old to new (final argument in this call)
            self:Build(NewStateRoot[Key], Value, NewPath, true)
        end

        return
    end

    if (NewStateRoot == LastStateRoot) then
        --self.Same(Path, NewStateRoot)
        return
    end

    self.Change(Path, LastStateRoot, NewStateRoot)
end

function TableDiff:Update()
    --[[
        Copy should be taken before any traversal so we have
        an unmodifiable table. Since 'CurrentState' can
        be changed during the delay time, this can cause
        bugs. Snapshotting beforehand solves any issues.
    ]]

    debug.profilebegin("Copy")
        local Temp = DeepCopy(self.CurrentState)
    debug.profileend()

    debug.profilebegin("Differentiate")
        self:Build(Temp, self.LastState, "", false)
    debug.profileend()

    self.LastState = Temp

    --print("Updated Replication")
end

-- Handlers to be overwritten
--function TableDiff.Same(Path, Value) end
function TableDiff.Change(Path, Old, New) end
function TableDiff.Addition(Path, New) end
function TableDiff.Removal(Path, Old) end

return TableDiff