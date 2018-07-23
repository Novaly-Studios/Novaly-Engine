setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

Graphics:TweenEffect(
	"Tint", "TintColor", Color3.new(1, 0, 0), 10, "linear", false
)

wait(5)

Graphics:TweenEffect(
	"Tint", "TintColor", Color3.new(0, 0.5, 0), 10, "linear", false
)