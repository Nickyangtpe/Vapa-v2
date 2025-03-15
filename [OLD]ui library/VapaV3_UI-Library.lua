local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local library = {}

library.theme = {
    background = Color3.fromRGB(30, 30, 30),
    windowBackground = Color3.fromRGB(30, 30, 30),
    foreground = Color3.fromRGB(255, 255, 255),
    muted = Color3.fromRGB(175, 175, 175),
    accent = Color3.fromRGB(0, 170, 255),
    success = Color3.fromRGB(0, 255, 0),
    warning = Color3.fromRGB(255, 255, 0),
    error = Color3.fromRGB(255, 0, 0)
}

local currentlyDraggedWindow = nil
local WINDOW_PADDING = 10
local DRAG_THRESHOLD = 5
local MOBILE = UserInputService.TouchEnabled

-- UI 建立 ScreenGui 物件，作為所有 UI 元素的容器
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VAPE"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if MOBILE then ScreenGui.IgnoreGuiInset = true end
if RunService:IsStudio() then
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

local function CreateTween(instance, properties, duration)
    return TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
end

local WindowManager = { activeWindow = nil, zIndex = 1, windows = {}, windowOffset = 0 }

function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
    self.activeWindow = window
end

------------------------------------------------
-- CreateWindow(name, fixed, Width, Height) / TagWindow – 創建Window
function library:CreateWindow(name, fixed, Width, Height)
    -- 創建 Frame 作為視窗基礎
    local window = Instance.new("Frame")
    window.Name = name
    window.Parent = ScreenGui
    window.BackgroundColor3 = self.theme.windowBackground
    window.BackgroundTransparency = 0.1
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.ZIndex = WindowManager.zIndex
    window.Visible = false
    WindowManager.zIndex = WindowManager.zIndex + 1

    window:SetAttribute("Fixed", fixed)
    if fixed then window.Visible = true end

    window.Size = UDim2.new(0, Width, 0, Height)

    if not fixed then
        local offset = WindowManager.windowOffset
        local screenWidth, screenHeight = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
        local windowX = (screenWidth - Width) / 2 + offset
        local windowY = (screenHeight - Height) / 2 + offset
        windowX = math.clamp(windowX, WINDOW_PADDING, screenWidth - Width - WINDOW_PADDING)
        windowY = math.clamp(windowY, WINDOW_PADDING, screenHeight - Height - WINDOW_PADDING)
        window.Position = UDim2.new(0, windowX, 0, windowY)
        WindowManager.windowOffset = offset + 20
        WindowManager.windows[window] = true
    else
        window.Position = UDim2.new(0, WINDOW_PADDING, 0, WINDOW_PADDING)
        WindowManager.windows[window] = true
    end

    -- UI 添加圓角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window

    -- UI 創建標題欄 Frame
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = window
    titleBar.BackgroundColor3 = self.theme.background
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 30)

    -- UI 標題欄圓角
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar

    -- UI 創建標題文字 TextLabel
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = titleBar
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- UI 創建摺疊/展開按鈕 TextButton
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = titleBar
    toggleButton.BackgroundTransparency = 1
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = UDim2.new(1, -25, 0.5, -10)
    toggleButton.Text = "-"
    toggleButton.TextColor3 = self.theme.foreground
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 16

    local expanded = true
    local expandedSize = window.Size
    local collapsedSize = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, titleBar.Size.Y.Offset)

    toggleButton.MouseButton1Click:Connect(function()
        if expanded then
            expanded = false
            toggleButton.Text = "+"
            CreateTween(window, { Size = collapsedSize }, 0.3):Play()
        else
            expanded = true
            toggleButton.Text = "-"
            CreateTween(window, { Size = expandedSize }, 0.3):Play()
        end
    end)

    -- UI 創建內容捲動區域 ScrollingFrame
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Parent = window
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 30)
    content.Size = UDim2.new(1, 0, 1, -30)
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = self.theme.accent
    content.ScrollBarImageTransparency = 0.8
    content.CanvasSize = UDim2.new(0, 0, 0, 0)

    -- UI 創建列表佈局 UIListLayout 用於垂直排列內容
    local list = Instance.new("UIListLayout")
    list.Parent = content
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 4)

    -- UI 創建內邊距 UIPadding 讓內容與邊框間有間距
    local padding = Instance.new("UIPadding")
    padding.Parent = content
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
    end)

    if not fixed then
        local dragStart, startPos = nil, nil
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if not currentlyDraggedWindow then
                    currentlyDraggedWindow = window
                    dragStart = input.Position
                    startPos = window.Position
                    WindowManager:BringToFront(window)
                end
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if currentlyDraggedWindow == window and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if delta.Magnitude >= DRAG_THRESHOLD then
                    local newPos = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                    window.Position = newPos
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if currentlyDraggedWindow == window and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                currentlyDraggedWindow = nil
            end
        end)
    end

    return { Window = window, Content = content, Fixed = fixed }
