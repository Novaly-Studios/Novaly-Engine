local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local ReplicatedStorage = Novarine:Get("ReplicatedStorage")

local Sounds = {}

function Sounds:PlaySound(ID, OnObject)
    local Sound = Instance.new("Sound")
    Sound.SoundId = (type(ID) == "number" and "rbxassetid://" .. ID or ID)
    Sound.Ended:Connect(function()
        Sound:Destroy()
    end)
    Sound.Parent = (OnObject and OnObject or ReplicatedStorage)
    Sound:Play()

    return Sound
end

function Sounds:PlaySoundCached(ID, OnObject)
    local Parent = OnObject and OnObject or ReplicatedStorage

    local Sound = Parent:FindFirstChild(tostring(ID)) or Instance.new("Sound")
    Sound.SoundId = (type(ID) == "number" and "rbxassetid://" .. ID or ID)
    Sound.Ended:Connect(function()
        Sound:Destroy()
    end)
    Sound.Name = tostring(ID)
    Sound.Parent = Parent
    Sound:Play()

    return Sound
end

return Sounds