-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> MenuButtonsClient

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SystemMenuHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2
screenGui.Parent = playerGui

local menuContainer = Instance.new("Frame")
menuContainer.AnchorPoint = Vector2.new(1, 1) -- FIX: Jobb alsó horgony
menuContainer.Position = UDim2.new(1, -20, 1, -20) -- FIX: A Hotbar és HP sáv vonalában
menuContainer.Size = UDim2.new(0, 300, 0, 35) 
menuContainer.BackgroundTransparency = 1
menuContainer.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal 
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right 
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = menuContainer

local function createMenuButton(title, hotkeyStr, action)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(20, 15, 15)
	btn.BorderColor3 = Color3.fromRGB(100, 30, 30)
	btn.BorderSizePixel = 2
	btn.Text = title
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = menuContainer

	local hotkeyLabel = Instance.new("TextLabel")
	hotkeyLabel.Size = UDim2.new(0, 15, 0, 15)
	hotkeyLabel.Position = UDim2.new(0, 2, 0, 2)
	hotkeyLabel.BackgroundTransparency = 1
	hotkeyLabel.Text = hotkeyStr
	hotkeyLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	hotkeyLabel.Font = Enum.Font.GothamBlack
	hotkeyLabel.TextSize = 10
	hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Left
	hotkeyLabel.TextYAlignment = Enum.TextYAlignment.Top
	hotkeyLabel.Parent = btn

	btn.MouseButton1Click:Connect(action)
	return btn
end

local function toggleFrame(guiName)
	local gui = playerGui:FindFirstChild(guiName)
	if gui then
		local mainFrame = gui:FindFirstChild("MainFrame") or gui:FindFirstChildOfClass("Frame")
		if mainFrame then
			mainFrame.Visible = not mainFrame.Visible
		end
	end
end

createMenuButton("Karakter", "C", function() toggleFrame("CharacterWindow") end)
createMenuButton("Táska", "B", function() toggleFrame("InventoryHUD") end)
createMenuButton("Felszerelés", "E", function() toggleFrame("EquipmentHUD") end)

UIS.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if input.KeyCode == Enum.KeyCode.C then
		toggleFrame("CharacterWindow")
	elseif input.KeyCode == Enum.KeyCode.B then
		toggleFrame("InventoryHUD")
	elseif input.KeyCode == Enum.KeyCode.E then
		toggleFrame("EquipmentHUD")
	end
end)