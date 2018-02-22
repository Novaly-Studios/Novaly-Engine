Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

--[[
	Prefixes:
	g - Graphics Library
	w - Wrapper Library
	s - Sequence Library
	p - Player Data Library
	_ - Global
--]]

Config = {
	
	_TargetFramerate = 60;
	
	gEnableGraphics = true;
	gEnableLensFlare = true;
	gEnableParticleStabilisation = true;
	
	sConditionalTimeTolerance = 1 / 60;
	
	wEnableObjectWrapping = true;
	wCheckSignals = {
		OnClientEvent = true;
		OnServerEvent = true;
	};
	
	pVersion = "1.0.0";
	
}

Func({
	Client = {CONFIG = Config};
	Server = {CONFIG = Config};
})

return true