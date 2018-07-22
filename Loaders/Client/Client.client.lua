setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

Wait(2)

local Up1 = TweenValue.New("PiecewiseTransition", "HermiteSpline", CONFIG["_TargetFramerate"], {
    ["EasingStyle"] = "linear";
    ["SuperEasingStyle"] = "outBounce";
}, {
    CFrame.new(0, 0, 0);
    CFrame.new(0, 10, 0) * CFrame.Angles(0, Math.PI / 2, 0);
    CFrame.new(10, 10, 0) * CFrame.Angles(Math.PI / 2, Math.PI / 2, 0);
    CFrame.new(10, 10, 10) * CFrame.Angles(Math.PI / 2, Math.PI / 2, Math.PI / 2);
})

local Transparency = TweenValue.New("PiecewiseTransition", "Linear", CONFIG._TargetFramerate, {}, {
    0.00;
    0.80;
    0.40;
    0.00;
})

local Anim1 = Animation.New({
    Target          = Workspace.A;
    Duration        = 6;
    StartTime       = 0;
}, {
    CFrame          = Up1;
    Transparency    = Transparency;
})

local Sequence1 = Sequence.New({Duration = 6})
Sequence1:AddAnimation(Anim1):Initialise():Resume():Wait():Destroy()

Anim1:Destroy()
Up1:Destroy()