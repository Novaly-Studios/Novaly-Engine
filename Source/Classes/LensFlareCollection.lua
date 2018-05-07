setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local LensFlareCollection = Class.FromConstructor(script.Name, function(Self, Name, FadeTime, Adornee, MaxDistance)

    Self.Show           = true
    Self.Enabled        = true
    Self.Adornee        = Adornee
    Self.Name           = Name
    Self.MaxDistance    = MaxDistance
    Self.FadeTime       = FadeTime
    Self.Transparency   = 0
    Self.LensFlares     = {}

    Sequence.New(Name, FadeTime, Enum.SequenceType.Conditional, function()
        return Self.Show and Self.Enabled
    end)

end)

function LensFlareCollection:AddLensFlares(...)

    local Args = {...}

    for _, Value in pairs(Args) do

        local ImageLabel = Instance.new("ImageLabel")
        ImageLabel.Image = "rbxassetid://" .. Value.ImageID
        ImageLabel.BackgroundTransparency = 1
        ImageLabel.Size = GUI.V2U(nil, Value.Size)

        Table.Insert(self.LensFlares, {Value, ImageLabel})

        Sequence.NewAnim(
            self.Name,
            Enum.AnimationType.TwoPoint,
            Enum.AnimationControlPointState.Static,
            0,
            ImageLabel,
            "ImageTransparency",
            Value.TransparencyValues,
            "linear",
            self.FadeTime
        )

    end

    Sequence.NewAnim(
        self.Name,
        Enum.AnimationType.TwoPoint,
        Enum.AnimationControlPointState.Static,
        0,
        self,
        "Transparency",
        {
            1;
            0;
        },
        "linear",
        self.FadeTime
    )

end

function LensFlareCollection:Start()

    Sequence.Start(self.Name)

end

function LensFlareCollection:Pause()

    Sequence.Pause(self.Name)

end

function LensFlareCollection:Remove()

    Sequence.Delete(self.Name)

end

return LensFlareCollection