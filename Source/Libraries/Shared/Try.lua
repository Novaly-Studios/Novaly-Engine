local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Async = Novarine:Get("Async")

local function Raw(Operation, Limit, ...)
    local Object = {}
    local Handlers = {} -- Collection of error handlers
    local Finished
    local Succeeded
    local PcallResults
    local RecursionLimit = Limit or 100 -- Maximum amount of retries

    local function Throw(Exception)
        return {THROW_FAIL = Exception}
    end

    local Args = {...}

    if (Args[1] ~= Throw) then
        Args = {Throw, ...}
    end

    local function CheckError()
        if Finished then
            -- Disallow whacky re-calling behaviour
            return
        end

        if (not PcallResults) then
            -- No point doing anything if the operation hasn't completed
            return
        end

        if (PcallResults[1]) then
            if (type(PcallResults[2]) == "table" and PcallResults[2].THROW_FAIL) then
                local Handler = Handlers[PcallResults[2].THROW_FAIL]

                if (not Handler) then
                    return
                end

                Finished = true
                Async.Spawn(Handler, Object)
                return
            end

            -- Attempt to invoke the Success condition
            local Success = Handlers.Success

            if (not Success) then
                return
            end

            Finished = true -- Following function might yield
            Succeeded = true

            local VarResult = {}

            for Index = 2, #PcallResults do
                VarResult[Index - 1] = PcallResults[Index]
            end

            Success(Object, unpack(VarResult))
            return
        end

        -- If all tests fail, pass to unhandled exception
        local Unhandled = Handlers.Unhandled

        if (not Unhandled) then
            return
        end

        Unhandled(Object, PcallResults[2])
    end

    Object.Retry = function()
        assert(RecursionLimit ~= 0, "Retry limit reached!")
        RecursionLimit = RecursionLimit - 1

        assert(not Succeeded, "Try already succeeded.")
        Finished = false

        Async.Spawn(function()
            PcallResults = {ypcall(Operation, unpack(Args))}
            CheckError()
        end)
    end

    setmetatable(Object, {
        __newindex = function(_, Key, Value)
            if (type(Value) == "function") then
                Handlers[Key] = Value
                rawset(Object, Key, nil)

                -- Case occurs when pcall already completes by the time we connect
                -- (i.e. for non-yielding functions)
                CheckError()
            end
        end;
    })

    Object.Retry()

    return Object
end

local function Wrap(Operation, Limit)
    return function(...)
        return Raw(Operation, Limit, ...)
    end
end

return {
    Try = Raw;
    Wrap = Wrap;
};