end

-- 另行建立一個別名 TagWindow（與 CreateWindow 功能完全相同）
library.TagWindow = library.CreateWindow

------------------------------------------------
-- CreateItem(parent, name, options, callback) - 創建Item(按鈕)
function library:CreateItem(parent, name, options, callback)
    -- UI 創建 Frame 作為 Item 容器
    local item = Instance.new("Frame")
    item.Name = name
    item.Parent = parent
    item.BackgroundColor3 = self.theme.background
    item.BackgroundTransparency = 0.9
    item.Size = UDim2.new(1, 0, 0, 32)
    item.ClipsDescendants = true

    -- UI Item 圓角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = item

    -- UI 創建按鈕 TextButton
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Parent = item
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, -30, 0, 32)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Font = Enum.Font.Gotham
    button.Text = name
    button.TextColor3 = self.theme.foreground
    button.TextSize = 13
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false

    -- UI 按鈕文字內邊距
    local padding = Instance.new("UIPadding")
    padding.Parent = button
    padding.PaddingLeft = UDim.new(0, 10)

    local toggled = false

    local enabledBackgroundColor = Color3.fromRGB(255, 255, 255)
    local enabledTextColor = Color3.fromRGB(0, 0, 0)
    local disabledBackgroundColor = self.theme.background
    local disabledTextColor = self.theme.foreground
    local disabledBackgroundTransparency = 0.9

    -- UI 設定按鈕 (齒輪) ImageButton
    local settings = Instance.new("ImageButton")
    settings.Name = "Settings"
    settings.Parent = item
    settings.Visible = false
    settings.BackgroundTransparency = 1
    settings.AnchorPoint = Vector2.new(1, 0)
    settings.Position = UDim2.new(1, -24, 0, 8)
    settings.Size = UDim2.new(0, 16, 0, 16)
    settings.Image = "rbxassetid://3926307971"
    settings.ImageRectOffset = Vector2.new(324, 124)
    settings.ImageRectSize = Vector2.new(36, 36)
    settings.ImageColor3 = self.theme.foreground
    settings.ImageTransparency = 0.5
    local defaultGearColor = self.theme.foreground

    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(item, { BackgroundColor3 = enabledBackgroundColor, BackgroundTransparency = 0 }, 0.2):Play()
            CreateTween(button, { TextColor3 = enabledTextColor }, 0.2):Play()
            CreateTween(settings, { ImageColor3 = enabledTextColor }, 0.2):Play()
        else
            CreateTween(item,
                { BackgroundColor3 = disabledBackgroundColor, BackgroundTransparency = disabledBackgroundTransparency },
                0.2):Play()
            CreateTween(button, { TextColor3 = disabledTextColor }, 0.2):Play()
            CreateTween(settings, { ImageColor3 = defaultGearColor }, 0.2):Play()
        end
        callback(toggled)
    end)

    button.MouseEnter:Connect(function()
        if not toggled then
            CreateTween(item, { BackgroundTransparency = 0.8 }, 0.2):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if not toggled then
            CreateTween(item, { BackgroundTransparency = 0.9 }, 0.2):Play()
        end
    end)

    if options then
        local settingsExpanded = false

        settings.Visible = true;

        -- UI 設定區域 Frame，用於展開顯示設定項
        local settingsArea = Instance.new("Frame")
        settingsArea.Name = "SettingsArea_" .. item.Name
        settingsArea.Parent = parent
        settingsArea.BackgroundColor3 = self.theme.windowBackground
        settingsArea.BackgroundTransparency = 0.9
        settingsArea.BorderSizePixel = 1
        settingsArea.BorderColor3 = self.theme.background
        settingsArea.Position = UDim2.new(0, 0, 0, 44)
        settingsArea.Size = UDim2.new(1, 0, 0, 0)
        settingsArea.Visible = false
        settingsArea.ClipsDescendants = true
        settingsArea.ZIndex = 9

        -- UI 設定區域圓角
        local areaCorner = Instance.new("UICorner")
        areaCorner.CornerRadius = UDim.new(0, 4)
        areaCorner.Parent = settingsArea

        -- UI 設定面板 Frame，用於容納設定項
        local settingsPanel = Instance.new("Frame")
        settingsPanel.Name = "SettingsPanel"
        settingsPanel.Parent = settingsArea
        settingsPanel.BackgroundTransparency = 1
        settingsPanel.BorderSizePixel = 0
        settingsPanel.Size = UDim2.new(1, 0, 1, 0)
        settingsPanel.Position = UDim2.new(0, 0, 0, 0)

        -- UI 設定面板列表佈局 UIListLayout
        local panelList = Instance.new("UIListLayout")
        panelList.Parent = settingsPanel
        panelList.SortOrder = Enum.SortOrder.LayoutOrder
        panelList.Padding = UDim.new(0, 4)

        -- UI 設定面板內邊距 UIPadding
        local panelPadding = Instance.new("UIPadding")
        panelPadding.Parent = settingsPanel
        panelPadding.PaddingLeft = UDim.new(0, 8)
        panelPadding.PaddingRight = UDim.new(0, 8)
        panelPadding.PaddingTop = UDim.new(0, 8)
        panelPadding.PaddingBottom = UDim.new(0, 8)

        -- UI Item 底部內邊距，用於在展開設定時增加 Item 高度
        local itemPaddingBottom = Instance.new("UIPadding")
        itemPaddingBottom.Name = "ItemPaddingBottom"
        itemPaddingBottom.Parent = item
        itemPaddingBottom.PaddingBottom = UDim.new(0, 8)

        local function updateExpandedSize()
            local expandedPanelHeight = panelList.AbsoluteContentSize.Y + panelPadding.PaddingTop.Offset +
                panelPadding.PaddingBottom.Offset
            local newItemHeight = 32 + 12 + expandedPanelHeight
            return expandedPanelHeight, newItemHeight
        end

        settings.MouseButton1Click:Connect(function()
            if settingsExpanded then
                settingsExpanded = false
                local tween = CreateTween(settingsArea, { Size = UDim2.new(1, 0, 0, 0) }, 0.3)
                tween:Play()
                tween.Completed:Connect(function()
                    settingsArea.Visible = false
                end)
                CreateTween(item, { Size = UDim2.new(1, 0, 0, 32) }, 0.3):Play()
            else
                settingsExpanded = true
                settingsArea.Visible = true
                local expandedPanelHeight, newItemHeight = updateExpandedSize()
                CreateTween(settingsArea, { Size = UDim2.new(1, 0, 0, expandedPanelHeight) }, 0.3):Play()
                CreateTween(item, { Size = UDim2.new(1, 0, 0, 32) }, 0.3):Play()
            end
        end)

        panelList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if settingsExpanded then
                local expandedPanelHeight, newItemHeight = updateExpandedSize()
                CreateTween(settingsArea, { Size = UDim2.new(1, 0, 0, expandedPanelHeight) }, 0.3):Play()
                CreateTween(item, { Size = UDim2.new(1, 0, 0, 32) }, 0.3):Play()
            end
        end)
    end

    return item
