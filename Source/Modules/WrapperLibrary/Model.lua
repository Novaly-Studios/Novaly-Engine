local Func = require(game:GetService("ReplicatedStorage").Import)
setfenv(1, Func())

return {
	Properties = {
		Anchored = -1;
	};
	Methods = {
		CallRecursive = function(Self, Func)
			local Items = Self:GetChildren()
			for Index = 1, #Items do
				local Object = Items[Index]
				Func(Object)
				if Object:IsA("Model") then
					Object:CallRecursive(Func)
				end
			end
		end;
		Weld = function(Self, ...)
			assert(Self.PrimaryPart ~= nil, "This model does not have a primary part and cannot be welded!")
			Weld.WeldModel("Weld", Self, Self.PrimaryPart, ...)
		end;
		AnchoredChange = function(Self, Old, New)
			--[[Recursive(Self, function(Object)
				if Object:IsA("BasePart") then
					Object.Anchored = New
				end
			end)]]
			Self:CallRecursive(function(Object)
				if Object:IsA("BasePart") then
					Object.Anchored = New
				end
			end)
		end;
	};
}