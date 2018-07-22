setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local WrappedUDim2 = Class:FromName(script.Name)

function WrappedUDim2:WrappedUDim2(Subject)
    return {Subject = Subject}
end

function WrappedUDim2:__add(Other)
    return WrappedUDim2.New(self.Subject + Other.Subject)
end

function WrappedUDim2:__sub(Other)
    return WrappedUDim2.New(self.Subject - Other.Subject)
end

function WrappedUDim2:__unm()
    return WrappedUDim2.New(-self.Subject)
end

function WrappedUDim2:__mul(Other)

    local Subject = self.Subject

    if (Type(Other) == "number") then
        return WrappedUDim2.new(
            Subject.X.Offset * Other,
            Subject.X.Scale * Other,
            Subject.Y.Offset * Other,
            Subject.Y.Scale * Other
        )
    end

    return WrappedUDim2.New(
        UDim2.new(
            Subject.X.Offset * Other.X.Offset,
            Subject.X.Scale * Other.X.Scale,
            Subject.Y.Offset * Other.Y.Offset,
            Subject.Y.Scale * Other.Y.Scale
        )
    )
end

function WrappedUDim2:__div(Other)

    local Subject = self.Subject

    if (Type(Other) == "number") then
        return WrappedUDim2.new(
            Subject.X.Offset / Other,
            Subject.X.Scale / Other,
            Subject.Y.Offset / Other,
            Subject.Y.Scale / Other
        )
    end

    return WrappedUDim2.New(
        UDim2.new(
            Subject.X.Offset / Other.X.Offset,
            Subject.X.Scale / Other.X.Scale,
            Subject.Y.Offset / Other.Y.Offset,
            Subject.Y.Scale / Other.Y.Scale
        )
    )
end

return WrappedUDim2