-- ArrayList UI Library for Roblox
-- Customizable, animated UI list positioned in the top-right corner

local ArrayListUI = {}
ArrayListUI.__index = ArrayListUI

-- Configuration
local DEFAULT_CONFIG = {
    Title = "ArrayList",
    TitleColor = Color3.fromRGB(255, 50, 50), -- Red by default
    ActiveColor = Color3.fromRGB(255, 50, 50), -- Red by default
    InactiveColor = Color3.fromRGB(200, 200, 200), -- Light gray
    BackgroundColor = Color3.fromRGB(30, 30, 30), -- Dark background
    BackgroundTransparency = 0.2,
    BorderColor = Color3.fromRGB(255, 50, 50), -- Red border
    TextSize = 18,
    Padding = 5,
    AnimationSpeed = 0.3, -- Animation duration in seconds
    Position = UDim2.new(1, -5, 0, 5), -- Top-right corner
    AnchorPoint = Vector2.new(1, 0), -- Anchor to top-right
}

-- Create a new ArrayList
function ArrayListUI.new(config)
    local self = setmetatable({}, ArrayListUI)
    
    -- Merge default config with user config
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = (config and config[key] ~= nil) and config[key] or value
    end
    
    -- Initialize items list
    self.items = {}
    self.activeItems = {}
    
    -- Create main UI
    self:CreateUI()
    
    return self
end

-- Create the UI elements
function ArrayListUI:CreateUI()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "ArrayListUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = playerGui
    
    -- Create main frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.BackgroundColor3 = self.config.BackgroundColor
    self.mainFrame.BackgroundTransparency = self.config.BackgroundTransparency
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Position = self.config.Position
    self.mainFrame.AnchorPoint = self.config.AnchorPoint
    self.mainFrame.AutomaticSize = Enum.AutomaticSize.Y
    self.mainFrame.Size = UDim2.new(0, 200, 0, 0)
    self.mainFrame.Parent = self.screenGui
    
    -- Create title
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "Title"
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Size = UDim2.new(1, 0, 0, self.config.TextSize + 10)
    self.titleLabel.Font = Enum.Font.SourceSansBold
    self.titleLabel.Text = self.config.Title
    self.titleLabel.TextColor3 = self.config.TitleColor
    self.titleLabel.TextSize = self.config.TextSize + 2
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Position = UDim2.new(0, self.config.Padding, 0, 0)
    self.titleLabel.Size = UDim2.new(1, -self.config.Padding * 2, 0, self.config.TextSize + 10)
    self.titleLabel.Parent = self.mainFrame
    
    -- Create list layout
    self.listLayout = Instance.new("UIListLayout")
    self.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.listLayout.Padding = UDim.new(0, 2)
    self.listLayout.Parent = self.mainFrame
    
    -- Create padding
    self.uiPadding = Instance.new("UIPadding")
    self.uiPadding.PaddingTop = UDim.new(0, self.config.Padding)
    self.uiPadding.PaddingBottom = UDim.new(0, self.config.Padding)
    self.uiPadding.PaddingLeft = UDim.new(0, self.config.Padding)
    self.uiPadding.PaddingRight = UDim.new(0, self.config.Padding)
    self.uiPadding.Parent = self.mainFrame
    
    -- Create border line
    self.borderLine = Instance.new("Frame")
    self.borderLine.Name = "BorderLine"
    self.borderLine.BackgroundColor3 = self.config.BorderColor
    self.borderLine.BorderSizePixel = 0
    self.borderLine.Position = UDim2.new(1, 0, 0, 0)
    self.borderLine.Size = UDim2.new(0, 2, 1, 0)
    self.borderLine.Parent = self.mainFrame
    
    -- Create items container
    self.itemsContainer = Instance.new("Frame")
    self.itemsContainer.Name = "ItemsContainer"
    self.itemsContainer.BackgroundTransparency = 1
    self.itemsContainer.Position = UDim2.new(0, 0, 0, self.config.TextSize + 10)
    self.itemsContainer.Size = UDim2.new(1, 0, 0, 0)
    self.itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
    self.itemsContainer.Parent = self.mainFrame
    
    -- Create list layout for items
    self.itemsLayout = Instance.new("UIListLayout")
    self.itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.itemsLayout.Padding = UDim.new(0, 2)
    self.itemsLayout.Parent = self.itemsContainer
end

