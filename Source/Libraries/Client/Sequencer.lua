local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Modules = Novarine:Get("Modules")
local RunService = Novarine:Get("RunService")
local TimeSpring = Novarine:Get("TimeSpring")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Sequencer = {
    Sequences       = {};
    EasingStyles    = require(Modules.TweeningStyles);
    PresetEasing    = {
        ["LowElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.1;
        };
        ["MidElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.3;
        };
        ["HighElastic"] = {
            Target      = 1.0;
            Damping     = 0.05;
            Compression = 60.0;
            Velocity    = 0.6;
        };
    };
};

function Sequencer:Register(Target)
    self.Sequences[Target] = true
end

function Sequencer:Deregister(Target)
    self.Sequences[Target] = nil
end

function Sequencer:PreRender(Target)
   -- Todo
end

function Sequencer:AddEasingStyle(Name, Spring)
    self.EasingStyles[Name] = function(CurrentTime)
        return Spring:UpdateAt(CurrentTime).Current
    end
end

function Sequencer.Init()

    -- Main update event
    RunService.Stepped:Connect(function(_, Step)
        debug.profilebegin("SequenceBatch")

        for Subject in pairs(Sequencer.Sequences) do
            if (Subject.Play) then
                debug.profilebegin("SequenceStep")

                Subject:Step(Step)

                debug.profileend()
            end
        end

        debug.profileend()
    end)

    for Name, Properties in pairs(Sequencer.PresetEasing) do
        Sequencer:AddEasingStyle(Name, TimeSpring.New(Properties))
    end
end

return Sequencer