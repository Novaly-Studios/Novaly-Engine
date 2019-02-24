shared()

local LensFlareCollection = Class:FromName(script.Name)

function LensFlareCollection:LensFlareCollection(Name, FadeTime, Adornee, MaxDistance)

    self.Adornee        = Adornee
    self.Name           = Name
    self.MaxDistance    = MaxDistance
    self.FadeTime       = FadeTime
    self.Show           = true
    self.Enabled        = true
    self.Transparency   = 0
    self.LensFlares     = {}

    local FlareSequence = Sequence.New({
        Duration = FadeTime;
        AutoStop = false;
    })
    FlareSequence:BindOnUpdate(function()
        FlareSequence.Increment = (self.Show and self.Enabled) and 1 or -1
    end)
    FlareSequence:Initialise():Resume()
    self.FlareSequence = FlareSequence
end

function LensFlareCollection:AddLensFlares(...)

    local Args = {...}

    for _, Value in pairs(Args) do

        local ImageLabel = Instance.new("ImageLabel")
        ImageLabel.Image = "rbxassetid://" .. Value.ImageID
        ImageLabel.BackgroundTransparency = 1
        ImageLabel.Size = GUI:V2U(nil, Value.Size)

        table.insert(self.LensFlares, {Value, ImageLabel})

        local FlareTransparency = TweenValue.New("PiecewiseTransition", "Linear", CONFIG._TargetFramerate, {}, Value.TransparencyValues)
        self.FlareSequence:AddAnimation(Animation.New({
            Target              = ImageLabel;
            Duration            = self.FadeTime;
            StartTime           = 0;
        }, {
            ImageTransparency   = FlareTransparency;
        }))
    end

    local Transparency = TweenValue.New("PiecewiseTransition", "Linear", CONFIG._TargetFramerate, {}, {0, 1})
    self.FlareSequence:AddAnimation(Animation.New({
        Target              = self;
        Duration            = self.FadeTime;
        StartTime           = 0;
    }, {
        ImageTransparency   = Transparency;
    }))
end

function LensFlareCollection:Start()
    Sequence:Resume()
end

function LensFlareCollection:Pause()
    Sequence:Pause()
end

function LensFlareCollection:Remove()
    Sequence:Destroy()
end

return LensFlareCollection