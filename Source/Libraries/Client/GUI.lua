local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local TweenValue = Novarine:Get("TweenValue")
local Sequence = Novarine:Get("Sequence")
local Animation = Novarine:Get("Animation")
local Configuration = Novarine:Get("Configuration")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local GUI = {
    OverStatusObjects = {};
};

function GUI:V2U(VecScale, VecOffset)
    VecScale = VecScale or Vector2.new()
    VecOffset = VecOffset or Vector2.new()
    return UDim2.new(VecScale.X, VecOffset.X, VecScale.Y, VecOffset.Y)
end

function GUI:U2V(UDim2Value)
    return Vector2.new(UDim2Value.X.Scale, UDim2Value.Y.Scale), Vector2.new(UDim2Value.X.Offset, UDim2Value.Y.Offset)
end

function GUI:DivUDim2(UDim2Value, Div)
    return UDim2.new(
        UDim2Value.X.Scale / Div,
        UDim2Value.X.Offset / Div,
        UDim2Value.Y.Scale / Div,
        UDim2Value.Y.Offset / Div
    )
end

function GUI:MulUDim2(UDim2Value, Mul)
    return UDim2.new(
        UDim2Value.X.Scale * Mul,
        UDim2Value.X.Offset * Mul,
        UDim2Value.Y.Scale * Mul,
        UDim2Value.Y.Offset * Mul
    )
end

function GUI:GetCorners(Size, Position)
    return {
        TopLeft = Position;
        TopRight =  Position + Vector2.new(Size.X, 0);
        BottomLeft = Position + Vector2.new(0, Size.Y);
        BottomRight = Position + Vector2.new(Size.X, Size.Y);
    }
end

function GUI:TouchingElement(A, B)
    local g1p, g1s = A.AbsolutePosition, A.AbsoluteSize
    local g2p, g2s = B.AbsolutePosition, B.AbsoluteSize
    return ((g1p.x < g2p.x + g2s.x and g1p.x + g1s.x > g2p.x) and (g1p.y < g2p.y + g2s.y and g1p.y + g1s.y > g2p.y))
end

function GUI:RotatedClip(Element, Parent)
    Element.Changed:Connect(function()
        Element.Visible = GUI.TouchingElement(Element, Parent)
    end)
end

function GUI:RippleEffect(Parent, Position, StartRadius, EndRadius, StartTransparency, EndTransparency, StartColour, EndColour, Time, Style)

    StartRadius = StartRadius or 1
    EndRadius = EndRadius or 50
    StartTransparency = StartTransparency or 0
    EndTransparency = EndTransparency or 1
    StartColour = StartColour or Color3.new(1, 1, 1)
    EndColour = EndColour or Color3.new(1, 1, 1)
    Time = Time or 0.35
    Style = Style or "linear"

    local RippleImage = Instance.new("ImageLabel")
    RippleImage.Size = UDim2.new(0, StartRadius * 2, 0, StartRadius * 2)
    RippleImage.Position = Position - UDim2.new(0, StartRadius, 0, StartRadius)
    RippleImage.ImageTransparency = StartTransparency
    RippleImage.ImageColor3 = StartColour
    RippleImage.Image = "rbxassetid://426424851"
    RippleImage.BackgroundTransparency = 1
    RippleImage.Parent = Parent

    local RippleSequence = Sequence.New({Duration = Time})
    local RipplePosition = TweenValue.New("SingleTransition", "Linear", Configuration._TargetFramerate, {
        EasingStyle = Style;
    }, {
        RippleImage.Position;
        UDim2.new(0, Position.X.Offset - EndRadius, 0, Position.Y.Offset - EndRadius);
    })
    local RippleSize = TweenValue.New("SingleTransition", "Linear", Configuration._TargetFramerate, {
        EasingStyle = Style;
    }, {
        RippleImage.Size;
        UDim2.new(0, EndRadius * 2, 0, EndRadius * 2);
    })
    local RippleTransparency = TweenValue.New("SingleTransition", "Linear", Configuration._TargetFramerate, {
        EasingStyle = Style;
    }, {
        StartTransparency;
        EndTransparency;
    })
    local RippleColour = TweenValue.New("SingleTransition", "Linear", Configuration._TargetFramerate, {
        EasingStyle = Style;
    }, {
        StartColour;
        EndColour;
    })
    local RippleAnim = Animation.New({
        Target              = RippleImage;
        Duration            = Time;
        StartTime           = 0;
    }, {
        Position            = RipplePosition;
        Size                = RippleSize;
        ImageTransparency   = RippleTransparency;
        ImageColor3         = RippleColour;
    })

    RippleSequence:AddAnimation(RippleAnim):Initialise():Resume():Wait():Destroy()
    RippleImage:Destroy()
end

function GUI:CorrectMouseOver()
    local OverStatusObjects = self.OverStatusObjects
    for _, Object in pairs(OverStatusObjects) do
        Object.Status = false
        if (Object.MouseLeaveFunc) then
            Object.MouseLeaveFunc()
        end
    end
end

function GUI:GetMouseOverIndicator(Button, MouseEnterFunc, MouseLeaveFunc)

    local OverObject = {
        Status = false;
        MouseEnterFunc = MouseEnterFunc;
        MouseLeaveFunc = MouseLeaveFunc;
    }
    local OverStatusObjects = self.OverStatusObjects

    -- NOTE These never get cleaned up. Could this leak?

    Button.MouseEnter:Connect(function()
        self:CorrectMouseOver()
        OverObject.Status = true
        if MouseEnterFunc then
            MouseEnterFunc()
        end
    end)

    Button.MouseLeave:Connect(function()
        self:CorrectMouseOver()
        if MouseLeaveFunc then
            MouseLeaveFunc()
        end
    end)

    table.insert(OverStatusObjects, OverObject)

    return function()
        return OverObject.Status
    end
end

return GUI