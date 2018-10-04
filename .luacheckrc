files[".luacheckrc"].global = false

stds.services = {
  globals = {
    "StarterGui", "CollectionService", "PhysicsService", "ReplicatedStorage",
    "TeleportService", "Players", "UserInputService", "RunService",
    "DataStoreService", "AssetService", "LocalizationService", "Lighting",
    "ContextActionService",
  }
}

stds.engine = {
  globals = {
    "With", "Assets", "LensFlare", "GetNaryLoop", "TypeChain", "SetAssociation", "DataStructures",
    "PlayerDataManagement", "InputLibrary", "CollectionHelper", "Weld", "Classes", "Character", "PlayerData", "Filter",
    "Sub", "UnyieldSequence", "Reduce", "TimeSpring", "Log", "Replication", "SharedData", "Class", "ReplicatedData",
    "HeartbeatWait", "BindRemoteFunction", "LensFlareCollection", "Graphics", "Switch", "Misc", "Sequencer", "Map",
    "Animation", "OperationTable", "FireRemoteEvent", "Event", "RemoteFunction", "GUI", "Count", "Hierarchy",
    "RemoteEvent", "BindRemoteEvent", "Sequence", "SpringSequence", "InvokeRemoteFunction", "OriginalEnv",
    "OperationQueue", "SurfaceBillboard", "Geometry", "Curve", "LinkedList", "CONFIG", "Product", "SimpleSpring",
    "LinkedNode", "ImportClass", "Svc", "Association", "Quaternion", "Date", "Line", "Modules", "SpringAnimation",
    "SteppedWait", "Range", "TweenValue", "Player", "RunServiceWait", "CircularBuffer", "Table", "Math", "String",
    "Broadcast", "Time"
  }
}

stds.roblox = {
  globals = {
    "script", "workspace", "plugin", "shared",
  },

  read_globals = {
    -- Roblox globals (http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace)

    -- variables
    "game", "Enum", math = { fields = { "clamp" } },
    -- functions
    "delay", "elapsedTime", "settings", "spawn", "tick", "time", "typeof",
    "UserSettings", "version", "wait", "warn",
    -- classes
    "CFrame", "Color3", "Instance", "PhysicalProperties", "Ray", "Rect",
    "Region3", "TweenInfo", "UDim", "UDim2", "Vector2", "Vector3", "Random",
    "NumberRange", "NumberSequence", "ColorSequence"
  }
}

ignore = {
  "self",
	"421", -- shadowing local variable
	"422", -- shadowing argument
  "423", -- shadowing loop variable
	"431", -- shadowing upvalue
  "432", -- shadowing upvalue argument
}

max_line_length = false

std = "lua51+roblox+engine+services"
