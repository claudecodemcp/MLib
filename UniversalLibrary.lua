local cloneref = cloneref or function(i) return i end
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local GuiService = cloneref(game:GetService("GuiService"))

local gethui = gethui or function() return CoreGui end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local setclipboard = setclipboard or toclipboard or nil

local Library = {
    Toggles = {},
    Options = {},
    Buttons = {},
    Labels = {},
    Tabs = {},
    Signals = {},
    Refreshers = {},
    DependencyBoxes = {},
    KeyPickers = {},
    Toggled = true,
    Unloaded = false,
    ShowKeybindList = false,
    ToggleKeyName = "RightControl",
    DPIScale = 1,
    Theme = {
        Background = Color3.fromRGB(17, 17, 21),
        Panel = Color3.fromRGB(26, 26, 32),
        Element = Color3.fromRGB(34, 34, 42),
        Outline = Color3.fromRGB(48, 48, 58),
        Accent = Color3.fromRGB(90, 170, 255),
        Text = Color3.fromRGB(235, 235, 240),
        SubText = Color3.fromRGB(150, 150, 160),
        Red = Color3.fromRGB(255, 80, 80),
    },
}

local Theme = Library.Theme
local Registry = setmetatable({}, { __mode = "k" })

local ColorProps = {
    BackgroundColor3 = true,
    TextColor3 = true,
    ImageColor3 = true,
    Color = true,
    ScrollBarImageColor3 = true,
    PlaceholderColor3 = true,
}

local function Reg(Obj, Prop, Key)
    Registry[Obj] = Registry[Obj] or {}
    Registry[Obj][Prop] = Key
    Obj[Prop] = Theme[Key]
end

local function Tween(Obj, Props, Time)
    TweenService:Create(Obj, TweenInfo.new(Time or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props):Play()
end

local function New(Class, Props, Parent)
    local Obj = Instance.new(Class)
    pcall(function()
        Obj.BorderSizePixel = 0
    end)

    if Obj:IsA("GuiButton") then
        Obj.AutoButtonColor = false
    end
    if Obj:IsA("TextLabel") or Obj:IsA("TextButton") or Obj:IsA("TextBox") then
        Obj.Font = Enum.Font.Gotham
        Obj.TextSize = 14
        Reg(Obj, "TextColor3", "Text")
    end
    if Obj:IsA("TextLabel") then
        Obj.BackgroundTransparency = 1
    end
    if Obj:IsA("TextBox") then
        Reg(Obj, "PlaceholderColor3", "SubText")
    end

    for K, V in Props or {} do
        if ColorProps[K] and type(V) == "string" then
            Reg(Obj, K, V)
        else
            if Registry[Obj] then
                Registry[Obj][K] = nil
            end
            Obj[K] = V
        end
    end

    Obj.Parent = Parent
    return Obj
end

local function Round(Parent, Radius)
    return New("UICorner", { CornerRadius = UDim.new(0, Radius or 4) }, Parent)
end

local function Stroke(Parent, Key)
    return New("UIStroke", {
        Color = Key or "Outline",
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, Parent)
end

local function Pad(Parent, L, R, T, B)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, L or 0),
        PaddingRight = UDim.new(0, R or L or 0),
        PaddingTop = UDim.new(0, T or 0),
        PaddingBottom = UDim.new(0, B or T or 0),
    }, Parent)
end

local function List(Parent, Gap)
    return New("UIListLayout", {
        Padding = UDim.new(0, Gap or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Parent)
end

local function Signal(Conn)
    table.insert(Library.Signals, Conn)
    return Conn
end

local function RoundTo(Value, Decimals)
    local M = 10 ^ (Decimals or 0)
    return math.floor(Value * M + 0.5) / M
end

local function AbsInputPos(Input)
    local Inset = GuiService:GetGuiInset()
    return Vector2.new(Input.Position.X + Inset.X, Input.Position.Y + Inset.Y)
end

local function IsClick(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsOver(Frame, Pos)
    local P, S = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Pos.X >= P.X and Pos.X <= P.X + S.X and Pos.Y >= P.Y and Pos.Y <= P.Y + S.Y
end

function Library:AddRefresher(Func)
    table.insert(Library.Refreshers, Func)
end

function Library:UpdateTheme()
    for Obj, Props in Registry do
        for Prop, Key in Props do
            pcall(function()
                Obj[Prop] = Theme[Key]
            end)
        end
    end
    for _, Func in Library.Refreshers do
        pcall(Func)
    end
end

function Library:UpdateDependencyBoxes()
    for _, Box in Library.DependencyBoxes do
        Box:Update()
    end
end

function Library:MakeDraggable(Frame, Handle)
    local Dragging, StartPos, StartMouse = false, nil, nil

    Handle.InputBegan:Connect(function(Input)
        if IsClick(Input) then
            Dragging = true
            StartPos = Frame.Position
            StartMouse = Input.Position
        end
    end)
    Signal(UserInputService.InputChanged:Connect(function(Input)
        if Dragging and IsMove(Input) then
            local D = Input.Position - StartMouse
            Frame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + D.X, StartPos.Y.Scale, StartPos.Y.Offset + D.Y)
        end
    end))
    Signal(UserInputService.InputEnded:Connect(function(Input)
        if IsClick(Input) then
            Dragging = false
        end
    end))
end

function Library:MakeDrag(Obj, OnMove, OnEnd)
    local Dragging = false

    Obj.InputBegan:Connect(function(Input)
        if IsClick(Input) then
            Dragging = true
            OnMove(AbsInputPos(Input))
        end
    end)
    Signal(UserInputService.InputChanged:Connect(function(Input)
        if Dragging and IsMove(Input) then
            OnMove(AbsInputPos(Input))
        end
    end))
    Signal(UserInputService.InputEnded:Connect(function(Input)
        if Dragging and IsClick(Input) then
            Dragging = false
            if OnEnd then OnEnd() end
        end
    end))
end

local ScreenGui = New("ScreenGui", {
    Name = "UniversalLibrary",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(protectgui, ScreenGui)
local OkParent = pcall(function() ScreenGui.Parent = gethui() end)
if not OkParent or not ScreenGui.Parent then
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end
Library.ScreenGui = ScreenGui

local Overlay = New("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 50,
}, ScreenGui)

local CurrentPopup = nil

function Library:ClosePopup()
    if not CurrentPopup then return end
    local P = CurrentPopup
    CurrentPopup = nil
    P.Frame.Visible = false
    if P.OnClose then P.OnClose() end
end

function Library:OpenPopup(Frame, Anchor, OnClose)
    if CurrentPopup and CurrentPopup.Frame == Frame then
        Library:ClosePopup()
        return
    end
    Library:ClosePopup()

    CurrentPopup = { Frame = Frame, Anchor = Anchor, OnClose = OnClose }
    Frame.Visible = true

    local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local X = Anchor.AbsolutePosition.X
    local Y = Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y + 4
    X = math.min(X, Viewport.X - Frame.AbsoluteSize.X - 6)
    Y = math.min(Y, Viewport.Y - Frame.AbsoluteSize.Y - 6)
    Frame.Position = UDim2.fromOffset(math.max(X, 6), math.max(Y, 6))
end

Signal(UserInputService.InputBegan:Connect(function(Input)
    if not CurrentPopup then return end
    if IsClick(Input) or Input.UserInputType == Enum.UserInputType.MouseButton2 then
        local Pos = AbsInputPos(Input)
        if not IsOver(CurrentPopup.Frame, Pos) and not IsOver(CurrentPopup.Anchor, Pos) then
            Library:ClosePopup()
        end
    end
end))

local NotifyHolder = New("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -12, 1, -12),
    Size = UDim2.fromOffset(260, 400),
    BackgroundTransparency = 1,
    ZIndex = 60,
}, ScreenGui)
New("UIListLayout", {
    Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, NotifyHolder)

function Library:Notify(Info, Time)
    local Title, Text
    if typeof(Info) == "table" then
        Title = Info.Title
        Text = Info.Description or Info.Text
        Time = Info.Time or Time
    else
        Text = Info
    end

    local Box = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "Panel",
        BackgroundTransparency = 1,
    }, NotifyHolder)
    Round(Box, 4)
    local BoxStroke = Stroke(Box, "Accent")
    BoxStroke.Transparency = 1
    Pad(Box, 10, 10, 8, 8)
    List(Box, 2)

    local Labels = {}
    if Title then
        table.insert(Labels, New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = tostring(Title),
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1,
            LayoutOrder = 1,
        }, Box))
    end
    table.insert(Labels, New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = tostring(Text),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Title and "SubText" or "Text",
        TextTransparency = 1,
        LayoutOrder = 2,
    }, Box))

    Tween(Box, { BackgroundTransparency = 0 }, 0.2)
    Tween(BoxStroke, { Transparency = 0 }, 0.2)
    for _, L in Labels do Tween(L, { TextTransparency = 0 }, 0.2) end

    task.delay(Time or 4, function()
        if not Box.Parent then return end
        Tween(Box, { BackgroundTransparency = 1 }, 0.2)
        Tween(BoxStroke, { Transparency = 1 }, 0.2)
        for _, L in Labels do Tween(L, { TextTransparency = 1 }, 0.2) end
        task.wait(0.25)
        Box:Destroy()
    end)
