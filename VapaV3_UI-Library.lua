-- UILibrary ModuleScript
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
    }
}

-- Screen GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UILibraryGui"
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

local function CreateTween(instance, properties, duration)
    return TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
end

local WindowManager = {
    zIndex = 1,
    windows = {},
    windowOffset = 0
}

function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
end

-- 建立視窗，fixed 為 true 時視窗為固定（不可拖曳）
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

        -- 加入拖曳功能
        local dragging = false
        local dragStart, startPos
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

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                WindowManager:BringToFront(window)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if delta.Magnitude >= DRAG_THRESHOLD then
                    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    window.Position = newPos
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    else
        window.Position = UDim2.new(0, WINDOW_PADDING, 0, WINDOW_PADDING)
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window

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
-- 建立主視窗（唯一、固定）
function library:CreateMainWindow(name)
    if self.mainWindow then
        return self.mainWindow
    end
    self.mainWindow = self:CreateWindow(name or "Main", true)
    return self.mainWindow
end

------------------------------------------------
-- 建立 Tag 視窗，並自動在主視窗中產生同名 item，該 item 開關控制 Tag 視窗的顯示
function library:CreateTag(tagName)
    local tagWindow = self:CreateWindow(tagName, false)
    local mainWindow = self:CreateMainWindow("Main")
    self:CreateItem(mainWindow.Content, tagName, function(state)
        tagWindow.Window.Visible = state
    end)
    return tagWindow
end

------------------------------------------------
-- 建立 Item（不含預設選項），可傳入 callback(state)
function library:CreateItem(parent, name, callback)
    local item = Instance.new("Frame")
    item.Name = name
    item.Parent = parent
    item.BackgroundColor3 = self.theme.background
    item.BackgroundTransparency = 0.9
    item.Size = UDim2.new(1, 0, 0, 32)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = item

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = item
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    local padding = Instance.new("UIPadding")
    padding.Parent = title
    padding.PaddingLeft = UDim.new(0, 10)

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

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(toggleInner, {Size = UDim2.new(1, -4, 1, -4)}, 0.2):Play()
        else
            CreateTween(toggleInner, {Size = UDim2.new(0, 0, 0, 0)}, 0.2):Play()
        end
        if callback then
            callback(toggled)
        end
    end)

    return item
end

------------------------------------------------
-- 建立滑桿 (可註冊 callback(newValue))
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

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Parent = slider
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -30, 0, 0)
    valueLabel.Size = UDim2.new(0, 30, 0, 20)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = self.theme.foreground
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

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
            valueLabel.Text = tostring(newValue)
            if callback then
                callback(newValue)
            end
        end
    end)
end

------------------------------------------------
-- 建立勾選開關 (可註冊 callback(state))
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
        if callback then
            callback(toggled)
        end
    end)
end

------------------------------------------------
-- 建立下拉選單 (可註冊 callback(selectedOption))
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
    dropdownList.Size = UDim2.new(1, 0, 0, (#options)*25)
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
            if callback then
                callback(option)
            end
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

return library
