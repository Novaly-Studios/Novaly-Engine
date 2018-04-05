local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local GUI = {}

function GUI.V2U(VecScale, VecOffset)

    VecScale = VecScale or Vector2.new()
    VecOffset = VecOffset or Vector2.new()
    return UDim2.new(VecScale.X, VecOffset.X, VecScale.Y, VecOffset.Y)

end

function GUI.U2V(UDim2Value)

    return Vector2.new(UDim2Value.X.Scale, UDim2Value.Y.Scale), Vector2.new(UDim2Value.X.Offset, UDim2Value.Y.Offset)

end

function GUI.DivUDim2(UDim2Value, Div)

    return UDim2.new(
        UDim2Value.X.Scale / Div,
        UDim2Value.X.Offset / Div,
        UDim2Value.Y.Scale / Div,
        UDim2Value.Y.Offset / Div
    )

end

function GUI.GetCorners(Size, Position)

    return {
        TopLeft = Position;
        TopRight =  Position + Vector2.new(Size.X, 0);
        BottomLeft = Position + Vector2.new(0, Size.Y);
        BottomRight = Position + Vector2.new(Size.X, Size.Y);
    }

end

function GUI.TouchingElement(A, B)

    local g1p, g1s = A.AbsolutePosition, A.AbsoluteSize
    local g2p, g2s = B.AbsolutePosition, B.AbsoluteSize
    
    return ((g1p.x < g2p.x + g2s.x and g1p.x + g1s.x > g2p.x) and (g1p.y < g2p.y + g2s.y and g1p.y + g1s.y > g2p.y))
    
end

function GUI.RotatedClip(Element, Parent)

    Element.Changed:connect(function(Property)
        
        Element.Visible = GUI.TouchingElement(Element, Parent)
        
    end)

end

function GUI.MulUDim2(UDim2Value, Mul)

    return UDim2.new(

        UDim2Value.X.Scale * Mul,
        UDim2Value.X.Offset * Mul,
        UDim2Value.Y.Scale * Mul,
        UDim2Value.Y.Offset * Mul

    )

end

function GUI.RoundOffset(UDim2Value, Determinant)

    local F = function(x) return math.floor(x + 0.5) end

    if Determinant == true then

        F = math.floor

    elseif Determinant == false then

        F = math.ceil

    end

    return UDim2.new(

        F(UDim2Value.X.Scale),
        F(UDim2Value.X.Offset),
        F(UDim2Value.Y.Scale),
        F(UDim2Value.Y.Offset)

    )

end

function GUI.RippleEffect(Parent, Position, RippleImage, StartRadius, EndRadius, StartTransparency, EndTransparency, StartColour, EndColour, Time, Style)

    StartRadius = StartRadius or 1
    EndRadius = EndRadius or 50
    StartTransparency = StartTransparency or 0
    EndTransparency = EndTransparency or 1
    StartColour = StartColour or Color3.new(1, 1, 1)
    EndColour = EndColour or Color3.new(1, 1, 1)
    Time = Time or 0.35
    Style = Style or "linear"
    
    local Name = Sequence.GetUniqueName()
    local RippleImage = Instance.new("ImageLabel")
    RippleImage.Size = UDim2.new(0, StartRadius * 2, 0, StartRadius * 2)
    RippleImage.Position = Position - UDim2.new(0, StartRadius, 0, StartRadius)
    RippleImage.ImageTransparency = StartTransparency
    RippleImage.ImageColor3 = StartColour
    RippleImage.Image = "rbxassetid://426424851"
    RippleImage.BackgroundTransparency = 1
    RippleImage.Parent = Parent
    Sequence.New(Name, Time)
    Sequence.NewAnim(Name, Enum.AnimationType.TwoPoint, Enum.AnimationControlPointState.Static, 0, RippleImage, "Position", {RippleImage.Position, UDim2.new(0, Position.X.Offset - EndRadius, 0, Position.Y.Offset - EndRadius)}, Style, Time)
    Sequence.NewAnim(Name, Enum.AnimationType.TwoPoint, Enum.AnimationControlPointState.Static, 0, RippleImage, "Size", {RippleImage.Size, UDim2.new(0, EndRadius * 2, 0, EndRadius * 2)}, Style, Time)
    Sequence.NewAnim(Name, Enum.AnimationType.TwoPoint, Enum.AnimationControlPointState.Static, 0, RippleImage, "ImageTransparency", {StartTransparency, EndTransparency}, Style, Time)
    Sequence.NewAnim(Name, Enum.AnimationType.TwoPoint, Enum.AnimationControlPointState.Static, 0, RippleImage, "ImageColor3", {StartColour, EndColour}, Style, Time)
    Sequence.Start(Name)
    Sequence.Wait(Name)
    Sequence.Delete(Name)
    RippleImage:Destroy()

end

function GUI.GetPosition(gX, eX, eY, bX, bY, Index)
    
    local cX, cY = 0, 0
    
    while Index > 1 do
        
        cX = cX + eX
        
        if cX >= gX then
            
            cX = 0
            cY = cY + eY
            
        end
        
        Index = Index - 1
        
    end
    
    return Vector2.new(cX + bX, cY + bY), Vector2.new(eX - bX * 2, eY - bY * 2)
    
end

Func({
    Client = {GUI = GUI};
    Server = {};
})

return true