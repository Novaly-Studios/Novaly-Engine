--[[
    Adds custom graphical effects.

    @module Graphics Library
    @alias GraphicsLibrary
    @author TPC9000
]]

local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Configuration = Novarine:Get("Configuration")
local Players = Novarine:Get("Players")
local Async = Novarine:Get("Async")
local OperationTable = Novarine:Get("OperationTable")
local RunService = Novarine:Get("RunService")
local CollectionService = Novarine:Get("CollectionService")
local Sequence = Novarine:Get("Sequence")
local TweenValue = Novarine:Get("TweenValue")
local Animation = Novarine:Get("Animation")
local GUI = Novarine:Get("GUI")
local Misc = Novarine:Get("Misc")
local Math = Novarine:Get("Math")
local Table = Novarine:Get("Table")
local Workspace = Novarine:Get("Workspace")
local NewSurfaceBillboard = Novarine:Get("NewSurfaceBillboard")
--local ObjectRegistry = Novarine:Get("ObjectRegistry")
--local SurfaceBillboard = Novarine:Get("SurfaceBillboard")
local CollectiveObjectRegistry = Novarine:Get("CollectiveObjectRegistry")
local Lighting = Novarine:Get("Lighting")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

local Graphics                  = {
    Tags = {
        TransparentPart         = "Graphics:TransparentPart";
        SurfaceBillboard        = "Graphics:SurfaceBillboard";
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
end

function Graphics:UpdateHorizontalFoV()
    -- Horizontal Field of View
    Graphics.HalfHorizontalFoV = math.atan(math.tan(math.rad(Graphics.Camera.FieldOfView / 2)) * Graphics.AspectRatio)
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
    local PropertyTransition = TweenValue.New("SingleTransition", "Linear", Configuration._TargetFramerate, {
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

    if (Configuration.gEnableLensFlare == true) then

        for _, FlareCollection in pairs(Graphics.LensFlareItems) do

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

                        for _, Pairing in pairs(FlareCollection.LensFlares) do

                            local FlareObject = Pairing[1]
                            local ImageLabel = Pairing[2]
                            local From = Vec2ScreenSpace - FlareObject.Centre
                            local To = Graphics.ScreenCentre - FlareObject.Centre
                            local NewPos = From:Lerp(To, FlareObject.Offset)
                            ImageLabel.Position = GUI:V2U(nil, NewPos)
                            -- Todo: rotate and scale

                            if (FlareObject.Rotate) then
                                ImageLabel.Rotation = math.deg(math.atan2(
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

    --[[ local SurfaceBillboards = Graphics.SurfaceBillboards

    for _, Value in pairs(SurfaceBillboards) do
        if (Value.Part.Parent) then
            Value:Update()
        end
    end ]]
end
--[[ 
function Graphics:RegisterSurfaceBillboard(Item)
    table.insert(self.SurfaceBillboards, Item)
end
 ]]
function Graphics:HandlePartTransparency(Item)
    if Item then
        local SettingsFolder = Item:FindFirstChild("Settings")
        if SettingsFolder then
            local Settings = Misc:TableFromTreeValues(SettingsFolder)
            local MinDist, MaxDist, InitialTransparency, ChangedTransparency = Settings.MinDist, Settings.MaxDist, Settings.InitialTransparency, Settings.ChangedTransparency
            if (MinDist and MaxDist and InitialTransparency and ChangedTransparency) then
                if (Item:IsA("Part")) then
                    Item.Transparency = Math.Lerp(InitialTransparency, ChangedTransparency, math.clamp(
                        ((Graphics.Camera.CFrame.p - Item.Position).magnitude - MinDist) / (MaxDist - MinDist)
                    , 0, 1))
                end
            end
        end
    end
end

function Graphics:IsVisible(Subject, Target, Tolerance)
    return (math.acos(Subject.lookVector:Dot((Target - Subject.p).unit)) <= Tolerance)
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

    for _, FlareObject in pairs(Collection.LensFlares) do
        FlareObject[2].Parent = Table.WaitForItem(Graphics, "GraphicsGui"):WaitForChild("LensFlareFrame")
    end

    Graphics.LensFlareItems[#Graphics.LensFlareItems + 1] = Collection
end

function Graphics:Init()

    if (Configuration.gEnableGraphics == false) then
        return
    end

    local Player = Players.LocalPlayer

    Async.WaitForChild(Player, "PlayerGui")
        :andThen(function(PlayerGui)
            -- This is wrapped in a promise so the yield for PlayerGui doesn't
            -- bog down initial load times.
            local GraphicsGui = Instance.new("ScreenGui", PlayerGui)
            GraphicsGui.Name = "GraphicsGui"

            local LensFlareFrame = Instance.new("Frame", GraphicsGui)
            LensFlareFrame.Name = "LensFlareFrame"

            if (Configuration.gEnableLensFlare == true) then
                local FlareFrame = Instance.new("Frame", GraphicsGui)
                FlareFrame.Name = "LensFlare"
                Graphics.GraphicsGui = GraphicsGui
            end
        end)

    --[[ local Bloom = Instance.new("BloomEffect", Lighting)
    local Blur = Instance.new("BlurEffect", Lighting)
    local Tint = Instance.new("ColorCorrectionEffect", Lighting)
    local SunRays = Instance.new("SunRaysEffect", Lighting)

    local TransparentPartHandler = OperationTable.New(function(Part)
        Graphics:HandlePartTransparency(Part)
    end)

    Blur.Size           = 0
    Bloom.Intensity     = 0
    SunRays.Intensity   = 0.03
    SunRays.Spread      = 0.1

    Graphics.Bloom      = Bloom
    Graphics.Blur       = Blur
    Graphics.Tint       = Tint
    Graphics.SunRays    = SunRays ]]

    Graphics.Camera = workspace.CurrentCamera
    Graphics.UpdateScreenValues()

    Graphics.AnimateItems   = {
        ["Lighting"]        = Lighting;
--[[         ["Bloom"]           = Bloom;
        ["Blur"]            = Blur;
        ["Tint"]            = Tint;
        ["SunRays"]         = SunRays; ]]
        ["Terrain"]         = workspace:WaitForChild("Terrain");
    }

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Graphics.Camera = workspace.CurrentCamera
    end)

    --[[ local function Clean(_, Value)
        return not Value
    end ]]

    --[[ Async.Timer(1/60, function(Step)
        local PartIters = math.floor(Configuration.gTransparentPartsPerFrame * (1 / Step) / Configuration._TargetFramerate)
        Graphics:UpdateLensFlares()
        TransparentPartHandler:Next(PartIters)
        TransparentPartHandler:Clean(Clean, PartIters)
    end, "GraphicsStep") ]]

    --[[ CollectionService:GetInstanceAddedSignal(Graphics.Tags.TransparentPart):Connect(function(Part)
        TransparentPartHandler:Add(Part)
    end) ]]

    CollectiveObjectRegistry.Register("Graphics:SurfaceBillboard", {NewSurfaceBillboard}, function(_, Item)
        if (Workspace:IsAncestorOf(Item)) then
            local Object = NewSurfaceBillboard.New(Item)
            Object:Initial()
            return Object
        end
    end)

    --[[ for _, Part in pairs(CollectionService:GetTagged(Graphics.Tags.TransparentPart)) do
        TransparentPartHandler:Add(Part)
    end ]]

    Graphics.Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        Graphics:UpdateScreenValues()
    end)

    Graphics.Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        Graphics:UpdateHorizontalFoV()
    end)
end

return Graphics