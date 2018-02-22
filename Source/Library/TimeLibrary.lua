local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Time          = {}
Time.Metatable      = {
    __index = function(Self, Key)
        return Time.CustomMethods[Key] or rawget(Self, Key)
    end;
    __newindex = function(Self, Key, Value)
        if Self[Key] then
            rawset(Self, Key, Value)
        end
    end;
    __add = function(Self, New)
        return Self:AddTime(New)
    end;
    __sub = function(Self, New)
        return Self:AddTime(New, true)
    end;
    __lt = function(Self, Time2)
        return Self:GetSeconds() < Time2:GetSeconds()
    end;
    __le = function(Self, Time2)
        return Self:GetSeconds() <= Time2:GetSeconds()
    end;
    __eq = function(Self, Time2)
        return Self:GetSeconds() == Time2:GetSeconds()
    end;
    __unm = function(Self)
        return Time.FromSeconds(-Self:GetSeconds())
    end;
    __tostring = function(Time1)
        return Time1:TimeString()
    end;
}

Time.CustomMethods = {
    ["GetSeconds"] = function(Time1)
        return (Time1.H * 60 ^ 2) + (Time1.M * 60) + Time1.S
    end;
    ["TimeString"] = function(Time1, Delimiter)
        local function fTime(Value, Pad)
            return ("%0"..Pad.."d"):format(Value)
        end
        Delimiter = Delimiter or ":"
        return fTime(Time1.H, 2) .. Delimiter .. fTime(Time1.M, 2) .. Delimiter .. fTime(Time1.S, 2)
    end;
    ["AddTime"] = function(Time1, Time2, Negate)
        return Time.FromSeconds(Time1:GetSeconds() + (Negate and -Time2:GetSeconds() or Time2:GetSeconds()))
    end;
}

function Time.FromSeconds(Seconds)
    return Time.new(math.floor(Seconds / 60 ^ 2) % 24, math.floor(Seconds / 60) % 60, math.floor(Seconds % 60))
end

function Time.GetTime(Timezone)
    return Time.FromSeconds(tick() + 60 ^ 2 * (Timezone or 0))
end

function Time.new(Hours, Minutes, Seconds)
    return setmetatable({S = Seconds or 0, M = Minutes or 0, H = Hours or 0}, Time.Metatable)
end

Func({
    Client = {Time = Time};
    Server = {Time = Time};
})

return true