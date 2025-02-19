-- UILibrary ModuleScript

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local library = {}
library.theme = {
    background = Color3.fromRGB(25,25,25),
    windowBackground = Color3.fromRGB(30,30,30),
    foreground = Color3.fromRGB(255,255,255),
    muted = Color3.fromRGB(175,175,175),
    accent = Color3.fromRGB(0,170,255),
    success = Color3.fromRGB(0,255,0),
    warning = Color3.fromRGB(255,255,0),
    error = Color3.fromRGB(255,0,0)
}
library.windows = {}       -- 一般視窗
library.tagWindows = {}    -- 各個 tag 視窗
library.mainWindow = nil   -- 唯一的 tag 主視窗

-- 建立 ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UILibraryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if RunService:IsStudio() then
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

local WINDOW_PADDING = 10

local function CreateTween(instance, properties, duration)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), properties)
    return tween
end

local WindowManager = {
    zIndex = 1,
    windows = {}
}

function WindowManager:BringToFront(window)
    self.zIndex = self.zIndex + 1
    window.ZIndex = self.zIndex
end

--------------------------------------------------
-- 1. 建立視窗 (可指定是否可移動)
-- movable 預設為 true，一般視窗可移動；若為 false 則不可移動（例如 mainWindow）
function library:CreateWindow(name, movable)
    movable = movable == nil and true or movable
    local window = Instance.new("Frame")
    window.Name = name
    window.Parent = ScreenGui
    window.BackgroundColor3 = self.theme.windowBackground
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Size = UDim2.new(0, 220, 0, 300)
    window.Position = UDim2.new(0, WINDOW_PADDING, 0, WINDOW_PADDING)
    window.ZIndex = WindowManager.zIndex
    WindowManager.zIndex = WindowManager.zIndex + 1
    window.Active = movable  -- 若可移動，則設為 Active

    if movable then
        -- 加入可拖曳的標題列
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Parent = window
        titleBar.BackgroundColor3 = self.theme.background
        titleBar.Size = UDim2.new(1,0,0,30)
        titleBar.Active = true
        
        local title = Instance.new("TextLabel")
        title.Parent = titleBar
        title.Text = name
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -40, 1, 0)
        title.TextColor3 = self.theme.foreground
        title.Font = Enum.Font.Gotham
        
        local closeButton = Instance.new("TextButton")
        closeButton.Parent = titleBar
        closeButton.Text = "X"
        closeButton.Size = UDim2.new(0,30,0,30)
        closeButton.Position = UDim2.new(1, -30, 0, 0)
        closeButton.TextColor3 = self.theme.error
        closeButton.BackgroundTransparency = 1
        closeButton.MouseButton1Click:Connect(function()
            window:Destroy()
        end)
        
        local dragging = false
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                WindowManager:BringToFront(window)
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    else
        -- 不可移動的視窗（例如 mainWindow），僅顯示標題列
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Parent = window
        titleBar.BackgroundColor3 = self.theme.background
        titleBar.Size = UDim2.new(1,0,0,30)
        local title = Instance.new("TextLabel")
        title.Parent = titleBar
        title.Text = name
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, 0, 1, 0)
        title.TextColor3 = self.theme.foreground
        title.Font = Enum.Font.Gotham
    end

    -- 內容容器 (後續放入 item)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Parent = window
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0,0,0,30)
    content.Size = UDim2.new(1,0,1,-30)
    content.ScrollBarThickness = 4
    content.CanvasSize = UDim2.new(0,0,0,0)
    local list = Instance.new("UIListLayout", content)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0,4)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y)
    end)
    
    self.windows[name] = window
    return {Window = window, Content = content}
end

--------------------------------------------------
-- 2. 建立 Item (不自動加入預設選項)
-- 此 item 會包含標題與一顆 toggle 按鈕，方便用來做 tag 控制等用途
function library:CreateItem(parent, name)
    local item = Instance.new("Frame")
    item.Name = name
    item.Parent = parent
    item.BackgroundColor3 = self.theme.background
    item.Size = UDim2.new(1,0,0,30)
    item.ClipsDescendants = true
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = item
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Text = name
    title.TextColor3 = self.theme.foreground
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.Gotham
    title.TextSize = 14

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = item
    toggleButton.Size = UDim2.new(0,30,0,30)
    toggleButton.Position = UDim2.new(1, -30, 0, 0)
    toggleButton.BackgroundColor3 = self.theme.muted
    toggleButton.Text = "Off"
    toggleButton.TextColor3 = self.theme.foreground
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 14
    item.ToggleButton = toggleButton

    -- 建立一個空的設定區 (供後續加入選項)
    local settingsArea = Instance.new("Frame")
    settingsArea.Name = "SettingsArea"
    settingsArea.Parent = item
    settingsArea.BackgroundTransparency = 1
    settingsArea.Size = UDim2.new(1,0,0,0)
    settingsArea.Visible = false
    item.SettingsArea = settingsArea

    -- 若需要手動顯示設定項，可呼叫 item:ToggleSettings()
    function item:ToggleSettings()
        settingsArea.Visible = not settingsArea.Visible
    end

    return item
end

