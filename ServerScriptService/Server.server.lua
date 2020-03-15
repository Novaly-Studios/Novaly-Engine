--[[ local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
Novarine:Init()

local Replication = Novarine:Get("Replication")

Replication.ReplicatedData.One = {
    Two = {
        Three = 3;
        Other = {
            Red = Color3.new(1, 0, 0);
            Green = Color3.new(0, 1, 0);
            Blue = Color3.new(0, 0, 1);
        };
        Nested = {
            Ahhh = {
                Ahhhhh = {
                    Ahhhhhhhhh = {};
                };
            };
        };
        1;
        2;
        3;
    };
};

delay(20, function()
    --Replication.ReplicatedData.One.Two.Nested = nil
    Replication.ReplicatedData.One.Two[2] = 3000
    Replication.ReplicatedData.One.Two[3] = nil
    Replication.ReplicatedData.One.Two[6] = 6000
end)

while true do
    for Iter = 1, 255 do
        wait(0.2)
        if (math.random() > 0.9) then
            Replication.ReplicatedData.One.Two.Other = {
                Yellow = Color3.fromRGB(Iter, Iter, Iter);
                Green = Color3.fromRGB(Iter, Iter, Iter);
                Blue = Color3.fromRGB(Iter, Iter, Iter);
            }
        else
            Replication.ReplicatedData.One.Two.Other = {
                Red = Color3.fromRGB(Iter, Iter, Iter);
                Green = Color3.fromRGB(Iter, Iter, Iter);
                Blue = Color3.fromRGB(Iter, Iter, Iter);
            }
        end
    end
end ]]