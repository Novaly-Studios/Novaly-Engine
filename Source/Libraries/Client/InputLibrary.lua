local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Event = Novarine:Get("Event")
local UserInputService = Novarine:Get("UserInputService")
local RunService = Novarine:Get("RunService")
local CollectionService = Novarine:Get("CollectionService")
local ContextActionService = Novarine:Get("ContextActionService")

if (Novarine:Get("RunService"):IsServer()) then
    return false
end

--[[
    Provides extra input-capturing capabilities.

    @module Input Library
    @alias InputLibrary
    @author TPC9000
]]

local InputLibrary = {
    Keys        = {};
    DownBinds   = {};
    UpBinds     = {};
    Mouse       = {
        IgnoreTag   = {};
        Ignore      = {};
        Pos         = Vector3.new(0, 0, 0);
        XY          = Vector2.new(0, 0);
        Target      = nil;
        Dist        = 300;
    };
};

function InputLibrary.Init()

    local Mouse = InputLibrary.Mouse

    local Button1Up = Event.New()
    Mouse.Button1Up = Button1Up

    local Button1Down = Event.New()
    Mouse.Button1Down = Button1Down

    local NGPButton1Up = Event.New()
    Mouse.NGPButton1Up = NGPButton1Up

    local NGPButton1Down = Event.New()
    Mouse.NGPButton1Down = NGPButton1Down

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        local InputType = Input.UserInputType
        if (InputType == Enum.UserInputType.Keyboard or InputType == Enum.UserInputType.Gamepad1) then
            local KeyCode = Input.KeyCode
            local Bind = InputLibrary.DownBinds[KeyCode]
            InputLibrary.Keys[KeyCode] = true
            if Bind then
                Bind:Fire()
            end
        elseif (InputType == Enum.UserInputType.MouseButton1) then
            if (not GameProcessed) then
                NGPButton1Down:Fire()
            end
            Button1Down:Fire()
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseMovement) then
            Mouse.XY = Input.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(Input, GameProcessed)
        local InputType = Input.UserInputType
        if (InputType == Enum.UserInputType.Keyboard or InputType == Enum.UserInputType.Gamepad1) then
            local KeyCode = Input.KeyCode
            local Bind = InputLibrary.UpBinds[KeyCode]
            InputLibrary.Keys[KeyCode] = false
            if Bind then
                Bind:Fire()
            end
        elseif (InputType == Enum.UserInputType.MouseButton1) then
            if (not GameProcessed) then
                NGPButton1Up:Fire()
            end
            Button1Up:Fire()
        end
    end)

    RunService:BindToRenderStep("MouseInput", Enum.RenderPriority.Input.Value + 1, function()
        InputLibrary:UpdateMouse()
    end)
end

--[[
    @function UpdateMouse

    Updates the mouse with a raycast.
]]

function InputLibrary:UpdateMouse()
    local Mouse = self.Mouse
    local XY = Mouse.XY
    local MouseRay = Novarine:Get("Graphics").Camera:ScreenPointToRay(XY.X + 0.5, XY.Y + 0.5)
    local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(Ray.new(MouseRay.Origin, MouseRay.Direction * Mouse.Dist), Mouse.Ignore)
    Mouse.Target = Hit
    Mouse.Pos = Pos
end

--[[
    @function AddMouseIgnoreTag

    Adds a CollectionService tag for the mouse raycast to ignore.

    @usage
        InputLibrary:AddMouseIgnoreTag("IgnoreThisPart")

    @param Tag The tag to ignore.
]]

function InputLibrary:AddMouseIgnoreTag(Tag)

    assert(typeof(Tag) == "string")

    local Mouse = self.Mouse

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Object)
        table.insert(Mouse.Ignore, Object)
    end)

    for _, Object in pairs(CollectionService:GetTagged(Tag)) do
        table.insert(Mouse.Ignore, Object)
    end
end

--[[
    @function BindOnKeyDown

    Binds a function to the user pressing a key.

    @usage
        InputLibrary:BindOnKeyDown(Enum.KeyCode.Q, function()
            print("Q key pressed")
        end)

    @param Key A KeyCode Enum representing the key to monitor.
    @param AssociateFunction The function to run when the key is pressed.
]]

function InputLibrary:BindOnKeyDown(Key, AssociateFunction)

    assert(typeof(AssociateFunction) == "function")

    local DownBinds = self.DownBinds
    local Target = DownBinds[Key] or Event.New()
    DownBinds[Key] = Target

    return Target:Connect(AssociateFunction)
end

--[[
    @function BindOnKeyUp

    Binds a function to the user releasing a key.

    @usage
        InputLibrary:BindOnKeyUp(Enum.KeyCode.Q, function()
            print("Q key released")
        end)

    @param Key A KeyCode Enum representing the key to monitor.
    @param AssociateFunction The function to run when the key is released.
]]

function InputLibrary:BindOnKeyUp(Key, AssociateFunction)

    assert(typeof(AssociateFunction) == "function")

    local UpBinds = self.UpBinds
    local Target = UpBinds[Key] or Event.New()
    UpBinds[Key] = Target

    return Target:Connect(AssociateFunction)
end

--[[
    @function UnbindOnKeyDown

    Disconnects all actions associated with
    the key down event.

    @usage
        InputLibrary:UnbindOnKeyDown(Enum.KeyCode.Q)

    @param Key A KeyCode Enum representing the key to un-bind from the event.
]]

function InputLibrary:UnbindOnKeyDown(Key)
    local Target = self.DownBinds[Key]
    if Target then
        Target:Flush()
    end
end

--[[
    @function UnbindOnKeyUp

    Disconnects all actions associated with
    the key up event.

    @usage
        InputLibrary:UnbindOnKeyUp(Enum.KeyCode.Q)

    @param Key A KeyCode Enum representing the key to un-bind from the event.
]]

function InputLibrary:UnbindOnKeyUp(Key)
    local Target = self.UpBinds[Key]
    if Target then
        Target:Flush()
    end
end

--[[
    @function BlockInput

    Blocks scripts from receiving pressed keys.

    @untested
]]

function InputLibrary:BlockInput(Name, Keys)
    ContextActionService:BindActionAtPriority(
        Name,
        function(_, _, Input)
            Input.UserInputState = Enum.UserInputState.Cancel
            return Enum.ContextActionResult.Pass
        end,
        false,
        2,
        unpack(Keys)
    )
end

function InputLibrary:UnblockInput(Name)
    ContextActionService:UnbindAction(Name)
end

return InputLibrary