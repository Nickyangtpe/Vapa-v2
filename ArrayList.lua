local ArrayListUI = {}
ArrayListUI.__index = ArrayListUI

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20),
    TEXT_COLOR = Color3.fromRGB(255, 50, 50),
    SECONDARY_TEXT_COLOR = Color3.fromRGB(200, 200, 200),
    BORDER_COLOR = Color3.fromRGB(255, 50, 50),
    FONT = Enum.Font.SourceSansBold,
    TEXT_SIZE = 16,
    PADDING = 8,
    ANIMATION_SPEED = 0.3,
    POSITION = UDim2.new(1, -10, 0, 10), -- Right top corner
}

-- Create a new ArrayList UI
function ArrayListUI.new()
    local self = setmetatable({}, ArrayListUI)
    
    -- Create main frame
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "ArrayListUI"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Container for all items
    self.container = Instance.new("Frame")
    self.container.Name = "Container"
    self.container.BackgroundTransparency = 1
    self.container.Size = UDim2.new(0, 200, 0, 500)
    self.container.Position = CONFIG.POSITION
    self.container.AnchorPoint = Vector2.new(1, 0)
    self.container.Parent = self.gui
    
    -- List of all items
    self.items = {}
    self.isAnimating = false
    
    -- Parent to PlayerGui
    if RunService:IsStudio() then
        self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    else
        self.gui.Parent = game:GetService("CoreGui")
    end
    
    return self
end

-- Add a new item to the ArrayList
function ArrayListUI:AddItem(name, value)
    local item = Instance.new("Frame")
    item.Name = name
    item.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    item.BorderSizePixel = 0
    item.Size = UDim2.new(0, 0, 0, CONFIG.TEXT_SIZE + CONFIG.PADDING * 2)
    item.Position = UDim2.new(1, 200, 0, 0)
    item.AnchorPoint = Vector2.new(1, 0)
    item.Parent = self.container

    local border = Instance.new("Frame")
    border.Name = "Border"
    border.BackgroundColor3 = CONFIG.BORDER_COLOR
    border.BorderSizePixel = 0
    border.Size = UDim2.new(0, 2, 1, 0)
    border.Position = UDim2.new(1, 0, 0, 0)
    border.Parent = item

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, CONFIG.PADDING, 0, 0)
    nameLabel.Font = CONFIG.FONT
    nameLabel.TextSize = CONFIG.TEXT_SIZE
    nameLabel.TextColor3 = CONFIG.TEXT_COLOR
    nameLabel.Text = name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = item

    local valueLabel = nil
    if value then
        valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.BackgroundTransparency = 1
        valueLabel.Size = UDim2.new(0, 0, 1, 0)
        valueLabel.Font = CONFIG.FONT
        valueLabel.TextSize = CONFIG.TEXT_SIZE
        valueLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        valueLabel.Text = value
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = item
    end

    local newItem = {
        name = name,
        frame = item,
        nameLabel = nameLabel,
        valueLabel = valueLabel
    }
    
    table.insert(self.items, newItem)

    -- 等待 TextBounds 更新後再執行排序與動畫
    nameLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        self:UpdateValueLabelPosition(newItem)
        self:WaitForAnimations(function()
            self:SortItems()
            self:UpdatePositions()
            self:AnimateItem(item, true)
        end)
    end)

    return item
end

-- 更新 ValueLabel 位置
function ArrayListUI:UpdateValueLabelPosition(item)
    if item.valueLabel then
        item.valueLabel.Position = UDim2.new(0, item.nameLabel.TextBounds.X + CONFIG.PADDING * 2, 0, 0)
    end
end

-- 排序項目（長度由長到短）
function ArrayListUI:SortItems()
    table.sort(self.items, function(a, b)
        return self:GetItemWidth(a) > self:GetItemWidth(b)
    end)
end

-- 計算選項的寬度
function ArrayListUI:GetItemWidth(item)
    local width = item.nameLabel.TextBounds.X + CONFIG.PADDING * 2
    if item.valueLabel then
        width = width + item.valueLabel.TextBounds.X + CONFIG.PADDING
    end
    return width
end

-- 更新位置
function ArrayListUI:UpdatePositions()
    self.isAnimating = true
    local yOffset = 0
    for i, item in ipairs(self.items) do
        local tween = TweenService:Create(
            item.frame,
            TweenInfo.new(CONFIG.ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, 0, 0, yOffset)}
        )
        tween:Play()
        yOffset = yOffset + item.frame.Size.Y.Offset
    end
    wait(CONFIG.ANIMATION_SPEED + 0.05)
    self.isAnimating = false
end

-- 動畫顯示 / 隱藏選項
function ArrayListUI:AnimateItem(item, isIn)
    self.isAnimating = true
    local targetX = isIn and 0 or 200
    local tween = TweenService:Create(
        item,
        TweenInfo.new(CONFIG.ANIMATION_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, targetX, item.Position.Y.Scale, item.Position.Y.Offset)}
    )
    tween:Play()
end

-- 等待動畫完成
function ArrayListUI:WaitForAnimations(callback)
    if self.isAnimating then
        task.wait(CONFIG.ANIMATION_SPEED)
    end
    callback()
end

return ArrayListUI