end

local Watermark = New("TextLabel", {
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 0,
    BackgroundColor3 = "Panel",
    Text = "",
    Visible = false,
    ZIndex = 5,
}, ScreenGui)
Round(Watermark, 4)
Stroke(Watermark)
Pad(Watermark, 10, 10, 0, 0)
Library:MakeDraggable(Watermark, Watermark)

function Library:SetWatermark(Text)
    Watermark.Text = tostring(Text)
end

function Library:SetWatermarkVisibility(State)
    Watermark.Visible = State == true
end

local KeybindFrame = New("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 10, 0.5, 0),
    Size = UDim2.fromOffset(170, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "Panel",
    Visible = false,
    ZIndex = 5,
}, ScreenGui)
Round(KeybindFrame, 4)
Stroke(KeybindFrame)
List(KeybindFrame, 0)

local KeybindHeader = New("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24),
    Text = "Keybinds",
    Font = Enum.Font.GothamMedium,
    LayoutOrder = 0,
}, KeybindFrame)
local KeybindContainer = New("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 1,
}, KeybindFrame)
List(KeybindContainer, 2)
Pad(KeybindContainer, 10, 10, 2, 8)
Library:MakeDraggable(KeybindFrame, KeybindHeader)

function Library:SetKeybindListVisibility(State)
    Library.ShowKeybindList = State == true
    KeybindFrame.Visible = Library.ShowKeybindList
end

Signal(RunService.Heartbeat:Connect(function()
    if not Library.ShowKeybindList then return end
    for Picker in Library.KeyPickers do
        if Picker.Row then
            local Active = Picker:GetState()
            Picker.Row.TextColor3 = Active and Theme.Accent or Theme.SubText
        end
    end
end))

local Addons = {}

local function MakeAddonHolder(Parent)
    local F = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        ZIndex = 2,
    }, Parent)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, F)
    return F
end

local function AttachAddons(Element, Parent)
    Element.GetAddonHolder = function(self)
        if not self.AddonHolder then
            self.AddonHolder = MakeAddonHolder(Parent)
        end
        return self.AddonHolder
    end
    Element.AddKeyPicker = Addons.AddKeyPicker
    Element.AddColorPicker = Addons.AddColorPicker
end

local MouseKeys = {
    MB1 = Enum.UserInputType.MouseButton1,
    MB2 = Enum.UserInputType.MouseButton2,
    MB3 = Enum.UserInputType.MouseButton3,
}

local function InputToKey(Input)
    if Input.UserInputType == Enum.UserInputType.Keyboard then
        if Input.KeyCode == Enum.KeyCode.Escape then return "None" end
        if Input.KeyCode == Enum.KeyCode.Unknown then return nil end
        return Input.KeyCode.Name
    end
    for Name, Type in MouseKeys do
        if Input.UserInputType == Type then return Name end
    end
    return nil
end

local function KeyIsDown(Key)
    if Key == "None" or UserInputService:GetFocusedTextBox() then return false end
    if MouseKeys[Key] then
        return UserInputService:IsMouseButtonPressed(MouseKeys[Key])
    end
    local Ok, Code = pcall(function() return Enum.KeyCode[Key] end)
    return Ok and Code ~= nil and UserInputService:IsKeyDown(Code)
end

function Addons:AddKeyPicker(Idx, Info)
    Info = Info or {}
    local Parent = self

    local Picker = {
        Text = Info.Text or Parent.Text or tostring(Idx),
        Value = Info.Default or "None",
        Mode = Info.Mode or "Toggle",
        Modes = Info.Modes or { "Always", "Toggle", "Hold" },
        Toggled = false,
        SyncToggleState = Info.SyncToggleState == true,
        NoUI = Info.NoUI == true,
        Callback = Info.Callback,
        Clicked = Info.Clicked,
        ChangedCallback = Info.ChangedCallback,
        Changed = Info.Changed,
        Type = "KeyPicker",
        Parent = Parent,
    }

    if Picker.SyncToggleState and Picker.Mode == "Always" then
        Picker.Mode = "Toggle"
    end
    if Parent.Type == "Toggle" and Picker.SyncToggleState then
        Picker.Toggled = Parent.Value
    end

    local Picking = false

    local Btn = New("TextButton", {
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = "Element",
        Text = Picker.Value,
        TextSize = 12,
        TextColor3 = "SubText",
        LayoutOrder = 2,
    }, Parent:GetAddonHolder())
    Round(Btn, 3)
    Stroke(Btn)
    Pad(Btn, 6, 6, 0, 0)

    local ModeFrame = New("Frame", {
        Size = UDim2.fromOffset(80, #Picker.Modes * 22),
        BackgroundColor3 = "Panel",
        Visible = false,
    }, Overlay)
    Round(ModeFrame, 4)
    Stroke(ModeFrame)

    local ModeButtons = {}
    for I, Mode in Picker.Modes do
        local MB = New("TextButton", {
            Position = UDim2.fromOffset(0, (I - 1) * 22),
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = Mode,
            TextSize = 13,
        }, ModeFrame)
        ModeButtons[Mode] = MB
        MB.MouseButton1Click:Connect(function()
            Picker.Mode = Mode
            Picker:Update()
            Library:ClosePopup()
        end)
    end

    local Row = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Text = "",
        TextSize = 13,
        TextColor3 = "SubText",
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
    }, KeybindContainer)
    Picker.Row = Row

    function Picker:GetState()
        if Picker.Mode == "Always" then return true end
        if Picker.Mode == "Hold" then return KeyIsDown(Picker.Value) end
        return Picker.Toggled
    end

    function Picker:Update()
        Btn.Text = Picking and "..." or Picker.Value
        for Mode, MB in ModeButtons do
            MB.TextColor3 = Mode == Picker.Mode and Theme.Accent or Theme.SubText
        end
        Row.Text = string.format("[%s] %s (%s)", Picker.Value, Picker.Text, Picker.Mode)
        Row.Visible = Picker.Value ~= "None" and not Picker.NoUI
    end

    function Picker:DoClick()
        if Picker.Callback then task.spawn(Picker.Callback, Picker:GetState()) end
        if Picker.Clicked then task.spawn(Picker.Clicked, Picker:GetState()) end
    end

    function Picker:OnClick(Func) Picker.Clicked = Func end
    function Picker:OnChanged(Func) Picker.Changed = Func end

    function Picker:SetValue(Data)
        local Key, Mode = Data[1], Data[2]
        Picker.Value = Key or "None"
        if Mode and table.find(Picker.Modes, Mode) then
            Picker.Mode = Mode
        end
        Picker:Update()
        if Picker.ChangedCallback then task.spawn(Picker.ChangedCallback, Picker.Value, Picker.Mode) end
        if Picker.Changed then task.spawn(Picker.Changed, Picker.Value, Picker.Mode) end
    end

    function Picker:SetText(Text)
        Picker.Text = Text
        Picker:Update()
    end

    function Picker:Destroy()
        Library.KeyPickers[Picker] = nil
        Btn:Destroy()
        ModeFrame:Destroy()
        Row:Destroy()
        Library.Options[Idx] = nil
    end

    Btn.MouseButton1Click:Connect(function()
        if Picking then return end
        Picking = true
        Picker:Update()

        local Conn
        Conn = UserInputService.InputBegan:Connect(function(Input)
            local Key = InputToKey(Input)
            if not Key then return end
            Conn:Disconnect()
            task.defer(function()
                Picking = false
                Picker:SetValue({ Key, Picker.Mode })
            end)
        end)
    end)

    Btn.MouseButton2Click:Connect(function()
        Library:OpenPopup(ModeFrame, Btn)
    end)

    Signal(UserInputService.InputBegan:Connect(function(Input, Processed)
        if Library.Unloaded or Picking or Picker.Value == "None" or Picker.Mode == "Always" then return end
        if UserInputService:GetFocusedTextBox() then return end

        local IsMouse = MouseKeys[Picker.Value] ~= nil
        if IsMouse and Library.Toggled then return end
        if not IsMouse and Processed then return end

        local Match
        if IsMouse then
            Match = Input.UserInputType == MouseKeys[Picker.Value]
        else
            Match = Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Picker.Value
        end
        if not Match then return end

        if Picker.Mode == "Toggle" then
            Picker.Toggled = not Picker.Toggled
            if Picker.SyncToggleState and Parent.Type == "Toggle" then
                Parent:SetValue(Picker.Toggled)
            end
            Picker:DoClick()
        elseif Picker.Mode == "Hold" then
            if Picker.SyncToggleState and Parent.Type == "Toggle" then
                Parent:SetValue(true)
            end
            Picker:DoClick()
            local Conn
            Conn = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Conn:Disconnect()
                    if Picker.SyncToggleState and Parent.Type == "Toggle" then
                        Parent:SetValue(false)
                    end
                    if Picker.Callback then task.spawn(Picker.Callback, false) end
                    if Picker.Clicked then task.spawn(Picker.Clicked, false) end
                end
            end)
        end
    end))

    Library:AddRefresher(function() Picker:Update() end)

    Parent.Addons = Parent.Addons or {}
    table.insert(Parent.Addons, Picker)

    Picker.Default = Picker.Value
    Picker.DefaultMode = Picker.Mode
    Library.KeyPickers[Picker] = true
    Library.Options[Idx] = Picker
    Picker:Update()
    return self