end

------------------------------------------------
-- CreateSlider(item, name, min, max, default, callback) – 創建普通滑桿 callback(Value)
function library:CreateSlider(item, name, min, max, default, callback)
    local SettingsArea = item.Parent:FindFirstChild("SettingsArea_" .. item.Name)
    local parent = SettingsArea:FindFirstChild("SettingsPanel")

    -- UI 滑桿容器 Frame
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -10, 0, 25)

    -- UI 滑桿標題 TextLabel
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = slider
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- UI 滑桿軌道 Frame
    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Parent = slider
    sliderBar.BackgroundColor3 = self.theme.muted
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 0, 1, -5)
    sliderBar.Size = UDim2.new(1, 0, 0, 2)

    -- UI 滑桿按鈕 Frame
    local sliderButton = Instance.new("Frame")
    sliderButton.Name = "SliderButton"
    sliderButton.Parent = sliderBar
    sliderButton.BackgroundColor3 = self.theme.accent
    sliderButton.BorderSizePixel = 0
    sliderButton.Size = UDim2.new(0, 10, 0, 10)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -0.5, 0.5, 0)
    sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)

    -- UI 滑桿按鈕圓角
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = sliderButton

    -- UI 滑桿數值顯示 TextLabel
    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Parent = slider
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(1, -30, 0, 0)
    value.Size = UDim2.new(0, 30, 0, 20)
    value.Font = Enum.Font.Gotham
    value.Text = tostring(default)
    value.TextColor3 = self.theme.foreground
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right

    local dragging = false
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    sliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation()
            local relativePos = mousePos - sliderBar.AbsolutePosition
            local percentage = math.clamp(relativePos.X / sliderBar.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(min + (max - min) * percentage)
            sliderButton.Position = UDim2.new(percentage, -0.5, 0.5, 0)
            value.Text = tostring(newValue)
            if callback then callback(newValue) end
        end
    end)
