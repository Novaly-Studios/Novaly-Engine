local Svc					= setmetatable({}, {__index = function(_, Key) return game:GetService(Key) end})

local ReplicatedStorage		= Svc.ReplicatedStorage;
local RunService			= Svc.RunService;
local Server				= RunService:IsServer();

local Functions				= ReplicatedStorage["Functions"]
local Events				= ReplicatedStorage["Events"]
local Library				= ReplicatedStorage["Library"]

local Env					= {}
local EnvironmentMT			= {
	
	__index = function(Self, Key)
		
		return Env[Key] or rawget(Self, 1)[Key]
		
	end;
	
}

local PreDefinedObjects		= {
	
	{Functions, {
		
		{"RemoteFunction", Name = "Test"};
		
	}};
	
	{Events, {
		
		{"RemoteEvent", Name = "DeathEffect"};
		
	}};
	
}

local CoreObjects			= {
	
	{Functions, {
		
		{"RemoteFunction", Name = "PingLatency"};
		{"RemoteFunction", Name = "WaitLatency"};
		{"RemoteFunction", Name = "JoinServer"};
		
	}};
	
	{Events, {
		
		{"RemoteEvent", Name = "ReplicateData"};
		{"RemoteEvent", Name = "GetReplicatedData"};
		
	}};
	
}

Env["OriginalEnv"]		= getfenv()

Env["Events"]			= ReplicatedStorage.Events
Env["Functions"]		= ReplicatedStorage.Functions
Env["Assets"]			= ReplicatedStorage.Assets
Env["Modules"]			= ReplicatedStorage.Modules

local function AddObjects(Data)
	
	for Key, Value in next, Data do
		
		local Parent = Value[1]	
		
		for Key, Value in next, Value[2] do
			
			local Object = Instance.new(Value[1])
			
			for Key, Value in next, Value do
				
				if Key ~= 1 then
					
					Object[Key] = Value
					
				end
				
			end
			
			local Old = Parent:FindFirstChild(Object.Name)
			
			if Old ~= nil then
				
				Old:Destroy()
				
			end
			
			Object.Parent = Parent
			
		end
		
	end
	
end

local function AddPlugin(Plugin)
	
	local Object = (Server and Plugin.Server or Plugin.Client)
	
	for Key, Value in next, Object do
		
		if Key == "__main" then
			
			Value()
			
		else
			
			Env[Key] = Value
			
		end
		
	end
	
end

if Server then
	
	AddObjects(CoreObjects)
	AddObjects(PreDefinedObjects)
	
end

return function(Plugin)
	
	if Plugin then
		
		AddPlugin(Plugin)
		
	else
		
		return setmetatable({getfenv(0)}, EnvironmentMT)
		
	end
	
end