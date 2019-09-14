local Novarine = require(game:GetService("ReplicatedFirst").Novarine.Loader)
local Event = Novarine:Get("Event")
local UserInputService = Novarine:Get("UserInputService")
local RunService = Novarine:Get("RunService")
local CollectionService = Novarine:Get("CollectionService")
local ContextActionService = Novarine:Get("ContextActionService")
local Player = Novarine:Get("Player")

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
    InputData   = {
        IgnoreTag   = {};
        Ignore      = {};
        Pos         = Vector3.new(0, 0, 0);
        XY          = Vector3.new(0, 0, 0);
        Target      = nil;
        Dist        = 80;
    };
    MouseRaycast = 0;
};

function InputLibrary.Init()

    local InputData = InputLibrary.InputData

    local Up = Event.New()
    InputData.Up = Up

    local Down = Event.New()
    InputData.Down = Down

    local NGPUp = Event.New()
    InputData.NGPUp = NGPUp

    local NGPDown = Event.New()
    InputData.NGPDown = NGPDown

    local UpRightClick = Event.New()
    InputData.UpRightClick = UpRightClick

    local DownRightClick = Event.New()
    InputData.DownRightClick = DownRightClick

    local NGPDownRightClick = Event.New()
    InputData.NGPDownRightClick = NGPDownRightClick

    local NGPUpRightClick = Event.New()
    InputData.NGPUpRightClick = NGPUpRightClick

    local Move = Event.New()
    InputData.Move = Move

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        local InputType = Input.UserInputType
        if (InputType == Enum.UserInputType.Keyboard or InputType == Enum.UserInputType.Gamepad1) then
            local KeyCode = Input.KeyCode
            local Bind = InputLibrary.DownBinds[KeyCode]
            InputLibrary.Keys[KeyCode] = true
            if Bind then
                Bind:Fire(GameProcessed)
            end
        elseif (InputType == Enum.UserInputType.MouseButton1 or InputType == Enum.UserInputType.Touch) then
            if (not GameProcessed) then
                NGPDown:Fire()
            end
            Down:Fire()
        elseif (InputType == Enum.UserInputType.MouseButton2) then
            if (not GameProcessed) then
                DownRightClick:Fire()
            end
            NGPDownRightClick:Fire()
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            if (InputData.XY ~= Vector3.new(0, 0, 0)) then
                InputData.Move:Fire(Input.Position - InputData.XY)
            end
            InputData.XY = Input.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(Input, GameProcessed)
        local InputType = Input.UserInputType
        if (InputType == Enum.UserInputType.Keyboard or InputType == Enum.UserInputType.Gamepad1) then
            local KeyCode = Input.KeyCode
            local Bind = InputLibrary.UpBinds[KeyCode]
            InputLibrary.Keys[KeyCode] = false
            if Bind then
                Bind:Fire(GameProcessed)
            end
        elseif (InputType == Enum.UserInputType.MouseButton1 or InputType == Enum.UserInputType.Touch) then
            if (not GameProcessed) then
                NGPUp:Fire()
            end
            Up:Fire()
        elseif (InputType == Enum.UserInputType.MouseButton2) then
            if (not GameProcessed) then
                NGPUpRightClick:Fire()
            end
            UpRightClick:Fire()
        end
    end)

--[[     RunService:BindToRenderStep("MouseInput", Enum.RenderPriority.Input.Value + 1, function()
        InputLibrary:UpdateMouse()
    end) ]]

    RunService.RenderStepped:Connect(function()
        InputLibrary:UpdateMouse()
    end)
end

--[[
    @function AddIgnoreInstance

    Adds an ignore part, assuming InputLibrary is using inbuilt mouse raycast.
]]

function InputLibrary:AddIgnoreInstance(Item)
    local Ignore = workspace:FindFirstChild("Ignore")

    if (not Ignore) then
        Ignore = Instance.new("Folder", workspace)
    end

    Ignore.Name = "Ignore"
    Item.Parent = Ignore

    self.IgnoreFolder = Ignore
end

--[[
    @function SetMouseRaycastActive

    Enables or disables the custom mouse raycasts,
    useful since they're expensive. Assumes scripts
    will call enable once and by extension disable once.
    Accounts for multiple scripts.
]]

function InputLibrary:SetMouseRaycastActive(Enabled)
    self.MouseRaycast = self.MouseRaycast + (Enabled and 1 or -1)
end

--[[
    @function UpdateMouse

    Updates the mouse with a raycast.
]]

function InputLibrary:UpdateMouse()
    local InputData = self.InputData

    if (self.UseInbuiltMouse) then
        local Mouse = Player:GetMouse()
        InputData.Target = Mouse.Target
        InputData.Pos = Mouse.Hit.Position

        if (not Mouse.TargetFilter and self.IgnoreFolder) then
            Mouse.TargetFilter = self.IgnoreFolder
        end
    else
        local XY = InputData.XY
        local MouseRay = Novarine:Get("Graphics").Camera:ScreenPointToRay(XY.X + 0.5, XY.Y + 0.5)

        if (self.MouseRaycast > 0) then
            local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(Ray.new(MouseRay.Origin, MouseRay.Direction * InputData.Dist), InputData.Ignore)
            InputData.Target = Hit
            InputData.Pos = Pos
        end
    end
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

    local InputData = self.InputData

    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Object)
        table.insert(InputData.Ignore, Object)
    end)

    for _, Object in pairs(CollectionService:GetTagged(Tag)) do
        table.insert(InputData.Ignore, Object)
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