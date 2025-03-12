-- ArrayList UI Library for Roblox
-- Positioned in top-right corner with animations and dynamic sizing

local ArrayListUI = {}
local ArrayListItems = {}

-- Configuration
local config = {
    position = UDim2.new(1, -10, 0, 10), -- Top right corner
    itemSpacing = 5,
    animationSpeed = 0.3,
    textSize = 14,
    font = Enum.Font.SourceSansBold,
    defaultColor = Color3.fromRGB(85, 170, 255), -- Blue default
    background = {
        transparency = 0.3,
        color = Color3.fromRGB(30, 30, 30)
    },
    border = {
        size = 1,
        color = Color3.fromRGB(60, 60, 60)
    },
    shadow = true,
    cornerRadius = UDim.new(0, 4)
}

-- Create main UI container
local function createMainFrame()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArrayListUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainContainer"
    MainFrame.BackgroundTransparency = 1
    MainFrame.Position = config.position
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- Will auto-resize
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top-right
    MainFrame.Parent = ScreenGui
    
    return MainFrame
end

-- Initialize the UI
function ArrayListUI:Init()
    self.mainFrame = createMainFrame()
    self.items = {}
    return self
end

-- Add a new item to the ArrayList
function ArrayListUI:AddItem(text, color)
    local itemColor = color or config.defaultColor
    local itemId = #self.items + 1
    
    -- Create item container
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundColor3 = config.background.color
    itemFrame.BackgroundTransparency = config.background.transparency
    itemFrame.BorderSizePixel = config.border.size
    itemFrame.BorderColor3 = config.border.color
    itemFrame.Size = UDim2.new(0, 0, 0, config.textSize + 10) -- Initial size, will animate
    itemFrame.Position = UDim2.new(1, 0, 0, self:GetTotalHeight())
    itemFrame.AnchorPoint = Vector2.new(1, 0)
    itemFrame.Parent = self.mainFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.cornerRadius
    corner.Parent = itemFrame
    
    -- Add shadow if enabled
    if config.shadow then
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxassetid://5554236805"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.6
        shadow.Position = UDim2.fromOffset(-15, -15)
        shadow.Size = UDim2.new(1, 30, 1, 30)
        shadow.ZIndex = -1
        shadow.Parent = itemFrame
    end
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -10, 1, 0)
    textLabel.Position = UDim2.new(0, 5, 0, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = text
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.Parent = itemFrame
    
    -- Calculate width based on text
    local textWidth = game:GetService("TextService"):GetTextSize(
        text, 
        config.textSize, 
        config.font, 
        Vector2.new(1000, 100)
    ).X
    
    local targetWidth = textWidth + 20 -- Add padding
    
    -- Store item data
    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        width = targetWidth
    }
    
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData
    
    -- Animate item appearance
    self:AnimateItem(itemFrame, targetWidth)
    self:UpdatePositions()
    
    return itemId
end

-- Animate an item appearing
function ArrayListUI:AnimateItem(frame, targetWidth)
    local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(
        frame,
        tweenInfo,
        {Size = UDim2.new(0, targetWidth, 0, frame.Size.Y.Offset)}
    )
    tween:Play()
end

-- Get the total height of all items
function ArrayListUI:GetTotalHeight()
    local height = 0
    for _, item in ipairs(self.items) do
        height = height + item.frame.Size.Y.Offset + config.itemSpacing
    end
    return height
end

-- Update positions of all items
function ArrayListUI:UpdatePositions()
    local currentHeight = 0
    for _, item in ipairs(self.items) do
        local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(
            item.frame,
            tweenInfo,
            {Position = UDim2.new(1, 0, 0, currentHeight)}
        )
        tween:Play()
        currentHeight = currentHeight + item.frame.Size.Y.Offset + config.itemSpacing
    end
end

