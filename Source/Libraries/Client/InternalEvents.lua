shared()

local InternalEvents = {
    Events = {};
    Scheduled = {};
}

function InternalEvents:Get(Name)
    local Target = self.Events[Name]

    if (not Target) then
        Target = Event:New()
        self.Events[Name] = Target
    end

    return Target
end

function InternalEvents:Invoke(Name, Pass, Arguments)
    local Target = self.Events[Name]
    assert(Target, string.format("Registered event %s not found!", Name))

    if Arguments then
        assert(Arguments.Action, "No action specified on event!")
        Switch(Arguments.Action) {
            ["Delay"] = function()
                delay(Arguments.Duration, function()
                    Target:Fire(unpack(Pass))
                end)
            end;
            ["On"] = function()
                local Interval = Arguments.Interval
                coroutine.wrap(function()
                    local Passed, Data = Arguments.Check()
                    while (not Passed) do
                        if (Interval < 1 / 30) then
                            RunService.Stepped:Wait()
                        else
                            wait(Interval)
                        end
                        Passed, Data = Arguments.Check()
                    end
                    Target:Fire(unpack(Data))
                end)()
            end;
            ["At"] = function()
                local EndTime

                if (Arguments.Reset) then
                    EndTime = tick() + Arguments.Duration
                else
                    local Accum = Target.State.EndTime
                    EndTime = (Accum and Accum or tick()) + Arguments.Duration
                end

                Target.State.EndTime = EndTime
                Target.State.Pass = Pass
                self.Scheduled[Target] = true
            end;
        }
        return
    end

    Target:Fire(unpack(Pass))
end

function InternalEvents:Clean()
    for Index, Item in pairs(self.Events) do
        if (#Item.Connections == 0) then
            self.Events[Index] = nil
        end
    end
end

function InternalEvents:Init()
    RunService.RenderStepped:Connect(function()
        for Target in pairs(InternalEvents.Scheduled) do
            local EndTime = Target.State.EndTime
            if EndTime then
                if (tick() >= EndTime) then
                    Target:Fire(unpack(Target.State.Pass))
                    InternalEvents.Scheduled[Target] = nil
                end
            end
        end
    end)
end

return {
    InternalEvents = InternalEvents;
    Init = InternalEvents.Init;
}