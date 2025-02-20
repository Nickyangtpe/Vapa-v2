-- UILibrary ModuleScript
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- 全域參數與主題設定
local MOBILE = UserInputService.TouchEnabled
local WINDOW_PADDING = 10
local DRAG_THRESHOLD = 5

local library = {
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
    tagWindows = {} -- 儲存各個 tag 的視窗
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

-- Tween 工具
local function CreateTween(instance, properties, duration)
    return TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
end

-- 窗口管理器（用於拖曳、層級管理）
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
-- (1) CreateWindow
-- 建立一個視窗（固定視窗 fixed 為 true 則不允許拖曳）
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
    
    -- 非固定視窗依照偏移置中
    if not fixed then
        local offset = WindowManager.windowOffset
        local screenWidth, screenHeight = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
        local windowX = math.clamp((screenWidth - defaultWidth) / 2 + offset, WINDOW_PADDING, screenWidth - defaultWidth - WINDOW_PADDING)
        local windowY = math.clamp((screenHeight - defaultHeight) / 2 + offset, WINDOW_PADDING, screenHeight - defaultHeight - WINDOW_PADDING)
        window.Position = UDim2.new(0, windowX, 0, windowY)
        WindowManager.windowOffset = offset + 20
        WindowManager.windows[window] = true
    else
        window.Position = UDim2.new(0, WINDOW_PADDING, 0, WINDOW_PADDING)
        WindowManager.windows[window] = true
    end

    -- 圓角效果
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = window

    -- TitleBar 與摺疊按鈕（保留原樣）
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = window
    titleBar.BackgroundColor3 = self.theme.background
    titleBar.BackgroundTransparency = 0.5
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1,0,0,30)
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = titleBar
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,10,0,0)
    title.Size = UDim2.new(1,-50,1,0)
    title.Font = Enum.Font.GothamBold
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = titleBar
    toggleButton.BackgroundTransparency = 1
    toggleButton.Size = UDim2.new(0,20,0,20)
    toggleButton.Position = UDim2.new(1,-25,0.5,-10)
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

    -- Content 區域
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Parent = window
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0,0,0,30)
    content.Size = UDim2.new(1,0,1,-30)
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = self.theme.accent
    content.ScrollBarImageTransparency = 0.8
    content.CanvasSize = UDim2.new(0,0,0,0)

    local list = Instance.new("UIListLayout")
    list.Parent = content
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0,4)

    local padding = Instance.new("UIPadding")
    padding.Parent = content
    padding.PaddingLeft = UDim.new(0,8)
    padding.PaddingRight = UDim.new(0,8)
    padding.PaddingTop = UDim.new(0,8)
    padding.PaddingBottom = UDim.new(0,8)

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y + 16)
    end)
    
    -- 若非固定視窗則加入拖曳功能
    if not fixed then
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragStart = input.Position
                startPos = window.Position
                WindowManager:BringToFront(window)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if delta.Magnitude >= DRAG_THRESHOLD then
                    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    window.Position = newPos
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = nil
            end
        end)
    end

    return {Window = window, Content = content, Fixed = fixed}
end

------------------------------------------------
-- (2) CreateItem
-- 建立一個 item，**不自動加入預設選項**，且可傳入 toggleCallback(state)
function library:CreateItem(parent, name, toggleCallback)
    local item = Instance.new("Frame")
    item.Name = name
    item.BackgroundColor3 = self.theme.background
    item.BackgroundTransparency = 0.9
    item.Size = UDim2.new(1,0,0,32)
    item.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,4)
    corner.Parent = item

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = item
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-30,1,0)
    title.Font = Enum.Font.Gotham
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = item
    toggleButton.BackgroundColor3 = self.theme.muted
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = UDim2.new(1,-25,0.5,-10)
    toggleButton.Size = UDim2.new(0,20,0,20)
    toggleButton.Text = ""
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0,4)
    toggleCorner.Parent = toggleButton

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            toggleButton.BackgroundColor3 = self.theme.accent
        else
            toggleButton.BackgroundColor3 = self.theme.muted
        end
        if toggleCallback then
            toggleCallback(toggled)
        end
    end)
    item.Parent = parent
    return item
