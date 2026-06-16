-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> InventoryUIClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local invFrame = Instance.new("Frame")
invFrame.Size = UDim2.new(0, 200, 0, 360)
invFrame.AnchorPoint = Vector2.new(1, 0.5) -- FIX: Jobb-közép horgony
invFrame.Position = UDim2.new(0.95, 0, 0.5, 0) -- FIX: Jobb oldalon középen
invFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
invFrame.BorderColor3 = Color3.fromRGB(80, 60, 40)
invFrame.BorderSizePixel = 3
invFrame.Active = true 
invFrame.Visible = false 
invFrame.Parent = screenGui

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 30)
invTitle.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
invTitle.TextColor3 = Color3.new(1, 1, 1)
invTitle.Text = "TÁSKA (B)"
invTitle.Font = Enum.Font.GothamBold
invTitle.TextSize = 14
invTitle.Active = true 
invTitle.Parent = invFrame

local draggingInv, dragInputInv, mousePosInv, framePosInv

invTitle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingInv = true
		mousePosInv = input.Position
		framePosInv = invFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then draggingInv = false end
		end)
	end
end)

invTitle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputInv = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputInv and draggingInv then
		local delta = input.Position - mousePosInv
		invFrame.Position = UDim2.new(framePosInv.X.Scale, framePosInv.X.Offset + delta.X, framePosInv.Y.Scale, framePosInv.Y.Offset + delta.Y)
	end
end)

local goldContainer = Instance.new("Frame")
goldContainer.Size = UDim2.new(1, -10, 0, 30)
goldContainer.Position = UDim2.new(0, 5, 1, -35)
goldContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
goldContainer.BorderColor3 = Color3.fromRGB(100, 80, 50)
goldContainer.BorderSizePixel = 1
goldContainer.Parent = invFrame

local goldLabel = Instance.new("TextLabel")
goldLabel.Size = UDim2.new(1, -10, 1, 0)
goldLabel.Position = UDim2.new(0, 5, 0, 0)
goldLabel.BackgroundTransparency = 1
goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0) 
goldLabel.Text = "Pénz: 0"
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextSize = 14
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
goldLabel.Parent = goldContainer

local stats = player:WaitForChild("PlayerStats")
local goldStat = stats:WaitForChild("Gold")

local function updateGold()
	goldLabel.Text = "Pénz: " .. goldStat.Value
end

goldStat.Changed:Connect(updateGold)
updateGold() 

local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(1, -20, 1, -85) 
gridFrame.Position = UDim2.new(0, 10, 0, 40)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = invFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 40, 0, 40)
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = gridFrame

for i = 1, 8 do
	local invSlot = Instance.new("Frame")
	invSlot.Name = "InvSlot_" .. i
	invSlot.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	invSlot.BorderColor3 = Color3.fromRGB(100, 80, 50)
	invSlot.BorderSizePixel = 2
	invSlot.Parent = gridFrame
end

invFrame.InputBegan:Connect(function(input)
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

local invCloseBtn = Instance.new("TextButton")
invCloseBtn.Size = UDim2.new(0, 30, 0, 30)
invCloseBtn.Position = UDim2.new(1, -5, 0, 5)
invCloseBtn.AnchorPoint = Vector2.new(1, 0)
invCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
invCloseBtn.BorderColor3 = Color3.fromRGB(80, 20, 20)
invCloseBtn.BorderSizePixel = 2
invCloseBtn.Text = "X"
invCloseBtn.TextColor3 = Color3.new(1, 1, 1)
invCloseBtn.Font = Enum.Font.GothamBold
invCloseBtn.TextSize = 14
invCloseBtn.Parent = invFrame 

invCloseBtn.MouseButton1Click:Connect(function()
	invFrame.Visible = false
end)