-- Add a new item to the list
function ArrayListUI:AddItem(name, active, callback)
    if self.items[name] then
        return self.items[name]
    end
    
    local item = {}
    item.name = name
    item.active = active or false
    item.callback = callback
    
    -- Create item frame
    item.frame = Instance.new("TextButton")
    item.frame.Name = name
    item.frame.BackgroundTransparency = 1
    item.frame.Size = UDim2.new(1, 0, 0, self.config.TextSize + 4)
    item.frame.Text = ""
    item.frame.AutoButtonColor = false
    
    -- Create item text
    item.text = Instance.new("TextLabel")
    item.text.BackgroundTransparency = 1
    item.text.Size = UDim2.new(1, -self.config.Padding, 1, 0)
    item.text.Font = Enum.Font.SourceSans
    item.text.Text = name
    item.text.TextSize = self.config.TextSize
    item.text.TextXAlignment = Enum.TextXAlignment.Left
    item.text.TextColor3 = item.active and self.config.ActiveColor or self.config.InactiveColor
    item.text.Parent = item.frame
    
    -- Add click functionality if callback provided
    if callback then
        item.frame.MouseButton1Click:Connect(function()
            item.active = not item.active
            self:UpdateItem(name, item.active)
            if callback then
                callback(item.active)
            end
        end)
    end
    
    -- Set initial state
    self:UpdateItem(name, item.active, true)
    
    -- Add to items list
    self.items[name] = item
    
    -- Add to container with animation
    item.frame.Parent = self.itemsContainer
    item.frame.Size = UDim2.new(1, 0, 0, 0)
    item.frame.TextTransparency = 1
    
    -- Animation
    local tweenInfo = TweenInfo.new(self.config.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(
        item.frame,
        tweenInfo,
        {Size = UDim2.new(1, 0, 0, self.config.TextSize + 4), TextTransparency = 0}
    )
    tween:Play()
    
    return item
end

-- Update an item's state
function ArrayListUI:UpdateItem(name, active, noAnimation)
    local item = self.items[name]
    if not item then return end
    
    item.active = active
    
    -- Update text color
    local targetColor = active and self.config.ActiveColor or self.config.InactiveColor
    
    if noAnimation then
        item.text.TextColor3 = targetColor
    else
        local tweenInfo = TweenInfo.new(self.config.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(
            item.text,
            tweenInfo,
            {TextColor3 = targetColor}
        )
        tween:Play()
    end
    
    -- Update active items list for sorting
    if active then
        if not table.find(self.activeItems, name) then
            table.insert(self.activeItems, name)
        end
    else
        local index = table.find(self.activeItems, name)
        if index then
            table.remove(self.activeItems, index)
        end
    end
    
    -- Sort items
    self:SortItems()
end

-- Remove an item from the list
function ArrayListUI:RemoveItem(name)
    local item = self.items[name]
    if not item then return end
    
    -- Animation
    local tweenInfo = TweenInfo.new(self.config.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(
        item.frame,
        tweenInfo,
        {Size = UDim2.new(1, 0, 0, 0), TextTransparency = 1}
    )
    
    tween.Completed:Connect(function()
        item.frame:Destroy()
        self.items[name] = nil
        
        -- Remove from active items
        local index = table.find(self.activeItems, name)
        if index then
            table.remove(self.activeItems, index)
        end
    end)
    
    tween:Play()
end

-- Sort items (active items first)
function ArrayListUI:SortItems()
    local order = 0
    
    -- First, active items
    for _, name in ipairs(self.activeItems) do
        local item = self.items[name]
        if item then
            item.frame.LayoutOrder = order
            order = order + 1
        end
    end
    
    -- Then, inactive items
    for name, item in pairs(self.items) do
        if not item.active then
            item.frame.LayoutOrder = order
            order = order + 1
        end
    end
end

-- Set the color theme
function ArrayListUI:SetTheme(activeColor, inactiveColor, backgroundColor, borderColor)
    self.config.ActiveColor = activeColor or self.config.ActiveColor
    self.config.InactiveColor = inactiveColor or self.config.InactiveColor
    self.config.BackgroundColor = backgroundColor or self.config.BackgroundColor
    self.config.BorderColor = borderColor or self.config.BorderColor
    
    -- Update UI elements
    self.mainFrame.BackgroundColor3 = self.config.BackgroundColor
    self.borderLine.BackgroundColor3 = self.config.BorderColor
    self.titleLabel.TextColor3 = self.config.ActiveColor
    
    -- Update all items
    for name, item in pairs(self.items) do
        self:UpdateItem(name, item.active, true)
    end
end

-- Example usage function
local function CreateExampleArrayList()
    local arrayList = ArrayListUI.new({
        Title = "Features",
        ActiveColor = Color3.fromRGB(255, 50, 50),  -- Red
        InactiveColor = Color3.fromRGB(200, 200, 200),  -- Light gray
        BackgroundColor = Color3.fromRGB(30, 30, 30),  -- Dark background
        BorderColor = Color3.fromRGB(255, 50, 50),  -- Red border
    })
    
    -- Add items
    arrayList:AddItem("FakeLag", true, function(active) print("FakeLag:", active) end)
    arrayList:AddItem("Dynamic", false, function(active) print("Dynamic:", active) end)
    arrayList:AddItem("NoItemRelease", true, function(active) print("NoItemRelease:", active) end)
    arrayList:AddItem("Velocity", false, function(active) print("Velocity:", active) end)
    arrayList:AddItem("Normal", false, function(active) print("Normal:", active) end)
    arrayList:AddItem("Trajectories", true, function(active) print("Trajectories:", active) end)
    arrayList:AddItem("AutoClicker", true, function(active) print("AutoClicker:", active) end)
    arrayList:AddItem("SilentAura", true, function(active) print("SilentAura:", active) end)
    arrayList:AddItem("Indicators", true, function(active) print("Indicators:", active) end)
    arrayList:AddItem("AntiBot", true, function(active) print("AntiBot:", active) end)
    arrayList:AddItem("Reach", true, function(active) print("Reach:", active) end)
    arrayList:AddItem("Sprint", true, function(active) print("Sprint:", active) end)
    arrayList:AddItem("ESP", true, function(active) print("ESP:", active) end)
    
    return arrayList
end

-- Public API
return {
    new = ArrayListUI.new,
    createExample = CreateExampleArrayList
}
