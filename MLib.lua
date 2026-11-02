--[[
    MLib - Clean Dark UI Library
    Designed to closely match the floating panel style from the screenshot.
]]

local MLib = {
    Version = "1.1.0",
    Flags = {},
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Theme matching the screenshot
local Theme = {
    Background      = Color3.fromRGB(22, 22, 28),
    Secondary       = Color3.fromRGB(30, 30, 38),
    Tertiary        = Color3.fromRGB(40, 40, 50),
    Accent          = Color3.fromRGB(145, 100, 255),
    Text            = Color3.fromRGB(235, 235, 245),
    TextDim         = Color3.fromRGB(150, 150, 165),
    Outline         = Color3.fromRGB(55, 55, 70),
    ToggleOn        = Color3.fromRGB(145, 100, 255),
    ToggleOff       = Color3.fromRGB(55, 55, 70),
    SliderBg        = Color3.fromRGB(45, 45, 55),
    Danger          = Color3.fromRGB(230, 70, 70),
}

-------------------------------------------------
-- Utilities
-------------------------------------------------
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function Tween(obj, props, time)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-------------------------------------------------
-- ScreenGui
-------------------------------------------------
local ScreenGui = Create("ScreenGui", {
    Name = "MLib",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = (gethui and gethui()) or CoreGui,
})

-------------------------------------------------
-- CreateWindow
-------------------------------------------------
function MLib:CreateWindow(config)
    config = config or {}
    local Title = config.Title or "MLib"
    local Size = config.Size or UDim2.fromOffset(520, 360)
    local Position = config.Position or UDim2.fromOffset(120, 100)

    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Flags = MLib.Flags,
    }

    -- Main floating window
    local Main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = Position,
        Size = Size,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Main })
    Create("UIStroke", {
        Color = Theme.Outline,
        Thickness = 1,
        Transparency = 0.4,
        Parent = Main,
    })

    -- Top bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = Main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = TopBar })
    Create("Frame", { -- cover bottom radius
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = TopBar,
    })

    local TitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = Title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    -- Close button
    local CloseBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0.5, -9),
        Size = UDim2.fromOffset(18, 18),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.TextDim,
        TextSize = 16,
        Parent = TopBar,
    })
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { TextColor3 = Theme.Danger })
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { TextColor3 = Theme.TextDim })
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)

    MakeDraggable(Main, TopBar)

    -- Horizontal Tab Bar (under topbar)
    local TabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = Main,
    })
    local TabList = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar,
    })
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4),
        Parent = TabBar,
    })

    -- Content area
    local Content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 62),
        Size = UDim2.new(1, 0, 1, -62),
        ClipsDescendants = true,
        Parent = Main,
    })

    -------------------------------------------------
    -- AddTab
    -------------------------------------------------
    function Window:AddTab(name)
        local Tab = {
            Name = name,
        }

        local TabBtn = Create("TextButton", {
            BackgroundColor3 = Theme.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Enum.Font.Gotham,
            Text = "  " .. name .. "  ",
            TextColor3 = Theme.TextDim,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = TabBar,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        local Indicator = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2),
            Visible = false,
            Parent = TabBtn,
        })

        local TabPage = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = Content,
        })

        -- Two columns
        local LeftCol = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 6),
            Size = UDim2.new(0.5, -12, 1, -12),
            Parent = TabPage,
        })
        local LeftLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = LeftCol,
        })

        local RightCol = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 4, 0, 6),
            Size = UDim2.new(0.5, -12, 1, -12),
            Parent = TabPage,
        })
        local RightLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = RightCol,
        })

        local function UpdateCanvas()
            local h = math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, h + 16)
        end
        LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        function Tab:Show()
            if Window.ActiveTab then
                Window.ActiveTab.Page.Visible = false
                Window.ActiveTab.Button.BackgroundTransparency = 1
                Window.ActiveTab.Button.TextColor3 = Theme.TextDim
                Window.ActiveTab.Indicator.Visible = false
            end
            TabPage.Visible = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3 = Theme.Text
            Indicator.Visible = true
            Window.ActiveTab = { Page = TabPage, Button = TabBtn, Indicator = Indicator }
        end

        TabBtn.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        -------------------------------------------------
        -- Groupbox factory
        -------------------------------------------------
        local function CreateGroupbox(side, name)
            local Holder = side == 1 and LeftCol or RightCol

            local Box = Create("Frame", {
                BackgroundColor3 = Theme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Holder,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Box })
            Create("UIStroke", {
                Color = Theme.Outline,
                Thickness = 1,
                Transparency = 0.55,
                Parent = Box,
            })

            -- Header
            local Header = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 0, 26),
                Position = UDim2.fromOffset(10, 2),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Box,
            })

            local Container = Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 28),
                Size = UDim2.new(1, -16, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Box,
            })
            Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                Parent = Container,
            })

            local Groupbox = { Container = Container }

            -------------------------------------------------
            -- Elements
            -------------------------------------------------
            function Groupbox:AddLabel(text)
                return Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Container,
                })
            end

            function Groupbox:AddButton(text, callback)
                local Btn = Create("TextButton", {
                    BackgroundColor3 = Theme.Tertiary,
                    Size = UDim2.new(1, 0, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    AutoButtonColor = false,
                    Parent = Container,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Theme.Accent })
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Theme.Tertiary })
                end)
                Btn.MouseButton1Click:Connect(function()
                    if callback then task.spawn(callback) end
                end)
                return Btn
            end

            function Groupbox:AddToggle(flag, options)
                options = options or {}
                local Text = options.Text or flag or "Toggle"
                local Default = options.Default or false
                local Callback = options.Callback or function() end

                MLib.Flags[flag] = Default

                local Row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    Parent = Container,
                })

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -42, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                -- Pill toggle (like screenshot)
                local ToggleBg = Create("Frame", {
                    BackgroundColor3 = Default and Theme.ToggleOn or Theme.ToggleOff,
                    Position = UDim2.new(1, -36, 0.5, -8),
                    Size = UDim2.fromOffset(34, 16),
                    Parent = Row,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleBg })

                local Circle = Create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Position = Default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                    Size = UDim2.fromOffset(12, 12),
                    Parent = ToggleBg,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Circle })

                local function Set(val)
                    MLib.Flags[flag] = val
                    Tween(ToggleBg, { BackgroundColor3 = val and Theme.ToggleOn or Theme.ToggleOff })
                    Tween(Circle, {
                        Position = val and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                    })
                    Callback(val)
                end

                local Hit = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "",
                    Parent = Row,
                })
                Hit.MouseButton1Click:Connect(function()
                    Set(not MLib.Flags[flag])
                end)

                return { Set = Set, Get = function() return MLib.Flags[flag] end }
            end

            function Groupbox:AddSlider(flag, options)
                options = options or {}
                local Text = options.Text or flag or "Slider"
                local Min = options.Min or 0
                local Max = options.Max or 100
                local Default = math.clamp(options.Default or Min, Min, Max)
                local Rounding = options.Rounding or 0
                local Suffix = options.Suffix or ""
                local Callback = options.Callback or function() end

                MLib.Flags[flag] = Default

                local Row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 36),
                    Parent = Container,
                })

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local ValueLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -48, 0, 0),
                    Size = UDim2.fromOffset(48, 14),
                    Font = Enum.Font.Gotham,
                    Text = tostring(Default) .. Suffix,
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Row,
                })

                local BarBg = Create("Frame", {
                    BackgroundColor3 = Theme.SliderBg,
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, 5),
                    Parent = Row,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = BarBg })

                local Fill = Create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((Default - Min) / math.max(Max - Min, 1), 0, 1, 0),
                    Parent = BarBg,
                })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

                local dragging = false
                local function Update(val)
                    val = math.clamp(val, Min, Max)
                    val = Round(val, Rounding)
                    MLib.Flags[flag] = val
                    local pct = (val - Min) / math.max(Max - Min, 1)
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    ValueLabel.Text = tostring(val) .. Suffix
                    Callback(val)
                end

                local function fromInput(input)
                    local rel = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
                    Update(Min + (Max - Min) * rel)
                end

                BarBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        fromInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        fromInput(input)
                    end
                end)

                return { Set = Update, Get = function() return MLib.Flags[flag] end }
            end

            function Groupbox:AddDropdown(flag, options)
                options = options or {}
                local Text = options.Text or flag or "Dropdown"
                local Values = options.Values or { "Option 1" }
                local Default = options.Default or Values[1]
                local Callback = options.Callback or function() end

                MLib.Flags[flag] = Default

                local Row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = Container,
                })

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local DropBtn = Create("TextButton", {
                    BackgroundColor3 = Theme.Tertiary,
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 24),
                    Font = Enum.Font.Gotham,
                    Text = "  " .. tostring(Default) .. "  ▼",
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    Parent = Row,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropBtn })

                local Open = false
                local ListFrame = Create("Frame", {
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(0, 0, 1, 3),
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 40,
                    Parent = DropBtn,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ListFrame })
                Create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = ListFrame })
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ListFrame })

                local function Close()
                    Open = false
                    ListFrame.Visible = false
                    ListFrame.Size = UDim2.new(1, 0, 0, 0)
                end

                for _, val in ipairs(Values) do
                    local Opt = Create("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 22),
                        Font = Enum.Font.Gotham,
                        Text = "  " .. tostring(val),
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 41,
                        Parent = ListFrame,
                    })
                    Opt.MouseEnter:Connect(function()
                        Opt.BackgroundTransparency = 0.85
                        Opt.BackgroundColor3 = Theme.Accent
                    end)
                    Opt.MouseLeave:Connect(function()
                        Opt.BackgroundTransparency = 1
                    end)
                    Opt.MouseButton1Click:Connect(function()
                        MLib.Flags[flag] = val
                        DropBtn.Text = "  " .. tostring(val) .. "  ▼"
                        Callback(val)
                        Close()
                    end)
                end

                DropBtn.MouseButton1Click:Connect(function()
                    if Open then
                        Close()
                    else
                        Open = true
                        ListFrame.Visible = true
                        ListFrame.Size = UDim2.new(1, 0, 0, #Values * 22)
                    end
                end)

                return {
                    Set = function(v)
                        MLib.Flags[flag] = v
                        DropBtn.Text = "  " .. tostring(v) .. "  ▼"
                        Callback(v)
                    end,
                    Get = function() return MLib.Flags[flag] end,
                }
            end

            function Groupbox:AddInput(flag, options)
                options = options or {}
                local Text = options.Text or flag or "Input"
                local Default = options.Default or ""
                local Placeholder = options.Placeholder or ""
                local Callback = options.Callback or function() end

                MLib.Flags[flag] = Default

                local Row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = Container,
                })

                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Box = Create("TextBox", {
                    BackgroundColor3 = Theme.Tertiary,
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 24),
                    Font = Enum.Font.Gotham,
                    Text = Default,
                    PlaceholderText = Placeholder,
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.TextDim,
                    TextSize = 11,
                    ClearTextOnFocus = false,
                    Parent = Row,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Box })
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    Parent = Box,
                })

                Box.FocusLost:Connect(function()
                    MLib.Flags[flag] = Box.Text
                    Callback(Box.Text)
                end)

                return {
                    Set = function(v)
                        Box.Text = tostring(v)
                        MLib.Flags[flag] = v
                        Callback(v)
                    end,
                    Get = function() return MLib.Flags[flag] end,
                }
            end

            function Groupbox:AddDivider()
                Create("Frame", {
                    BackgroundColor3 = Theme.Outline,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = Container,
                })
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(name)
            return CreateGroupbox(1, name)
        end

        function Tab:AddRightGroupbox(name)
            return CreateGroupbox(2, name)
        end

        function Tab:AddGroupbox(name, side)
            return CreateGroupbox(side or 1, name)
        end

        table.insert(Window.Tabs, Tab)
        if not Window.ActiveTab then
            Tab:Show()
        end

        return Tab
    end

    function Window:SetTitle(t)
        TitleLabel.Text = t
    end

    function Window:Toggle()
        Main.Visible = not Main.Visible
    end

    -- Toggle key
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == ToggleKey then
            Window:Toggle()
        end
    end)

    return Window
end

-------------------------------------------------
-- Notify
-------------------------------------------------
function MLib:Notify(title, text, duration)
    duration = duration or 3
    local Notif = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 20, 1, -80),
        Size = UDim2.fromOffset(250, 56),
        Parent = ScreenGui,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Notif })
    Create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = Notif })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = title or "Notification",
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notif,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 26),
        Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = Notif,
    })

    Tween(Notif, { Position = UDim2.new(1, -270, 1, -80) }, 0.25)
    task.delay(duration, function()
        local tw = Tween(Notif, { Position = UDim2.new(1, 20, 1, -80) }, 0.25)
        tw.Completed:Wait()
        Notif:Destroy()
    end)
end

return MLib
