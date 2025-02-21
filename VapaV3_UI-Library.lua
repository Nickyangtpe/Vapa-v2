-- UILibrary 腳本
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local library = {}
library.theme = {
    background = Color3.fromRGB(25, 25, 25),
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
-- CreateWindow (或 TagWindow) – 與原版一致
function library:CreateWindow(name, fixed)
    local window = Instance.new("Frame")
    window.Name = name
    window.Parent = ScreenGui
    window.BackgroundColor3 = self.theme.windowBackground
    window.BackgroundTransparency = 0.1
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.ZIndex = WindowManager.zIndex
    WindowManager.zIndex = WindowManager.zIndex + 1

    local defaultWidth = 220
    local defaultHeight = 300
    window.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)

    if not fixed then
        local offset = WindowManager.windowOffset
        local screenWidth, screenHeight = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
        local windowX = (screenWidth - defaultWidth) / 2 + offset
        local windowY = (screenHeight - defaultHeight) / 2 + offset
        windowX = math.clamp(windowX, WINDOW_PADDING, screenWidth - defaultWidth - WINDOW_PADDING)
        windowY = math.clamp(windowY, WINDOW_PADDING, screenHeight - defaultHeight - WINDOW_PADDING)
        window.Position = UDim2.new(0, windowX, 0, windowY)
        WindowManager.windowOffset = offset + 20
        WindowManager.windows[window] = true
    else
        window.Position = UDim2.new(0, WINDOW_PADDING, 0, WINDOW_PADDING)
        WindowManager.windows[window] = true
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = window
    titleBar.BackgroundColor3 = self.theme.background
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 30)

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar

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
            CreateTween(window, {Size = collapsedSize}, 0.3):Play()
        else
            expanded = true
            toggleButton.Text = "-"
            CreateTween(window, {Size = expandedSize}, 0.3):Play()
        end
    end)

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

    local list = Instance.new("UIListLayout")
    list.Parent = content
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 4)

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
-- CreateItem – 此函式只建立一個按鈕項目，不會自動產生預設選項
function library:CreateItem(parent, name, callback)
    local item = Instance.new("Frame")
    item.Name = name
    item.Parent = parent
    item.BackgroundColor3 = self.theme.background
    item.BackgroundTransparency = 0.9
    item.Size = UDim2.new(1, 0, 0, 32)
    item.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = item

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

    local padding = Instance.new("UIPadding")
    padding.Parent = button
    padding.PaddingLeft = UDim.new(0, 10)

    local toggled = false
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(item, {BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0}, 0.2):Play()
            CreateTween(button, {TextColor3 = Color3.fromRGB(0,0,0)}, 0.2):Play()
        else
            CreateTween(item, {BackgroundColor3 = self.theme.background, BackgroundTransparency = 0.9}, 0.2):Play()
            CreateTween(button, {TextColor3 = self.theme.foreground}, 0.2):Play()
        end
        if callback then
            callback(toggled)
        end
    end)
    return item
end

------------------------------------------------
-- 可呼叫此函式為 item 附加一個「選項容器」，供你自行添加各類控制項
function library:AttachSettings(item)
    if not item:FindFirstChild("SettingsContainer") then
        local container = Instance.new("Frame")
        container.Name = "SettingsContainer"
        container.Parent = item
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 0, 0)  -- 初始隱藏，可根據內容自動延展
        local layout = Instance.new("UIListLayout", container)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        return container
    end
    return item.SettingsContainer
end

