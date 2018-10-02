shared()

local Graphics                  = {
    Tags = {
        TransparentPart         = "Graphics:TransparentPart";
        Model                   = "Graphics:Model";
    };
    EffectSequences             = {};
    LensFlareItems              = {};
    SurfaceBillboards           = {};
    TransparentParts            = {};
    HalfHorizontalFoV           = 0;
    AspectRatio                 = 0;
    EffectsEnabled              = true;
};

function Graphics:UpdateScreenValues()

    -- Screen Values and Aspect Ratio
    local ScreenSize        = Graphics.Camera.ViewportSize
    Graphics.ScreenSize     = ScreenSize
    Graphics.ScreenCentre   = ScreenSize / 2
    Graphics.AspectRatio    = ScreenSize.X / ScreenSize.Y

    -- Horizontal Field of View
    Graphics.HalfHorizontalFoV = Math.ATan(Math.Tan(Math.Rad(Graphics.Camera.FieldOfView / 2)) * Graphics.AspectRatio)
end

function Graphics:SetEffect(Item, Property, To)
    self.AnimateItems[Item][Property] = To
end

function Graphics:GetEffect(Item)
    return self.AnimateItems[Item]
end

function Graphics:TweenEffect(Item, Property, To, Time, Style, Wait)

    local SequenceName = Item .. Property
    local Item = self.AnimateItems[Item]
    local TweenSequence = self.EffectSequences[SequenceName]

    if TweenSequence then
        TweenSequence:Destroy()
    end

    TweenSequence = Sequence.New({
        Duration = Time;
    })
    local PropertyTransition = TweenValue.New("SingleTransition", "Linear", CONFIG["_TargetFramerate"], {
        ["EasingStyle"] = Style;
    }, {
        Item[Property];
        To;
    })
    local PropertyAnimation = Animation.New({
        Target      = Item;
        Duration    = Time;
        StartTime   = 0;
    }, {
        [Property]  = PropertyTransition;
    })
    TweenSequence:AddAnimation(PropertyAnimation):Initialise():Resume()

    if Wait then
        TweenSequence:Wait()
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

function Graphics:HandlePartTransparency(Item)
    if Item then
        local SettingsFolder = Item:FindFirstChild("Settings")
        if SettingsFolder then
            local Settings = Misc:TableFromTreeValues(SettingsFolder)
            local MinDist, MaxDist, InitialTransparency, ChangedTransparency = Settings.MinDist, Settings.MaxDist, Settings.InitialTransparency, Settings.ChangedTransparency
            if (MinDist and MaxDist and InitialTransparency and ChangedTransparency) then
                if (Item:IsA("Part")) then
                    Item.Transparency = Math.Lerp(InitialTransparency, ChangedTransparency, Math.Clamp(
                        ((Graphics.Camera.CFrame.p - Item.Position).magnitude - MinDist) / (MaxDist - MinDist)
                    , 0, 1))
                end
            end
        end
    end
end

function Graphics:HandleModel(Item)
    if Item then
        local SettingsFolder = Item:FindFirstChild("Settings")
        if SettingsFolder then
            local MaxDist = SettingsFolder:FindFirstChild("MaxDist")
            if MaxDist then
                local MaxDist = MaxDist.Value
                for _, Object in Pairs(Item:GetDescendants()) do
                    if (Object:IsA("BasePart")) then
                        local OriginalTransparency = Object:FindFirstChild("OriginalTransparency")
                        if OriginalTransparency then
                            Object.Transparency = ((Graphics.Camera.CFrame.p - Item.Position).magnitude > MaxDist and 1 or OriginalTransparency.Value)
                        end
                    end
                end
            end
        end
    end
end

local function ClientInit()

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

    local TransparentPartHandler = OperationTable.New(function(Part)
        Graphics:HandlePartTransparency(Part)
    end)

    --[[local ModelHandler = OperationTable.New(function(Model)
        Graphics:HandleModel(Model)
    end)]]

    Blur.Size           = 0
    Bloom.Intensity     = 0
    SunRays.Intensity   = 0.03
    SunRays.Spread      = 0.1

    Graphics.Bloom      = Bloom
    Graphics.Blur       = Blur
    Graphics.Tint       = Tint
    Graphics.SunRays    = SunRays

    Graphics.Camera = Workspace.CurrentCamera
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

    local function Clean(_, Value)
        return not Value
    end

    RunService.Heartbeat:Connect(function(Step)
        local PartIters = Math.Floor(CONFIG.gTransparentPartsPerFrame * CONFIG._TargetFramerate / (1 / Step))
        -- local ModelIters = Math.Floor(CONFIG.gModelsPerFrame * CONFIG._TargetFramerate / (1 / Step))
        Graphics:UpdateLensFlares()
        Graphics:UpdateBillboards()
        TransparentPartHandler:Next(PartIters)
        TransparentPartHandler:Clean(Clean, PartIters)
        --[[ModelHandler:Next(ModelIters)
        ModelHandler:Clean(Clean, ModelIters)]]
    end)

    Coroutine.Wrap(function()
        while Wait(1/15) do
            Graphics:DetectPlayer()
        end
    end)

    CollectionService:GetInstanceAddedSignal(Graphics.Tags.TransparentPart):Connect(function(Part)
        TransparentPartHandler:Add(Part)
    end)

    for _, Part in Pairs(CollectionService:GetTagged(Graphics.Tags.TransparentPart)) do
        TransparentPartHandler:Add(Part)
    end

    --[[CollectionService:GetInstanceAddedSignal(Graphics.Tags.Model):Connect(function(Part)
        ModelHandler:Add(Part)
    end)

    for _, Part in Pairs(CollectionService:GetTagged(Graphics.Tags.Model)) do
        ModelHandler:Add(Part)
    end]]

    Graphics.Camera.Changed:Connect(function(Property)
        if (Property == "ViewportSize" or Property == "FieldOfView") then
            Graphics:UpdateScreenValues()
        end
    end)

    GraphicsGui.Name = "GraphicsGui"
    LensFlareFrame.Name = "LensFlareFrame"
end

local function ServerInit()
    Coroutine.Wrap(function()
        for Index, Part in Pairs(CollectionService:GetTagged(Graphics.Tags.TransparentPart)) do
            local Settings = Part:FindFirstChild("Settings")
            if Settings then
                Settings.InitialTransparency.Value = Part.Transparency
            end
            if (Index % 50 == 0) then
                Wait()
            end
        end
        --[[for Index, Model in Pairs(CollectionService:GetTagged(Graphics.Tags.Model)) do
            for _, Object in Pairs(Model:GetDescendants()) do
                if (Object:IsA("BasePart")) then
                    Object.
                end
            end
            if (Index % 50 == 0) then
                Wait()
            end
        end]]
    end)()
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

return {
    Client = {Graphics = Graphics, Init = ClientInit};
    Server = {Init = ServerInit};
}