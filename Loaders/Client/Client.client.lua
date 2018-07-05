setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

wait(4)
Sequence.New("Test", 10)
Sequence.NewAnim("Test", Enum.AnimationType.HermiteSpline, Enum.AnimationControlPointState.Static, 0, workspace.Test, "CFrame", Curve.New({
	CFrame.new(90, 0, 0);
	CFrame.new(90, 0, 0);
	CFrame.new(90, 10, 0) * CFrame.Angles(0, math.pi / 2, 0);
	CFrame.new(90, 10, 30);
	CFrame.new(90, 10, 30);
}), "linear", 10, 0.5, 0)
Sequence.Start("Test")