end

function Addons:AddColorPicker(Idx, Info)
    Info = Info or {}
    local Parent = self
    local HasAlpha = Info.Transparency ~= nil

    local CP = {
        Value = Info.Default or Color3.new(1, 1, 1),
        Transparency = Info.Transparency or 0,
        Title = Info.Title,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Type = "ColorPicker",
        Parent = Parent,
    }
    CP.Hue, CP.Sat, CP.Vib = CP.Value:ToHSV()

    local Swatch = New("TextButton", {
        Size = UDim2.fromOffset(24, 18),
        BackgroundColor3 = CP.Value,
        Text = "",
        LayoutOrder = 1,
    }, Parent:GetAddonHolder())
    Round(Swatch, 3)
    Stroke(Swatch)

    local Width = HasAlpha and 218 or 198
    local Popup = New("Frame", {
        Size = UDim2.fromOffset(Width, 192),
        BackgroundColor3 = "Panel",
        Visible = false,
    }, Overlay)
    Round(Popup, 5)
    Stroke(Popup)

    local SV = New("Frame", {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(150, 120),
        BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1),
        ClipsDescendants = true,
    }, Popup)
    Round(SV, 3)

    local White = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 1,
    }, SV)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, White)

    local Black = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 2,
    }, SV)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
    }, Black)

    local SVCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 3,
    }, SV)
    Round(SVCursor, 4)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, SVCursor)

    local HueBar = New("Frame", {
        Position = UDim2.fromOffset(166, 8),
        Size = UDim2.fromOffset(14, 120),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, Popup)
    Round(HueBar, 3)
    local Keys = {}
    for I = 0, 6 do
        table.insert(Keys, ColorSequenceKeypoint.new(I / 6, Color3.fromHSV(math.min(I / 6, 0.999), 1, 1)))
    end
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Keys) }, HueBar)
    local HueCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 4, 0, 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, HueBar)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, HueCursor)

    local AlphaBar, AlphaFill, AlphaCursor
    if HasAlpha then
        AlphaBar = New("Frame", {
            Position = UDim2.fromOffset(188, 8),
            Size = UDim2.fromOffset(14, 120),
            BackgroundColor3 = "Element",
        }, Popup)
        Round(AlphaBar, 3)
        Stroke(AlphaBar)
        AlphaFill = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = CP.Value,
        }, AlphaBar)
        Round(AlphaFill, 3)
        New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, AlphaFill)
        AlphaCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 4, 0, 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
        }, AlphaBar)
        New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, AlphaCursor)
    end

    local HexBox = New("TextBox", {
        Position = UDim2.fromOffset(8, 136),
        Size = UDim2.fromOffset(Width - 16, 22),
        BackgroundColor3 = "Element",
        Text = "",
        ClearTextOnFocus = false,
        TextSize = 13,
    }, Popup)
    Round(HexBox, 4)
    Stroke(HexBox)

    local function PopupButton(Text, X, W, Func)
        local B = New("TextButton", {
            Position = UDim2.fromOffset(X, 162),
            Size = UDim2.fromOffset(W, 22),
            BackgroundColor3 = "Element",
            Text = Text,
            TextSize = 13,
            TextColor3 = "SubText",
        }, Popup)
        Round(B, 4)
        Stroke(B)
        B.MouseButton1Click:Connect(Func)
        return B
    end

    local Half = (Width - 24) / 2

    function CP:Display()
        CP.Value = Color3.fromHSV(CP.Hue, CP.Sat, CP.Vib)
        Swatch.BackgroundColor3 = CP.Value
        SV.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
        SVCursor.Position = UDim2.fromScale(CP.Sat, 1 - CP.Vib)
        HueCursor.Position = UDim2.fromScale(0.5, CP.Hue)
        if AlphaFill then
            AlphaFill.BackgroundColor3 = CP.Value
            AlphaCursor.Position = UDim2.fromScale(0.5, CP.Transparency)
        end
        if not HexBox:IsFocused() then
            HexBox.Text = "#" .. CP.Value:ToHex()
        end
    end

    local function Fire()
        CP:Display()
        if CP.Callback then task.spawn(CP.Callback, CP.Value, CP.Transparency) end
        if CP.Changed then task.spawn(CP.Changed, CP.Value, CP.Transparency) end
    end

    function CP:OnChanged(Func) CP.Changed = Func end

    function CP:SetValueRGB(Color, Transparency)
        CP.Hue, CP.Sat, CP.Vib = Color:ToHSV()
        if HasAlpha and Transparency then
            CP.Transparency = Transparency
        end
        Fire()
    end

    function CP:SetValue(Value, Transparency)
        if typeof(Value) == "Color3" then
            CP:SetValueRGB(Value, Transparency)
        elseif typeof(Value) == "table" then
            CP:SetValueRGB(Color3.fromHSV(Value[1], Value[2], Value[3]), Transparency)
        end
    end

    function CP:Destroy()
        Swatch:Destroy()
        Popup:Destroy()
        Library.Options[Idx] = nil
    end

    PopupButton("Copy", 8, Half, function()
        Library.CopiedColor = { CP.Value, CP.Transparency }
    end)
    PopupButton("Paste", 16 + Half, Half, function()
        if Library.CopiedColor then
            CP:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
        end
    end)

    Library:MakeDrag(SV, function(Pos)
        CP.Sat = math.clamp((Pos.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
        CP.Vib = 1 - math.clamp((Pos.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
        Fire()
    end)
    Library:MakeDrag(HueBar, function(Pos)
        CP.Hue = math.clamp((Pos.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
        Fire()
    end)
    if AlphaBar then
        Library:MakeDrag(AlphaBar, function(Pos)
            CP.Transparency = math.clamp((Pos.Y - AlphaBar.AbsolutePosition.Y) / AlphaBar.AbsoluteSize.Y, 0, 1)
            Fire()
        end)
    end

    HexBox.FocusLost:Connect(function()
        local Ok, Color = pcall(Color3.fromHex, HexBox.Text)
        if Ok and typeof(Color) == "Color3" then
            CP.Hue, CP.Sat, CP.Vib = Color:ToHSV()
        end
        Fire()
    end)

    Swatch.MouseButton1Click:Connect(function()
        Library:OpenPopup(Popup, Swatch)
    end)

    Parent.Addons = Parent.Addons or {}
    table.insert(Parent.Addons, CP)

    CP.Default = CP.Value
    Library.Options[Idx] = CP
    CP:Display()
    return self
end

local Funcs = {}
Funcs.__index = Funcs

function Funcs:AddLabel(Text, Wrap)
    local Label = { Text = Text, Type = "Label" }
    local Obj = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, Wrap and 0 or 18),
        AutomaticSize = Wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Text = Text,
        TextWrapped = Wrap == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = "SubText",
    }, self.Container)

    function Label:SetText(NewText)
        Label.Text = NewText
        Obj.Text = NewText
    end
    function Label:SetVisible(V) Obj.Visible = V end
    function Label:Destroy() Obj:Destroy() end

    if not Wrap then
        AttachAddons(Label, Obj)
    end

    Label.Holder = Obj
    table.insert(Library.Labels, Label)
    return Label
end

function Funcs:AddDivider(Text)
    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
    }, self.Container)

    if Text then
        local Label = New("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 14),
            Text = " " .. Text .. " ",
            TextSize = 12,
            TextColor3 = "SubText",
            ZIndex = 2,
        }, Holder)
        New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(0.5, -(Label.TextBounds.X / 2) - 4, 0, 1),
            BackgroundColor3 = "Outline",
        }, Holder)
        New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.new(0.5, -(Label.TextBounds.X / 2) - 4, 0, 1),
            BackgroundColor3 = "Outline",
        }, Holder)
    else
        New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = "Outline",
        }, Holder)
    end

    return { Holder = Holder, Type = "Divider", SetVisible = function(_, V) Holder.Visible = V end }