------------------------------------------------
-- CreateSlider – 現在可傳入 callback(value)
function library:CreateSlider(parent, name, min, max, default, callback)
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -10, 0, 25)

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

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Parent = slider
    sliderBar.BackgroundColor3 = self.theme.muted
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 0, 1, -5)
    sliderBar.Size = UDim2.new(1, 0, 0, 2)

    local sliderButton = Instance.new("Frame")
    sliderButton.Name = "SliderButton"
    sliderButton.Parent = sliderBar
    sliderButton.BackgroundColor3 = self.theme.accent
    sliderButton.BorderSizePixel = 0
    sliderButton.Size = UDim2.new(0, 10, 0, 10)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -0.5, 0.5, 0)
    sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = sliderButton

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
-- CreateRangeSlider – 可傳入 callback(minValue, maxValue)
function library:CreateRangeSlider(parent, name, min, max, defaultMin, defaultMax, callback)
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -10, 0, 40)

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

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Parent = slider
    sliderBar.BackgroundColor3 = self.theme.muted
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 0, 1, -20)
    sliderBar.Size = UDim2.new(1, 0, 0, 2)

    local minSliderButton = Instance.new("Frame")
    minSliderButton.Name = "MinSliderButton"
    minSliderButton.Parent = sliderBar
    minSliderButton.BackgroundColor3 = self.theme.accent
    minSliderButton.BorderSizePixel = 0
    minSliderButton.Size = UDim2.new(0, 10, 0, 10)
    minSliderButton.Position = UDim2.new((defaultMin - min) / (max - min), -0.5, 0.5, 0)
    minSliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
    local minButtonCorner = Instance.new("UICorner")
    minButtonCorner.CornerRadius = UDim.new(0, 5)
    minButtonCorner.Parent = minSliderButton

    local maxSliderButton = Instance.new("Frame")
    maxSliderButton.Name = "MaxSliderButton"
    maxSliderButton.Parent = sliderBar
    maxSliderButton.BackgroundColor3 = self.theme.accent
    maxSliderButton.BorderSizePixel = 0
    maxSliderButton.Size = UDim2.new(0, 10, 0, 10)
    maxSliderButton.Position = UDim2.new((defaultMax - min) / (max - min), -0.5, 0.5, 0)
    maxSliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
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
-- CreateToggle – 可傳入 callback(state)
function library:CreateToggle(parent, name, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Parent = parent
    toggle.BackgroundTransparency = 1
    toggle.Size = UDim2.new(1, -10, 0, 25)

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

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = toggle
    toggleButton.BackgroundColor3 = self.theme.muted
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = UDim2.new(1, -25, 0.5, -10)
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Text = ""

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton

    local toggleInner = Instance.new("Frame")
    toggleInner.Name = "ToggleInner"
    toggleInner.Parent = toggleButton
    toggleInner.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleInner.BackgroundColor3 = self.theme.accent
    toggleInner.BorderSizePixel = 0
    toggleInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    toggleInner.Size = UDim2.new(0, 0, 0, 0)

    local toggleInnerCorner = Instance.new("UICorner")
    toggleInnerCorner.CornerRadius = UDim.new(0, 4)
    toggleInnerCorner.Parent = toggleInner

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(toggleInner, {Size = UDim2.new(1, -4, 1, -4)}, 0.2):Play()
        else
            CreateTween(toggleInner, {Size = UDim2.new(0, 0, 0, 0)}, 0.2):Play()
        end
        if callback then callback(toggled) end
    end)
end

------------------------------------------------
-- CreateDropdown – 可傳入 callback(option)
function library:CreateDropdown(parent, name, options, callback)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 25)
    container.ClipsDescendants = true

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

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

    local dropdownPadding = Instance.new("UIPadding")
    dropdownPadding.Parent = dropdownButton
    dropdownPadding.PaddingLeft = UDim.new(0, 5)

    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = dropdownButton

    local dropdownList = Instance.new("Frame")
    dropdownList.Name = "DropdownList"
    dropdownList.Parent = container
    dropdownList.BackgroundColor3 = self.theme.windowBackground
    dropdownList.BorderSizePixel = 0
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
    dropdownList.Visible = false

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = dropdownList
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, option in ipairs(options) do
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

        local optionPadding = Instance.new("UIPadding")
        optionPadding.Parent = optionButton
        optionPadding.PaddingLeft = UDim.new(0, 5)

        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            dropdownList.Visible = false
            container.Size = UDim2.new(1, 0, 0, 25)
            if callback then callback(option) end
        end)
    end

    dropdownButton.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        if dropdownList.Visible then
            container.Size = UDim2.new(1, 0, 0, 25 + (#options * 25) + 2)
        else
            container.Size = UDim2.new(1, 0, 0, 25)
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
        elseif not window.Fixed then
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
library.mainWindow = library:CreateWindow("Main", true)
library.mainWindow.Window.Position = UDim2.new(0, 10, 0, 10)

-- 將一個視窗的開關項加入 mainWindow，點選後可切換對應視窗的顯示與隱藏
function library:AddWindowToggle(windowInstance)
    local item = library:CreateItem(library.mainWindow.Content, windowInstance.Window.Name, function(state)
        windowInstance.Window.Visible = state
    end)
    return item
end

------------------------------------------------
_G.UILibrary = library
return library
