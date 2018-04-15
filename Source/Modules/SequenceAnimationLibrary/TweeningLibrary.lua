setfenv(1, require(game:GetService("ReplicatedStorage").Novarine)())

local Tweeners = {}

Tweeners["ObjectLerp"] = function(Lerper, AnimType, Tweener, Forward, Points, Time, Extra)

    local Args = (Extra ~= nil and Extra or {})
    local Path = Tweener(Forward, 0, 1, Time, unpack(Args))

    if AnimType == Enum.AnimationType.TwoPoint then

        return Lerper(Points[1], Points[2], Path)

    elseif AnimType == Enum.AnimationType.BezierCurve then

        return Points:InterpolateBezier(Path, Lerper)

    elseif AnimType == Enum.AnimationType.HermiteSpline then

        return Points:InterpolatePiecewiseCubic(Path, Lerper, Extra[1], Extra[2])

    end

end

Tweeners["Vector3"] = function(...)

    return Tweeners["ObjectLerp"](Math.Lerp, ...)

end

Tweeners["Vector2"] = function(...)

    return Tweeners["ObjectLerp"](Math.LerpVector2, ...)

end

Tweeners["Color3"] = function(...)

    return Tweeners["ObjectLerp"](Math.LerpColor3, ...)

end

Tweeners["UDim2"] = function(...)

    return Tweeners["ObjectLerp"](Math.LerpUDim2, ...)

end

Tweeners["UDim"] = function(...)

    return Tweeners["ObjectLerp"](Math.LerpUDim, ...)

end

Tweeners["CFrame"] = function(AnimType, ...)

    if AnimType == Enum.AnimationType.HermiteSpline then

        return Tweeners["ObjectLerp"](Math.HermiteInterpolateCFrame, AnimType, ...)

    else

        return Tweeners["ObjectLerp"](CFrame.new().lerp, AnimType, ...)

    end

end

Tweeners["number"] = function(AnimType, Tweener, Forward, Points, Time, Extra)

    local Args = (Extra ~= nil and Extra or {})
    
    if AnimType == Enum.AnimationType.TwoPoint then
        
        local Start = Points[1]
        
        return Tweener(Forward, Start, Points[2] - Start, Time, unpack(Args))
        
    elseif AnimType == Enum.AnimationType.BezierCurve then
        
        return Points:Interpolate(Tweener(Forward, 0, 1, Time), Math.Lerp)
        
    elseif AnimType == Enum.AnimationType.HermiteSpline then
        
        return Points:InterpolatePiecewiseCubic(Tweener(Forward, 0, 1, Time), Math.HermiteInterpolate, Extra[1], Extra[2])
        
    end
    
end

return Tweeners