end

function Funcs:AddButton(...)
    local A, B = ...
    local Info = typeof(A) == "table" and A or { Text = A, Func = B }

    local Button = {
        Text = Info.Text or "Button",
        Func = Info.Func or Info.Callback or function() end,
        DoubleClick = Info.DoubleClick,
        Type = "Button",
    }

    local Obj = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = "Element",
        Text = Button.Text,
        TextColor3 = "SubText",
    }, self.Container)
    Round(Obj, 4)
    Stroke(Obj)

    local Armed = false
    Obj.MouseEnter:Connect(function() Tween(Obj, { TextColor3 = Theme.Text }) end)
    Obj.MouseLeave:Connect(function() Tween(Obj, { TextColor3 = Theme.SubText }) end)
    Obj.MouseButton1Click:Connect(function()
        if Button.DoubleClick then
            if not Armed then
                Armed = true
                Obj.Text = "Are you sure?"
                task.delay(1, function()
                    Armed = false
                    Obj.Text = Button.Text
                end)
                return
            end
            Armed = false
            Obj.Text = Button.Text
        end
        task.spawn(Button.Func)
    end)

    function Button:SetText(T) Button.Text = T; Obj.Text = T end
    function Button:SetVisible(V) Obj.Visible = V end
    function Button:Destroy() Obj:Destroy() end

    Button.Holder = Obj
    table.insert(Library.Buttons, Button)
    return Button
end

function Funcs:AddToggle(Idx, Info)
    Info = Info or {}
    local Toggle = {
        Text = Info.Text or "Toggle",
        Value = Info.Default == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Type = "Toggle",
    }

    local Holder = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
    }, self.Container)

    local Box = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = "Element",
    }, Holder)
    Round(Box, 3)
    local BoxStroke = Stroke(Box)

    local Check = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = "Accent",
    }, Box)
    Round(Check, 2)

    local Label = New("TextLabel", {
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = Toggle.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = "SubText",
    }, Holder)

    function Toggle:Display()
        Tween(Check, { Size = Toggle.Value and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) })
        Tween(BoxStroke, { Color = Toggle.Value and Theme.Accent or Theme.Outline })
        Tween(Label, { TextColor3 = Toggle.Value and Theme.Text or Theme.SubText })
    end

    function Toggle:OnChanged(Func) Toggle.Changed = Func end

    function Toggle:SetValue(Value)
        Toggle.Value = Value == true
        Toggle:Display()

        for _, Addon in Toggle.Addons or {} do
            if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                Addon.Toggled = Toggle.Value
                Addon:Update()
            end
        end

        Library:UpdateDependencyBoxes()
        if Toggle.Callback then task.spawn(Toggle.Callback, Toggle.Value) end
        if Toggle.Changed then task.spawn(Toggle.Changed, Toggle.Value) end
    end

    function Toggle:SetText(T) Toggle.Text = T; Label.Text = T end
    function Toggle:SetVisible(V) Holder.Visible = V end
    function Toggle:Destroy() Holder:Destroy(); Library.Toggles[Idx] = nil end

    Holder.MouseButton1Click:Connect(function()
        Toggle:SetValue(not Toggle.Value)
    end)

    AttachAddons(Toggle, Holder)
    Library:AddRefresher(function() Toggle:Display() end)

    Toggle.Default = Toggle.Value
    Toggle.Holder = Holder
    Toggle:Display()
    Library.Toggles[Idx] = Toggle
    return Toggle
end

function Funcs:AddSlider(Idx, Info)
    Info = Info or {}
    local Slider = {
        Text = Info.Text or "Slider",
        Min = Info.Min or 0,
        Max = Info.Max or 100,
        Rounding = Info.Rounding or 0,
        Prefix = Info.Prefix or "",
        Suffix = Info.Suffix or "",
        Value = Info.Default or Info.Min or 0,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Type = "Slider",
    }

    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    }, self.Container)

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Text = Slider.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = "SubText",
    }, Holder)

    local ValueLabel = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Right,
    }, Holder)

    local Bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = "Element",
    }, Holder)
    Round(Bar, 4)
    Stroke(Bar)

    local Fill = New("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = "Accent",
    }, Bar)
    Round(Fill, 4)

    local Knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = "Text",
        ZIndex = 2,
    }, Bar)
    Round(Knob, 6)

    function Slider:Display()
        local Alpha = (Slider.Value - Slider.Min) / math.max(Slider.Max - Slider.Min, 1e-9)
        Alpha = math.clamp(Alpha, 0, 1)
        Fill.Size = UDim2.fromScale(Alpha, 1)
        Knob.Position = UDim2.fromScale(Alpha, 0.5)
        ValueLabel.Text = string.format("%s%s%s", Slider.Prefix, tostring(Slider.Value), Slider.Suffix)
    end

    function Slider:OnChanged(Func) Slider.Changed = Func end

    function Slider:SetValue(Value)
        Value = tonumber(Value)
        if not Value then return end
        Value = RoundTo(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding)
        if Value == Slider.Value then return end

        Slider.Value = Value
        Slider:Display()
        if Slider.Callback then task.spawn(Slider.Callback, Value) end
        if Slider.Changed then task.spawn(Slider.Changed, Value) end
    end

    function Slider:SetMax(V) Slider.Max = V; Slider:SetValue(Slider.Value); Slider:Display() end
    function Slider:SetMin(V) Slider.Min = V; Slider:SetValue(Slider.Value); Slider:Display() end
    function Slider:SetVisible(V) Holder.Visible = V end
    function Slider:Destroy() Holder:Destroy(); Library.Options[Idx] = nil end

    Library:MakeDrag(Bar, function(Pos)
        local Alpha = math.clamp((Pos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Alpha)
    end)

    Slider.Default = Slider.Value
    Slider.Holder = Holder
    Slider:Display()
    Library.Options[Idx] = Slider
    return Slider
end

function Funcs:AddInput(Idx, Info)
    Info = Info or {}
    local Input = {
        Text = Info.Text,
        Value = Info.Default or "",
        Numeric = Info.Numeric,
        Finished = Info.Finished,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Type = "Input",
    }

    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, Input.Text and 44 or 26),
        BackgroundTransparency = 1,
    }, self.Container)

    if Input.Text then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            Text = Input.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = "SubText",
        }, Holder)
    end

    local Box = New("TextBox", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = "Element",
        Text = Input.Value,
        PlaceholderText = Info.Placeholder or "",
        ClearTextOnFocus = Info.ClearTextOnFocus == true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Holder)
    Round(Box, 4)
    local BoxStroke = Stroke(Box)
    Pad(Box, 8, 8, 0, 0)

    function Input:OnChanged(Func) Input.Changed = Func end

    function Input:SetValue(Text)
        Text = tostring(Text)
        if Input.Numeric and Text ~= "" and not tonumber(Text) then
            Text = Input.Value
        end
        Input.Value = Text
        Box.Text = Text
        if Input.Callback then task.spawn(Input.Callback, Text) end
        if Input.Changed then task.spawn(Input.Changed, Text) end
    end

    function Input:SetVisible(V) Holder.Visible = V end
    function Input:Destroy() Holder:Destroy(); Library.Options[Idx] = nil end

    Box.Focused:Connect(function() Tween(BoxStroke, { Color = Theme.Accent }) end)
    Box.FocusLost:Connect(function(Enter)
        Tween(BoxStroke, { Color = Theme.Outline })
        if Input.Finished and not Enter then
            Box.Text = Input.Value
            return
        end
        Input:SetValue(Box.Text)
    end)

    if not Input.Finished then
        Box:GetPropertyChangedSignal("Text"):Connect(function()
            if Box.Text ~= Input.Value then
                Input:SetValue(Box.Text)
            end
        end)
    end

    Input.Default = Input.Value
    Input.Holder = Holder
    Library.Options[Idx] = Input
    return Input
