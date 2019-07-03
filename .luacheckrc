files[".luacheckrc"].global = false

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

std = "lua51+roblox"
