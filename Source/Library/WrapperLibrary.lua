local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local Wrapper               = {}
Wrapper.ObjectItems         = {}
Wrapper.WrapperCache        = {}
Wrapper.OldInstance         = Instance
Wrapper.OldRequire          = require
Wrapper.ToWrap              = {
    -- Environment variables to wrap
    ["game"]                = true;
    ["Game"]                = true;
    ["workspace"]           = true;
    ["Workspace"]           = true;
    ["Assets"]              = true;
    ["Modules"]             = true;
    ["Classes"]             = true;
}

-- Storing as external metatables will allow metamethods such as __eq to function correctly
Wrapper.Metatable = {

    __eq = function(Self, Other)

        return Self.Object == Other.Object

    end;
    __index = function(Self, Key)
        
        -- The user accesses a property from the object
        local Properties = rawget(Self, 1)
        local Methods = rawget(Self, 2)
        local Object = rawget(Self, "Object")
        
        -- Determine if user is indexing a custom property or method
        local IValue = Properties[Key] or Methods[Key]
        
        -- Determine if user is indexing a real instance property or method
        local OValue = Wrapper.Test(Object, Key)
        
        -- Actual value
        local Value = IValue or OValue
        local ReturnValue = Value
        
        if type(Value) == "function" and OValue ~= nil then

            -- Return a fake function which wraps the raw object's method, tricking the user into calling it
            ReturnValue = function(_, ...)

                local Args = {...}
                local Result = {}
                -- Inject a 'this' object into method environment for easy self-referencing
                Wrapper.SetMethodEnvironment(Value, Self)

                if IValue == nil then

                    -- Strip objects so we can pass them to the method
                    Wrapper.RecursiveStripObjects(Args)

                end

                -- Encapsulate returned result(s) into a table
                Result = {Value(Object, unpack(Args))}
                -- Re-wrap any instances in the resultant output
                Wrapper.RecursiveWrapObjects(Result)

                return unpack(Result)

            end

        elseif tostring(Value) == ("Signal " .. Key) then

            -- Wraps RbxScriptSignals
            if Wrapper.DoesExist(Value, "connect") then

                -- Only wrap specific RbxScriptSignal objects as listed in configuration

                if CONFIG.wCheckSignals[Key] ~= nil then

                    ReturnValue = setmetatable({Value}, Wrapper.RbxSignalMetatable)

                else

                    ReturnValue = Value

                end
            end

        end
        
        -- Wrap indexed item
        ReturnValue = {ReturnValue}
        Wrapper.RecursiveWrapObjects(ReturnValue)

        return unpack(ReturnValue)
        
    end;
    __newindex = function(Self, Key, Value)
        
        -- The user creates a new property in the wrapped object...
        rawset(Self, Key, nil)
        local Object = rawget(Self, "Object")

        if type(Value) == "function" then

            -- If setting a property to a function...
            local Temp = Value

            Value = function(...)

                -- Since the game itself will call this it will pass unwrapped objects which will need to be wrapped
                local Args = {...}
                Wrapper.RecursiveWrapObjects(Args)

                return Temp(unpack(Args))

            end

        end
        
        -- Todo: use coroutine
        local Success, Res = pcall(function()

            -- Attempt to apply value to object property
            local Apply = Value

            if Wrapper.DoesExist(Apply, "Object") then

                Apply = Apply.Object

            elseif type(Apply) == "table" then

                Wrapper.RecursiveStripObjects(Apply)

            end

            Object[Key] = Apply

        end)
        
        -- If attempted applying has failed...
        if not Success then

            local NewProperties = rawget(Self, 1)
            -- Show 'not a valid member of' error or other error thrown

            if NewProperties[Key] == nil then

                if Res:find("valid member") then

                    error("'" .. Key .. "' is not a valid member of " .. tostring(Object))

                else

                    error(tostring(Object) .. ": " .. Res)

                end

            end

            -- Obtain custom property change handler and invoke it with new and old values
            local PropertyChange = rawget(Self, 2)[Key .. "Change"]

            if PropertyChange ~= nil then

                Wrapper.SetMethodEnvironment(PropertyChange, Self)
                PropertyChange(Self, NewProperties[Key], Value)

            end

            NewProperties[Key] = Value
            rawset(Self, 1, NewProperties)

        end
        
    end;
    __tostring = function(Self)

        return "[Wrapped] " .. tostring(Self.Object)

    end;

}

Wrapper.RbxSignalMetatable = {
    __index = function(Self, Key)

        local Signal = rawget(Self, 1)
        local Func = Signal[Key]

        return function(_, UserFunc)

            -- Below is equivalent to event connection
            Func(Signal, function(...)

                -- Wrap any instances for the event handler
                local Args = {...}
                Wrapper.RecursiveWrapObjects(Args)
                UserFunc(unpack(Args))

            end)

        end

    end;
    __eq = function(Self, Other)

        return Self[1] == Other[1]

    end;

}

