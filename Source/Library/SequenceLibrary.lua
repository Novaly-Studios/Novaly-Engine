local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Sequencer = {
    Sequences = {}; --SetMetatable({}, {__mode = "k"});
}

function Sequencer:Register(Target)
    self.Sequences[Target] = true
end

function Sequencer:Deregister(Target)
    self.Sequences[Target] = nil
end

function Sequencer:PreRender(Target)
    
end

function ClientInit()

    -- Main update event
    RunService.Stepped:Connect(function(_, Step)
        for Subject in Pairs(Sequencer.Sequences) do
            if (Subject.Play) then
                Subject:Step(Step)
            end
            Print(Subject)
        end
    end)
end

Func({
    Client = {Sequencer = Sequencer, Init = ClientInit};
    Server = {};
})

return true