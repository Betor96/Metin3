-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> ShopUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") 
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItem = Events:WaitForChild("BuyItem")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- ==========================================
-- ÚJ: TOOLTIP MANAGER BEHÍVÁSA
-- ==========================================
local TooltipManager = require(ReplicatedStorage:WaitForChild("TooltipManager"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame" -- FONTOS AZ ELNEVEZÉS A DRAG & DROP MIATT!
shopFrame.Size = UDim2.new(0, 250, 0, 350)
shopFrame.AnchorPoint = Vector2.new(0, 0.5) 
shopFrame.Position = UDim2.new(0.05, 0, 0.5, 0) 
-- METINESÍTÉS
shopFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10) -- Sötét, rusztikus háttér
shopFrame.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany keret
shopFrame.BorderSizePixel = 2
shopFrame.Active = true
shopFrame.Visible = false 
shopFrame.Parent = screenGui

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 30)
shopTitle.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
shopTitle.BorderColor3 = Color3.fromRGB(180, 140, 50)
shopTitle.BorderSizePixel = 1
shopTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Arany szöveg
shopTitle.Text = "BOLT"
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 14
shopTitle.Active = true 
shopTitle.Parent = shopFrame

-- ABLAK MOZGATÁSA
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

local currentShopNPC = nil
local MAX_SHOP_DISTANCE = 15

-- ==========================================
-- ELADÁS MÓD KAPCSOLÓ
-- ==========================================
local sellMode = Instance.new("BoolValue")
sellMode.Name = "SellMode"
sellMode.Value = false
sellMode.Parent = shopFrame

local sellToggleBtn = Instance.new("TextButton")
sellToggleBtn.Size = UDim2.new(1, -20, 0, 30)
sellToggleBtn.Position = UDim2.new(0, 10, 1, -40)
-- Metinesítés
sellToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
sellToggleBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
sellToggleBtn.BorderSizePixel = 1
sellToggleBtn.TextColor3 = Color3.new(1, 1, 1)
sellToggleBtn.Text = "Eladás Mód: KI"
sellToggleBtn.Font = Enum.Font.GothamBold
sellToggleBtn.Parent = shopFrame

sellToggleBtn.MouseButton1Click:Connect(function()
	sellMode.Value = not sellMode.Value
	if sellMode.Value then
		sellToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		sellToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		sellToggleBtn.Text = "Eladás Mód: BE (Jobb Klikk)"
	else
		sellToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
		sellToggleBtn.TextColor3 = Color3.new(1, 1, 1)
		sellToggleBtn.Text = "Eladás Mód: KI"
	end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
closeBtn.BorderSizePixel = 2
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = shopFrame

local function resetShop()
	shopFrame.Visible = false
	currentShopNPC = nil
	sellMode.Value = false
	sellToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
	sellToggleBtn.TextColor3 = Color3.new(1, 1, 1)
	sellToggleBtn.Text = "Eladás Mód: KI"
	TooltipManager.hide() -- Biztonság kedvéért bezáráskor is elrejtjük
end

closeBtn.MouseButton1Click:Connect(resetShop)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -85) -- Kicsit kisebb, hogy beférjen az Eladás gomb
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
		Items = {
			"Kezdőkard",
			"Hosszúkard",

			-- Kaszt / játékstílus szerinti alap fegyverek
			"Őrző Pallos",      -- Guardian / tankosabb karakternek
			"Árnyék Tőr",       -- Shadowblade / gyors krites karakternek
			"Lélekbot",         -- Soulweaver / Sealer / INT karakternek

			-- Kicsit későbbi fegyverek
			"Metinromboló Kard",
			"Vérivó Kard",
			"Párbajpenge"
		}
	},

	["Pancelkereskedo"] = {
		Title = "PÁNCÉLKERESKEDŐ",
		Items = {
			-- Páncélok
			"Vadfarkas Páncél",
			"Vas Páncél",
			"Őrző Lemezvért",
			"Árnyék Kabát",
			"Lélek Köntös",
			"Sárkány Páncél",

			-- Sisakok / sapkák
			"Bőr Sisak",
			"Harcos Sisak",
			"Árnyék Csuklya",
			"Bölcs Csuklya",

			-- Cipők
			"Bőrcipő",
			"Farkasjáró Csizma",
			"Árnylépő Csizma",

			-- Pajzsok
			"Fa Pajzs",
			"Vas Pajzs",
			"Metin Pajzs",
			"Párbaj Pajzs",

			-- Nyakláncok
			"Réz Nyaklánc",
			"Vadász Nyaklánc",
			"Rubin Nyaklánc",
			"Hold Nyaklánc",

			-- Karkötők
			"Bőr Karkötő",
			"Vadász Karkötő",
			"Vér Karkötő",
			"Párbaj Karkötő",

			-- Fülbevalók
			"Ezüst Fülbevaló",
			"Harcos Fülbevaló",
			"Árny Fülbevaló",
			"Lélek Fülbevaló"
		}
	},

	["Vegyesbolt"] = {
		Title = "VEGYESBOLT",
		Items = {
			-- Italok
			"Életerő Ital",
			"Nagy Életerő Ital",
			"Mana Ital",
			"Nagy Mana Ital",

			-- Buff italok
			"Zöld Ital",
			"Ügyesség itala",
			"Kritikus Ital",
			"Vadász Ital",
			"Metinromboló Ital",

			-- Csákány maradjon itt
			"Csákány+0"
		}
	}
}

