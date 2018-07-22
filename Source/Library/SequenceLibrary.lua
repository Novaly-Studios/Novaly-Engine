local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Sequencer = {
    Sequences       = {};
    Tweens          = Require(Modules.Sequence.TweeningStyles);
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
    self.Tweens[Name] = function(CurrentTime)
        return Spring:UpdateAt(CurrentTime).Current
    end
end

function ClientInit()

    -- Main update event
    RunService.Stepped:Connect(function(_, Step)
        for Subject in Pairs(Sequencer.Sequences) do
            if (Subject.Play) then
                Subject:Step(Step)
            end
        end
    end)

    for Name, Properties in Pairs(Sequencer.PresetEasing) do
        Sequencer:AddEasingStyle(Name, TimeSpring.New(Properties))
    end
end

Func({
    Client = {Sequencer = Sequencer, Init = ClientInit};
    Server = {};
})

return true