-- UILibrary ModuleScript (修改版)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local library = {
    windows = {},
    theme = {
        background = Color3.fromRGB(25,25,25),
        windowBackground = Color3.fromRGB(30,30,30),
        foreground = Color3.fromRGB(255,255,255),
        muted = Color3.fromRGB(175,175,175),
        accent = Color3.fromRGB(0,170,255),
        success = Color3.fromRGB(0,255,0),
        warning = Color3.fromRGB(255,255,0),
        error = Color3.fromRGB(255,0,0)
    },
    mainWindow = nil
}

local MOBILE = UserInputService.TouchEnabled
local WINDOW_PADDING = 10
local DRAG_THRESHOLD = 5

-- 建立 ScreenGui
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

-- 用來管理拖曳視窗
local WindowManager = {
    zIndex = 1,
    windows = {},
    windowOffset = 0
}
function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
end

------------------------------------------------
-- 基本視窗建立 (fixed 為 true 時視窗不可移動)
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

    local defaultWidth, defaultHeight = 220, 300
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
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window

    -- 標題列 (如果視窗可移動，則可拖曳)
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

    -- 摺疊/展開按鈕 (保持範例)
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

    -- 內容區
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

    local list = Instance.new("UIListLayout", content)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 4)

    local padding = Instance.new("UIPadding", content)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
    end)

    -- 若視窗可移動，則加入拖曳邏輯
    if not fixed then
        local currentlyDraggedWindow = nil
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
                    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

    return {Window = window, Content = content, Fixed = fixed}
end

------------------------------------------------
-- 建立主視窗（mainWindow），全局只會有一個，且固定不可移動
function library:CreateMainWindow(name)
    if self.mainWindow then return self.mainWindow end
    self.mainWindow = self:CreateWindow(name or "Main", true)
    self.mainWindow.Window.Name = "mainWindow"
    return self.mainWindow
end

------------------------------------------------
-- 建立 Tag 視窗  
-- 當呼叫此函式時，會建立一個固定的 Tag 視窗（預設隱藏），
-- 並自動在 mainWindow 裡新增一個同名的 item，其開關控制該 Tag 視窗的顯示
function library:CreateTagWindow(name)
    local tagWindow = self:CreateWindow(name, true)
    tagWindow.Window.Visible = false
    local mainWin = self.mainWindow or self:CreateMainWindow("Main")
    local tagItem = self:CreateItem(mainWin.Content, name, { 
        onToggle = function(state)
            tagWindow.Window.Visible = state
            if tagWindow.ToggleEvent then
                tagWindow.ToggleEvent(state)
            end
        end 
    })
    tagWindow.associatedItem = tagItem
    return tagWindow
end

------------------------------------------------
-- 建立 Item (不會自動添加預設選項)
-- options 可傳入 onToggle 來註冊開關事件
function library:CreateItem(parent, name, options)
    options = options or {}
    local item = Instance.new("Frame")
    item.Name = name
    item.Parent = parent
    item.BackgroundColor3 = self.theme.background
    item.BackgroundTransparency = 0.9
    item.Size = UDim2.new(1, 0, 0, 32)
    item.ClipsDescendants = true

    local corner = Instance.new("UICorner", item)
    corner.CornerRadius = UDim.new(0, 4)

    local button = Instance.new("TextButton", item)
    button.Name = "Button"
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, -30, 0, 32)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Font = Enum.Font.Gotham
    button.Text = name
    button.TextColor3 = self.theme.foreground
    button.TextSize = 13
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    local padding = Instance.new("UIPadding", button)
    padding.PaddingLeft = UDim.new(0, 10)

    local toggled = false
    local toggleButton = Instance.new("TextButton", item)
    toggleButton.Name = "ToggleButton"
    toggleButton.BackgroundTransparency = 1
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = UDim2.new(1, -25, 0.5, -10)
    toggleButton.Text = ""
    if options.onToggle then
        toggleButton.MouseButton1Click:Connect(function()
            toggled = not toggled
            options.onToggle(toggled)
        end)
    end

    return item
end