--------------------------------------------------
-- 3. 在指定的 item 裡新增選項 (選項型態： "toggle", "slider", "dropdown", "button")
-- parameters 可傳入預設值、數值範圍或選項列表
-- callback 為事件函式，對於 toggle 會回傳狀態 (state)
function library:AddOption(item, optionType, optionName, parameters, callback)
    local parent = item.SettingsArea
    local option
    if optionType == "toggle" then
        option = Instance.new("Frame")
        option.Name = optionName
        option.Parent = parent
        option.BackgroundTransparency = 1
        option.Size = UDim2.new(1,0,0,30)

        local label = Instance.new("TextLabel")
        label.Parent = option
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Text = optionName
        label.TextColor3 = self.theme.foreground
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14

        local btn = Instance.new("TextButton")
        btn.Parent = option
        btn.Size = UDim2.new(0,30,0,30)
        btn.Position = UDim2.new(1, -30, 0, 0)
        btn.BackgroundColor3 = self.theme.muted
        btn.Text = (parameters and parameters.default and "On") or "Off"
        btn.TextColor3 = self.theme.foreground
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        local state = parameters and parameters.default or false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = state and "On" or "Off"
            if callback then
                callback(state)
            end
        end)
    elseif optionType == "slider" then
        option = Instance.new("Frame")
        option.Name = optionName
        option.Parent = parent
        option.BackgroundTransparency = 1
        option.Size = UDim2.new(1,0,0,40)

        local label = Instance.new("TextLabel")
        label.Parent = option
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Text = optionName
        label.TextColor3 = self.theme.foreground
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 14

        local sliderBar = Instance.new("Frame")
        sliderBar.Parent = option
        sliderBar.BackgroundColor3 = self.theme.muted
        sliderBar.Size = UDim2.new(1, -10, 0, 10)
        sliderBar.Position = UDim2.new(0,5,0,25)

        local sliderButton = Instance.new("Frame")
        sliderButton.Parent = sliderBar
        sliderButton.BackgroundColor3 = self.theme.accent
        sliderButton.Size = UDim2.new(0,10,0,10)
        sliderButton.Position = UDim2.new((parameters.default - parameters.min)/(parameters.max - parameters.min), -5, 0.5, -5)
        sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)

        local dragging = false
        sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        sliderButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation().X
                local barPos = sliderBar.AbsolutePosition.X
                local barSize = sliderBar.AbsoluteSize.X
                local percentage = math.clamp((mousePos - barPos) / barSize, 0, 1)
                sliderButton.Position = UDim2.new(percentage, -5, 0.5, -5)
                local value = parameters.min + (parameters.max - parameters.min) * percentage
                if callback then
                    callback(math.floor(value))
                end
            end
        end)
    elseif optionType == "dropdown" then
        option = Instance.new("Frame")
        option.Name = optionName
        option.Parent = parent
        option.BackgroundTransparency = 1
        option.Size = UDim2.new(1,0,0,30)
        
        local btn = Instance.new("TextButton")
        btn.Parent = option
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundColor3 = self.theme.muted
        btn.Text = parameters.default or parameters.options[1]
        btn.TextColor3 = self.theme.foreground
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        
        local dropdownList = Instance.new("Frame")
        dropdownList.Parent = option
        dropdownList.BackgroundColor3 = self.theme.windowBackground
        dropdownList.Size = UDim2.new(1,0,0, #parameters.options * 30)
        dropdownList.Position = UDim2.new(0,0,1,0)
        dropdownList.Visible = false
        
        local layout = Instance.new("UIListLayout", dropdownList)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        for _, optionText in ipairs(parameters.options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Parent = dropdownList
            optBtn.Size = UDim2.new(1,0,0,30)
            optBtn.BackgroundTransparency = 1
            optBtn.Text = optionText
            optBtn.TextColor3 = self.theme.foreground
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 14
            optBtn.MouseButton1Click:Connect(function()
                btn.Text = optionText
                dropdownList.Visible = false
                if callback then
                    callback(optionText)
                end
            end)
        end
        
        btn.MouseButton1Click:Connect(function()
            dropdownList.Visible = not dropdownList.Visible
        end)
    elseif optionType == "button" then
        option = Instance.new("TextButton")
        option.Name = optionName
        option.Parent = parent
        option.Size = UDim2.new(1,0,0,30)
        option.BackgroundColor3 = self.theme.muted
        option.Text = optionName
        option.TextColor3 = self.theme.foreground
        option.Font = Enum.Font.GothamBold
        option.TextSize = 14
        option.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)
    end
    
    return option
end

--------------------------------------------------
-- 4. 建立唯一的 MainWindow (tag 主視窗，不可移動)
function library:CreateMainWindow()
    if self.mainWindow then
        return self.mainWindow
    end
    self.mainWindow = self:CreateWindow("MainWindow", false)
    return self.mainWindow
end

--------------------------------------------------
-- 5. 新增 Tag
-- 此函式會建立一個 tag 視窗（可移動或依需求調整）並自動在 mainWindow 裡產生同名的 item，
-- 該 item 內的 toggle 按鈕會控制 tag 視窗的顯示/隱藏
function library:AddTag(tagName)
    -- 建立 tag 視窗（此範例設為可移動，可依需求改為 false）
    local tagWindow = self:CreateWindow(tagName, true)
    self.tagWindows[tagName] = tagWindow
    
    local mainWin = self:CreateMainWindow()
    local tagItem = self:CreateItem(mainWin.Content, tagName)
    -- 覆寫 item 的 toggle 行為：切換 tagWindow 的 Visible 狀態
    tagItem.ToggleButton.MouseButton1Click:Connect(function()
        if tagWindow.Window.Visible then
            tagWindow.Window.Visible = false
            tagItem.ToggleButton.Text = "Off"
        else
            tagWindow.Window.Visible = true
            tagItem.ToggleButton.Text = "On"
        end
    end)
    return tagWindow, tagItem
end

return library
