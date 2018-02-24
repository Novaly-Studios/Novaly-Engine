local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Graphics                      = {}
Graphics.ParticleEmitters           = {}
Graphics.CullCollections            = {}
Graphics.LensFlareItems             = {}
Graphics.Variables                  = {}
Graphics.HorizontalFoV              = 0
Graphics.HalfHorizontalFoV          = 0
Graphics.AspectRatio                = 0

function Graphics.NewRenderWait(Func, WaitFunc)
    
    WaitFunc = WaitFunc or rswait
    
    Sub(function()
        while true do
            Func()
            WaitFunc()
        end
    end)
    
end

function Graphics.UpdateAspectRatio()
    
    local Screen = Graphics.Camera.ViewportSize
    Graphics.AspectRatio = Screen.X / Screen.Y
    
end

function Graphics.UpdateFoV()
    
    --Graphics.HalfHorizontalFoV = math.rad(Graphics.Camera.FieldOfView * Graphics.AspectRatio) / 2
    Graphics.HalfHorizontalFoV = math.atan(math.tan(math.rad(Graphics.Camera.FieldOfView / 2)) * Graphics.AspectRatio)
    Graphics.HorizontalFoV = Graphics.HalfHorizontalFoV * 2
    
end

function Graphics.AddParticleEmitter(Object)
    
    if Object:IsA("ParticleEmitter") then
        
        local Index = #Graphics.ParticleEmitters + 1
        Graphics.ParticleEmitters[ Index ] = {Object, Object.Rate}
        
        Object.Parent.ChildRemoved:Connect(function(Child)
            
            if Child == Object then
                Graphics.ParticleEmitters[Index] = nil
            end
            
        end)
        
    end
    
end

function Graphics.DetectPlayer()
    
    if Players.LocalPlayer == nil then
        return
    end
    
    local Char = Players.LocalPlayer.Character
    
    if Char then
        
        local Head = Char.Head
        if Head then
            if (Head.Position - Graphics.Camera.CFrame.p).magnitude < 0.8 then
                Graphics.PlayerIgnore = Char
            end
        end
        
    end
end

function Graphics.StabiliseParticles()
    
    if CONFIG.gEnableParticleStabilisation == true then
        
        local CurrentFPS = 1 / Latency.GetRenderLatency()
        for x = 1, #Graphics.ParticleEmitters do
            local Target = Graphics.ParticleEmitters[x][1]
            
            if Target.Parent == nil then
                Graphics.ParticleEmitters[x] = nil
            elseif Target:IsA("ParticleEmitter") then
                Target.Rate = math.floor((CurrentFPS / CONFIG._TargetFramerate) * Graphics.ParticleEmitters[x][2])
            end
            
            rswait()
        end
        
    end
    
end

function Graphics.UpdateLensFlares()
    
    if CONFIG.gEnableLensFlare == true then
        
        for _, Flare in next, Graphics.LensFlareItems do
            
            -- Adornee, Object, FlareData.Offset, FlareData.Raycast, FlareData.Rotate, FlareData.Distance, false, FlareData.Size / 2
            for Value = 1, #Flare do
                
                Value = Flare[Value]
                
                local CamCF = Graphics.Camera.CFrame
                local Adornee = Value[1]
                local ImageLabel = Value[2]
                local Diff = Adornee.Position - CamCF.p
                local Dist = Diff.magnitude
                
                if Dist <= Value[6] or Value[6] == 0 then
                    
                    if Graphics.IsVisible(CamCF, Adornee.Position, Graphics.HalfHorizontalFoV) then
                        
                        if Value[4] then
                            
                            local Temp = Adornee
                            if Temp.Parent == nil then
                                Temp = nil
                            end
                            Value[7] = workspace:FindPartOnRayWithIgnoreList(Ray.new(CamCF.p, Diff.unit * Dist), {Temp, Graphics.PlayerIgnore}) == nil
                            
                        else
                            Value[7] = true
                        end
                        
                        if Value[7] then
                            
                            if Value[9] and Value[6] ~= 0 then
                                local Scalar = 1 - Dist / Value[6]
                                local ScaledSize = Value[10] * Scalar
                                Value[2].Size = GUI.V2U(nil, ScaledSize)
                                Value[8] = ScaledSize / 2
                            end
                            
                            local ScreenPosVec3 = Camera:WorldToScreenPoint(Adornee.Position)
                            local ScreenPos = Vector2.new(ScreenPosVec3.X, ScreenPosVec3.Y)
                            local CentrePos = Camera.ViewportSize / 2
                            Value[2].Position = GUI.V2U(nil, math.Lerp(ScreenPos, CentrePos, Value[3]) - Value[8])
                            
                            if Value[5] then
                                local Diff = ScreenPos - CentrePos
                                Value[2].Rotation = math.deg(math.atan2(Diff.y, Diff.x))
                            end
                            
                        end
                        
                    else
                        Value[7] = false
                    end
                else
                    Value[7] = false
                end
            end
        end
    end