------------------------------------------------
-- 建立 Toggle 控制項，並可註冊 callback(state)
function library:CreateToggle(parent, name, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Parent = parent
    toggle.BackgroundTransparency = 1
    toggle.Size = UDim2.new(1, -10, 0, 25)

    local title = Instance.new("TextLabel", toggle)
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton", toggle)
    toggleButton.Name = "ToggleButton"
    toggleButton.BackgroundColor3 = self.theme.muted
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = UDim2.new(1, -25, 0.5, -10)
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Text = ""

    local toggleCorner = Instance.new("UICorner", toggleButton)
    toggleCorner.CornerRadius = UDim.new(0, 4)

    local toggleInner = Instance.new("Frame", toggleButton)
    toggleInner.Name = "ToggleInner"
    toggleInner.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleInner.BackgroundColor3 = self.theme.accent
    toggleInner.BorderSizePixel = 0
    toggleInner.Position = UDim2.new(0.5, 0, 0.5, 0)
    toggleInner.Size = UDim2.new(0, 0, 0, 0)

    local toggleInnerCorner = Instance.new("UICorner", toggleInner)
    toggleInnerCorner.CornerRadius = UDim.new(0, 4)

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
-- 建立 Slider 控制項 (可註冊 callback(newValue))
function library:CreateSlider(parent, name, min, max, default, callback)
    local slider = Instance.new("Frame", parent)
    slider.Name = name
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -10, 0, 25)

    local title = Instance.new("TextLabel", slider)
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBar = Instance.new("Frame", slider)
    sliderBar.Name = "SliderBar"
    sliderBar.BackgroundColor3 = self.theme.muted
    sliderBar.BorderSizePixel = 0
    sliderBar.Position = UDim2.new(0, 0, 1, -5)
    sliderBar.Size = UDim2.new(1, 0, 0, 2)

    local sliderButton = Instance.new("Frame", sliderBar)
    sliderButton.Name = "SliderButton"
    sliderButton.BackgroundColor3 = self.theme.accent
    sliderButton.BorderSizePixel = 0
    sliderButton.Size = UDim2.new(0, 10, 0, 10)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -0.5, 0.5, 0)
    sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)

    local buttonCorner = Instance.new("UICorner", sliderButton)
    buttonCorner.CornerRadius = UDim.new(0, 5)

    local value = Instance.new("TextLabel", slider)
    value.Name = "Value"
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
-- 建立 Dropdown 控制項 (可註冊 callback(selectedOption))
function library:CreateDropdown(parent, name, options, callback)
    local container = Instance.new("Frame", parent)
    container.Name = name .. "Container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 25)
    container.ClipsDescendants = true

    local layout = Instance.new("UIListLayout", container)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    local dropdownButton = Instance.new("TextButton", container)
    dropdownButton.Name = "DropdownButton"
    dropdownButton.BackgroundColor3 = self.theme.muted
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Size = UDim2.new(1, 0, 0, 25)
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Text = options[1] or ""
    dropdownButton.TextColor3 = self.theme.foreground
    dropdownButton.TextSize = 12
    dropdownButton.TextXAlignment = Enum.TextXAlignment.Left

    local dropdownPadding = Instance.new("UIPadding", dropdownButton)
    dropdownPadding.PaddingLeft = UDim.new(0, 5)

    local dropdownCorner = Instance.new("UICorner", dropdownButton)
    dropdownCorner.CornerRadius = UDim.new(0, 4)

    local dropdownList = Instance.new("Frame", container)
    dropdownList.Name = "DropdownList"
    dropdownList.BackgroundColor3 = self.theme.windowBackground
    dropdownList.BorderSizePixel = 0
    dropdownList.Size = UDim2.new(1, 0, 0, (#options * 25))
    dropdownList.Visible = false

    local listLayout = Instance.new("UIListLayout", dropdownList)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton", dropdownList)
        optionButton.Name = option
        optionButton.BackgroundTransparency = 1
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.Font = Enum.Font.Gotham
        optionButton.Text = option
        optionButton.TextColor3 = self.theme.foreground
        optionButton.TextSize = 12
        optionButton.TextXAlignment = Enum.TextXAlignment.Left

        local optionPadding = Instance.new("UIPadding", optionButton)
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
-- AddOption: 在某個 item 內加入選項 (例如 "toggle", "slider", "dropdown")
-- params 內包含該控制項所需的參數；callback 為狀態改變時的函式
function library:AddOption(item, optionType, name, params, callback)
    local settingsArea = item:FindFirstChild("SettingsArea")
    if not settingsArea then
        settingsArea = Instance.new("Frame", item)
        settingsArea.Name = "SettingsArea"
        settingsArea.BackgroundTransparency = 1
        settingsArea.Size = UDim2.new(1, 0, 0, 0)
        local list = Instance.new("UIListLayout", settingsArea)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 4)
    end
    if optionType == "toggle" then
        return self:CreateToggle(settingsArea, name, callback)
    elseif optionType == "slider" then
        return self:CreateSlider(settingsArea, name, params.min, params.max, params.default, callback)
    elseif optionType == "dropdown" then
        return self:CreateDropdown(settingsArea, name, params.options, callback)
    end
end

return library
