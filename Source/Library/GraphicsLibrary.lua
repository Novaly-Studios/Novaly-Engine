Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Graphics                  = {
    LensFlareItems              = {};
    SurfaceBillboards           = {};
    HalfHorizontalFoV           = 0;
    AspectRatio                 = 0;
    EffectsEnabled              = true;
}

function Graphics:NewRenderWait(Func, WaitFunc)

    WaitFunc = WaitFunc or HeartbeatWait

    Coroutine.Wrap(function()
        while true do
            if (Graphics.EffectsEnabled) then
                Func()
            end
            WaitFunc()
        end
    end)()
end

function Graphics:UpdateScreenValues()

    -- Screen Values and Aspect Ratio
    local ScreenSize        = Graphics.Camera.ViewportSize
    Graphics.ScreenSize     = ScreenSize
    Graphics.ScreenCentre   = ScreenSize / 2
    Graphics.AspectRatio    = ScreenSize.X / ScreenSize.Y

    -- Horizontal Field of View
    Graphics.HalfHorizontalFoV = Math.ATan(Math.Tan(Math.Rad(Graphics.Camera.FieldOfView / 2)) * Graphics.AspectRatio)

end

function Graphics:TweenEffect(Item, Property, To, Time, Style, Wait)

    local SequenceName = Item .. Property
    local Item = Graphics.AnimateItems[Item]

    if (Sequence:Exists(SequenceName)) then
        Sequence:Delete(SequenceName)
    end

    Sequence:New(SequenceName, Time)
    Sequence:NewAnim(
        SequenceName,
        Enum.AnimationType.TwoPoint,
        Enum.AnimationControlPointState.Static,
        0,
        Item,
        Property,
        {
            Item[Property];
            To;
        },
        Style,
        Time
    )
    Sequence:Start(SequenceName)

    if Wait then
        Sequence:Wait(SequenceName)
    end
end

function Graphics:DetectPlayer()
    
    if Players.LocalPlayer == nil then return end
    local Char = Players.LocalPlayer.Character

    if Char then
        local Head = Char:FindFirstChild("Head")
        if Head then
            if ((Head.Position - Graphics.Camera.CFrame.p).magnitude < 0.8) then
                Graphics.PlayerIgnore = Char
            end
        end
    end
end

function Graphics:UpdateLensFlares()
    
    if (CONFIG.gEnableLensFlare == true) then
        
        for _, FlareCollection in Pairs(Graphics.LensFlareItems) do
            
            local Adornee = FlareCollection.Adornee
            local MaxDistance = FlareCollection.MaxDistance

            if (FlareCollection.Enabled) then

                local TargetPosition = Adornee.Position
                local CheckRay = Ray.new(Graphics.Camera.CFrame.p, (TargetPosition - Graphics.Camera.CFrame.p).unit * MaxDistance)
                local Hit = workspace:FindPartOnRayWithIgnoreList(CheckRay, {Graphics.PlayerIgnore})

                if (Hit == nil) then

                    local IsVisible, Vec3ScreenSpace = Graphics:AccurateIsVisible(TargetPosition)
                    local Vec2ScreenSpace = Vector2.new(Vec3ScreenSpace.X, Vec3ScreenSpace.Y)

                    if (FlareCollection.Transparency < 1) then

                        for _, Pairing in Pairs(FlareCollection.LensFlares) do

                            local FlareObject = Pairing[1]
                            local ImageLabel = Pairing[2]
                            local From = Vec2ScreenSpace - FlareObject.Centre
                            local To = Graphics.ScreenCentre - FlareObject.Centre
                            local NewPos = From:Lerp(To, FlareObject.Offset)
                            ImageLabel.Position = GUI:V2U(nil, NewPos)
                            -- Todo: rotate and scale

                            if (FlareObject.Rotate) then
                                ImageLabel.Rotation = Math.Deg(Math.ATan2(
                                    Vec2ScreenSpace.Y - Graphics.ScreenCentre.Y,
                                    Vec2ScreenSpace.X - Graphics.ScreenCentre.X
                                ))
                            end
                        end
                    end
                    FlareCollection.Show = IsVisible
                else
                    FlareCollection.Show = false
                end
            end
        end
    end