end

function Funcs:AddDropdown(Idx, Info)
    Info = Info or {}
    local Dropdown = {
        Text = Info.Text,
        Values = Info.Values or {},
        Multi = Info.Multi == true,
        AllowNull = Info.AllowNull,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Open = false,
        Type = "Dropdown",
    }
    Dropdown.Value = Dropdown.Multi and {} or nil

    local Default = Info.Default
    if Default ~= nil then
        if Dropdown.Multi then
            if typeof(Default) == "table" then
                for _, V in Default do Dropdown.Value[V] = true end
            else
                Dropdown.Value[Default] = true
            end
        else
            Dropdown.Value = Default
        end
    end

    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, self.Container)
    List(Holder, 3)

    if Dropdown.Text then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            Text = Dropdown.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = "SubText",
            LayoutOrder = 1,
        }, Holder)
    end

    local Head = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = "Element",
        Text = "---",
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
    }, Holder)
    Round(Head, 4)
    local HeadStroke = Stroke(Head)
    Pad(Head, 8, 24, 0, 0)

    local Arrow = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 20, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Text = "v",
        TextSize = 12,
        TextColor3 = "SubText",
    }, Head)

    local ListFrame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "Panel",
        Visible = false,
        LayoutOrder = 3,
    }, Holder)
    Round(ListFrame, 4)
    Stroke(ListFrame)
    List(ListFrame, 0)

    local function IsSelected(V)
        if Dropdown.Multi then return Dropdown.Value[V] == true end
        return Dropdown.Value == V
    end

    function Dropdown:Display()
        local Str = ""
        if Dropdown.Multi then
            local Parts = {}
            for _, V in Dropdown.Values do
                if Dropdown.Value[V] then table.insert(Parts, tostring(V)) end
            end
            Str = table.concat(Parts, ", ")
        elseif Dropdown.Value ~= nil then
            Str = tostring(Dropdown.Value)
        end
        if #Str > 28 then Str = Str:sub(1, 25) .. "..." end
        Head.Text = Str == "" and "---" or Str
    end

    local function Fire()
        Dropdown:Display()
        Library:UpdateDependencyBoxes()
        if Dropdown.Callback then task.spawn(Dropdown.Callback, Dropdown.Value) end
        if Dropdown.Changed then task.spawn(Dropdown.Changed, Dropdown.Value) end
    end

    function Dropdown:Refresh()
        for _, C in ListFrame:GetChildren() do
            if C:IsA("TextButton") then C:Destroy() end
        end

        for _, V in Dropdown.Values do
            local Selected = IsSelected(V)
            local Opt = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = "Element",
                BackgroundTransparency = Selected and 0 or 1,
                Text = tostring(V),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Selected and "Accent" or "SubText",
            }, ListFrame)
            Pad(Opt, 8, 8, 0, 0)

            Opt.MouseButton1Click:Connect(function()
                if Dropdown.Multi then
                    local Add = not Dropdown.Value[V]
                    if not Add and not Dropdown.AllowNull then
                        local Count = 0
                        for _ in Dropdown.Value do Count += 1 end
                        if Count <= 1 then return end
                    end
                    Dropdown.Value[V] = Add or nil
                else
                    if Dropdown.Value == V and Dropdown.AllowNull then
                        Dropdown.Value = nil
                    else
                        Dropdown.Value = V
                    end
                    Dropdown:Toggle(false)
                end
                Dropdown:Refresh()
                Fire()
            end)
        end
    end

    function Dropdown:Toggle(State)
        if State == nil then State = not Dropdown.Open end
        Dropdown.Open = State
        ListFrame.Visible = State
        Arrow.Text = State and "^" or "v"
        Tween(HeadStroke, { Color = State and Theme.Accent or Theme.Outline })
    end

    function Dropdown:OnChanged(Func) Dropdown.Changed = Func end

    function Dropdown:SetValue(Value)
        if Dropdown.Multi then
            local T = {}
            if typeof(Value) == "table" then
                for K, V in Value do
                    if typeof(K) == "number" then
                        T[V] = true
                    elseif V == true then
                        T[K] = true
                    end
                end
            elseif Value ~= nil then
                T[Value] = true
            end
            Dropdown.Value = T
        else
            Dropdown.Value = Value
        end
        Dropdown:Refresh()
        Fire()
    end

    function Dropdown:SetValues(Values)
        Dropdown.Values = Values
        if Dropdown.Multi then
            for V in Dropdown.Value do
                if not table.find(Values, V) then Dropdown.Value[V] = nil end
            end
        elseif Dropdown.Value ~= nil and not table.find(Values, Dropdown.Value) then
            Dropdown.Value = nil
        end
        Dropdown:Refresh()
        Dropdown:Display()
    end

    function Dropdown:SetVisible(V) Holder.Visible = V end
    function Dropdown:Destroy() Holder:Destroy(); Library.Options[Idx] = nil end

    Head.MouseButton1Click:Connect(function() Dropdown:Toggle() end)

    Library:AddRefresher(function()
        Dropdown:Refresh()
        HeadStroke.Color = Dropdown.Open and Theme.Accent or Theme.Outline
    end)

    Dropdown.Default = Dropdown.Multi and table.clone(Dropdown.Value) or Dropdown.Value
    Dropdown.Holder = Holder
    Dropdown:Refresh()
    Dropdown:Display()
    Library.Options[Idx] = Dropdown
    return Dropdown
end

function Funcs:AddDependencyBox()
    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    }, self.Container)
    List(Frame, 6)

    local Box = setmetatable({
        Container = Frame,
        Dependencies = {},
        Type = "DependencyBox",
    }, Funcs)

    function Box:Update()
        local Show = true
        for _, Dep in Box.Dependencies do
            local Element, Value = Dep[1], Dep[2]
            if Element.Type == "Toggle" then
                if Element.Value ~= Value then Show = false end
            elseif Element.Type == "Dropdown" then
                if Element.Multi then
                    if not Element.Value[Value] then Show = false end
                elseif Element.Value ~= Value then
                    Show = false
                end
            end
        end
        Frame.Visible = Show
    end

    function Box:SetupDependencies(Dependencies)
        Box.Dependencies = Dependencies
        Box:Update()
    end

    function Box:Destroy()
        Frame:Destroy()
        local I = table.find(Library.DependencyBoxes, Box)
        if I then table.remove(Library.DependencyBoxes, I) end
    end

    table.insert(Library.DependencyBoxes, Box)
    return Box
