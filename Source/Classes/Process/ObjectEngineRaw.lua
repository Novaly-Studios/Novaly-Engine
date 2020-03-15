local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local ObjectEngineRaw = Class:FromName(script.Name)

local function InternalDiff(ToTree, FromTree, Constructing, OnSame, OnDifferent, OnCreate, OnDestroy, Path)
    Path = Path or {}
    local Pool = {}

    for Key in pairs(FromTree) do
        Pool[Key] = true
    end

    for Key in pairs(ToTree) do
        Pool[Key] = true
    end

    Constructing = Constructing or {}

    for Key in pairs(Pool) do
        local FromTreeSubject = FromTree[Key]
        local ToTreeSubject = ToTree[Key]
        local FromTreeIsTable = (type(FromTreeSubject) == "table")

        local NewPath = {}

        for Index, Item in pairs(Path) do
            NewPath[Index] = Item
        end

        table.insert(NewPath, Key)

        if (FromTreeSubject and ToTreeSubject) then
            if (FromTreeIsTable or (FromTreeSubject == ToTreeSubject)) then
                OnSame(Key, NewPath)
            else
                OnDifferent(Key, NewPath)
            end

            if FromTreeIsTable then
                local New = {}
                Constructing[Key] = New
                InternalDiff(FromTreeSubject, ToTreeSubject, New, OnSame, OnDifferent, OnCreate, OnDestroy, NewPath)
            else
                Constructing[Key] = ToTreeSubject
            end
        elseif (not FromTreeSubject and ToTreeSubject) then
            OnDestroy(Key, NewPath)
            Constructing[Key] = nil
        elseif (FromTreeSubject and not ToTreeSubject) then
            OnCreate(Key, NewPath)
            if FromTreeIsTable then
                local New = {}
                Constructing[Key] = New
                --Diff(FromTreeSubject, FromTreeSubject, New, Callback)
                InternalDiff(FromTreeSubject, New, New, OnSame, OnDifferent, OnCreate, OnDestroy, NewPath)
            else
                Constructing[Key] = FromTreeSubject
            end
        end
    end

    return Constructing
end

function ObjectEngineRaw:ObjectEngineRaw()
    return setmetatable({}, ObjectEngineRaw)
end

function ObjectEngineRaw:Diff(ToTree, FromTree)
    return InternalDiff(ToTree, FromTree, {},
                        self.OnSame or function() end,
                        self.OnDifferent or function() end,
                        self.OnCreate or function() end,
                        self.OnDestroy or function() end)
end

function ObjectEngineRaw:SetOnCreate(Func)
    self.OnCreate = Func
end

function ObjectEngineRaw:SetOnDestroy(Func)
    self.OnDestroy = Func
end

function ObjectEngineRaw:SetOnSame(Func)
    self.OnSame = Func
end

function ObjectEngineRaw:SetOnDifferent(Func)
    self.OnDifferent = Func
end

return ObjectEngineRaw