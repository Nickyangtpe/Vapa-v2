-- ArrayList UI Library for Roblox
-- Positioned in top-right corner with vertical line design

local ArrayListUI = {}
local ArrayListItems = {}

-- Configuration
local config = {
    position = UDim2.new(1, -10, 0, 10), -- Top right corner
    textSize = 16,
    font = Enum.Font.SourceSansBold,
    activeColor = Color3.fromRGB(255, 85, 85), -- Red for active items
    inactiveColor = Color3.fromRGB(180, 180, 180), -- Gray for inactive items
    background = {
        transparency = 0.2,
        color = Color3.fromRGB(20, 20, 20)
    },
    verticalLine = {
        width = 2,
        color = Color3.fromRGB(255, 85, 85) -- Red vertical line
    },
    padding = 8 -- Horizontal padding
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
    MainFrame.BackgroundColor3 = config.background.color
    MainFrame.BackgroundTransparency = config.background.transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = config.position
    MainFrame.Size = UDim2.new(0, 200, 0, 0) -- Will auto-resize
    MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top-right
    MainFrame.Parent = ScreenGui
    
    -- Create the vertical line on the right
    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.BackgroundColor3 = config.verticalLine.color
    verticalLine.BorderSizePixel = 0
    verticalLine.Position = UDim2.new(1, 0, 0, 0) 
    verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    verticalLine.AnchorPoint = Vector2.new(0, 0)
    verticalLine.ZIndex = 2
    verticalLine.Parent = MainFrame
    
    return MainFrame
end

-- Initialize the UI
function ArrayListUI:Init()
    self.mainFrame = createMainFrame()
    self.items = {}
    return self
end

-- Add a new item to the ArrayList
function ArrayListUI:AddItem(name, value, isActive)
    local itemColor = isActive and config.activeColor or config.inactiveColor
    local itemId = #self.items + 1
    local displayText = value and (name .. " " .. value) or name
    
    -- Create item container
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. itemId
    itemFrame.BackgroundTransparency = 1
    itemFrame.Size = UDim2.new(1, 0, 0, config.textSize + 4) -- Height based on text size
    itemFrame.Position = UDim2.new(0, 0, 0, self:GetTotalHeight())
    itemFrame.Parent = self.mainFrame
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -config.padding, 1, 0)
    textLabel.Position = UDim2.new(0, config.padding, 0, 0)
    textLabel.Font = config.font
    textLabel.TextSize = config.textSize
    textLabel.TextColor3 = itemColor
    textLabel.Text = displayText
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.Parent = itemFrame
    
    -- Calculate width based on text
    local textWidth = game:GetService("TextService"):GetTextSize(
        displayText, 
        config.textSize, 
        config.font, 
        Vector2.new(1000, 100)
    ).X
    
    local targetWidth = textWidth + (config.padding * 2) + config.verticalLine.width
    
    -- Update main frame width if needed
    if targetWidth > self.mainFrame.Size.X.Offset then
        self.mainFrame.Size = UDim2.new(0, targetWidth, self.mainFrame.Size.Y)
    end
    
    -- Store item data
    local itemData = {
        id = itemId,
        frame = itemFrame,
        text = textLabel,
        name = name,
        value = value,
        isActive = isActive
    }
    
    table.insert(self.items, itemData)
    ArrayListItems[itemId] = itemData
    
    -- Update vertical line and frame height
    self:UpdateFrameHeight()
    
    return itemId
end

-- Get the total height of all items
function ArrayListUI:GetTotalHeight()
    local height = 0
    for _, item in ipairs(self.items) do
        height = height + item.frame.Size.Y.Offset
    end
    return height
end

-- Update main frame height
function ArrayListUI:UpdateFrameHeight()
    local totalHeight = self:GetTotalHeight()
    self.mainFrame.Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, totalHeight)
    
    -- Update vertical line height
    local verticalLine = self.mainFrame:FindFirstChild("VerticalLine")
    if verticalLine then
        verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
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
        item.frame:Destroy()
        table.remove(self.items, itemIndex)
        ArrayListItems[itemId] = nil
        
        -- Reposition all items after the removed one
        for i = itemIndex, #self.items do
            local currentItem = self.items[i]
            currentItem.frame.Position = UDim2.new(0, 0, 0, self:GetItemPosition(i))
        end
        
        -- Update frame height
        self:UpdateFrameHeight()
        return true
    end
    
    return false
end

-- Get position for item at index
function ArrayListUI:GetItemPosition(index)
    local position = 0
    for i = 1, index - 1 do
        position = position + self.items[i].frame.Size.Y.Offset
    end
    return position
end

-- Toggle an item's active state
function ArrayListUI:ToggleItemActive(itemId)
    local item = ArrayListItems[itemId]
    if item then
        item.isActive = not item.isActive
        item.text.TextColor3 = item.isActive and config.activeColor or config.inactiveColor
        return true
    end
    return false
end

-- Update an item's value
function ArrayListUI:UpdateValue(itemId, newValue)
    local item = ArrayListItems[itemId]
    if item then
        item.value = newValue
        local displayText = newValue and (item.name .. " " .. newValue) or item.name
        item.text.Text = displayText
        
        -- Recalculate width based on new text
        local textWidth = game:GetService("TextService"):GetTextSize(
            displayText, 
            config.textSize, 
            config.font, 
            Vector2.new(1000, 100)
        ).X
        
        local targetWidth = textWidth + (config.padding * 2) + config.verticalLine.width
        
        -- Update main frame width if needed
        if targetWidth > self.mainFrame.Size.X.Offset then
            self.mainFrame.Size = UDim2.new(0, targetWidth, self.mainFrame.Size.Y)
        end
        
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
    
    -- Update vertical line
    local verticalLine = self.mainFrame:FindFirstChild("VerticalLine")
    if verticalLine then
        verticalLine.BackgroundColor3 = config.verticalLine.color
        verticalLine.Size = UDim2.new(0, config.verticalLine.width, 1, 0)
    end
    
    -- Update main frame
    self.mainFrame.BackgroundColor3 = config.background.color
    self.mainFrame.BackgroundTransparency = config.background.transparency
    self.mainFrame.Position = config.position
    
    -- Update all items
    for _, item in ipairs(self.items) do
        item.text.Font = config.font
        item.text.TextSize = config.textSize
        item.text.TextColor3 = item.isActive and config.activeColor or config.inactiveColor
        item.text.Position = UDim2.new(0, config.padding, 0, 0)
        item.text.Size = UDim2.new(1, -config.padding, 1, 0)
        item.frame.Size = UDim2.new(1, 0, 0, config.textSize + 4)
    end
    
    -- Reposition items
    for i, item in ipairs(self.items) do
        item.frame.Position = UDim2.new(0, 0, 0, self:GetItemPosition(i))
    end
    
    -- Update frame height
    self:UpdateFrameHeight()
end

-- Clear all items
function ArrayListUI:ClearAll()
    for _, item in ipairs(self.items) do
        item.frame:Destroy()
    end
    
    self.items = {}
    ArrayListItems = {}
    self.mainFrame.Size = UDim2.new(0, self.mainFrame.Size.X.Offset, 0, 0)
end

-- Example usage
local function Example()
    local arrayList = ArrayListUI:Init()
    
    -- Add some example items with active/inactive states matching the image
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
    
    -- Toggle some items after delay
    task.delay(3, function()
        arrayList:ToggleItemActive(3) -- Toggle Velocity
    end)
    
    -- Update a value after delay
    task.delay(5, function()
        arrayList:UpdateValue(1, "Off") -- Change FakeLag value
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
