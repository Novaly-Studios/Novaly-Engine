setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

-- EXAMPLE: Animations

Wait(2)

local Up1 = TweenValue.New("SingleTransition", "Linear", CONFIG["_TargetFramerate"], {
    ["EasingStyle"] = "LowElastic";
    --["SuperEasingStyle"] = "SlowElastic";
}, {
    CFrame.new(0, 0, 0);
    CFrame.new(0, 10, 0) * CFrame.Angles(0, Math.PI / 2, 0);
})

local Up2 = TweenValue.New("SingleTransition", "Linear", CONFIG["_TargetFramerate"], {
    ["EasingStyle"] = "MidElastic";
    --["SuperEasingStyle"] = "SlowElastic";
}, {
    CFrame.new(0, 0, 0);
    CFrame.new(0, 20, 0) * CFrame.Angles(0, Math.PI / 2, 0);
})

local Up3 = TweenValue.New("SingleTransition", "Linear", CONFIG["_TargetFramerate"], {
    ["EasingStyle"] = "HighElastic";
    --["SuperEasingStyle"] = "SlowElastic";
}, {
    CFrame.new(0, 0, 0);
    CFrame.new(0, 30, 0) * CFrame.Angles(0, Math.PI / 2, 0);
})

local Transparency = TweenValue.New("PiecewiseTransition", "Linear", CONFIG._TargetFramerate, {}, {
    0.00;
    0.80;
    0.40;
    0.00;
})

local Anim1 = Animation.New({
    Target          = Workspace.A;
    Duration        = 20;
    StartTime       = 0;
}, {
    CFrame          = Up1;
    Transparency    = Transparency;
})

local Anim2 = Animation.New({
    Target          = Workspace.B;
    Duration        = 20;
    StartTime       = 0;
}, {
    CFrame          = Up2;
    Transparency    = Transparency;
})

local Anim3 = Animation.New({
    Target          = Workspace.C;
    Duration        = 20;
    StartTime       = 0;
}, {
    CFrame          = Up3;
    Transparency    = Transparency;
})

local Sequence1 = Sequence.New({
    Duration = 20;
})

Sequence1:AddAnimation(Anim1):AddAnimation(Anim2):AddAnimation(Anim3):Initialise():Resume()

local SpringAnim1 = SpringAnimation.New({
    Target = Workspace.D;
}, {
    Position = TimeSpring.New({
        Start       = Vector3.new(0, 0, 0);
        Target      = Vector3.new(0, 40, 0);
        Damping     = 0.02; --Vector3.new(0.05, 0.05, 0.05);
        Compression = 1; --Vector3.new(60, 60, 60);
        Velocity    = Vector3.new(0.6, 0.6, 0.6);
    });
    Transparency = TimeSpring.New({
        Target      = 0.50;
        Damping     = 0.05;
        Compression = 1.0;
        Velocity    = 0.20;
    });
})

local SpringSequence1 = SpringSequence.New()
SpringSequence1:AddAnimation(SpringAnim1):Initialise():Resume()