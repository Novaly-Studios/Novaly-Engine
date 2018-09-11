setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Date = Class:FromName(script.Name)

function Date:Date(Day, Month, Year, UseLeapYears)

    if (type(Day) == "string") then
        return Date.GetData(Day)
    end

    return {
        Day             = Day or 0;
        Month           = Month or 0;
        Year            = Year or 0;
        UseLeapYears    = UseLeapYears or true;
    }
end

Date.MonthConstants                 = {
    {Name = "January",      Days = 31};
    {Name = "Feburary",     Days = 28};
    {Name = "March",        Days = 31};
    {Name = "April",        Days = 30};
    {Name = "May",          Days = 31};
    {Name = "June",         Days = 30};
    {Name = "July",         Days = 31};
    {Name = "August",       Days = 31};
    {Name = "September",    Days = 30};
    {Name = "October",      Days = 31};
    {Name = "November",     Days = 30};
    {Name = "December",     Days = 31};
}

Date.MonthConstantsLeap             = {
    {Name = "January",      Days = 31};
    {Name = "Feburary",     Days = 29};
    {Name = "March",        Days = 31};
    {Name = "April",        Days = 30};
    {Name = "May",          Days = 31};
    {Name = "June",         Days = 30};
    {Name = "July",         Days = 31};
    {Name = "August",       Days = 31};
    {Name = "September",    Days = 30};
    {Name = "October",      Days = 31};
    {Name = "November",     Days = 30};
    {Name = "December",     Days = 31};
}

function Date:__add(Operand)
    return Date.AddDays(self, Operand:GetDays())
end

function Date:__sub(Operand)
    return Date.AddDays(self, -Operand:GetDays())
end

function Date:__lt(Operand)
    return self:GetDays() < Operand:GetDays()
end

function Date:__le(Operand)
    return self:GetDays() <= Operand:GetDays()
end

function Date:__eq(Operand)
    return self.Day == Operand.Day and self.Month == Operand.Month and self.Year == Operand.Year
end

function Date:__tostring()
    return self:DateString()
end

function Date:GetDays()

    local Day, Month, Year = self.Day, self.Month, self.Year
    local YearDaysToAdd = Date.YearsToDays(Year)
    local MonthDaysToAdd

    if self.UseLeapYears then
        MonthDaysToAdd = Date.MonthsToDays(Month, Date.IsLeapYear(Year))
    else
        MonthDaysToAdd = Date.MonthsToDays(Month, false)
    end

    return YearDaysToAdd + MonthDaysToAdd + Day
end

function Date:DateString(Delimiter, UseInferiorNotation)

    Delimiter = Delimiter or "/"
    return  ("%02d"):format(UseInferiorNotation and self.Month or self.Day) .. Delimiter ..
            ("%02d"):format(UseInferiorNotation and self.Day or self.Month) .. Delimiter ..
            ("%04d"):format(self.Year)
end

function Date:AddDays(Days)
    return Date.Add(self, Days)
end

function Date:DifferenceInDays(Other)

    local SelfDays = self:GetDays()
    local OtherDays = Other:GetDays()

    return math.max(SelfDays, OtherDays) - math.min(SelfDays, OtherDays)
end

function Date:GetMonthName(Date1)
    return Date.MonthNames[Date1.M]
end

function Date.GetData(Str, Delimiter, UseInferiorNotation)

    local Split = {}
    local Index = 1

    Delimiter = Delimiter or "/"

    for Part in Str:gmatch("[^%" .. Delimiter .. "]+") do
        if Index == 4 then break end
        Split[Index] = tonumber(Part)
        Index = Index + 1
    end

    return (UseInferiorNotation and Date.new(Split[2], Split[1], Split[3]) or Date.new(Split[1], Split[2], Split[3]))
end

function Date.GetCurrentDate(Time)
    return Date.new(1, 1, 1970) + Date.new(math.floor(Time / (60 * 60 * 24)))
end

function Date.IsLeapYear(Year)
    return (Year % 4 == 0 and Year % 100 ~= 0) or Year % 400 == 0
end

function Date.GetMonth(Index, LeapYear)
    return Date.GetConstants(LeapYear)[Index % 12 + 1]
end

function Date.GetConstants(LeapYear)
    return (LeapYear and Date.MonthConstantsLeap or Date.MonthConstants)
end

function Date.Add(Subject, Days)

    local DayValue, MonthValue, YearValue = Subject.Day, Subject.Month, Subject.Year
    local NewConstants = Date.GetConstants(Date.IsLeapYear(YearValue))

    for x = 1, Days do

        DayValue = DayValue + 1

        if DayValue > NewConstants[MonthValue].Days then

            DayValue = 1
            MonthValue = MonthValue + 1

            if MonthValue == 13 then

                MonthValue = 1
                YearValue = YearValue + 1

                if Subject.UseLeapYears then

                    NewConstants = Date.GetConstants(Date.IsLeapYear(YearValue))
                end
            end
        end
    end

    return Date.new(DayValue, MonthValue, YearValue)
end

function Date.YearsToDays(Year)

    local SumDays = 0

    for x = 1, Year do
        SumDays = SumDays + (Date.IsLeapYear(x) and 366 or 365)
    end

    return SumDays
end

function Date.MonthsToDays(Month, LeapYear)

    local SumDays = 0

    for x = 1, Month do
        SumDays = SumDays + Date.GetMonth(x, LeapYear).Days
    end

    return SumDays
end

return Date