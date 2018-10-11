shared()

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

local function ClientInit()

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
                Bind()
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
                Bind()
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

function InputLibrary:UpdateMouse()
    local Mouse = self.Mouse
    local XY = Mouse.XY
    local MouseRay = Graphics.Camera:ScreenPointToRay(XY.X + 0.5, XY.Y + 0.5)
    local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(Ray.new(MouseRay.Origin, MouseRay.Direction * Mouse.Dist), Mouse.Ignore)
    Mouse.Target = Hit
    Mouse.Pos = Pos
end

function InputLibrary:AddMouseIgnoreTag(Tag)
    local Mouse = self.Mouse
    CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Object)
        table.insert(Mouse.Ignore, Object)
    end)
    for _, Object in pairs(CollectionService:GetTagged(Tag)) do
        table.insert(Mouse.Ignore, Object)
    end
end

function InputLibrary:BindOnKeyDown(Key, AssociateFunction)
    self.DownBinds[Key] = AssociateFunction
end

function InputLibrary:BindOnKeyUp(Key, AssociateFunction)
    self.UpBinds[Key] = AssociateFunction
end

function InputLibrary:UnbindOnKeyDown(Key)
    self.DownBinds[Key] = nil
end

function InputLibrary:UnbindOnKeyUp(Key)
    self.UpBinds[Key] = nil
end

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

return {
    Client = {InputLibrary = InputLibrary, Init = ClientInit};
    Server = {};
}