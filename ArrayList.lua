-- ArrayList UI Library for Roblox
-- Inspired by Vape v4 ArrayList

local ArrayListLib = {}
ArrayListLib.__index = ArrayListLib

-- Configuration
local DEFAULT_CONFIG = {
    Position = UDim2.new(1, -5, 0, 5), -- Top right corner
    TextSize = 18,
    Font = Enum.Font.SourceSansBold,
    MainColor = Color3.fromRGB(255, 50, 50), -- Red by default, can be changed
    SecondaryColor = Color3.fromRGB(255, 255, 255), -- White
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.3,
    AnimationSpeed = 0.2, -- Speed of animations
    Padding = 2, -- Padding between items
    SortingMethod = "Alphabetical", -- "Alphabetical" or "Length"
}

-- Create a new ArrayList
function ArrayListLib.new(config)
    local self = setmetatable({}, ArrayListLib)
    
    -- Merge default config with user config
    self.Config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.Config[key] = (config and config[key] ~= nil) and config[key] or value
    end
    
    -- Initialize variables
    self.Items = {}
    self.Gui = nil
    
    -- Create the UI
    self:CreateUI()
    
    return self
end

-- Create the UI elements
function ArrayListLib:CreateUI()
    -- Create ScreenGui
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "ArrayListUI"
    self.Gui.ResetOnSpawn = false
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent the ScreenGui appropriately based on Roblox's security context
    local success, result = pcall(function()
        -- Try to use CoreGui (works in exploits)
        return game:GetService("CoreGui")
    end)
    
    if success then
        self.Gui.Parent = result
    else
        -- Fallback to PlayerGui (works in normal scripts)
        self.Gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Create main frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "ArrayListFrame"
    self.MainFrame.BackgroundTransparency = 1
    self.MainFrame.Position = self.Config.Position
    self.MainFrame.Size = UDim2.new(0, 200, 0, 0) -- Will be auto-sized
    self.MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top-right
    self.MainFrame.Parent = self.Gui
    
    -- Create UIListLayout for automatic positioning
    self.ListLayout = Instance.new("UIListLayout")
    self.ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    self.ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    self.ListLayout.Padding = UDim.new(0, self.Config.Padding)
    self.ListLayout.Parent = self.MainFrame
    
    -- Create the vertical line on the right
    self.VerticalLine = Instance.new("Frame")
    self.VerticalLine.Name = "VerticalLine"
    self.VerticalLine.BackgroundColor3 = self.Config.MainColor
    self.VerticalLine.BorderSizePixel = 0
    self.VerticalLine.Position = UDim2.new(1, 0, 0, 0)
    self.VerticalLine.Size = UDim2.new(0, 2, 1, 0)
    self.VerticalLine.AnchorPoint = Vector2.new(0, 0)
    self.VerticalLine.Parent = self.MainFrame
    
    -- Connect the UIListLayout to auto-size the frame
    self.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.MainFrame.Size = UDim2.new(0, 200, 0, self.ListLayout.AbsoluteContentSize.Y)
        self.VerticalLine.Size = UDim2.new(0, 2, 1, 0)
    end)
end