end

------------------------------------------------
-- CreateRangeSlider(item, name, min, max, defaultMin, defaultMax, callback) – 創建範圍滑桿 callback(Min, Max)
function library:CreateRangeSlider(item, name, min, max, defaultMin, defaultMax, callback)
    local SettingsArea = item.Parent:FindFirstChild("SettingsArea_" .. item.Name)
    local parent = SettingsArea:FindFirstChild("SettingsPanel")

    -- UI 範圍滑桿容器 Frame
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -10, 0, 40)

    -- UI 範圍滑桿標題 TextLabel
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = slider
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- UI 範圍滑桿數值範圍顯示 TextLabel
    local rangeValueLabel = Instance.new("TextLabel")
    rangeValueLabel.Name = "RangeValue"
    rangeValueLabel.Parent = slider
    rangeValueLabel.BackgroundTransparency = 1
    rangeValueLabel.Position = UDim2.new(1, -60, 0, 0)
    rangeValueLabel.Size = UDim2.new(0, 60, 0, 20)
    rangeValueLabel.Font = Enum.Font.Gotham
    rangeValueLabel.Text = defaultMin .. "-" .. defaultMax
    rangeValueLabel.TextColor3 = self.theme.muted
    rangeValueLabel.TextSize = 12
    rangeValueLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- UI 範圍滑桿軌道 Frame
    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Parent = slider
    sliderBar.BackgroundColor3 = self.theme.muted
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 0, 1, -20)
    sliderBar.Size = UDim2.new(1, 0, 0, 2)

    -- UI 範圍滑桿最小值按鈕 Frame
    local minSliderButton = Instance.new("Frame")
    minSliderButton.Name = "MinSliderButton"
    minSliderButton.Parent = sliderBar
    minSliderButton.BackgroundColor3 = self.theme.accent
    minSliderButton.BorderSizePixel = 0
    minSliderButton.Size = UDim2.new(0, 10, 0, 10)
    minSliderButton.Position = UDim2.new((defaultMin - min) / (max - min), -0.5, 0.5, 0)
    minSliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
    -- UI 最小值按鈕圓角
    local minButtonCorner = Instance.new("UICorner")
    minButtonCorner.CornerRadius = UDim.new(0, 5)
    minButtonCorner.Parent = minSliderButton

    -- UI 範圍滑桿最大值按鈕 Frame
    local maxSliderButton = Instance.new("Frame")
    maxSliderButton.Name = "MaxSliderButton"
    maxSliderButton.Parent = sliderBar
    maxSliderButton.BackgroundColor3 = self.theme.accent
    maxSliderButton.BorderSizePixel = 0
    maxSliderButton.Size = UDim2.new(0, 10, 0, 10)
    maxSliderButton.Position = UDim2.new((defaultMax - min) / (max - min), -0.5, 0.5, 0)
    maxSliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
    -- UI 最大值按鈕圓角
    local maxButtonCorner = Instance.new("UICorner")
    maxButtonCorner.CornerRadius = UDim.new(0, 5)
    maxButtonCorner.Parent = maxSliderButton

    local draggingMin = false
    local draggingMax = false

    minSliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMin = true
        end
    end)

    maxSliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMax = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingMin = false
            draggingMax = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UserInputService:GetMouseLocation()
            local relativePos = mousePos - sliderBar.AbsolutePosition
            local percentage = math.clamp(relativePos.X / sliderBar.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(min + (max - min) * percentage)
            if draggingMin then
                local currentMax = tonumber(string.split(rangeValueLabel.Text, "-")[2])
                if newValue > currentMax then newValue = currentMax end
                minSliderButton.Position = UDim2.new(percentage, -0.5, 0.5, 0)
                rangeValueLabel.Text = tostring(newValue) .. "-" .. tostring(currentMax)
                if callback then callback(newValue, currentMax) end
            elseif draggingMax then
                local currentMin = tonumber(string.split(rangeValueLabel.Text, "-")[1])
                if newValue < currentMin then newValue = currentMin end
                maxSliderButton.Position = UDim2.new(percentage, -0.5, 0.5, 0)
                rangeValueLabel.Text = tostring(currentMin) .. "-" .. tostring(newValue)
                if callback then callback(currentMin, newValue) end
            end
        end
    end)
