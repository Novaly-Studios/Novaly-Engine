--[[
    Prefixes:
    co - Communication Library
    g - Graphics Library
    s - Sequence Library
    p - Player Data Library
    r - Replication Library
    _ - Global
--]]

local Config = {

    _TargetFramerate = 60;

    coMaxTries = 60;
    coPollInterval = 0.5;

    gEnableGraphics = true;
    gEnableLensFlare = false;
    gTransparentPartsPerFrame = 15;

    sConditionalTimeTolerance = 1 / 60;

    rKey = "Vars"; -- Todo
}

return Config