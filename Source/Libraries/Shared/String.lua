local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Math = Novarine:Get("Math")

local String = {}
local Compression = {}
Compression.LZW = {}

function Compression.LZW.Compress(Str)

    local Dictionary = {}
    local Result = {}
    local Prev = ""
    local Size = 255

    for x = 0, 255 do
        Dictionary[("" .. x):char()] = x
    end

    for x = 1, #Str do

        local Char = Str:sub(x, x)
        local Concat = Prev .. Char

        if (Dictionary[Concat] ~= nil) then
            Prev = Prev .. Char
        else
            Result[ #Result + 1 ] = Dictionary[Prev]
            Size = Size + 1
            Dictionary[Concat] = Size
            Prev = Char
        end
    end

    if (Prev ~= "") then
        Result[ #Result + 1 ] = Dictionary[Prev]
    end

    return Result
end

function Compression.LZW.Decompress(Data)

    local Dictionary = {}
    local Size = 255
    local Last = ""
    local Result = ""
    local Entry, Val

    for x = 0, 255 do
        Dictionary[x] = ("" .. x):char()
    end

    for x = 1, #Data do

        Val = Data[x]

        if (Dictionary[Val]) then
            Entry = Dictionary[Val]
        elseif (Val == Size) then
            Entry = Last .. Last:sub(1, 1)
        else
            return false
        end

        Result = Result .. Entry
        Dictionary[Size] = Last .. Entry:sub(1, 1)
        Size = Size + 1
        Last = Entry
    end

    return Result
end

function String.Compress(Str, Method, ...)

    local TargetCompression = Compression[Method]
    assert(TargetCompression, "Compression method '" .. Method .. "' does not exist.")

    return TargetCompression.Compress(Str, ...)
end

function String.Uncompress(Str, Method, ...)

    local TargetCompression = Compression[Method]
    assert(TargetCompression, "Compression method '" .. Method .. "' does not exist.")

    return TargetCompression.Decompress(Str, ...)
end

function String.NumberComma(Input)

    local Formatted = Input
    local Index

    while true do

        Formatted, Index = string.gsub(Formatted, "^(-?%d+)(%d%d%d)", '%1,%2')

        if (Index == 0) then
            break
        end
    end

    return Formatted
end

function String.NumberSuffix(Number, DecimalPlaces)
    DecimalPlaces = DecimalPlaces or 1

    if (Number > 1e12) then
        Number = Math.NumberToLength(Number / 1e12, DecimalPlaces) .. "T"
    elseif (Number > 1e9) then
        Number = Math.NumberToLength(Number / 1e9, DecimalPlaces) .. "B"
    elseif (Number > 1e6) then
        Number = Math.NumberToLength(Number / 1e6, DecimalPlaces) .. "M"
    elseif (Number > 1e3) then
        Number = Math.NumberToLength(Number / 1e3, DecimalPlaces) .. "K"
    end

    return tostring(Number)
end

function String.LevenshteinDistance(Initial, Other, InitialLength, OtherLength)

    local Matrix = {}

    -- Set first column to incremental values
    for Iter1 = 1, InitialLength do
        for Iter2 = 1, OtherLength do
            Matrix[Iter1] = Matrix[Iter1] or {}
            Matrix[Iter1][Iter2] = Iter1
        end
    end

    -- Set first row to incremental values
    for Iter2 = 1, OtherLength do
        Matrix[1][Iter2] = Iter2
    end

    for Iter2 = 2, OtherLength do
        for Iter1 = 2, InitialLength do
            local Cost = 1

            if (Initial:sub(Iter2, Iter2) == Other:sub(Iter1, Iter1)) then
                Cost = 0
            end

            Matrix[Iter1][Iter2] = math.min(
                Matrix[Iter1 - 1][Iter2] + 1,
                Matrix[Iter1][Iter2 - 1] + 1,
                Matrix[Iter1 - 1][Iter2 - 1] + Cost
            )
        end
    end

    return Matrix[InitialLength][OtherLength]
end

--[[
    Uses edit distance to find the closest rough
    search match for some text against a set of
    terms.

    @param Set An array of acceptable terms.
    @param Text The search term.

    @todo Add optional delay to prevent lag.
    @return MatchTable, MostLikely, AverageSimilarity, MinSimilarity, MaxSimilarity

    @usage
        local Terms = {
            "Apple";
            "Bread";
            "Phone";
            "Cow";
            "Pen";
        }
        local SearchFor = "bapple"
        local Results, MostLikely, Average = String.ApproximateSearch(Terms, SearchFor)
        print(MostLikely)
]]

function String.ApproximateSearch(Set, Text)
    local Matches = {}
    local SimilaritySum = 0
    local MatchCount = 0
    local MinSimilarity = math.huge
    local MaxSimilarity = 0

    for _, Term in pairs(Set) do
        local Similarity = String.LevenshteinDistance(Text:lower(), Term:lower(), #Text, #Term)
        MinSimilarity = math.min(Similarity, MinSimilarity)
        MaxSimilarity = math.max(Similarity, MaxSimilarity)
        MatchCount = MatchCount + 1

        Matches[MatchCount] = {
            Similarity = Similarity;
            Text = Term;
        }

        SimilaritySum = SimilaritySum + Similarity
    end

    table.sort(Matches, function(Initial, Other)
        return Initial.Similarity < Other.Similarity
    end)

    -- Table of likelihoods where index 1 is most likely and index #Result is least likely
    return Matches, Matches[1].Text, SimilaritySum / MatchCount, MinSimilarity, MaxSimilarity
end

return String