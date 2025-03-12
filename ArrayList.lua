local ArrayListUI = {}
local ArrayListItems = {}

-- 配置
local config = {
    position = UDim2.new(1, -10, 0, 10), -- 右上角
    textSize = 16,
    font = Enum.Font.SourceSansBold,
    activeColor = Color3.fromRGB(255, 85, 85), -- 紅色
    inactiveColor = Color3.fromRGB(180, 180, 180), -- 灰色
    background = {
        transparency = 0.2,
        color = Color3.fromRGB(20, 20, 20)
    },
    verticalLine = {
        width = 2,
        color = Color3.fromRGB(255, 85, 85) -- 紅色
    },
    padding = 8, -- 內邊距
    animationTime = 0.3,
    animationStyle = Enum.EasingStyle.Quart,
    animationDirection = Enum.EasingDirection.Out
}

-- 創建主 UI 容器
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
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- 自動調整
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- 右上角對齊
    MainFrame.Parent = ScreenGui

    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.BackgroundColor3 = config.verticalLine.color
    verticalLine.BorderSizePixel = 0
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    verticalLine.AnchorPoint = Vector2.new(1, 0) -- 右對齊
    verticalLine.Parent = MainFrame

    return MainFrame, verticalLine
end

function ArrayListUI:Init()
    self.mainFrame, self.verticalLine = createMainFrame()
    self.items = {}
    return self
end

-- 獲取選項總高度
function ArrayListUI:GetTotalHeight()
    local height = 0
    for _, item in ipairs(self.items) do
        height = height + item.frame.Size.Y.Offset
    end
    return height
end

-- 新增選項
function ArrayListUI:AddItem(name, value, isActive)
    local textColor = isActive and config.activeColor or config.inactiveColor
    local fullText = value and (name .. " " .. value) or name

    local textWidth = game:GetService("TextService"):GetTextSize(
        fullText, config.textSize, config.font, Vector2.new(1000, 100)
    ).X

    local itemFrame = Instance.new("Frame")
    itemFrame.BackgroundTransparency = 1
    itemFrame.Size = UDim2.new(0, textWidth + config.padding * 2, 0, config.textSize + 4)
    itemFrame.Parent = self.mainFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = textColor
    textLabel.Text = fullText
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.Parent = itemFrame

    local itemData = {
        frame = itemFrame,
        text = textLabel,
        textWidth = textWidth,
        isActive = isActive
    }

    table.insert(self.items, itemData)
    self:UpdateUI()
end

-- 更新 UI（排序、對齊、動畫）
function ArrayListUI:UpdateUI()
    table.sort(self.items, function(a, b)
        return a.textWidth > b.textWidth
    end)

    local maxWidth = 0
    local totalHeight = 0

    for i, item in ipairs(self.items) do
        local targetPos = totalHeight
        totalHeight = totalHeight + item.frame.Size.Y.Offset

        item.frame:TweenPosition(
            UDim2.new(1, 0, 0, targetPos),
            config.animationDirection,
            config.animationStyle,
            config.animationTime,
            true
        )

        if item.textWidth > maxWidth then
            maxWidth = item.textWidth
        end
    end

    self.mainFrame:TweenSize(
        UDim2.new(0, maxWidth + config.padding * 2, 0, totalHeight),
        config.animationDirection,
        config.animationStyle,
        config.animationTime,
        true
    )

    self.verticalLine:TweenSize(
        UDim2.new(0, config.verticalLine.width, 0, totalHeight),
        config.animationDirection,
        config.animationStyle,
        config.animationTime,
        true
    )
end

-- 移除選項
function ArrayListUI:RemoveItem(index)
    if self.items[index] then
        local item = self.items[index]

        game:GetService("TweenService"):Create(
            item.text,
            TweenInfo.new(config.animationTime, config.animationStyle, config.animationDirection),
            {TextTransparency = 1}
        ):Play()

        item.frame:TweenPosition(
            UDim2.new(1, 0, 0, item.frame.Position.Y.Offset),
            config.animationDirection,
            config.animationStyle,
            config.animationTime,
            true,
            function()
                item.frame:Destroy()
                table.remove(self.items, index)
                self:UpdateUI()
            end
        )
    end
end

-- 測試
local function Example()
    local arrayList = ArrayListUI:Init()

    arrayList:AddItem("FakeLag", "Dynamic", true)
    arrayList:AddItem("NoItemRelease", nil, true)
    arrayList:AddItem("Velocity", "Normal", false)
    arrayList:AddItem("Trajectories", nil, true)
    arrayList:AddItem("AutoClicker", nil, true)
    arrayList:AddItem("SilentAura", nil, true)
    arrayList:AddItem("Indicators", nil, true)
    arrayList:AddItem("AntiBot", nil, true)
    arrayList:AddItem("Reach", nil, true)
    arrayList:AddItem("Sprint", nil, true)
    arrayList:AddItem("ESP", nil, true)

    task.delay(3, function()
        arrayList:RemoveItem(3)
    end)

    task.delay(5, function()
        arrayList:AddItem("NewItem", "Active", true)
    end)
end

local API = {
    Init = function() return ArrayListUI:Init() end,
    RunExample = Example
}

return API