end

------------------------------------------------
-- CreateToggle(item, name, callback) – 創建Toggle callback(state)
function library:CreateToggle(item, name, callback)
    local SettingsArea = item.Parent:FindFirstChild("SettingsArea_" .. item.Name)
    local parent = SettingsArea:FindFirstChild("SettingsPanel")

    -- UI Toggle 容器 Frame
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Parent = parent
    toggle.BackgroundTransparency = 1
    toggle.Size = UDim2.new(1, -10, 0, 25)

    -- UI Toggle 標題 TextLabel
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = toggle
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- UI Toggle 按鈕 TextButton (背景)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = toggle
    toggleButton.BackgroundColor3 = self.theme.muted
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = UDim2.new(1, -25, 0.5, -10)
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Text = ""

    -- UI Toggle 按鈕圓角
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton

    -- UI Toggle 內部指示器 Frame
    local toggleInner = Instance.new("Frame")
    toggleInner.Name = "ToggleInner"
    toggleInner.Parent = toggleButton
    toggleInner.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleInner.BackgroundColor3 = self.theme.accent
    toggleInner.BorderSizePixel = 0
    toggleInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    toggleInner.Size = UDim2.new(0, 0, 0, 0)

    -- UI Toggle 內部指示器圓角
    local toggleInnerCorner = Instance.new("UICorner")
    toggleInnerCorner.CornerRadius = UDim.new(0, 4)
    toggleInnerCorner.Parent = toggleInner

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(toggleInner, { Size = UDim2.new(1, -4, 1, -4) }, 0.2):Play()
        else
            CreateTween(toggleInner, { Size = UDim2.new(0, 0, 0, 0) }, 0.2):Play()
        end
        if callback then callback(toggled) end
    end)
end

