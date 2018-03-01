repeat wait() until _G["Loaded"]
local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Curve1 = Curve.New({
	CFrame.new(0, 0, 0);
	CFrame.new(0, 10, 0) * CFrame.Angles(0, math.pi, 0);
	CFrame.new(10, 10, 0) * CFrame.Angles(0, math.pi, math.pi);
	CFrame.new(10, 10, 10);
})

Sequence.New("Test", 20)
Sequence.NewAnim("Test", Enum.AnimationType.HermiteSpline, Enum.AnimationControlPointState.Static, 0, workspace.Part, "CFrame", Curve1, "linear", 20, 0, 0)
Sequence.Start("Test")