end

function c__main()
    
    if CONFIG.gEnableGraphics == false then
        return
    end
    
    local Player = Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local GraphicsGui = Instance.new("ScreenGui", PlayerGui)
    local LensFlareFrame = Instance.new("Frame", GraphicsGui)
    
    Graphics.Camera = workspace.CurrentCamera
    Graphics.UpdateAspectRatio()
    Graphics.UpdateFoV()
    
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Graphics.Camera = workspace.CurrentCamera
    end)
    
    if CONFIG.gEnableLensFlare == true then
        local FlareFrame = Instance.new("Frame", GraphicsGui)
        FlareFrame.Name = "LensFlare"
        Graphics.GraphicsGui = GraphicsGui
    end
    
    if CONFIG.gEnableParticleStabilisation == true then
        --Recursive(workspace, Graphics.AddParticleEmitter)
        workspace.DescendantAdded:Connect(Graphics.AddParticleEmitter)
    end
    
    Graphics.NewRenderWait(Graphics.StabiliseParticles)
    Graphics.NewRenderWait(Graphics.UpdateLensFlares)
    Graphics.NewRenderWait(Graphics.DetectPlayer, wait)
    
    Graphics.Camera.Changed:Connect(function(Property)
        if Property == "ViewportSize" or Property == "FieldOfView" then
            Graphics.UpdateAspectRatio()
            Graphics.UpdateFoV()
        end
    end)
    
    GraphicsGui.Name = "GraphicsGui"
    LensFlareFrame.Name = "LensFlareFrame"
end

function Graphics.IsVisible(Subject, Target, Tolerance)
    return math.acos(Subject.lookVector:Dot((Target - Subject.p).unit)) <= Tolerance
end

function Graphics.NewFlare(ImageID, Offset, Size, Raycast, Distance, Scale, Rotate)
    return {
        IsFlare = true;
        ImageID = "rbxassetid://" .. ImageID;
        Offset = Offset;
        Size = Size;
        HalfSize = Size / 2;
        Raycast = Raycast;
        Distance = Distance;
        Scale = Scale; -- Todo, scale image size with distance
        Rotate = Rotate; -- Todo, rotate image around adornee
    }
end

function Graphics.RegisterFlare(CollectionName, FadeTime, Flares)
    
    local FlareObjects = {}
    
    for x = 1, #Flares do
        local Value = Flares[x]
        local Adornee = Value[1]
        local FlareData = Value[2]
        local Object = Instance.new("ImageLabel")
        Object.BackgroundTransparency = 1
        Object.Size = GUI.V2U(nil, FlareData.Size)
        Object.Image = FlareData.ImageID
        Object.Parent = Graphics.GraphicsGui.LensFlareFrame
        FlareObjects[x] = {Adornee, Object, FlareData.Offset, FlareData.Raycast, FlareData.Rotate, FlareData.Distance, false, FlareData.Size / 2, FlareData.Scale, FlareData.Size}
        local Ref = FlareObjects[x]
        local Name = CollectionName .. x
        Sequence.New(Name, FadeTime, Enum.SequenceType.Conditional, function() return Ref[7] end)
        Sequence.NewAnim(Name, Enum.AnimationType.TwoPoint, Enum.AnimationControlPointState.Static, 0, Object, "ImageTransparency", {1, 0}, "linear", FadeTime)
        Sequence.PreRender(Name, CONFIG._TargetFramerate)
        Sequence.Start(Name)
    end
    
    Graphics.LensFlareItems[CollectionName] = FlareObjects
    
end

function Graphics.RemoveFlare(CollectionName)
    
    local Target = Graphics.LensFlareItems[CollectionName]
    
    for x = 1, #Target do
        pcall(Sequence.Delete, CollectionName .. x)
        Target[x][2]:Destroy()
    end
    
    Graphics.LensFlareItems[CollectionName] = nil
    
end

function Graphics.SetFlareColour(CollectionName, Colours)
    
    local Target = Graphics.LensFlareItems[CollectionName]
    
    for x = 1, #Colours do
        Target[x][2].ImageColor3 = Colours[x]
    end
    
end

Func({
    Client = {Graphics = Graphics, __main = c__main};
    Server = {};
})

return true