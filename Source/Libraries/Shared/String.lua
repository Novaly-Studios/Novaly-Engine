local String = {}

local Compression   = {}
Compression.LZW     = {}

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

return String