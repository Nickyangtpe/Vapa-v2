local ArrayListUI = {}
local ArrayListItems = {}

-- 配置
local config = {
    position = UDim2.new(1, -10, 0, 10), -- 右上角
    textSize = 16,
    font = Enum.Font.SourceSansBold,
    activeColor = Color3.fromRGB(255, 85, 85), -- 紅色（開啟）
    inactiveColor = Color3.fromRGB(180, 180, 180), -- 灰色（關閉）
    background = {
        transparency = 0.2,
        color = Color3.fromRGB(20, 20, 20)
    },
    verticalLine = {
        width = 2,
        color = Color3.fromRGB(255, 85, 85) -- 右邊紅線
    },
    padding = 8, -- 左右間距
    animationTime = 0.5,
    animationStyle = Enum.EasingStyle.Quart,
    animationDirection = Enum.EasingDirection.Out
}

-- 建立 UI 主框架
local function createMainFrame()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArrayListUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainContainer"
    MainFrame.BackgroundColor3 = config.background.color
    MainFrame.BackgroundTransparency = config.background.transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = config.position
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- 自適應高度
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- 錨點設置為右上角
    MainFrame.Parent = ScreenGui

    -- **使用 UIListLayout 控制排列**
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2) -- 項目間距
    listLayout.Parent = MainFrame

    -- **右邊紅線**
    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.BackgroundColor3 = config.verticalLine.color
    verticalLine.BorderSizePixel = 0
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    verticalLine.Position = UDim2.new(1, -config.verticalLine.width, 0, 0)
    verticalLine.AnchorPoint = Vector2.new(0, 0)
    verticalLine.ZIndex = 2
    verticalLine.Parent = MainFrame

    return MainFrame, verticalLine
end

-- 初始化 UI
function ArrayListUI:Init()
    self.mainFrame, self.verticalLine = createMainFrame()
    self.items = {}
    return self
end

-- **新增選項**
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1
    
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundTransparency = 1
    itemFrame.Size = UDim2.new(1, 0, 0, config.textSize + 4)
    itemFrame.LayoutOrder = itemId
    itemFrame.Parent = self.mainFrame

    -- **右對齊文字**
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -config.padding * 2, 1, 0)
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = value and (name .. " " .. value) or name
    textLabel.TextXAlignment = Enum.TextXAlignment.Right -- **右對齊**
    textLabel.Parent = itemFrame

    -- **動畫效果**
    textLabel.TextTransparency = 1
    game:GetService("TweenService"):Create(
        textLabel, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {TextTransparency = 0}
    ):Play()

    -- **存入列表**
    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        isActive = isActive
    }
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData

    -- **更新高度**
    self:UpdateFrameHeight()
    return itemId
end

-- **移除選項**
function ArrayListUI:RemoveItem(itemId)
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            local fadeOutTween = game:GetService("TweenService"):Create(
                item.text, 
                TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
                {TextTransparency = 1}
            )
            fadeOutTween:Play()

            item.frame:TweenSize(
                UDim2.new(1, 0, 0, 0),
                config.animationDirection,
                config.animationStyle,
                config.animationTime,
                true,
                function()
                    item.frame:Destroy()
                end
            )

            table.remove(self.items, i)
            ArrayListItems[itemId] = nil
            self:UpdateFrameHeight()
            return true
        end
    end
    return false
end

-- **更新 UI 高度與紅線**
function ArrayListUI:UpdateFrameHeight()
    local totalHeight = 0
    for _, item in ipairs(self.items) do
        totalHeight = totalHeight + item.frame.Size.Y.Offset
    end

    game:GetService("TweenService"):Create(
        self.mainFrame, 
        TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection), 
        {Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, totalHeight)}
    ):Play()

    self.verticalLine.Size = UDim2.new(0, config.verticalLine.width, 0, totalHeight)
end

-- **示範測試**
local function Example()
    local arrayList = ArrayListUI:Init()
    
    arrayList:AddItem("WallHack", nil, true)
    arrayList:AddItem("AimAssist", "Active", true)
    arrayList:AddItem("ESP", nil, true)

    task.delay(3, function()
        arrayList:RemoveItem(2) -- 3 秒後移除 AimAssist
    end)
end

return {
    Init = function() return ArrayListUI:Init() end,
    RunExample = Example
}