-- Remove an item by ID
function ArrayListUI:RemoveItem(itemId)
    local itemIndex = nil
    for i, item in ipairs(self.items) do
        if item.id == itemId then
            itemIndex = i
            break
        end
    end
    
    if itemIndex then
        local item = self.items[itemIndex]
        
        -- Animate removal
        local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(
            item.frame,
            tweenInfo,
            {Size = UDim2.new(0, 0, 0, item.frame.Size.Y.Offset), BackgroundTransparency = 1}
        )
        
        tween.Completed:Connect(function()
            item.frame:Destroy()
            table.remove(self.items, itemIndex)
            ArrayListItems[itemId] = nil
            self:UpdatePositions()
        end)
        
        tween:Play()
        return true
    end
    
    return false
end

-- Update an item's text
function ArrayListUI:UpdateItem(itemId, newText, newColor)
    local item = ArrayListItems[itemId]
    if item then
        item.text.Text = newText
        
        if newColor then
            item.text.TextColor3 = newColor
        end
        
        -- Recalculate width based on new text
        local textWidth = game:GetService("TextService"):GetTextSize(
            newText, 
            config.textSize, 
            config.font, 
            Vector2.new(1000, 100)
        ).X
        
        local targetWidth = textWidth + 20 -- Add padding
        item.width = targetWidth
        
        -- Animate to new width
        local tweenInfo = TweenInfo.new(config.animationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(
            item.frame,
            tweenInfo,
            {Size = UDim2.new(0, targetWidth, 0, item.frame.Size.Y.Offset)}
        )
        tween:Play()
        
        return true
    end
    
    return false
end

-- Change the configuration
function ArrayListUI:UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if type(value) == "table" then
            for subKey, subValue in pairs(value) do
                config[key][subKey] = subValue
            end
        else
            config[key] = value
        end
    end
    
    -- Update existing items with new configuration
    for _, item in ipairs(self.items) do
        item.frame.BackgroundColor3 = config.background.color
        item.frame.BackgroundTransparency = config.background.transparency
        item.frame.BorderSizePixel = config.border.size
        item.frame.BorderColor3 = config.border.color
        
        local corner = item.frame:FindFirstChild("UICorner")
        if corner then
            corner.CornerRadius = config.cornerRadius
        end
        
        item.text.Font = config.font
        item.text.TextSize = config.textSize
    end
    
    -- Update main frame position
    self.mainFrame.Position = config.position
    
    -- Recalculate positions
    self:UpdatePositions()
end

-- Clear all items
function ArrayListUI:ClearAll()
    for _, item in ipairs(self.items) do
        item.frame:Destroy()
    end
    
    self.items = {}
    ArrayListItems = {}
end

-- Example usage
local function Example()
    local arrayList = ArrayListUI:Init()
    
    -- Add some example items
    local item1 = arrayList:AddItem("Speed: 100%", Color3.fromRGB(85, 255, 127))
    local item2 = arrayList:AddItem("Flight: Enabled", Color3.fromRGB(255, 170, 0))
    local item3 = arrayList:AddItem("Health: 100", Color3.fromRGB(255, 85, 85))
    
    -- Update an item after 2 seconds
    task.delay(2, function()
        arrayList:UpdateItem(item3, "Health: 75", Color3.fromRGB(255, 170, 85))
    end)
    
    -- Remove an item after 4 seconds
    task.delay(4, function()
        arrayList:RemoveItem(item2)
    end)
    
    -- Add another item after 5 seconds
    task.delay(5, function()
        arrayList:AddItem("Coins: 1,500", Color3.fromRGB(255, 255, 85))
    end)
    
    -- Change theme after 7 seconds
    task.delay(7, function()
        arrayList:UpdateConfig({
            background = {
                color = Color3.fromRGB(40, 40, 40),
                transparency = 0.2
            },
            border = {
                color = Color3.fromRGB(100, 100, 100)
            },
            cornerRadius = UDim.new(0, 8)
        })
    end)
end

-- Return the API
local API = {
    Init = function() return ArrayListUI:Init() end,
    RunExample = Example
}

-- Auto-run example if loaded with loadstring
if script and script.Name == "ArrayListLoader" then
    Example()
end

return API