-- ==========================================
-- JAVÍTÁS: TOOLTIP GENERÁLÓ A BOLTOSHOZ IS!
-- ==========================================
local function getTooltipDataForItem(itemName)
	local data = ItemDatabase[itemName]
	if not data then return nil end

	local toolData = {
		Name = itemName,
		Icon = "rbxassetid://0",
	}

	if data.Type == "Fegyver" then
		toolData.Active = "Szintkövetelmény: " .. (data.Level or 1)
		toolData.Passive = string.format("Sebzés: <font color='rgb(255,100,50)'>%d - %d</font>", data.MinDmg or 0, data.MaxDmg or 0)

	elseif data.Type == "Páncél" then
		toolData.Active = "Szintkövetelmény: " .. (data.Level or 1)
		toolData.Passive = string.format("Védelem: <font color='rgb(50,150,255)'>+%d Páncél</font>", data.Defense or 0)

	elseif data.Type == "Fogyóeszköz" then
		toolData.Active = "Nyomd meg a gombot vagy kattints duplán a használathoz."
	end

	if data.Description then
		toolData.Passive = (toolData.Passive and (toolData.Passive .. "\n\n") or "") .. "<i>" .. data.Description .. "</i>"
	end

	if data.Price then
		toolData.BottomStats = {{"Vételár", (data.Price) .. " Pénz"}}
	end

	return toolData
end

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
			itemRow.BackgroundColor3 = Color3.fromRGB(20, 18, 15) -- Metines belső
			itemRow.BorderColor3 = Color3.fromRGB(180, 140, 50)
			itemRow.BorderSizePixel = 1
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
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
			buyBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
			buyBtn.BorderSizePixel = 1
			buyBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
			buyBtn.Text = itemData.Price .. " Pénz"
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 12
			buyBtn.Parent = itemRow

			buyBtn.MouseButton1Click:Connect(function() BuyItem:FireServer(itemName) end)

			-- ÚJ: TOOLTIP MEGJELENÍTÉSE A TÁRGY FÖLÖTT!
			itemRow.MouseEnter:Connect(function()
				local tData = getTooltipDataForItem(itemName)
				if tData then TooltipManager.show(tData) end
			end)
			itemRow.MouseLeave:Connect(function() TooltipManager.hide() end)
		end
	end

	shopFrame.Visible = true
	screenGui.DisplayOrder = 100
end

local function setupNPCs()
	local npcFolder = workspace:FindFirstChild("NPCs")

	for npcName, _ in pairs(SHOPS) do
		-- Keresés az új NPCs mappában (ha nincs ott, megnézi a Workspace-t tartalékként)
		local npc = nil
		if npcFolder then
			npc = npcFolder:FindFirstChild(npcName)
		end
		if not npc then
			npc = workspace:FindFirstChild(npcName)
		end

		if npc then
			local clickDetector = npc:FindFirstChildOfClass("ClickDetector")
			if clickDetector then
				clickDetector.MouseClick:Connect(function()
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("HumanoidRootPart") then
						local dist = (char.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
						if dist > MAX_SHOP_DISTANCE then return end
					end

					currentShopNPC = npc
					openShop(npcName)
				end)
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	if shopFrame.Visible and currentShopNPC then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and currentShopNPC:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - currentShopNPC.HumanoidRootPart.Position).Magnitude
			if dist > MAX_SHOP_DISTANCE then
				resetShop()
			end
		else
			resetShop()
		end
	end
end)

-- Figyeljük az új NPCs mappát is, hátha később tölt be egy boltos!
local npcFolder = workspace:WaitForChild("NPCs", 5)
if npcFolder then
	npcFolder.ChildAdded:Connect(function(child)
		if SHOPS[child.Name] then task.wait(0.5) setupNPCs() end
	end)
end

-- Eredeti workspace figyelő tartaléknak
workspace.ChildAdded:Connect(function(child)
	if SHOPS[child.Name] then task.wait(0.5) setupNPCs() end
end)

setupNPCs()