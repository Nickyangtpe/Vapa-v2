-- UILibrary ModuleScript
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- 全域變數：目前正在拖曳的視窗（避免多重拖曳）
local currentlyDraggedWindow = nil

-- 常數設定
local MOBILE = UserInputService.TouchEnabled
local WINDOW_PADDING = 10
local DRAG_THRESHOLD = 5

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
    mainWindow = nil  -- 後續用 CreateMainWindow 建立唯一的主視窗
}

-- 建立 ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VAPE"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if MOBILE then
    ScreenGui.IgnoreGuiInset = true
end
if RunService:IsStudio() then
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

-- 小工具：Tween 簡寫
local function CreateTween(instance, properties, duration)
    return TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad),
        properties
    )
end

-- 視窗管理器（負責 zIndex 與累積偏移）
local WindowManager = {
    activeWindow = nil,
    zIndex = 1,
    windows = {},
    windowOffset = 0 -- 避免非固定視窗重疊
}

function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
    self.activeWindow = window
end

------------------------------------------------
-- 建立一般視窗 (fixed 為 true 時代表固定，不能拖曳)
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
        -- 非固定視窗：以畫面中心為基準並依序加上偏移
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

    -- Title Bar
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

    -- 摺疊/展開按鈕（可選）：僅作視覺效果，實際內容區預設為展開
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

    -- Content 區 (用於放入各種控制項)
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

    -- 拖曳功能（僅限非固定視窗）
    if not fixed then
        local dragStart, startPos = nil, nil

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if currentlyDraggedWindow == nil then
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

------------------------------------------------
--【新增】建立唯一的 Main Window（固定，不可移動）
function library:CreateMainWindow(name)
    if self.mainWindow then
        return self.mainWindow
    end
    -- 固定視窗 (fixed = true)
    self.mainWindow = self:CreateWindow(name, true)
    return self.mainWindow
end

------------------------------------------------
--【新增】建立 Tag 視窗，同時在 Main Window 中新增對應的 Item，Item 的開關控制該 Tag 的顯示/隱藏
function library:AddTagWindow(tagName)
    if not self.mainWindow then
        error("請先呼叫 CreateMainWindow 建立主視窗！")
    end
    -- 建立 Tag 視窗（可拖曳）
    local tagWindow = self:CreateWindow(tagName, false)
    tagWindow.Window.Visible = true  -- 預設顯示
    -- 在 Main Window 中建立對應的 Item，並註冊 callback 控制 tagWindow 的顯示
    local tagItem = self:CreateItem(self.mainWindow.Content, tagName, {
        noSettings = true,
        callback = function(state)
            tagWindow.Window.Visible = state
        end
    })
    return tagWindow, tagItem
end

------------------------------------------------
-- 修改後的 CreateItem：建立一個 Item（預設不加入任何選項）
-- 可透過 options.callback 註冊點擊開關事件（傳入 state 參數）
function library:CreateItem(parent, name, options)
    options = options or {}
    -- 預設不自動建立選項面板
    if options.noSettings == nil then options.noSettings = true end

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
    button.Size = UDim2.new(1, -10, 0, 32)
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
    local callback = options.callback

    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            item.BackgroundColor3 = self.theme.background
            button.TextColor3 = self.theme.foreground
        end
        if callback then
            callback(toggled)
        end
    end)

    return item
end

------------------------------------------------
--【新增】在指定 Item 中加入選項控制項
-- 若 Item 尚未建立選項區，則先建立一個 SettingsPanel
function library:AddOptionToItem(item, optionType, ...)
    if not item.SettingsPanel then
        local settingsArea = Instance.new("Frame")
        settingsArea.Name = "SettingsArea"
        settingsArea.Parent = item
        settingsArea.BackgroundTransparency = 1
        settingsArea.Size = UDim2.new(1, 0, 0, 0)  -- 初始高度 0，可由外部自行調整或搭配 Tween 展開
        settingsArea.Visible = true

        local settingsPanel = Instance.new("Frame")
        settingsPanel.Name = "SettingsPanel"
        settingsPanel.Parent = settingsArea
        settingsPanel.BackgroundTransparency = 1
        settingsPanel.Size = UDim2.new(1, 0, 1, 0)
        item.SettingsArea = settingsArea
        item.SettingsPanel = settingsPanel
    end
    local settingsPanel = item.SettingsPanel

    if optionType == "slider" then
        return self:CreateSlider(settingsPanel, ...)
    elseif optionType == "rangeSlider" then
        return self:CreateRangeSlider(settingsPanel, ...)
    elseif optionType == "toggle" then
        return self:CreateToggle(settingsPanel, ...)
    elseif optionType == "dropdown" then
        return self:CreateDropdown(settingsPanel, ...)
    elseif optionType == "button" and self.CreateButton then
        return self:CreateButton(settingsPanel, ...)
    end
end

------------------------------------------------
-- 建立 Slider
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
end

------------------------------------------------
-- 建立 Range Slider
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
                if callback then callback(newValue, nil) end
            elseif draggingMax then
                local currentMin = tonumber(string.split(rangeValueLabel.Text, "-")[1])
                if newValue < currentMin then newValue = currentMin end
                maxSliderButton.Position = UDim2.new(percentage, -0.5, 0.5, 0)
                rangeValueLabel.Text = tostring(currentMin) .. "-" .. tostring(newValue)
                if callback then callback(nil, newValue) end
            end
        end
    end)
end

------------------------------------------------
-- 建立 Dropdown
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
    dropdownButton.Text = options[1] or ""
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
-- 監聽螢幕尺寸變化，重新調整非固定視窗位置
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

return library
