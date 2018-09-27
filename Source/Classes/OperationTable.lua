shared()

local OperationTable = Class:FromName(script.Name)

function OperationTable:OperationTable(Handler)
    Assert(Handler)
    return {
        Current = 1;
        Handler = Handler;
        Items = {};
    }
end

function OperationTable:Clean(Condition, Count)
    local Items = self.Items
    for Index = 1, #Items do
        local Value = Items[Index]
        if (Count == 0) then
            break
        end
        if (Condition(Index, Value)) then
            Items[Index] = nil
        end
        Count = Count - 1
    end
end

function OperationTable:Add(Item)
    Table.Insert(self.Items, Item)
end

function OperationTable:Next(Count)

    local Items = self.Items
    local Handler = self.Handler
    local Current = self.Current

    for Index = 1, Count do
        local Value = Items[Current]
        if (not Value) then
            Current = 1
            break
        end
        Handler(Value, Items, Index)
        Current = Current + 1
    end

    self.Current = Current
end

return OperationTable