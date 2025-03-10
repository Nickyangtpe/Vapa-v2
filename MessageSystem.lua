-- ResponsiveMessageSystem.lua
-- 自動適應螢幕大小的訊息系統

local MessageSystem = {}

-- 服務
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-- 常數
local MESSAGE_DURATION = 5 -- 秒
local MESSAGE_TYPES = {
	INFO = {
		ICON = "rbxassetid://9072944922", -- 資訊圖示
		COLOR = Color3.fromRGB(255, 255, 255),
		BAR_COLOR = Color3.fromRGB(255, 255, 255)
	},
	WARNING = {
		ICON = "rbxassetid://9072944869", -- 警告圖示
		COLOR = Color3.fromRGB(255, 165, 0),
		BAR_COLOR = Color3.fromRGB(255, 120, 0)
	}
}

-- 變數
local player = Players.LocalPlayer

-- 創建響應式 ScreenGui
local function setupGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MessageSystem"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true -- 忽略 GUI 插入，使其覆蓋整個螢幕
	
	-- 獲取螢幕尺寸
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local insetTop = GuiService:GetGuiInset().Y
	
	-- 創建一個響應式容器
	local messageContainer = Instance.new("Frame")
	messageContainer.Name = "MessageContainer"
	messageContainer.BackgroundTransparency = 1
	messageContainer.Position = UDim2.new(1, -20, 0, 20 + insetTop) -- 考慮頂部插入
	messageContainer.Size = UDim2.new(0, math.min(350, viewportSize.X * 0.3), 1, -40) -- 根據螢幕寬度調整大小
	messageContainer.AnchorPoint = Vector2.new(1, 0)
	messageContainer.Parent = screenGui
	
	-- 創建一個 UIScale 以便根據螢幕大小進行縮放
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = math.clamp(viewportSize.X / 1920, 0.8, 1.2) -- 根據螢幕寬度調整縮放比例
	uiScale.Parent = messageContainer
	
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	uiListLayout.Parent = messageContainer
	
	-- 監聽螢幕大小變化
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local newViewportSize = workspace.CurrentCamera.ViewportSize
		messageContainer.Size = UDim2.new(0, math.min(350, newViewportSize.X * 0.3), 1, -40)
		uiScale.Scale = math.clamp(newViewportSize.X / 1920, 0.8, 1.2)
	end)
	
	return screenGui, messageContainer
end

-- 創建訊息框架
local function createMessageFrame(title, message, messageType)
	local msgType = MESSAGE_TYPES[messageType] or MESSAGE_TYPES.INFO
	
	-- 主框架
	local frame = Instance.new("Frame")
	frame.Name = "Message"
	frame.Size = UDim2.new(1, 0, 0, 0) -- 將根據內容調整大小
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	
	-- 圓角
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = frame
	
	-- 黑色覆蓋效果
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 2
	overlay.Parent = frame
	
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 6)
	overlayCorner.Parent = overlay
	
	-- 圖示
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 12, 0, 12)
	icon.BackgroundTransparency = 1
	icon.Image = msgType.ICON
	icon.ImageColor3 = msgType.COLOR
	icon.ZIndex = 3
	icon.Parent = frame
	
	-- 標題
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 0, 24)
	titleLabel.Position = UDim2.new(0, 48, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.ZIndex = 3
	titleLabel.Parent = frame
	
	-- 訊息
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -24, 0, 0) -- 高度將被調整
	messageLabel.Position = UDim2.new(0, 12, 0, 48)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextSize = 14
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.RichText = true -- 支援富文本
	messageLabel.Text = message
	messageLabel.ZIndex = 3
	messageLabel.Parent = frame
	
	-- 根據文本內容調整訊息高度
	local textSize = game:GetService("TextService"):GetTextSize(
		message:gsub("<[^>]+>", ""), -- 移除富文本標籤以獲得正確的文本大小
		14,
		Enum.Font.Gotham,
		Vector2.new(frame.AbsoluteSize.X - 24, 1000)
	)
	messageLabel.Size = UDim2.new(1, -24, 0, textSize.Y + 10)
	
	-- 進度條
	local progressBarContainer = Instance.new("Frame")
	progressBarContainer.Name = "ProgressBarContainer"
	progressBarContainer.Size = UDim2.new(1, 0, 0, 4)
	progressBarContainer.Position = UDim2.new(0, 0, 1, -4)
	progressBarContainer.BackgroundTransparency = 1
	progressBarContainer.ZIndex = 3
	progressBarContainer.Parent = frame
	
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.BackgroundColor3 = msgType.BAR_COLOR
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 3
	progressBar.Parent = progressBarContainer
	
	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 2)
	progressBarCorner.Parent = progressBar
	
	-- 根據內容調整框架高度
	frame.Size = UDim2.new(1, 0, 0, messageLabel.Position.Y.Offset + messageLabel.Size.Y.Offset + 12)
	
	-- 確保文本在框架大小變化時重新計算
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local newTextSize = game:GetService("TextService"):GetTextSize(
			message:gsub("<[^>]+>", ""),
			14,
			Enum.Font.Gotham,
			Vector2.new(frame.AbsoluteSize.X - 24, 1000)
		)
		messageLabel.Size = UDim2.new(1, -24, 0, newTextSize.Y + 10)
		frame.Size = UDim2.new(1, 0, 0, messageLabel.Position.Y.Offset + messageLabel.Size.Y.Offset + 12)
	end)
	
	return frame, progressBar
end

-- 顯示訊息
function MessageSystem:Show(title, message, messageType)
	-- 如果尚未初始化 GUI，則進行初始化
	if not self.ScreenGui then
		self.ScreenGui, self.Container = setupGui()
		self.ScreenGui.Parent = player.PlayerGui
	end
	
	-- 創建訊息框架
	local messageFrame, progressBar = createMessageFrame(title, message, messageType)
	messageFrame.Parent = self.Container
	
	-- 設置初始透明度和位置
	messageFrame.Position = UDim2.new(1, 0, 0, 0)
	messageFrame.BackgroundTransparency = 1
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	
	-- 動畫進入
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tweenIn = TweenService:Create(messageFrame, tweenInfo, {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0.2
	})
	tweenIn:Play()
	
	-- 進度條動畫
	local progressTweenInfo = TweenInfo.new(MESSAGE_DURATION, Enum.EasingStyle.Linear)
	local progressTween = TweenService:Create(progressBar, progressTweenInfo, {
		Size = UDim2.new(0, 0, 1, 0)
	})
	progressTween:Play()
	
	-- 安排移除
	task.delay(MESSAGE_DURATION, function()
		local tweenOut = TweenService:Create(messageFrame, tweenInfo, {
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		})
		tweenOut:Play()
		
		tweenOut.Completed:Connect(function()
			messageFrame:Destroy()
		end)
	end)
	
	return messageFrame
end

-- 顯示資訊訊息
function MessageSystem:Info(title, message)
	return self:Show(title, message, "INFO")
end

-- 顯示警告訊息
function MessageSystem:Warning(title, message)
	return self:Show(title, message, "WARNING")
end

-- 設置訊息持續時間
function MessageSystem:SetDuration(duration)
	MESSAGE_DURATION = duration
end

return MessageSystem