end

------------------------------------------------
-- (3) CreateTagWindow
-- 當呼叫此函式時，會建立一個 tag 視窗（外觀同 CreateWindow），
-- 並自動在 mainWindow 中新增一個同名 item，其開關控制該 tag 視窗的顯示與隱藏
function library:CreateTagWindow(tagName, tagCallback)
    -- 建立 tag 視窗（可自由移動）
    local tagWindow = self:CreateWindow(tagName, false)
    self.tagWindows[tagName] = tagWindow

    -- 若尚未建立 mainWindow，建立一個固定、不可移動的主 tag 視窗
    if not self.mainWindow then
        self.mainWindow = self:CreateWindow("Main", true)
        -- 調整 mainWindow 位置（依需求自行設定）
        self.mainWindow.Window.Position = UDim2.new(0,50,0,50)
    end

    -- 自動在 mainWindow 內加入一個 item
    self:CreateItem(self.mainWindow.Content, tagName, function(state)
        tagWindow.Window.Visible = state
        if tagCallback then
            tagCallback(state)
        end
    end)

    return tagWindow
end

------------------------------------------------
-- (4) CreateSlider（可傳入 sliderCallback）
function library:CreateSlider(parent, name, min, max, default, sliderCallback)
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1,-10,0,25)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = slider
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,0,0,20)
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
    sliderBar.Position = UDim2.new(0,0,1,-5)
    sliderBar.Size = UDim2.new(1,0,0,2)

    local sliderButton = Instance.new("Frame")
    sliderButton.Name = "SliderButton"
    sliderButton.Parent = sliderBar
    sliderButton.BackgroundColor3 = self.theme.accent
    sliderButton.BorderSizePixel = 0
    sliderButton.Size = UDim2.new(0,10,0,10)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -0.5, 0.5, 0)
    sliderButton.AnchorPoint = Vector2.new(0.5,0.5)
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0,5)
    buttonCorner.Parent = sliderButton

    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Parent = slider
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(1,-30,0,0)
    value.Size = UDim2.new(0,30,0,20)
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
            if sliderCallback then
                sliderCallback(newValue)
            end
        end
    end)
end

------------------------------------------------
-- (5) CreateToggle, CreateDropdown, CreateRangeSlider
-- 這些函式原理同上，均新增了可選 callback 參數（此處略，請依照 CreateSlider 修改即可）

-- 例如 CreateToggle:
function library:CreateToggle(parent, name, toggleCallback)
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Parent = parent
    toggle.BackgroundTransparency = 1
    toggle.Size = UDim2.new(1,-10,0,25)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = toggle
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-30,1,0)
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
    toggleButton.Position = UDim2.new(1,-25,0.5,-10)
    toggleButton.Size = UDim2.new(0,20,0,20)
    toggleButton.Text = ""
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0,4)
    toggleCorner.Parent = toggleButton

    local toggleInner = Instance.new("Frame")
    toggleInner.Name = "ToggleInner"
    toggleInner.Parent = toggleButton
    toggleInner.AnchorPoint = Vector2.new(0.5,0.5)
    toggleInner.BackgroundColor3 = self.theme.accent
    toggleInner.BorderSizePixel = 0
    toggleInner.Position = UDim2.new(0.5,0,0.5,0)
    toggleInner.Size = UDim2.new(0,0,0,0)
    local toggleInnerCorner = Instance.new("UICorner")
    toggleInnerCorner.CornerRadius = UDim.new(0,4)
    toggleInnerCorner.Parent = toggleInner

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            CreateTween(toggleInner, {Size = UDim2.new(1,-4,1,-4)}, 0.2):Play()
        else
            CreateTween(toggleInner, {Size = UDim2.new(0,0,0,0)}, 0.2):Play()
        end
        if toggleCallback then
            toggleCallback(toggled)
        end
    end)
end

------------------------------------------------
return library