-- Add an item to the ArrayList
function ArrayListLib:AddItem(name, state)
    -- Check if item already exists
    if self.Items[name] then
        return self:UpdateItem(name, state)
    end
    
    -- Create item frame
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = name
    itemFrame.BackgroundColor3 = self.Config.BackgroundColor
    itemFrame.BackgroundTransparency = self.Config.BackgroundTransparency
    itemFrame.BorderSizePixel = 0
    itemFrame.Size = UDim2.new(0, 0, 0, self.Config.TextSize + 6) -- Height based on text size
    itemFrame.ClipsDescendants = true
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ItemText"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -5, 1, 0)
    textLabel.Position = UDim2.new(0, 5, 0, 0)
    textLabel.Font = self.Config.Font
    textLabel.TextSize = self.Config.TextSize
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = itemFrame
    
    -- Set the text and color based on state
    if state then
        textLabel.Text = name
        textLabel.TextColor3 = self.Config.MainColor
    else
        textLabel.Text = name
        textLabel.TextColor3 = self.Config.SecondaryColor
    end
    
    -- Store the item
    self.Items[name] = {
        Frame = itemFrame,
        Text = textLabel,
        State = state or false
    }
    
    -- Add to UI with animation
    itemFrame.Parent = self.MainFrame
    
    -- Animate the item appearing
    itemFrame.Size = UDim2.new(0, 0, 0, self.Config.TextSize + 6)
    local textWidth = textLabel.TextBounds.X + 10
    
    -- Animation
    local tweenInfo = TweenInfo.new(self.Config.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(
        itemFrame,
        tweenInfo,
        {Size = UDim2.new(0, textWidth, 0, self.Config.TextSize + 6)}
    )
    tween:Play()
    
    -- Sort the items
    self:SortItems()
    
    return self.Items[name]
end

-- Update an existing item
function ArrayListLib:UpdateItem(name, state)
    local item = self.Items[name]
    if not item then
        return self:AddItem(name, state)
    end
    
    -- Update state
    item.State = state
    
    -- Update text color
    if state then
        item.Text.TextColor3 = self.Config.MainColor
    else
        item.Text.TextColor3 = self.Config.SecondaryColor
    end
    
    -- Sort the items
    self:SortItems()
    
    return item
end

-- Remove an item from the ArrayList
function ArrayListLib:RemoveItem(name)
    local item = self.Items[name]
    if not item then return end
    
    -- Animate the item disappearing
    local tweenInfo = TweenInfo.new(self.Config.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(
        item.Frame,
        tweenInfo,
        {Size = UDim2.new(0, 0, 0, self.Config.TextSize + 6)}
    )
    
    tween.Completed:Connect(function()
        item.Frame:Destroy()
        self.Items[name] = nil
    end)
    
    tween:Play()
end

-- Sort the items based on the sorting method
function ArrayListLib:SortItems()
    local sortedItems = {}
    
    -- Collect all items
    for name, item in pairs(self.Items) do
        table.insert(sortedItems, {
            Name = name,
            Item = item
        })
    end
    
    -- Sort based on the sorting method
    if self.Config.SortingMethod == "Alphabetical" then
        table.sort(sortedItems, function(a, b)
            return a.Name < b.Name
        end)
    elseif self.Config.SortingMethod == "Length" then
        table.sort(sortedItems, function(a, b)
            return #a.Name > #b.Name
        end)
    end
    
    -- Apply the sort order
    for i, itemData in ipairs(sortedItems) do
        itemData.Item.Frame.LayoutOrder = i
    end
end

-- Change the color theme
function ArrayListLib:SetTheme(mainColor, secondaryColor, backgroundColor)
    if mainColor then
        self.Config.MainColor = mainColor
        self.VerticalLine.BackgroundColor3 = mainColor
        
        -- Update all active items
        for name, item in pairs(self.Items) do
            if item.State then
                item.Text.TextColor3 = mainColor
            end
        end
    end
    
    if secondaryColor then
        self.Config.SecondaryColor = secondaryColor
        
        -- Update all inactive items
        for name, item in pairs(self.Items) do
            if not item.State then
                item.Text.TextColor3 = secondaryColor
            end
        end
    end
    
    if backgroundColor then
        self.Config.BackgroundColor = backgroundColor
        
        -- Update all item backgrounds
        for name, item in pairs(self.Items) do
            item.Frame.BackgroundColor3 = backgroundColor
        end
    end
end

-- Set the position of the ArrayList
function ArrayListLib:SetPosition(position)
    self.Config.Position = position
    self.MainFrame.Position = position
end

-- Toggle visibility of the ArrayList
function ArrayListLib:SetVisible(visible)
    self.Gui.Enabled = visible
end

-- Example usage
local function CreateExampleArrayList()
    -- Create a new ArrayList with custom config
    local arrayList = ArrayListLib.new({
        MainColor = Color3.fromRGB(255, 50, 50), -- Red
        SecondaryColor = Color3.fromRGB(200, 200, 200), -- Light gray
        BackgroundColor = Color3.fromRGB(30, 30, 30), -- Dark gray
        BackgroundTransparency = 0.3,
        TextSize = 18,
        AnimationSpeed = 0.2,
        SortingMethod = "Alphabetical"
    })
    
    -- Add some example items
    arrayList:AddItem("FakeLag", true)
    arrayList:AddItem("Dynamic", false)
    arrayList:AddItem("NoItemRelease", true)
    arrayList:AddItem("Velocity", true)
    arrayList:AddItem("Normal", false)
    arrayList:AddItem("Trajectories", true)
    arrayList:AddItem("AutoClicker", true)
    arrayList:AddItem("SilentAura", true)
    arrayList:AddItem("Indicators", true)
    arrayList:AddItem("AntiBot", true)
    arrayList:AddItem("Reach", true)
    arrayList:AddItem("Sprint", true)
    arrayList:AddItem("ESP", true)
    
    -- Return the ArrayList instance for further manipulation
    return arrayList
end

-- Return the library and create an example
return {
    Library = ArrayListLib,
    CreateExample = CreateExampleArrayList
}

-- Example of how to use this library:
--[[
local ArrayListModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/YourRepo/main/ArrayList.lua", true))()

-- Method 1: Create with default settings and add items manually
local myArrayList = ArrayListModule.Library.new()
myArrayList:AddItem("Speed", true)
myArrayList:AddItem("Jump", false)

-- Method 2: Use the example with predefined items
local exampleList = ArrayListModule.CreateExample()

-- Update items
myArrayList:UpdateItem("Speed", false)

-- Remove items
myArrayList:RemoveItem("Jump")

-- Change theme
myArrayList:SetTheme(
    Color3.fromRGB(0, 255, 0),  -- Main color (green)
    Color3.fromRGB(255, 255, 255),  -- Secondary color (white)
    Color3.fromRGB(20, 20, 20)  -- Background color (dark)
)
]]
