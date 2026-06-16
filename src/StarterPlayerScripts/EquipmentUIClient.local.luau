-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> EquipmentUIClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EquipmentHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local eqFrame = Instance.new("Frame")
eqFrame.Size = UDim2.new(0, 260, 0, 360)
eqFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
eqFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
eqFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
eqFrame.BorderColor3 = Color3.fromRGB(80, 60, 40)
eqFrame.BorderSizePixel = 3
eqFrame.Active = true 
eqFrame.Visible = false
eqFrame.Parent = screenGui

local eqTitle = Instance.new("TextLabel")
eqTitle.Size = UDim2.new(1, 0, 0, 30)
eqTitle.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
eqTitle.TextColor3 = Color3.new(1, 1, 1)
eqTitle.Text = "FELSZERELÉS (E)"
eqTitle.Font = Enum.Font.GothamBold
eqTitle.TextSize = 14
eqTitle.Active = true 
eqTitle.Parent = eqFrame

-- Ablak mozgatása
local draggingEq, dragInputEq, mousePosEq, framePosEq

eqTitle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingEq = true
		mousePosEq = input.Position
		framePosEq = eqFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then draggingEq = false end
		end)
	end
end)

eqTitle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputEq = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputEq and draggingEq then
		local delta = input.Position - mousePosEq
		eqFrame.Position = UDim2.new(framePosEq.X.Scale, framePosEq.X.Offset + delta.X, framePosEq.Y.Scale, framePosEq.Y.Offset + delta.Y)
	end
end)

local silhouette = Instance.new("TextLabel")
silhouette.Size = UDim2.new(0, 100, 0, 260)
silhouette.Position = UDim2.new(0.5, -50, 0.5, -110)
silhouette.BackgroundTransparency = 1
silhouette.TextColor3 = Color3.fromRGB(50, 50, 50)
silhouette.Text = "[Karakter\nHelye]"
silhouette.Font = Enum.Font.GothamBold
silhouette.TextSize = 16
silhouette.Parent = eqFrame

local function createSlot(parent, name, posX, posY, sizeY)
	local slot = Instance.new("Frame")
	slot.Name = name
	slot.Size = UDim2.new(0, 40, 0, sizeY or 40)
	slot.Position = UDim2.new(0, posX, 0, posY)
	slot.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	slot.BorderColor3 = Color3.fromRGB(100, 80, 50)
	slot.BorderSizePixel = 2
	slot.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(100, 100, 100)
	label.Text = name
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Parent = slot
	return slot
end

createSlot(eqFrame, "Sapka", 110, 45)
createSlot(eqFrame, "Páncél", 110, 140, 60)
createSlot(eqFrame, "Cipő", 110, 290)
createSlot(eqFrame, "Fegyver", 35, 90, 80)
createSlot(eqFrame, "Fülbevaló", 185, 45)
createSlot(eqFrame, "Nyaklánc", 185, 95)
createSlot(eqFrame, "Pajzs", 185, 145)
createSlot(eqFrame, "Karkötő", 185, 195)

-- ==========================================
-- JAVÍTOTT Z-INDEX KEZELÉS
-- ==========================================
eqFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local highest = 0
		for _, gui in pairs(player.PlayerGui:GetChildren()) do
			-- BIZTONSÁG: A TooltipHUD kivétele a versenyből!
			if gui:IsA("ScreenGui") and gui ~= screenGui and gui.Name ~= "TooltipHUD" then
				if gui.DisplayOrder > highest then
					highest = gui.DisplayOrder
				end
			end
		end
		screenGui.DisplayOrder = highest + 1
	end
end)

-- Bezáró gomb
local eqCloseBtn = Instance.new("TextButton")
eqCloseBtn.Size = UDim2.new(0, 30, 0, 30)
eqCloseBtn.Position = UDim2.new(1, -5, 0, 5)
eqCloseBtn.AnchorPoint = Vector2.new(1, 0)
eqCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
eqCloseBtn.BorderColor3 = Color3.fromRGB(80, 20, 20)
eqCloseBtn.BorderSizePixel = 2
eqCloseBtn.Text = "X"
eqCloseBtn.TextColor3 = Color3.new(1, 1, 1)
eqCloseBtn.Font = Enum.Font.GothamBold
eqCloseBtn.TextSize = 14
eqCloseBtn.Parent = eqFrame 

eqCloseBtn.MouseButton1Click:Connect(function()
	eqFrame.Visible = false
end)