------------------------------------------------
-- CreateDropdown – 可傳入 callback(option)
function library:CreateDropdown(item, name, options, callback) -- 加入 labelText 參數
    local SettingsArea = item.Parent:FindFirstChild("SettingsArea_" .. item.Name)
    local parent = SettingsArea:FindFirstChild("SettingsPanel")

    -- UI 下拉選單容器 Frame
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 52) -- 初始高度要容納 label 和 dropdownButton
    container.ClipsDescendants = true

    -- UI 容器列表佈局 UIListLayout
    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    -- UI 下拉選單標籤 TextLabel
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "DropdownLabel"
    dropdownLabel.Parent = container
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Size = UDim2.new(1, 0, 0, 25) -- 設定高度
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.Text = name
    dropdownLabel.TextColor3 = self.theme.foreground
    dropdownLabel.TextSize = 12
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- UI 下拉選單標籤內邊距
    local labelPadding = Instance.new("UIPadding")
    labelPadding.Parent = dropdownLabel
    labelPadding.PaddingLeft = UDim.new(0, 5)


    -- UI 下拉選單按鈕 TextButton (顯示當前選項)
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Parent = container
    dropdownButton.BackgroundColor3 = self.theme.muted
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Size = UDim2.new(1, 0, 0, 25)
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Text = options[1]
    dropdownButton.TextColor3 = self.theme.foreground
    dropdownButton.TextSize = 12
    dropdownButton.TextXAlignment = Enum.TextXAlignment.Left

    -- UI 下拉選單按鈕文字內邊距
    local dropdownPadding = Instance.new("UIPadding")
    dropdownPadding.Parent = dropdownButton
    dropdownPadding.PaddingLeft = UDim.new(0, 5)

    -- UI 下拉選單按鈕圓角
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = dropdownButton

    -- UI 下拉選單列表 Frame (選項列表)
    local dropdownList = Instance.new("Frame")
    dropdownList.Name = "DropdownList"
    dropdownList.Parent = container
    dropdownList.BackgroundColor3 = self.theme.windowBackground
    dropdownList.BorderSizePixel = 0
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
    dropdownList.Visible = false

    -- UI 下拉選單列表佈局 UIListLayout (垂直排列選項)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = dropdownList
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, option in ipairs(options) do
        -- UI 選項按鈕 TextButton (每個選項)
        local optionButton = Instance.new("TextButton")
        optionButton.Name = option
        optionButton.Parent = dropdownList
        optionButton.BackgroundTransparency = 1
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.Font = Enum.Font.Gotham
        optionButton.Text = option
        optionButton.TextColor3 = self.theme.foreground
        optionButton.TextSize = 12
        optionButton.TextXAlignment = Enum.TextXAlignment.Left

        -- UI 選項按鈕文字內邊距
        local optionPadding = Instance.new("UIPadding")
        optionPadding.Parent = optionButton
        optionPadding.PaddingLeft = UDim.new(0, 5)

        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            dropdownList.Visible = false
            container.Size = UDim2.new(1, 0, 0, 52) -- 收起時 container 高度
            if callback then callback(option) end
        end)
    end

    dropdownButton.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        if dropdownList.Visible then
            container.Size = UDim2.new(1, 0, 0, 52 + (#options * 25) + 2) -- 展開時 container 高度，加上 label 的高度
        else
            container.Size = UDim2.new(1, 0, 0, 52)                       -- 收起時 container 高度
        end
    end)
end

------------------------------------------------
-- 當螢幕尺寸改變時，重新調整非固定視窗的位置
ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    WindowManager.windowOffset = 0
    for window, _ in pairs(WindowManager.windows) do
        if not window:IsDescendantOf(ScreenGui) then
            WindowManager.windows[window] = nil
        elseif not window:GetAttribute("Fixed") then
            local defaultWidth = window.Size.X.Offset
            local defaultHeight = window.Size.Y.Offset
            local offset = WindowManager.windowOffset
            local screenWidth, screenHeight = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
            local windowX = (screenWidth - defaultWidth) / 2 + offset
            local windowY = (screenHeight - defaultHeight) / 2 + offset
            windowX = math.clamp(windowX, WINDOW_PADDING, screenWidth - defaultWidth - WINDOW_PADDING)
            windowY = math.clamp(windowY, WINDOW_PADDING, screenHeight - defaultHeight - WINDOW_PADDING)
            window.Position = UDim2.new(0, windowX, 0, windowY)
            WindowManager.windowOffset = offset + 20
        end
    end
end)

------------------------------------------------
-- 建立預設 mainWindow – 用於顯示所有視窗的 toggle 項
library.mainWindow = library:CreateWindow("VAPA v3", true, 220, 300)
library.mainWindow.Window.Position = UDim2.new(0, 10, 0, 10)

function library:AddWindowToggle(windowInstance)
    local item = library:CreateItem(library.mainWindow.Content, windowInstance.Window.Name, false, function(state)
        windowInstance.Window.Visible = state
    end)
    return item
end

-------------------------------------------------

return library