end

function Graphics:UpdateBillboards()

    local SurfaceBillboards = Graphics.SurfaceBillboards

    for Key, Value in Pairs(SurfaceBillboards) do
        if (Value.Part.Parent) then
            Value:Update()
        else
            Value:Destroy()
            SurfaceBillboards[Key] = nil
        end
    end
end

function Graphics:RegisterSurfaceBillboard(Item)
    Table.Insert(self.SurfaceBillboards, Item)
end

function ClientInit()

    if (CONFIG.gEnableGraphics == false) then
        return
    end

    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local GraphicsGui = Instance.new("ScreenGui", PlayerGui)
    local LensFlareFrame = Instance.new("Frame", GraphicsGui)

    local Bloom = Instance.new("BloomEffect", Lighting)
    local Blur = Instance.new("BlurEffect", Lighting)
    local Tint = Instance.new("ColorCorrectionEffect", Lighting)
    local SunRays = Instance.new("SunRaysEffect", Lighting)

    Blur.Size           = 0
    Bloom.Intensity     = 0
    SunRays.Intensity   = 0.03
    SunRays.Spread      = 0.1

    Graphics.Bloom      = Bloom
    Graphics.Blur       = Blur
    Graphics.Tint       = Tint
    Graphics.SunRays    = SunRays
    
    Graphics.Camera = workspace.CurrentCamera
    Graphics.UpdateScreenValues()

    Graphics.AnimateItems   = {
        ["Lighting"]        = Lighting;
        ["Bloom"]           = Bloom;
        ["Blur"]            = Blur;
        ["Tint"]            = Tint;
        ["SunRays"]         = SunRays;
        ["Terrain"]         = Workspace:WaitForChild("Terrain");
    }

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Graphics.Camera = Workspace.CurrentCamera
    end)

    if (CONFIG.gEnableLensFlare == true) then
        local FlareFrame = Instance.new("Frame", GraphicsGui)
        FlareFrame.Name = "LensFlare"
        Graphics.GraphicsGui = GraphicsGui
    end

    Graphics:NewRenderWait(Graphics.UpdateLensFlares)
    Graphics:NewRenderWait(Graphics.UpdateBillboards)
    Graphics:NewRenderWait(Graphics.DetectPlayer, Wait)

    Graphics.Camera.Changed:Connect(function(Property)
        if (Property == "ViewportSize" or Property == "FieldOfView") then
            Graphics:UpdateScreenValues()
        end
    end)

    GraphicsGui.Name = "GraphicsGui"
    LensFlareFrame.Name = "LensFlareFrame"
end

function Graphics:IsVisible(Subject, Target, Tolerance)
    return (Math.ACos(Subject.lookVector:Dot((Target - Subject.p).unit)) <= Tolerance)
end

function Graphics:AccurateIsVisible(Target)

    local Camera = Graphics.Camera
    local Position = Camera:WorldToScreenPoint(Target)
    local ScreenDimensions = Camera.ViewportSize

    if (Position.Z > 0) then
        return (Position.X <= ScreenDimensions.X and Position.X >= 0) and (Position.Y <= ScreenDimensions.Y and Position.Y >= 0), Position
    end

    return false, Position
end

function Graphics:RegisterFlare(Collection)

    for _, FlareObject in Pairs(Collection.LensFlares) do
        FlareObject[2].Parent = Graphics.GraphicsGui.LensFlareFrame
    end

    Graphics.LensFlareItems[#Graphics.LensFlareItems + 1] = Collection
end

Func({
    Client = {Graphics = Graphics, Init = ClientInit};
    Server = {};
})

return true