function Wrapper.GetAttribute(Object, Key)

    -- Horrible function but it needs to be used later
    return Object[Key]

end

function Wrapper.Test(Object, Key)

    -- Test an object (Object) for a property (Key)
    -- Coroutines are faster at error catching than protected calls
    local Success, Result = coroutine.resume(coroutine.create(Wrapper.GetAttribute), Object, Key)

    if Success == true then

        return Result

    else

        return nil

    end

end

function Wrapper.DoesExist(Object, Property)

    -- This tests userdata for property existence without throwing errors
    -- TODO: Check if it returns an error too so that we know a property may exist but have a null value
    return Wrapper.Test(Object, Property) ~= nil

end

function Wrapper.SetMethodEnvironment(Method, Object)

    local FunctionEnv = getfenv(Method)

    pcall(setfenv, Method, setmetatable({}, {

        __index = function(_, Key)

            return ((Key == "self" or Key == "this") and Object or FunctionEnv[Key])

        end;

    }))

end

function Wrapper.RecursiveStripObjects(Array)

    -- Recursively strip wrapped objects
    for Key, Value in next, Array do

        -- Check if value is a wrapped instance
        if type(Value) == "table" then

            if Wrapper.DoesExist(Value, "Object") then

                Array[Key] = Value.Object

            else

                Wrapper.RecursiveStripObjects(Value)

            end

        end

    end

end

function Wrapper.RecursiveWrapObjects(Array)

    -- Recursively wrap raw instances
    for Key, Value in next, Array do

        -- Check if value is an instance
        if type(Value) == "userdata" then

            if Wrapper.DoesExist(Value, "ClassName") then

                Array[Key] = Wrapper.Wrap(Value)

            end

        elseif type(Value) == "table" then

            -- Recursive traversal again over a sub-table
            Wrapper.RecursiveWrapObjects(Value)

        end

    end

end

function Wrapper.Wrap(Object)
    
    -- If wrapped objects are wrapped again it will cause problems
    assert(not Wrapper.DoesExist(Object, "Object"), "Error: Wrapped objects cannot be wrapped again!")
    local Cache = Wrapper.WrapperCache
    local Cached = Cache[Object]

    if Cached then

    	return Cached

    end
    
    -- Wrapped instance shell with custom properties and methods if they exist
    local Items = Wrapper.ObjectItems[Object.ClassName] or {
        Properties = {};
        Methods = {};
    }
    
    -- Copy properties, only point to methods for memory efficiency
    local Wrapped = setmetatable({table.Clone(Items.Properties), Items.Methods, Object = Object}, Wrapper.Metatable)
    
    -- Add to cache
    Cache[Object] = Wrapped
    
    return Wrapped

end

-- Easy game service access (e.g. Svc["Workspace"]/Svc("Workspace") instead of game:GetService("Workspace"))
Wrapper.Svc = setmetatable({}, {

    __index = function(_, Key)

        return game:GetService(Key)

    end;
    __call = function(_, ...)

        local Args = {...}

        for Arg = 1, #Args do

            Args[Arg] = game:GetService(Args[Arg])

        end

        return unpack(Args)

    end;

})

if CONFIG.wEnableObjectWrapping == true then
    
    -- Purpose: wrap any objects which are casually accessed; the rest will be recursively wrapped
    
    -- The require function usually takes a raw object, so it will need to be unwrapped if it is wrapped
    Wrapper.require = function(Arg)

        if Wrapper.DoesExist(Arg, "Object") then

            Arg = Arg.Object

        end

        return Wrapper.OldRequire(Arg)

    end
    
    -- Replace Instance.new such that it will automatically wrap new instances
    Wrapper.Instance = {}
    Wrapper.Instance.new = function(Object, Parent)

        if Wrapper.DoesExist(Parent, "Object") then

            Parent = Parent.Object

        end

        return Wrapper.Wrap(Wrapper.OldInstance.new(Object, Parent))

    end
    
    -- Wrap all necessary objects to stop the user acessing base objects
    for Key, Value in next, Wrapper.ToWrap do

        Wrapper[Key] = Wrapper.Wrap(getfenv()[Key])

    end
    
    -- Import custom property and method definitions
    for Key, Value in next, Modules[script.Name]:GetChildren() do

        Wrapper.ObjectItems[Value.Name] = require(Value)
        
    end
    
    -- Ensure items are de-referenced
    setmetatable(Wrapper.WrapperCache, {__mode = "k"})
    game.DescendantRemoving:Connect(function(Object)

    	Wrapper.WrapperCache[Object] = nil

    end)

end

-- This wrapper is compatible with both the client and the server

Func({
    Client = Wrapper;
    Server = Wrapper;
})

return true