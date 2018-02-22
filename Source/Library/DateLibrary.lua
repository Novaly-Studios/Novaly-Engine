local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Date			= {}

Date.Month			= {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
Date.MonthNames		= {"January", "February", "March", "April", "May"," June", "July", "August", "September", "October", "November", "December"}
Date.Metatable		= {
	__index = function(Self, Key)
		return Date.CustomMethods[Key] or rawget(Self, Key)
	end;
	__newindex = function(Self, Key, Value)
		if Self[Key] then
			rawset(Self, Key, Value)
		end
	end;
	__add = function(Date1, Date2)
		return Date.AddDays(Date1, Date2:GetDays())
	end;
	__sub = function(Date1, Date2)
		return Date.AddDays(Date1, -Date2:GetDays())
	end;
	__lt = function(Date1, Date2)
		return Date1:GetDays() < Date2:GetDays()
	end;
	__le = function(Date1, Date2)
		return Date1:GetDays() <= Date2:GetDays()
	end;
	__eq = function(Date1, Date2)
		return Date1:GetDays() == Date2:GetDays()
	end;
	__tostring = function(Date1)
		return Date1:DateString()
	end;
}

Date.CustomMethods = {
	["GetDays"] = function(Date1)
		local D2, M2, Y2 = Date1.D, Date1.M, Date1.Y
		local YearDaysToAdd = Date.YearsToDays(Y2)
		local MonthDaysToAdd
		if Date1.UseLeapYears then
			MonthDaysToAdd = Date.MonthsToDays(M2, Date.IsLeapYear(Y2))
		else
			MonthDaysToAdd = Date.MonthsToDays(M2, false)
		end
		return YearDaysToAdd + MonthDaysToAdd + D2
	end;
	["DateString"] = function(Date1, Delimiter)
		Delimiter = Delimiter or "/"
		return Date1.D .. Delimiter .. Date1.M .. Delimiter .. Date1.Y
	end;
	["AddDays"] = function(Date1, Days)
		return Date.AddDays(Date1, Days)
	end;
	["DifferenceInDays"] = function(Date1, Date2)
		local D1, D2 = Date1:GetDays(), Date2:GetDays()
		if D1 > D2 then
			return D1 - D2
		elseif D2 > D1 then
			return D2 - D1
		else
			return 0
		end
	end;
	["GetMonthName"] = function(Date1)
		return Date.MonthNames[Date1.M]
	end;
}

function Date.GetData(Str)
	local F1Index = Str:find("/")
	local Day = tonumber(Str:sub(1, F1Index - 1))
	local Next1 = Str:sub(F1Index + 1)
	local F2Index = Next1:find("/")
	local Month = tonumber(Next1:sub(1, F2Index - 1))
	local Year = tonumber(Next1:sub(F2Index + 1))
	return Date.new(Day, Month, Year)
end

function Date.GetCurrentDate(Time)
	return Date.new(1, 1, 1970) + Date.new(math.floor(Time / (60 * 60 * 24)))
end

function Date.IsLeapYear(Year)
	return (Year % 4 == 0 and Year % 100 ~= 0) or Year % 400 == 0
end

function Date.GetMonth(Index, LeapYear)
	local NewConstants = Date.Month
	if LeapYear then
		NewConstants[2] = 29
	end
	return NewConstants[Index % 12 + 1]
end

function Date.AddDays(Date1, Days)
	local D1, M1, Y1 = Date1.D, Date1.M, Date1.Y
	local NewConstants = Date.Month
	if Date1.UseLeapYears then
		NewConstants[2] = (Date.IsLeapYear(Y1) and 29 or 28)
	end
	for x = 1, Days do
		D1 = D1 + 1
		if D1 > NewConstants[M1] then
			D1 = 1
			M1 = M1 + 1
			if M1 == 13 then
				M1 = 1
				Y1 = Y1 + 1
				if Date1.UseLeapYears then
					NewConstants[2] = (Date.IsLeapYear(Y1) and 29 or 28)
				end
			end
		end
	end
	return Date.new(D1, M1, Y1)
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
		SumDays = SumDays + Date.GetMonth(x, LeapYear)
	end
	return SumDays
end

function Date.new(Day, Month, Year, UseLeapYears)
	if type(Day) == "string" then
		return Date.GetData(Day)
	end
	return setmetatable({D = Day or 0, M = Month or 0, Y = Year or 0, UseLeapYears = UseLeapYears or true}, Date.Metatable)
end

Func({
	Client = {Date = Date};
	Server = {Date = Date};
})

return true