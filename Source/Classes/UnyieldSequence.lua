shared()

local UnyieldSequence = Class:FromName(script.Name)

function UnyieldSequence:UnyieldSequence(StatusFunction)
    return {
        Actions = {StatusFunction};
        Fail    = nil;
    };
end

function UnyieldSequence:Next(NextAction)
    Table.Insert(self.Actions, NextAction)
    return self
end

function UnyieldSequence:SetStage(Stage, Func)
    self.Actions[Stage + 1] = Func
    return self
end

function UnyieldSequence:OnFailed(FailAction)
    self.Fail = FailAction
    return self
end

function UnyieldSequence:Run()

    local Actions = self.Actions
    local Last = {}

    for Index = 1, #Actions do
        Last = {Actions[Index](Unpack(Last))}
        if (not Last[1]) then
            self.Fail(Last[2])
            break
        end
    end

    return self
end

function UnyieldSequence:RunAsync()
    coroutine.wrap(function()
        self:Run()
    end)()
    return self
end

return UnyieldSequence