-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> EffectUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ApplyEffect = Events:WaitForChild("ApplyEffect")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local effectGui = Instance.new("ScreenGui")
effectGui.Name = "EffectHUD"
effectGui.ResetOnSpawn = false
-- JAVÍTÁS: Lekényszerítjük a 0-ás rétegre, így az ablakok MINDIG elé ugranak!
effectGui.DisplayOrder = 0 
effectGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 300, 0, 35)
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -120) 
container.BackgroundTransparency = 1
container.Parent = effectGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 5)
layout.Parent = container

local activeEffects = {}

ApplyEffect.OnClientEvent:Connect(function(itemName, effectType, value, duration)
	if activeEffects[effectType] then
		activeEffects[effectType].TimeLeft = duration
		return
	end

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 30, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(20, 50, 100)
	box.BorderColor3 = Color3.fromRGB(100, 200, 255)
	box.BorderSizePixel = 1
	box.Parent = container

	local shortName = string.sub(effectType, 1, 3)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	titleLabel.Text = shortName
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 9
	titleLabel.Parent = box

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, 0, 1, -12)
	timeLabel.Position = UDim2.new(0, 0, 0, 12)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.new(1, 1, 1)
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextSize = 11
	timeLabel.TextStrokeTransparency = 0
	timeLabel.Parent = box

	local tooltip = Instance.new("TextLabel")
	tooltip.Size = UDim2.new(0, 140, 0, 35)
	tooltip.Position = UDim2.new(0.5, -70, 0, -40) 
	tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tooltip.TextColor3 = Color3.new(1, 1, 1)
	tooltip.BorderColor3 = Color3.fromRGB(100, 80, 50)
	tooltip.BorderSizePixel = 2
	tooltip.Text = itemName .. "\n+" .. value .. " " .. effectType
	tooltip.Font = Enum.Font.Gotham
	tooltip.TextSize = 11
	tooltip.ZIndex = 10
	tooltip.Visible = false
	tooltip.Parent = box

	box.MouseEnter:Connect(function() tooltip.Visible = true end)
	box.MouseLeave:Connect(function() tooltip.Visible = false end)

	activeEffects[effectType] = {TimeLeft = duration, UI = box}

	task.spawn(function()
		while activeEffects[effectType] and activeEffects[effectType].TimeLeft > 0 do
			timeLabel.Text = activeEffects[effectType].TimeLeft .. "s"
			task.wait(1)
			if activeEffects[effectType] then
				activeEffects[effectType].TimeLeft -= 1
			end
		end

		if activeEffects[effectType] then
			activeEffects[effectType].UI:Destroy()
			activeEffects[effectType] = nil
		end
	end)
end)