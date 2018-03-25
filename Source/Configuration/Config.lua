local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

--[[
    Prefixes:
    co - Communication Library
    g - Graphics Library
    w - Wrapper Library
    s - Sequence Library
    p - Player Data Library
    _ - Global
--]]

Config = {
    
    _TargetFramerate = 60;

    coMaxTries = 60;
    coPollInterval = 0.5;
    
    gEnableGraphics = true;
    gEnableLensFlare = true;
    gEnableParticleStabilisation = true;
    
    sConditionalTimeTolerance = 1 / 60;
    
    wEnableObjectWrapping = true;
    wCheckSignals = {
        OnClientEvent = true;
        OnServerEvent = true;
    };
    
    pSaveInterval = 30;
    pVersion = "1.0.0";
    pDataStoreName = "PlayerData";
    pBackupSuffix = "_Backup";
    pDataStoreGetRetryWait = 5;
    
}

Func({
    Client = {CONFIG = Config};
    Server = {CONFIG = Config};
})

return true