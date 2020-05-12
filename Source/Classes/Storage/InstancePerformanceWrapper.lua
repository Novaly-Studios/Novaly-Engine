local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local InstancePerformanceWrapper = Class:New("InstancePerformanceWrapper")

function InstancePerformanceWrapper:InstancePerformanceWrapper()
    return {
        Instances = setmetatable({}, {__mode = "k"});
    };
end

--[[ local InstancePerformanceWrapper = {}
InstancePerformanceWrapper.__index = InstancePerformanceWrapper

function InstancePerformanceWrapper.New()
    return setmetatable({
        Instances = setmetatable({}, {__mode = "k"});
    }, InstancePerformanceWrapper);
end ]]

function InstancePerformanceWrapper:Wrap(Root)
    local Wrapped = self.Instances[Root]

    if Wrapped then
        return Wrapped
    end

    local Properties = {}
    local NewWrapped = setmetatable({__ROOT = Root}, {
        __newindex = function(_, Key, Value)
            if (Properties[Key] ~= Value) then
                Properties[Key] = Value
                Root[Key] = Value
            end
        end;
        __index = function(_, Key)
            local Result = Properties[Key]

            if Result then
                return Result
            end

            local NewResult = Root[Key]

            if (type(NewResult) == "function") then
                local Method = Root[Key]

                NewResult = function(_, ...)
                    -- Unwrap instances fed into methods with self-call
                    return Method(Root, ...)
                end
            end

            Properties[Key] = NewResult
            return NewResult
        end;
    })

    self.Instances[Root] = NewWrapped
    return NewWrapped
end

return InstancePerformanceWrapper