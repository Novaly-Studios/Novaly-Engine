local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

local Version       = CONFIG.pVersion
local Client        = {}
local Module        = {}
local PlrData       = {}
local OnChange      = {}

function RegisterChange(Player, Attr, Old, New)
    for Key, Value in next, OnChange do
        Value(Player, Attr, Old, New)
    end
end

function Module.WaitForPlayerData(Player)
    if Player == nil then return end
    repeat
        wait(0.5)
    until PlrData[Player.UserId] ~= nil
end

function Module.SetPlayerAttribute(Player, Attr, Value)
    if Player == nil then return end
    RegisterChange(Player, Attr, PlrData[Player.UserId][Attr], Value)
    PlrData[Player.UserId][Attr] = Value
end

function Module.ForcePlayerAttribute(Player, Attr, Value)
    if Player == nil then return end
    local Data = PlrData[Player.UserId]
    if Data ~= nil then
        RegisterChange(Player, Attr, PlrData[Player.UserId][Attr], Value)
        Data[Attr] = Value
        DB:SetAsync(Player.UserId .. "_DATA", Data)
    end
end

function Module.GetPlayerAttribute(Player, Attr)
    if Player == nil then return end
    return PlrData[Player.UserId][Attr]
end

function Module.BindOnChange(Func)
    OnChange[ #OnChange + 1 ] = Func
end

function Module.ForceSave(Player)
    if Player == nil then return end
    local Data = PlrData[Player.UserId]
    if Data ~= nil then
        DB:SetAsync(Player.UserId .. "_DATA", Data)
    end
end

function s__main()
    local IsOnline = pcall(function()
        DB = DataStoreService:GetDataStore("DB" .. Version)
        DB:SetAsync("Test", true)
        return DB:GetAsync("Test") or false
    end)
    local function PlayerAdded(Player)
        local Data = {}
        if IsOnline then
            local Success, Iter = false, 1
            repeat
                Success, Data = pcall(function() return DB:GetAsync(Player.UserId .. "_DATA") end)
                if Success and not Data then
                    Data = {Username = Player.Name}
                    DB:SetAsync(Player.UserId .. "_DATA", Data)
                end
                if Iter > 1 then
                    wait(10)
                end
                Iter = Iter + 1
            until Success
            if Data.Username ~= Player.Name then
                Data.Username = Player.Name
            end
        end
        PlrData[Player.UserId] = Data
    end
    local function PlayerRemoving(Player)
        local UserId = Player.UserId
        local Entry = PlrData[UserId]
        if Entry and IsOnline then
            DB:SetAsync(UserId .. "_DATA", Entry)
            PlrData[UserId] = nil
        end
    end
    Players.PlayerAdded:connect(PlayerAdded)
    Players.PlayerRemoving:connect(PlayerRemoving)
end

function Client.__main()
    local LocalPlayer = Players.LocalPlayer
    Client.Player = LocalPlayer
    repeat wait() until LocalPlayer.Character ~= nil
    Client.Character = LocalPlayer.Character
end

Func({
    Client = Client;
    Server = {PlayerData = Module, __main = s__main};
})

return true