end

function Library:SetDPIScale(Percent)
    Library.DPIScale = Percent / 100
    if Library.Window then
        Library.Window.Scale.Scale = Library.DPIScale
    end
end

function Library:CreateWindow(Info)
    Info = Info or {}
    if Info.Accent then
        Theme.Accent = Info.Accent
        Library:UpdateTheme()
    end

    local KeyCode = Info.ToggleKeybind or Enum.KeyCode.RightControl
    Library.ToggleKeyName = KeyCode.Name

    local Main = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = Info.Center == false and UDim2.fromOffset(100, 100) or UDim2.fromScale(0.5, 0.5),
        Size = Info.Size or UDim2.fromOffset(580, 420),
        BackgroundColor3 = "Background",
        ClipsDescendants = true,
    }, ScreenGui)
    Round(Main, 6)
    Stroke(Main)
    local Scale = New("UIScale", { Scale = Library.DPIScale }, Main)

    local TitleBar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = "Panel",
    }, Main)
    New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = "Accent",
    }, TitleBar)
    local TitleLabel = New("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        Text = Info.Title or "Universal Library",
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, TitleBar)

    local Close = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = "SubText",
    }, TitleBar)
    Close.MouseEnter:Connect(function() Tween(Close, { TextColor3 = Theme.Red }) end)
    Close.MouseLeave:Connect(function() Tween(Close, { TextColor3 = Theme.SubText }) end)

    Library:MakeDraggable(Main, TitleBar)

    local Sidebar = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(0, 120, 1, -32),
        BackgroundColor3 = "Panel",
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, Main)
    List(Sidebar, 2)
    Pad(Sidebar, 6, 6, 6, 6)

    local Content = New("Frame", {
        Position = UDim2.fromOffset(120, 32),
        Size = UDim2.new(1, -120, 1, -32),
        BackgroundTransparency = 1,
    }, Main)

    local Window = { Main = Main, Scale = Scale, ActiveTab = nil }

    function Window:SetTitle(T) TitleLabel.Text = T end

    function Window:AddTab(Name)
        local Button = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = "Element",
            BackgroundTransparency = 1,
            Text = Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = "SubText",
        }, Sidebar)
        Round(Button, 4)
        Pad(Button, 12, 6, 0, 0)

        local Bar = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -9, 0.5, 0),
            Size = UDim2.fromOffset(3, 0),
            BackgroundColor3 = "Accent",
        }, Button)
        Round(Bar, 2)

        local Page = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = "Outline",
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, Content)
        List(Page, 8)
        Pad(Page, 10, 12, 10, 10)

        local Tab = { Name = Name, Page = Page, Groupboxes = {} }

        function Tab:Refresh()
            local Active = Window.ActiveTab == Tab
            Button.BackgroundTransparency = Active and 0 or 1
            Button.TextColor3 = Active and Theme.Text or Theme.SubText
        end

        function Tab:Show()
            if Window.ActiveTab == Tab then return end
            Library:ClosePopup()
            local Old = Window.ActiveTab
            Window.ActiveTab = Tab
            if Old then
                Old.Page.Visible = false
                Old:Refresh()
                Old.SetBar(false)
            end
            Page.Visible = true
            Tab:Refresh()
            Tab.SetBar(true)
        end

        Tab.SetBar = function(State)
            Tween(Bar, { Size = State and UDim2.fromOffset(3, 16) or UDim2.fromOffset(3, 0) })
        end

        function Tab:AddGroupbox(GInfo)
            GInfo = typeof(GInfo) == "table" and GInfo or { Name = GInfo }

            local Box = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = "Panel",
            }, Page)
            Round(Box, 5)
            Stroke(Box)
            List(Box, 0)

            local Header = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = 1,
            }, Box)
            New("TextLabel", {
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = GInfo.Name or "Groupbox",
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)
            local Arrow = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Text = "-",
                TextColor3 = "SubText",
            }, Header)

            New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = "Outline",
                LayoutOrder = 2,
            }, Box)

            local Container = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 3,
            }, Box)
            List(Container, 6)
            Pad(Container, 10, 10, 8, 8)

            local Groupbox = setmetatable({
                Container = Container,
                Collapsed = false,
            }, Funcs)

            function Groupbox:SetCollapsed(State)
                Groupbox.Collapsed = State
                Container.Visible = not State
                Arrow.Text = State and "+" or "-"
            end
            function Groupbox:SetVisible(V) Box.Visible = V end

            Header.MouseButton1Click:Connect(function()
                Groupbox:SetCollapsed(not Groupbox.Collapsed)
            end)

            if GInfo.Collapsed then Groupbox:SetCollapsed(true) end

            Tab.Groupboxes[GInfo.Name or #Tab.Groupboxes + 1] = Groupbox
            return Groupbox
        end

        Button.MouseButton1Click:Connect(function() Tab:Show() end)
        Button.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then Tween(Button, { TextColor3 = Theme.Text }) end
        end)
        Button.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then Tween(Button, { TextColor3 = Theme.SubText }) end
        end)

        Library:AddRefresher(function() Tab:Refresh() end)

        if not Window.ActiveTab then Tab:Show() end

        Library.Tabs[Name] = Tab
        return Tab
    end

    function Window:Toggle(State)
        if State == nil then State = not Library.Toggled end
        Library.Toggled = State
        Main.Visible = State
        if not State then Library:ClosePopup() end
    end

    Close.MouseButton1Click:Connect(function() Library:Unload() end)

    Signal(UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed or Library.Unloaded then return end
        if UserInputService:GetFocusedTextBox() then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeyName then
            Window:Toggle()
        end
    end))

    Library.Window = Window
    return Window
end

function Library:Toggle(State)
    if Library.Window then Library.Window:Toggle(State) end
end

function Library:BuildUISettings(Tab)
    local Box = Tab:AddGroupbox("Menu")

    Box:AddToggle("UL_KeybindList", {
        Text = "Show keybind list",
        Default = false,
        Callback = function(V) Library:SetKeybindListVisibility(V) end,
    })
    Box:AddToggle("UL_Watermark", {
        Text = "Show watermark",
        Default = false,
        Callback = function(V) Library:SetWatermarkVisibility(V) end,
    })
    Box:AddSlider("UL_DPI", {
        Text = "UI scale",
        Min = 60,
        Max = 140,
        Default = 100,
        Suffix = "%",
        Callback = function(V) Library:SetDPIScale(V) end,
    })
    Box:AddLabel("Menu keybind"):AddKeyPicker("UL_MenuKeybind", {
        Default = Library.ToggleKeyName,
        Mode = "Always",
        Modes = { "Always" },
        NoUI = true,
        Text = "Menu keybind",
        ChangedCallback = function(Key)
            if Key ~= "None" then Library.ToggleKeyName = Key end
        end,
    })
    Box:AddDivider()
    Box:AddButton({ Text = "Unload", Func = function() Library:Unload() end })
    return Box
end

