-- UILibrary.lua
-- A customizable UI library for Roblox

local UILibrary = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local DEFAULT_CONFIG = {
    Title = "Menu",
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(255, 50, 50),
        Text = Color3.fromRGB(255, 50, 50),
        SubText = Color3.fromRGB(255, 255, 255),
        Hover = Color3.fromRGB(40, 40, 40)
    },
    Position = UDim2.new(1, -10, 0, 10), -- Top right with 10px padding
    Size = UDim2.new(0, 200, 0, 30), -- Initial size, will auto-adjust
    Animation = {
        Speed = 0.3,
        EasingStyle = Enum.EasingStyle.Quart,
        EasingDirection = Enum.EasingDirection.Out
    }
}

-- Create the main UI
function UILibrary.new(config)
    local self = {}
    self.Config = config or DEFAULT_CONFIG
    
    -- Apply default values for any missing config options
    for key, value in pairs(DEFAULT_CONFIG) do
        if type(value) == "table" and self.Config[key] then
            for subKey, subValue in pairs(value) do
                if self.Config[key][subKey] == nil then
                    self.Config[key][subKey] = subValue
                end
            end
        elseif self.Config[key] == nil then
            self.Config[key] = value
        end
    end
    
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "UILibrary"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Parent the ScreenGui appropriately
    if game:GetService("RunService"):IsStudio() then
        self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    else
        self.ScreenGui.Parent = game:GetService("CoreGui")
    end
    
    -- Create main frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.BackgroundColor3 = self.Config.Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Position = self.Config.Position
    self.MainFrame.Size = self.Config.Size
    self.MainFrame.AnchorPoint = Vector2.new(1, 0) -- Anchor to top right
    self.MainFrame.Parent = self.ScreenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = self.MainFrame
    
    -- Create title
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "Title"
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    self.TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = self.Config.Title
    self.TitleLabel.TextColor3 = self.Config.Theme.Text
    self.TitleLabel.TextSize = 14
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.MainFrame
    
    -- Create container for menu items
    self.ItemContainer = Instance.new("Frame")
    self.ItemContainer.Name = "ItemContainer"
    self.ItemContainer.BackgroundTransparency = 1
    self.ItemContainer.Position = UDim2.new(0, 0, 0, 30)
    self.ItemContainer.Size = UDim2.new(1, 0, 1, -30)
    self.ItemContainer.Parent = self.MainFrame
    
    -- Add UIListLayout for automatic positioning
    self.ListLayout = Instance.new("UIListLayout")
    self.ListLayout.Padding = UDim.new(0, 8)
    self.ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    self.ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.ListLayout.Parent = self.ItemContainer
    
    -- Add UIPadding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = self.ItemContainer
    
    -- Add right border line
    self.BorderLine = Instance.new("Frame")
    self.BorderLine.Name = "BorderLine"
    self.BorderLine.BackgroundColor3 = self.Config.Theme.Border
    self.BorderLine.BorderSizePixel = 0
    self.BorderLine.Position = UDim2.new(1, -2, 0, 0)
    self.BorderLine.Size = UDim2.new(0, 2, 1, 0)
    self.BorderLine.Parent = self.MainFrame
    
    -- Store menu items
    self.Items = {}
    self.ItemCount = 0
    
    -- Auto-resize function
    function self:UpdateSize()
        local contentHeight = self.ListLayout.AbsoluteContentSize.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset
        local newHeight = contentHeight + 30 -- 30 for title area
        
        -- Animate the size change
        local sizeTween = TweenService:Create(
            self.MainFrame,
            TweenInfo.new(
                self.Config.Animation.Speed,
                self.Config.Animation.EasingStyle,
                self.Config.Animation.EasingDirection
            ),
            {Size = UDim2.new(0, self.MainFrame.Size.X.Offset, 0, newHeight)}
        )
        sizeTween:Play()
    end
    
    -- Connect the auto-resize to the ListLayout's size change
    self.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:UpdateSize()
    end)
    
    -- Add a toggle button
    self.Visible = true
    function self:ToggleVisibility()
        self.Visible = not self.Visible
        local targetPosition
        
        if self.Visible then
            targetPosition = self.Config.Position
        else
            targetPosition = UDim2.new(1, 10, 0, 10) -- Move off screen
        end
        
        local posTween = TweenService:Create(
            self.MainFrame,
            TweenInfo.new(
                self.Config.Animation.Speed,
                self.Config.Animation.EasingStyle,
                self.Config.Animation.EasingDirection
            ),
            {Position = targetPosition}
        )
        posTween:Play()
    end
    
    -- Toggle with right shift key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            self:ToggleVisibility()
        end
    end)
    
    -- Add a new item to the menu
    function self:AddItem(name, options)
        options = options or {}
        self.ItemCount = self.ItemCount + 1
        
        local item = {
            Name = name,
            Status = options.Status or "",
            Enabled = options.Enabled or false,
            Callback = options.Callback or function() end,
            Order = options.Order or self.ItemCount
        }
        
        -- Create the item frame
        item.Frame = Instance.new("Frame")
        item.Frame.Name = name
        item.Frame.BackgroundTransparency = 1
        item.Frame.Size = UDim2.new(1, 0, 0, 24)
        item.Frame.LayoutOrder = item.Order
        item.Frame.Parent = self.ItemContainer
        
        -- Create the item name label
        item.NameLabel = Instance.new("TextLabel")
        item.NameLabel.Name = "NameLabel"
        item.NameLabel.BackgroundTransparency = 1
        item.NameLabel.Position = UDim2.new(0, 0, 0, 0)
        item.NameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        item.NameLabel.Font = Enum.Font.GothamSemibold
        item.NameLabel.Text = name
        item.NameLabel.TextColor3 = self.Config.Theme.Text
        item.NameLabel.TextSize = 14
        item.NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        item.NameLabel.Parent = item.Frame
        
        -- Create the status label
        item.StatusLabel = Instance.new("TextLabel")
        item.StatusLabel.Name = "StatusLabel"
        item.StatusLabel.BackgroundTransparency = 1
        item.StatusLabel.Position = UDim2.new(0.7, 0, 0, 0)
        item.StatusLabel.Size = UDim2.new(0.3, 0, 1, 0)
        item.StatusLabel.Font = Enum.Font.Gotham
        item.StatusLabel.Text = item.Status
        item.StatusLabel.TextColor3 = self.Config.Theme.SubText
        item.StatusLabel.TextSize = 14
        item.StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
        item.StatusLabel.Parent = item.Frame
        
        -- Create the button
        item.Button = Instance.new("TextButton")
        item.Button.Name = "Button"
        item.Button.BackgroundTransparency = 1
        item.Button.Position = UDim2.new(0, 0, 0, 0)
        item.Button.Size = UDim2.new(1, 0, 1, 0)
        item.Button.Font = Enum.Font.SourceSans
        item.Button.Text = ""
        item.Button.TextTransparency = 1
        item.Button.Parent = item.Frame
        
        -- Hover effect
        item.Button.MouseEnter:Connect(function()
            local hoverFrame = Instance.new("Frame")
            hoverFrame.Name = "HoverFrame"
            hoverFrame.BackgroundColor3 = self.Config.Theme.Hover
            hoverFrame.BorderSizePixel = 0
            hoverFrame.Size = UDim2.new(1, 0, 1, 0)
            hoverFrame.ZIndex = -1
            
            local hoverCorner = Instance.new("UICorner")
            hoverCorner.CornerRadius = UDim.new(0, 4)
            hoverCorner.Parent = hoverFrame
            
            hoverFrame.Parent = item.Frame
            
            -- Animate hover effect
            hoverFrame.BackgroundTransparency = 1
            local hoverTween = TweenService:Create(
                hoverFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0}
            )
            hoverTween:Play()
        end)
        
        item.Button.MouseLeave:Connect(function()
            local hoverFrame = item.Frame:FindFirstChild("HoverFrame")
            if hoverFrame then
                local hoverTween = TweenService:Create(
                    hoverFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                )
                hoverTween:Play()
                
                hoverTween.Completed:Connect(function()
                    hoverFrame:Destroy()
                end)
            end
        end)
        
        -- Click effect
        item.Button.MouseButton1Click:Connect(function()
            item.Enabled = not item.Enabled
            
            -- Visual feedback
            local clickEffect = Instance.new("Frame")
            clickEffect.Name = "ClickEffect"
            clickEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            clickEffect.BackgroundTransparency = 0.8
            clickEffect.BorderSizePixel = 0
            clickEffect.Size = UDim2.new(1, 0, 1, 0)
            clickEffect.ZIndex = 2
            
            local clickCorner = Instance.new("UICorner")
            clickCorner.CornerRadius = UDim.new(0, 4)
            clickCorner.Parent = clickEffect
            
            clickEffect.Parent = item.Frame
            
            local clickTween = TweenService:Create(
                clickEffect,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            clickTween:Play()
            
            clickTween.Completed:Connect(function()
                clickEffect:Destroy()
            end)
            
            -- Update text color based on enabled state
            if item.Enabled then
                item.NameLabel.TextColor3 = self.Config.Theme.Text
            else
                item.NameLabel.TextColor3 = Color3.new(
                    self.Config.Theme.Text.R * 0.6,
                    self.Config.Theme.Text.G * 0.6,
                    self.Config.Theme.Text.B * 0.6
                )
            end
            
            -- Call the callback function
            item.Callback(item.Enabled)
        end)
        
        -- Store the item
        self.Items[name] = item
        
        -- Update the size of the menu
        self:UpdateSize()
        
        -- Return the item for chaining
        return item
    end
    
    -- Update an existing item
    function self:UpdateItem(name, options)
        local item = self.Items[name]
        if not item then return nil end
        
        if options.Status ~= nil then
            item.Status = options.Status
            item.StatusLabel.Text = options.Status
        end
        
        if options.Enabled ~= nil then
            item.Enabled = options.Enabled
            
            -- Update text color based on enabled state
            if item.Enabled then
                item.NameLabel.TextColor3 = self.Config.Theme.Text
            else
                item.NameLabel.TextColor3 = Color3.new(
                    self.Config.Theme.Text.R * 0.6,
                    self.Config.Theme.Text.G * 0.6,
                    self.Config.Theme.Text.B * 0.6
                )
            end
        end
        
        if options.Callback then
            item.Callback = options.Callback
        end
        
        if options.Order then
            item.Order = options.Order
            item.Frame.LayoutOrder = options.Order
        end
        
        return item
    end
    
    -- Remove an item
    function self:RemoveItem(name)
        local item = self.Items[name]
        if not item then return false end
        
        -- Animate removal
        local removeTween = TweenService:Create(
            item.Frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 0), Transparency = 1}
        )
        removeTween:Play()
        
        removeTween.Completed:Connect(function()
            item.Frame:Destroy()
            self.Items[name] = nil
            self:UpdateSize()
        end)
        
        return true
    end
    
    -- Change theme
    function self:SetTheme(theme)
        for key, value in pairs(theme) do
            self.Config.Theme[key] = value
        end
        
        -- Update UI elements with new theme
        self.MainFrame.BackgroundColor3 = self.Config.Theme.Background
        self.BorderLine.BackgroundColor3 = self.Config.Theme.Border
        self.TitleLabel.TextColor3 = self.Config.Theme.Text
        
        -- Update all items
        for _, item in pairs(self.Items) do
            item.NameLabel.TextColor3 = self.Config.Theme.Text
            item.StatusLabel.TextColor3 = self.Config.Theme.SubText
        end
    end
    
    -- Show the menu with animation
    function self:Show()
        self.MainFrame.Position = UDim2.new(1, 10, 0, 10) -- Start off screen
        self.MainFrame.Visible = true
        self.Visible = true
        
        local showTween = TweenService:Create(
            self.MainFrame,
            TweenInfo.new(
                self.Config.Animation.Speed,
                self.Config.Animation.EasingStyle,
                self.Config.Animation.EasingDirection
            ),
            {Position = self.Config.Position}
        )
        showTween:Play()
    end
    
    -- Hide the menu with animation
    function self:Hide()
        self.Visible = false
        
        local hideTween = TweenService:Create(
            self.MainFrame,
            TweenInfo.new(
                self.Config.Animation.Speed,
                self.Config.Animation.EasingStyle,
                self.Config.Animation.EasingDirection
            ),
            {Position = UDim2.new(1, 10, 0, 10)} -- Move off screen
        )
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            if not self.Visible then
                self.MainFrame.Visible = false
            end
        end)
    end
    
    -- Initialize with animation
    self:Show()
    
    return self
end

return UILibrary
