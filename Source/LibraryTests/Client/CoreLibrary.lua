shared()

local Tests = {}

function Tests:Count()
    return (
        Count {1, 2, 3} == 3 and
        Count {a = 1, b = 2} == 2 and
        Count {a = 1, 2} == 2
    )
end

return Tests