local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Class = Novarine:Get("Class")

local Time = Class:FromName(script.Name)

function Time:Time(Hour, Minute, Second)

    if type(Hour) == "string" then
        return Time.GetData(Hour)
    end

    self.Hour = Hour or 0
    self.Minute = Minute or 0
    self.Second = Second or 0
end

Time.DefaultDelimiter = ":"
Time.SecondsInMinute = 60
Time.SecondsInHour = 60 ^ 2

function Time:__add(Other)
    return self:AddTime(Other)
end

function Time:__sub(Other)
    return self:AddTime(-Other)
end

function Time:__lt(Other)
    return self:GetSeconds() < Other:GetSeconds()
end

function Time:__le(Other)
    return self:GetSeconds() <= Other:GetSeconds()
end

function Time:__eq(Other)
    return self:GetSeconds() == Other:GetSeconds()
end

function Time:__unm()
    return Time.FromSeconds(-self:GetSeconds())
end

function Time:__tostring()
    return self:TimeString()
end

function Time:GetSeconds()

    return  (self.Hour * Time.SecondsInHour) +
            (self.Minute * Time.SecondsInMinute) +
            (self.Second)
end

function Time:TimeString(Delimiter)

    Delimiter = Delimiter or ":"
    return  ("%02d"):format(self.Hour) .. Delimiter ..
            ("%02d"):format(self.Minute) .. Delimiter ..
            ("%02d"):format(self.Second)
end

function Time.GetData(Str, Delimiter)

    local Split = {}
    local Index = 1

    Delimiter = Delimiter or Time.DefaultDelimiter

    for Part in Str:gmatch("[^%" .. Delimiter .. "]+") do
        if Index == 4 then break end
        Split[Index] = tonumber(Part)
        Index = Index + 1
    end

    return Time.new(Split[1], Split[2], Split[3])
end

function Time.AddTime(First, Other)
    return Time.FromSeconds(First:GetSeconds() + Other:GetSeconds())
end

function Time.FromSeconds(Seconds)
    return Time.new(
        math.floor(Seconds / Time.SecondsInHour) % 24,
        math.floor(Seconds / Time.SecondsInMinute) % 60,
        Seconds % 60
    )
end

function Time.GetCurrentTime(Tick, Scalar, Timezone)
    return Time.FromSeconds(Tick * (Scalar or 1) + Time.SecondsInHour * (Timezone or 0))
end

return Time