setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)("Wait"))

local PlayerGui = Player:WaitForChild("PlayerGui")
local TestGui = PlayerGui:WaitForChild("TestGui")
local Frame = TestGui:WaitForChild("Frame")
local Button = Frame:WaitForChild("Button")

Button.MouseButton1Click:Connect(function()
    GUI:RippleEffect(Frame, UDim2.new(0, 500, 0, 500))
end)