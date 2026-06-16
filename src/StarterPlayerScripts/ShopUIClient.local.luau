-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> ShopUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItem = Events:WaitForChild("BuyItem")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 250, 0, 350)
shopFrame.AnchorPoint = Vector2.new(0, 0.5) -- FIX: Bal-közép horgony
shopFrame.Position = UDim2.new(0.05, 0, 0.5, 0) -- FIX: Bal oldalon középen (a karakter ablakkal egy helyen)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
shopFrame.BorderColor3 = Color3.fromRGB(100, 80, 50)
shopFrame.BorderSizePixel = 3
shopFrame.Active = true
shopFrame.Visible = false 
shopFrame.Parent = screenGui

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 30)
shopTitle.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
shopTitle.TextColor3 = Color3.new(1, 1, 1)
shopTitle.Text = "BOLT"
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 14
shopTitle.Active = true -- FONTOS (húzáshoz)
shopTitle.Parent = shopFrame

-- ==========================================
-- ABLAK MOZGATÁSA CSAK A CÍMSORRÓL (ÚJ!)
-- ==========================================
local UserInputService = game:GetService("UserInputService")
local draggingShop, dragInputShop, mousePosShop, framePosShop

shopTitle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingShop = true
		mousePosShop = input.Position
		framePosShop = shopFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then draggingShop = false end
		end)
	end
end)

shopTitle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputShop = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputShop and draggingShop then
		local delta = input.Position - mousePosShop
		shopFrame.Position = UDim2.new(framePosShop.X.Scale, framePosShop.X.Offset + delta.X, framePosShop.Y.Scale, framePosShop.Y.Offset + delta.Y)
	end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = shopFrame

closeBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = shopFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(1, -10, 0, 50)
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

local SHOPS = {
	["Fegyverkereskedo"] = {
		Title = "FEGYVERKERESKEDŐ",
		Items = {"Kezdőkard", "Hosszúkard","Szabi farka"}
	},
	["Pancelkereskedo"] = {
		Title = "PÁNCÉLKERESKEDŐ",
		Items = {"Vadfarkas Páncél", "Vas Páncél"}
	},
	["Vegyesbolt"] = {
		Title = "VEGYESBOLT",
		Items = {"Életerő Ital", "Mana Ital"}
	}
}

local function openShop(npcName)
	local shopData = SHOPS[npcName]
	if not shopData then return end

	shopTitle.Text = shopData.Title

	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, itemName in ipairs(shopData.Items) do
		local itemData = ItemDatabase[itemName]

		if itemData then
			local itemRow = Instance.new("Frame")
			itemRow.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
			itemRow.BorderColor3 = Color3.fromRGB(80, 80, 80)
			itemRow.Parent = scrollFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Text = itemName 
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 12
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemRow

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0.4, 0, 0.6, 0)
			buyBtn.Position = UDim2.new(0.55, 0, 0.2, 0)
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
			buyBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
			buyBtn.Text = itemData.Price .. " Pénz"
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 12
			buyBtn.Parent = itemRow

			buyBtn.MouseButton1Click:Connect(function()
				BuyItem:FireServer(itemName)
			end)
		end
	end

	shopFrame.Visible = true
	screenGui.DisplayOrder = 100
end

local function setupNPCs()
	for npcName, _ in pairs(SHOPS) do
		local npc = workspace:FindFirstChild(npcName)
		if npc then
			local clickDetector = npc:FindFirstChildOfClass("ClickDetector")
			if clickDetector then
				clickDetector.MouseClick:Connect(function()
					openShop(npcName)
				end)
			end
		end
	end
end

workspace.ChildAdded:Connect(function(child)
	if SHOPS[child.Name] then
		task.wait(0.5)
		setupNPCs()
	end
end)
setupNPCs()