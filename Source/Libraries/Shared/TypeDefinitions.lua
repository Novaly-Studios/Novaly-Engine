local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Typing = Novarine:Get("Typing")

Typing:AddDefinition("PriorityQueue", {
    Size = Typing.Number;
    Heap = Typing.Table;

    Add = Typing.Function;
    SiftUp = Typing.Function;
    SiftDown = Typing.Function;
    IsEmpty = Typing.Function;
    GetAscendentOf = Typing.Function;
    GetLeftOf = Typing.Function;
    GetRightOf = Typing.Function;
    Get = Typing.Function;
    Pop = Typing.Function;
})

Typing:AddDefinition("ValueDataPair", {
    Value = Typing:Any();
    Data = Typing:Any();
    ValueDataPair = Typing:Equivalent(true);
})

Typing:AddDefinition("Date", {
    Day = Typing.Number;
    Month = Typing.Number;
    Year = Typing.Number;
})