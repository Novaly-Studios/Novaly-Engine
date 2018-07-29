local Func = require(game:GetService("ReplicatedStorage").Novarine)
setfenv(1, Func())

local InputLibrary = {
    Keys        = {};
    DownBinds   = {};
    UpBinds     = {};
}

function ClientInit()

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        local InputType = Input.UserInputType
        if (InputType == Enum.UserInputType.Keyboard or InputType == Enum.UserInputType.Gamepad1) then
            local KeyCode = Input.KeyCode
            local Bind = InputLibrary.DownBinds[KeyCode]
            InputLibrary.Keys[KeyCode] = true
            if Bind then
                Bind()
            end
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
        end
    end)
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
        Unpack(Keys)
    )
end

function InputLibrary:UnblockInput(Name)
    ContextActionService:UnbindAction(Name)
end

Func({
    Client = {InputLibrary = InputLibrary, Init = ClientInit};
    Server = {};
})

return true