local ThemeManager = {
    Folder = "UniversalLibrary",
    Applying = false,
    Presets = {
        Default = {
            Background = Color3.fromRGB(17, 17, 21), Panel = Color3.fromRGB(26, 26, 32),
            Element = Color3.fromRGB(34, 34, 42), Outline = Color3.fromRGB(48, 48, 58),
            Accent = Color3.fromRGB(90, 170, 255), Text = Color3.fromRGB(235, 235, 240),
            SubText = Color3.fromRGB(150, 150, 160),
        },
        Midnight = {
            Background = Color3.fromRGB(10, 12, 20), Panel = Color3.fromRGB(16, 19, 32),
            Element = Color3.fromRGB(24, 28, 46), Outline = Color3.fromRGB(38, 44, 70),
            Accent = Color3.fromRGB(120, 130, 255), Text = Color3.fromRGB(230, 232, 250),
            SubText = Color3.fromRGB(140, 146, 180),
        },
        Rose = {
            Background = Color3.fromRGB(20, 14, 18), Panel = Color3.fromRGB(30, 21, 27),
            Element = Color3.fromRGB(42, 29, 37), Outline = Color3.fromRGB(64, 44, 56),
            Accent = Color3.fromRGB(255, 105, 150), Text = Color3.fromRGB(245, 232, 238),
            SubText = Color3.fromRGB(170, 145, 156),
        },
        Emerald = {
            Background = Color3.fromRGB(12, 18, 16), Panel = Color3.fromRGB(18, 27, 23),
            Element = Color3.fromRGB(25, 38, 32), Outline = Color3.fromRGB(38, 58, 49),
            Accent = Color3.fromRGB(70, 220, 140), Text = Color3.fromRGB(230, 245, 238),
            SubText = Color3.fromRGB(140, 170, 155),
        },
        Amethyst = {
            Background = Color3.fromRGB(17, 13, 24), Panel = Color3.fromRGB(25, 19, 36),
            Element = Color3.fromRGB(35, 27, 50), Outline = Color3.fromRGB(54, 42, 77),
            Accent = Color3.fromRGB(170, 100, 255), Text = Color3.fromRGB(240, 232, 250),
            SubText = Color3.fromRGB(160, 146, 180),
        },
        Mono = {
            Background = Color3.fromRGB(14, 14, 14), Panel = Color3.fromRGB(22, 22, 22),
            Element = Color3.fromRGB(32, 32, 32), Outline = Color3.fromRGB(50, 50, 50),
            Accent = Color3.fromRGB(220, 220, 220), Text = Color3.fromRGB(240, 240, 240),
            SubText = Color3.fromRGB(140, 140, 140),
        },
        Light = {
            Background = Color3.fromRGB(238, 238, 242), Panel = Color3.fromRGB(250, 250, 252),
            Element = Color3.fromRGB(228, 228, 234), Outline = Color3.fromRGB(205, 205, 215),
            Accent = Color3.fromRGB(60, 130, 240), Text = Color3.fromRGB(30, 30, 40),
            SubText = Color3.fromRGB(100, 100, 115),
        },
    },
    Order = { "Default", "Midnight", "Rose", "Emerald", "Amethyst", "Mono", "Light" },
    Keys = { "Background", "Panel", "Element", "Outline", "Accent", "Text", "SubText" },
}

function ThemeManager:SetFolder(Folder)
    ThemeManager.Folder = Folder
end

function ThemeManager:ApplyTheme(Name)
    local Preset = ThemeManager.Presets[Name]
    if not Preset then return end

    ThemeManager.Applying = true
    for _, Key in ThemeManager.Keys do
        Theme[Key] = Preset[Key]
        local Picker = Library.Options["ThemeManager_" .. Key]
        if Picker then
            Picker:SetValueRGB(Preset[Key])
        end
    end
    ThemeManager.Applying = false
    Library:UpdateTheme()
end

function ThemeManager:ThemePath()
    return ThemeManager.Folder .. "/themes/default.json"
end

function ThemeManager:SaveDefault()
    if not (writefile and makefolder and isfolder) then
        Library:Notify("Your executor does not support file functions.")
        return
    end

    if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end
    if not isfolder(ThemeManager.Folder .. "/themes") then makefolder(ThemeManager.Folder .. "/themes") end

    local Data = {}
    for _, Key in ThemeManager.Keys do
        Data[Key] = Theme[Key]:ToHex()
    end
    writefile(ThemeManager:ThemePath(), HttpService:JSONEncode(Data))
    Library:Notify("Saved current theme as default.")
end

function ThemeManager:LoadDefault()
    if not (isfile and readfile) or not isfile(ThemeManager:ThemePath()) then return end

    local Ok, Data = pcall(function()
        return HttpService:JSONDecode(readfile(ThemeManager:ThemePath()))
    end)
    if not Ok then return end

    ThemeManager.Applying = true
    for _, Key in ThemeManager.Keys do
        if Data[Key] then
            local Good, Color = pcall(Color3.fromHex, Data[Key])
            if Good then
                Theme[Key] = Color
                local Picker = Library.Options["ThemeManager_" .. Key]
                if Picker then Picker:SetValueRGB(Color) end
            end
        end
    end
    ThemeManager.Applying = false
    Library:UpdateTheme()
end

function ThemeManager:BuildThemeSection(Tab)
    local Box = Tab:AddGroupbox("Theme")

    Box:AddDropdown("ThemeManager_Preset", {
        Text = "Preset",
        Values = ThemeManager.Order,
        Default = "Default",
        Callback = function(V)
            if V then ThemeManager:ApplyTheme(V) end
        end,
    })
    Box:AddDivider()

    for _, Key in ThemeManager.Keys do
        Box:AddLabel(Key .. " color"):AddColorPicker("ThemeManager_" .. Key, {
            Default = Theme[Key],
            Callback = function(Color)
                if ThemeManager.Applying then return end
                Theme[Key] = Color
                Library:UpdateTheme()
            end,
        })
    end

    Box:AddDivider()
    Box:AddButton("Save as default theme", function() ThemeManager:SaveDefault() end)
    Box:AddButton("Load default theme", function() ThemeManager:LoadDefault() end)
    return Box
end

local SaveManager = {
    Folder = "UniversalLibrary",
    SubFolder = "",
    IgnoreTheme = false,
    Ignore = {},
}

local Parsers = {
    Toggle = {
        Save = function(Idx, Obj) return { type = "Toggle", idx = Idx, value = Obj.Value } end,
        Load = function(Idx, Data)
            if Library.Toggles[Idx] then Library.Toggles[Idx]:SetValue(Data.value) end
        end,
    },
    Slider = {
        Save = function(Idx, Obj) return { type = "Slider", idx = Idx, value = Obj.Value } end,
        Load = function(Idx, Data)
            if Library.Options[Idx] then Library.Options[Idx]:SetValue(Data.value) end
        end,
    },
    Input = {
        Save = function(Idx, Obj) return { type = "Input", idx = Idx, value = Obj.Value } end,
        Load = function(Idx, Data)
            if Library.Options[Idx] and typeof(Data.value) == "string" then
                Library.Options[Idx]:SetValue(Data.value)
            end
        end,
    },
    Dropdown = {
        Save = function(Idx, Obj)
            local Value = Obj.Value
            if Obj.Multi then
                Value = {}
                for _, V in Obj.Values do
                    if Obj.Value[V] then table.insert(Value, V) end
                end
            end
            return { type = "Dropdown", idx = Idx, value = Value, multi = Obj.Multi }
        end,
        Load = function(Idx, Data)
            if Library.Options[Idx] then Library.Options[Idx]:SetValue(Data.value) end
        end,
    },
    KeyPicker = {
        Save = function(Idx, Obj) return { type = "KeyPicker", idx = Idx, key = Obj.Value, mode = Obj.Mode } end,
        Load = function(Idx, Data)
            if Library.Options[Idx] then Library.Options[Idx]:SetValue({ Data.key, Data.mode }) end
        end,
    },
    ColorPicker = {
        Save = function(Idx, Obj)
            return { type = "ColorPicker", idx = Idx, value = Obj.Value:ToHex(), transparency = Obj.Transparency }
        end,
        Load = function(Idx, Data)
            if Library.Options[Idx] and typeof(Data.value) == "string" then
                local Ok, Color = pcall(Color3.fromHex, Data.value)
                if Ok then Library.Options[Idx]:SetValueRGB(Color, Data.transparency) end
            end
        end,
    },
}

function SaveManager:SetFolder(Folder)
    SaveManager.Folder = Folder
    SaveManager:BuildFolderTree()
end

function SaveManager:SetSubFolder(Folder)
    SaveManager.SubFolder = Folder
    SaveManager:BuildFolderTree()
end

function SaveManager:SetIgnoreIndexes(List_)
    for _, Key in List_ do
        SaveManager.Ignore[Key] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    SaveManager.IgnoreTheme = true
end

