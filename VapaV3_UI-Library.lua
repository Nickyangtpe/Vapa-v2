-- UILibrary ModuleScript (更新版)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local library = {
    windows = {},
    theme = {
        background = Color3.fromRGB(25, 25, 25),
        windowBackground = Color3.fromRGB(30, 30, 30),
        foreground = Color3.fromRGB(255, 255, 255),
        muted = Color3.fromRGB(175, 175, 175),
        accent = Color3.fromRGB(0, 170, 255),
        success = Color3.fromRGB(0, 255, 0),
        warning = Color3.fromRGB(255, 255, 0),
        error = Color3.fromRGB(255, 0, 0)
    },
    mainWindow = nil,   -- 唯一的主視窗
    tagItems = {}       -- 用來記錄 tag 與對應 item 的對照表
}

-- 建立 ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VAPE"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if RunService:IsStudio() then
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

-- Tween 工具
local function CreateTween(instance, properties, duration)
    return TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
end

-- Window Manager（處理 zIndex 與偏移）
local WindowManager = {
    activeWindow = nil,
    zIndex = 1,
    windows = {},
    windowOffset = 0
}
function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
    self.activeWindow = window
end

------------------------------------------------
-- 建立視窗 (fixed 為 true 時表示不可移動，例如 mainWindow)
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
        local windowX = math.clamp((screenWidth - defaultWidth) / 2 + offset, 10, screenWidth - defaultWidth - 10)
        local windowY = math.clamp((screenHeight - defaultHeight) / 2 + offset, 10, screenHeight - defaultHeight - 10)
        window.Position = UDim2.new(0, windowX, 0, windowY)
        WindowManager.windowOffset = offset + 20
        WindowManager.windows[window] = true
    else
        window.Position = UDim2.new(0, 10, 0, 10)
        WindowManager.windows[window] = true
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window

    -- 標題列
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = window
    titleBar.BackgroundColor3 = self.theme.background
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 30)

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

    -- 若非固定視窗則可拖曳（mainWindow 固定，不可拖曳）
    if not fixed then
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = input.Position
                startPos = window.Position
                WindowManager:BringToFront(window)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if dragStart and startPos then
                    local delta = input.Position - dragStart
                    if delta.Magnitude > 5 then
                        window.Position = UDim2.new(
                            startPos.X.Scale, startPos.X.Offset + delta.X,
                            startPos.Y.Scale, startPos.Y.Offset + delta.Y
                        )
                    end
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = nil
                startPos = nil
            end
        end)
    end

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

    return {Window = window, Content = content, Fixed = fixed}
end

------------------------------------------------
-- 建立主視窗 (mainWindow，固定不可移動)
function library:CreateMainWindow(name)
    local mainWin = self:CreateWindow(name, true)
    self.mainWindow = mainWin
    return mainWin
end

------------------------------------------------
-- 建立 Tag 視窗，並自動在 mainWindow 中新增同名 item，其開關控制該視窗的顯示與隱藏
function library:CreateTagWindow(tagName)
    local tagWin = self:CreateWindow(tagName, false)
    if self.mainWindow then
        local tagItem = self:CreateItem(self.mainWindow.Content, tagName, function(state)
            tagWin.Window.Visible = state
        end)
        self.tagItems[tagName] = {tagWindow = tagWin, item = tagItem}
    else
        warn("請先建立主視窗 (mainWindow)！")
    end
    return tagWin
end

------------------------------------------------
-- 建立 item（僅建立基本 UI，不附帶預設選項），並可註冊 toggle 事件 (onToggle(state))
function library:CreateItem(parent, name, onToggle)
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
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = item
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

    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(toggleInner, {Size = UDim2.new(1, -4, 1, -4)}, 0.2):Play()
        else
            CreateTween(toggleInner, {Size = UDim2.new(0, 0, 0, 0)}, 0.2):Play()
        end
        if onToggle then
            onToggle(toggled)
        end
    end)

    return item
end

------------------------------------------------
-- 可將選項 (例如滑桿、勾選、下拉選單、範圍滑桿) 加入到指定 item 中，
-- 並可傳入 callback 當該控制項改變時執行 (callback 傳入新值)
function library:AddOptionToItem(item, optionType, params, callback)
    local optionControl
    if optionType == "slider" then
        optionControl = self:CreateSlider(item, params.name, params.min, params.max, params.default, callback)
    elseif optionType == "rangeSlider" then
        optionControl = self:CreateRangeSlider(item, params.name, params.min, params.max, params.defaultMin, params.defaultMax, callback)
    elseif optionType == "toggle" then
        optionControl = self:CreateToggle(item, params.name, callback)
    elseif optionType == "dropdown" then
        optionControl = self:CreateDropdown(item, params.name, params.options, callback)
    else
        warn("未知的選項類型：" .. tostring(optionType))
    end
    return optionControl
end

------------------------------------------------
-- Modified CreateSlider (支援 callback)
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
            if callback then
                callback(newValue)
            end
        end
    end)
    return slider
end

------------------------------------------------
-- Modified CreateRangeSlider (支援 callback)
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
    return slider
end

------------------------------------------------
-- Modified CreateToggle (支援 callback)
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
    return toggle
end

------------------------------------------------
-- Modified CreateDropdown (支援 callback)
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

    return container
end

------------------------------------------------
return library
