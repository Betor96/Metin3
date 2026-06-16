local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local stats = player:WaitForChild("PlayerStats")

local Events = ReplicatedStorage:WaitForChild("Events")
local AddStatPoint = Events:WaitForChild("AddStatPoint")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterWindow"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 300)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true -- Felfogja az egérkattintásokat
mainFrame.Visible = false
mainFrame.Parent = screenGui



local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "KARAKTER (C)"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Active = true -- FONTOS
titleLabel.Parent = mainFrame

-- ==========================================
-- ABLAK MOZGATÁSA CSAK A CÍMSORRÓL
-- ==========================================
local draggingChar, dragInputChar, mousePosChar, framePosChar

titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingChar = true
		mousePosChar = input.Position
		framePosChar = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then draggingChar = false end
		end)
	end
end)

titleLabel.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputChar = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputChar and draggingChar then
		local delta = input.Position - mousePosChar
		mainFrame.Position = UDim2.new(framePosChar.X.Scale, framePosChar.X.Offset + delta.X, framePosChar.Y.Scale, framePosChar.Y.Offset + delta.Y)
	end
end)

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.new(1, 0, 0, 30)
pointsLabel.Position = UDim2.new(0, 0, 0, 45)
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
pointsLabel.Text = "Elosztható pontok: 0"
pointsLabel.Font = Enum.Font.Gotham
pointsLabel.TextSize = 16
pointsLabel.Parent = mainFrame

local function createStatRow(statId, displayName, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 40)
	row.Position = UDim2.new(0, 10, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent = mainFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = displayName .. ":"
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.2, 0, 1, 0)
	valLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.TextColor3 = Color3.new(1, 1, 1)
	valLabel.Text = "1"
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 18
	valLabel.Parent = row

	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 30, 0, 30)
	plusBtn.Position = UDim2.new(0.85, 0, 0.5, -15)
	plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	plusBtn.TextColor3 = Color3.new(1, 1, 1)
	plusBtn.Text = "+"
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 20
	plusBtn.Parent = row

	plusBtn.MouseButton1Click:Connect(function()
		AddStatPoint:FireServer(statId)
	end)

	return valLabel
end

local vitValue = createStatRow("VIT", "VIT (Életerő)", 90)
local intValue = createStatRow("INT", "INT (Mágia)", 135)
local strValue = createStatRow("STR", "STR (Erő)", 180)
local dexValue = createStatRow("DEX", "DEX (Ügyesség)", 225)

local function updateUI()
	pointsLabel.Text = "Elosztható pontok: " .. stats.StatPoints.Value
	vitValue.Text = tostring(stats.VIT.Value)
	intValue.Text = tostring(stats.INT.Value)
	strValue.Text = tostring(stats.STR.Value)
	dexValue.Text = tostring(stats.DEX.Value)
end

stats.StatPoints.Changed:Connect(updateUI)
stats.VIT.Changed:Connect(updateUI)
stats.INT.Changed:Connect(updateUI)
stats.STR.Changed:Connect(updateUI)
stats.DEX.Changed:Connect(updateUI)

updateUI()



-- ==========================================
-- ABLAK ELŐTÉRBE HOZÁSA KATTINTÁSKOR
-- ==========================================
mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local highest = 0
		for _, gui in pairs(player.PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= screenGui then
				if gui.DisplayOrder > highest then
					highest = gui.DisplayOrder
				end
			end
		end
		screenGui.DisplayOrder = highest + 1
	end
end)

-- ==========================================
-- BEZÁRÓ "X" GOMB LÉTREHOZÁSA
-- ==========================================
local charCloseBtn = Instance.new("TextButton")
charCloseBtn.Size = UDim2.new(0, 30, 0, 30)
charCloseBtn.Position = UDim2.new(1, -5, 0, 5) -- Jobb felső sarok pici margóval
charCloseBtn.AnchorPoint = Vector2.new(1, 0)
charCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30) -- Pirosas háttér
charCloseBtn.BorderColor3 = Color3.fromRGB(80, 20, 20)
charCloseBtn.BorderSizePixel = 2
charCloseBtn.Text = "X"
charCloseBtn.TextColor3 = Color3.new(1, 1, 1)
charCloseBtn.Font = Enum.Font.GothamBold
charCloseBtn.TextSize = 14
charCloseBtn.Parent = mainFrame -- A karakter ablakhoz csatoljuk

charCloseBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)