function SaveManager:IsIgnored(Idx)
    if SaveManager.Ignore[Idx] then return true end
    if type(Idx) == "string" then
        if Idx:sub(1, 12) == "SaveManager_" then return true end
        if SaveManager.IgnoreTheme and Idx:sub(1, 13) == "ThemeManager_" then return true end
    end
    return false
end

function SaveManager:SettingsPath()
    local Path = SaveManager.Folder .. "/settings"
    if SaveManager.SubFolder ~= "" then
        Path = Path .. "/" .. SaveManager.SubFolder
    end
    return Path
end

function SaveManager:BuildFolderTree()
    if not (isfolder and makefolder) then return end

    local Paths = { SaveManager.Folder, SaveManager.Folder .. "/settings" }
    if SaveManager.SubFolder ~= "" then
        table.insert(Paths, SaveManager.Folder .. "/settings/" .. SaveManager.SubFolder)
    end
    for _, Path in Paths do
        if not isfolder(Path) then makefolder(Path) end
    end
end

function SaveManager:Save(Name)
    if not writefile then return false, "executor has no file functions" end
    if not Name or Name:gsub(" ", "") == "" then return false, "config name is empty" end

    SaveManager:BuildFolderTree()

    local Data = { objects = {} }
    for Idx, Toggle in Library.Toggles do
        if not SaveManager:IsIgnored(Idx) then
            table.insert(Data.objects, Parsers.Toggle.Save(Idx, Toggle))
        end
    end
    for Idx, Option in Library.Options do
        local Parser = Parsers[Option.Type]
        if Parser and not SaveManager:IsIgnored(Idx) then
            table.insert(Data.objects, Parser.Save(Idx, Option))
        end
    end

    local Ok, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)
    if not Ok then return false, "failed to encode config" end

    writefile(SaveManager:SettingsPath() .. "/" .. Name .. ".json", Encoded)
    return true
end

function SaveManager:Load(Name)
    if not (readfile and isfile) then return false, "executor has no file functions" end
    if not Name or Name == "" then return false, "no config selected" end

    local Path = SaveManager:SettingsPath() .. "/" .. Name .. ".json"
    if not isfile(Path) then return false, "config does not exist" end

    local Ok, Data = pcall(function()
        return HttpService:JSONDecode(readfile(Path))
    end)
    if not Ok then return false, "failed to decode config" end

    for _, Object in Data.objects do
        local Parser = Parsers[Object.type]
        if Parser and not SaveManager:IsIgnored(Object.idx) then
            task.spawn(pcall, Parser.Load, Object.idx, Object)
        end
    end
    return true
end

function SaveManager:Delete(Name)
    if not (delfile and isfile) then return false, "executor has no file functions" end

    local Path = SaveManager:SettingsPath() .. "/" .. Name .. ".json"
    if not isfile(Path) then return false, "config does not exist" end

    delfile(Path)
    return true
end

function SaveManager:GetList()
    if not (listfiles and isfolder) then return {} end

    SaveManager:BuildFolderTree()
    local Out = {}
    for _, File in listfiles(SaveManager:SettingsPath()) do
        local Name = File:match("([^/\\]+)%.json$")
        if Name then table.insert(Out, Name) end
    end
    table.sort(Out)
    return Out
end

function SaveManager:SetAutoload(Name)
    if not writefile then return false, "executor has no file functions" end
    SaveManager:BuildFolderTree()
    writefile(SaveManager:SettingsPath() .. "/autoload.txt", Name)
    return true
end

function SaveManager:GetAutoload()
    if not (isfile and readfile) then return nil end
    local Path = SaveManager:SettingsPath() .. "/autoload.txt"
    if isfile(Path) then
        local Name = readfile(Path)
        if Name ~= "" then return Name end
    end
    return nil
end

function SaveManager:ResetAutoload()
    if not (isfile and delfile) then return false end
    local Path = SaveManager:SettingsPath() .. "/autoload.txt"
    if isfile(Path) then delfile(Path) end
    return true
end

function SaveManager:LoadAutoload()
    local Name = SaveManager:GetAutoload()
    if not Name then return end

    local Ok, Err = SaveManager:Load(Name)
    if Ok then
        Library:Notify({ Title = "Config", Description = "Auto loaded config " .. Name })
    else
        Library:Notify({ Title = "Config", Description = "Failed to autoload: " .. tostring(Err) })
    end
end

function SaveManager:BuildConfigSection(Tab)
    SaveManager:BuildFolderTree()
    local Box = Tab:AddGroupbox("Configuration")

    local function Result(Ok, Err, Message)
        if Ok then
            Library:Notify({ Title = "Config", Description = Message })
        else
            Library:Notify({ Title = "Config error", Description = tostring(Err) })
        end
    end

    Box:AddInput("SaveManager_ConfigName", { Text = "Config name", Placeholder = "my config" })
    Box:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = SaveManager:GetList() })
    Box:AddDivider()

    local AutoLabel = Box:AddLabel("Autoload: " .. (SaveManager:GetAutoload() or "none"))

    Box:AddButton("Create config", function()
        local Name = Library.Options.SaveManager_ConfigName.Value
        local Ok, Err = SaveManager:Save(Name)
        Result(Ok, Err, "Created config " .. tostring(Name))
        if Ok then
            Library.Options.SaveManager_ConfigList:SetValues(SaveManager:GetList())
            Library.Options.SaveManager_ConfigList:SetValue(Name)
        end
    end)

    Box:AddButton("Load config", function()
        local Name = Library.Options.SaveManager_ConfigList.Value
        local Ok, Err = SaveManager:Load(Name)
        Result(Ok, Err, "Loaded config " .. tostring(Name))
    end)

    Box:AddButton({ Text = "Overwrite config", DoubleClick = true, Func = function()
        local Name = Library.Options.SaveManager_ConfigList.Value
        local Ok, Err = SaveManager:Save(Name)
        Result(Ok, Err, "Overwrote config " .. tostring(Name))
    end })

    Box:AddButton({ Text = "Delete config", DoubleClick = true, Func = function()
        local Name = Library.Options.SaveManager_ConfigList.Value
        local Ok, Err = SaveManager:Delete(Name)
        Result(Ok, Err, "Deleted config " .. tostring(Name))
        if Ok then
            Library.Options.SaveManager_ConfigList:SetValues(SaveManager:GetList())
            Library.Options.SaveManager_ConfigList:SetValue(nil)
        end
    end })

    Box:AddButton("Refresh list", function()
        Library.Options.SaveManager_ConfigList:SetValues(SaveManager:GetList())
    end)

    Box:AddButton("Set as autoload", function()
        local Name = Library.Options.SaveManager_ConfigList.Value
        if not Name then
            Library:Notify({ Title = "Config error", Description = "Select a config first." })
            return
        end
        local Ok, Err = SaveManager:SetAutoload(Name)
        Result(Ok, Err, "Autoload set to " .. Name)
        if Ok then AutoLabel:SetText("Autoload: " .. Name) end
    end)

    Box:AddButton("Reset autoload", function()
        SaveManager:ResetAutoload()
        AutoLabel:SetText("Autoload: none")
        Library:Notify({ Title = "Config", Description = "Autoload reset." })
    end)

    return Box
end

Library.ThemeManager = ThemeManager
Library.SaveManager = SaveManager

function Library:Unload()
    if Library.Unloaded then return end
    Library.Unloaded = true

    for _, C in Library.Signals do
        pcall(function() C:Disconnect() end)
    end
    table.clear(Library.Signals)

    for _, Func in Library.UnloadCallbacks or {} do
        pcall(Func)
    end

    ScreenGui:Destroy()

    table.clear(Library.Toggles)
    table.clear(Library.Options)
    table.clear(Library.Buttons)
    table.clear(Library.Labels)
    table.clear(Library.Tabs)
    table.clear(Library.Refreshers)
    table.clear(Library.DependencyBoxes)
    table.clear(Library.KeyPickers)
end

function Library:OnUnload(Func)
    Library.UnloadCallbacks = Library.UnloadCallbacks or {}
    table.insert(Library.UnloadCallbacks, Func)
end

return Library
