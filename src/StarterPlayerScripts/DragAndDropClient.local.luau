-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> DragAndDropClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Camera = workspace.CurrentCamera 

local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")
local ProcessUpgrade = Events:WaitForChild("ProcessUpgrade")
local UpgradeResult = Events:WaitForChild("UpgradeResult")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local invFolder = player:WaitForChild("Inventory")
local eqFolder = player:WaitForChild("Equipment")
local invHud = playerGui:WaitForChild("InventoryHUD")
local eqHud = playerGui:WaitForChild("EquipmentHUD")

local eqNameToServer = {
	["Sapka"] = "Sapka", ["Páncél"] = "Pancel", ["Cipő"] = "Cipo", 
	["Fegyver"] = "Fegyver", ["Fülbevaló"] = "Fulbevalo", ["Nyaklánc"] = "Nyaklanc", 
	["Pajzs"] = "Pajzs", ["Karkötő"] = "Karkoto"
}

-- ==========================================
-- KOVÁCS (UPGRADE) FELÜLET
-- ==========================================
local bsFrame = Instance.new("Frame")
bsFrame.Size = UDim2.new(0, 250, 0, 200)
bsFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
bsFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
bsFrame.BorderColor3 = Color3.fromRGB(150, 100, 50)
bsFrame.BorderSizePixel = 3
bsFrame.Active = true
bsFrame.Visible = false
bsFrame.ZIndex = 50
bsFrame.Parent = invHud

local bsTitle = Instance.new("TextLabel")
bsTitle.Size = UDim2.new(1, 0, 0, 30)
bsTitle.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
bsTitle.TextColor3 = Color3.new(1, 1, 1)
bsTitle.Text = "KOVÁCS"
bsTitle.Font = Enum.Font.GothamBold
bsTitle.ZIndex = 51
bsTitle.Parent = bsFrame

local bsInfo = Instance.new("TextLabel")
bsInfo.Size = UDim2.new(1, -20, 1, -80)
bsInfo.Position = UDim2.new(0, 10, 0, 40)
bsInfo.BackgroundTransparency = 1
bsInfo.TextColor3 = Color3.new(1, 1, 1)
bsInfo.Font = Enum.Font.Gotham
bsInfo.TextSize = 14
bsInfo.ZIndex = 51
bsInfo.Parent = bsFrame

local bsYesBtn = Instance.new("TextButton")
bsYesBtn.Size = UDim2.new(0, 100, 0, 30)
bsYesBtn.Position = UDim2.new(0, 15, 1, -40)
bsYesBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
bsYesBtn.TextColor3 = Color3.new(1, 1, 1)
bsYesBtn.Text = "Fejlesztés"
bsYesBtn.Font = Enum.Font.GothamBold
bsYesBtn.ZIndex = 51
bsYesBtn.Parent = bsFrame

local bsNoBtn = Instance.new("TextButton")
bsNoBtn.Size = UDim2.new(0, 100, 0, 30)
bsNoBtn.Position = UDim2.new(1, -115, 1, -40)
bsNoBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
bsNoBtn.TextColor3 = Color3.new(1, 1, 1)
bsNoBtn.Text = "Mégse"
bsNoBtn.Font = Enum.Font.GothamBold
bsNoBtn.ZIndex = 51
bsNoBtn.Parent = bsFrame

local currentUpgradeSlot = {Folder = nil, Slot = nil}

bsNoBtn.MouseButton1Click:Connect(function() bsFrame.Visible = false end)

bsYesBtn.MouseButton1Click:Connect(function()
	if currentUpgradeSlot.Folder and currentUpgradeSlot.Slot then
		ProcessUpgrade:FireServer(currentUpgradeSlot.Folder, currentUpgradeSlot.Slot)
		bsFrame.Visible = false
	end
end)

UpgradeResult.OnClientEvent:Connect(function(msg)
	bsTitle.Text = msg
	bsFrame.Visible = true
	bsYesBtn.Visible = false
	bsNoBtn.Text = "Rendben"
	task.wait(2.5)
	bsFrame.Visible = false
	bsTitle.Text = "KOVÁCS"
	bsYesBtn.Visible = true
	bsNoBtn.Text = "Mégse"
end)

-- ==========================================
-- TOOLTIP RENDSZER
-- ==========================================
local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 200, 0, 100)
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tooltip.BorderColor3 = Color3.fromRGB(100, 80, 50)
tooltip.BorderSizePixel = 2
tooltip.ZIndex = 999 
tooltip.Visible = false
tooltip.Parent = invHud

local tooltipTitle = Instance.new("TextLabel")
tooltipTitle.Size = UDim2.new(1, 0, 0, 25)
tooltipTitle.BackgroundTransparency = 1
tooltipTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
tooltipTitle.Font = Enum.Font.GothamBold
tooltipTitle.ZIndex = 1000
tooltipTitle.Parent = tooltip

local tooltipDesc = Instance.new("TextLabel")
tooltipDesc.Size = UDim2.new(1, -10, 1, -30)
tooltipDesc.Position = UDim2.new(0, 5, 0, 30)
tooltipDesc.BackgroundTransparency = 1
tooltipDesc.TextColor3 = Color3.new(1, 1, 1)
tooltipDesc.Font = Enum.Font.Gotham
tooltipDesc.TextSize = 12
tooltipDesc.TextWrapped = true
tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
tooltipDesc.ZIndex = 1000
tooltipDesc.Parent = tooltip

local function updateTooltipPosition()
	if not tooltip.Visible then return end

	local mousePos = UserInputService:GetMouseLocation()
	local viewportSize = Camera.ViewportSize
	local inset = GuiService:GetGuiInset()

	local tipWidth = 200 
	local tipHeight = 100 

	local xPos = mousePos.X + 15
	local yPos = mousePos.Y - inset.Y + 15

	if xPos + tipWidth > viewportSize.X then xPos = mousePos.X - tipWidth - 15 end
	if yPos + tipHeight > viewportSize.Y then yPos = mousePos.Y - inset.Y - tipHeight - 15 end

	tooltip.Position = UDim2.new(0, xPos, 0, yPos)
end
RunService.RenderStepped:Connect(updateTooltipPosition)

local function getTooltipText(itemName)
	local data = ItemDatabase[itemName]
	if not data then return "Nincs információ erről a tárgyról." end

	local text = ""
	if data.Type == "Fegyver" then
		text = "Szint: " .. (data.Level or 1) .. "\nSebzés: " .. (data.MinDmg or 0) .. " - " .. (data.MaxDmg or 0) .. "\n\n"
	elseif data.Type == "Páncél" then
		text = "Szint: " .. (data.Level or 1) .. "\nVédelem: " .. (data.Defense or 0) .. "\n\n"
	end

	text = text .. (data.Description or "")
	return text
end

-- ==========================================
-- ELADÁS ABLAK 
-- ==========================================
local sellFrame = Instance.new("Frame")
sellFrame.Size = UDim2.new(0, 250, 0, 150)
sellFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
sellFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
sellFrame.BorderColor3 = Color3.fromRGB(50, 100, 150)
sellFrame.BorderSizePixel = 3
sellFrame.Active = true
sellFrame.Visible = false
sellFrame.ZIndex = 60
sellFrame.Parent = invHud

local sellTitle = Instance.new("TextLabel")
sellTitle.Size = UDim2.new(1, 0, 0, 30)
sellTitle.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
sellTitle.TextColor3 = Color3.new(1, 1, 1)
sellTitle.Text = "ELADÁS"
sellTitle.Font = Enum.Font.GothamBold
sellTitle.ZIndex = 61
sellTitle.Parent = sellFrame

local sellInfo = Instance.new("TextLabel")
sellInfo.Size = UDim2.new(1, -20, 1, -80)
sellInfo.Position = UDim2.new(0, 10, 0, 40)
sellInfo.BackgroundTransparency = 1
sellInfo.TextColor3 = Color3.new(1, 1, 1)
sellInfo.Font = Enum.Font.Gotham
sellInfo.TextSize = 14
sellInfo.ZIndex = 61
sellInfo.Parent = sellFrame

local sellYesBtn = Instance.new("TextButton")
sellYesBtn.Size = UDim2.new(0, 100, 0, 30)
sellYesBtn.Position = UDim2.new(0, 15, 1, -40)
sellYesBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
sellYesBtn.TextColor3 = Color3.new(1, 1, 1)
sellYesBtn.Text = "Eladás"
sellYesBtn.Font = Enum.Font.GothamBold
sellYesBtn.ZIndex = 61
sellYesBtn.Parent = sellFrame

local sellNoBtn = Instance.new("TextButton")
sellNoBtn.Size = UDim2.new(0, 100, 0, 30)
sellNoBtn.Position = UDim2.new(1, -115, 1, -40)
sellNoBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
sellNoBtn.TextColor3 = Color3.new(1, 1, 1)
sellNoBtn.Text = "Mégse"
sellNoBtn.Font = Enum.Font.GothamBold
sellNoBtn.ZIndex = 61
sellNoBtn.Parent = sellFrame

local currentSellSlot = nil

sellNoBtn.MouseButton1Click:Connect(function() sellFrame.Visible = false currentSellSlot = nil end)

sellYesBtn.MouseButton1Click:Connect(function()
	if currentSellSlot then
		local SellItem = ReplicatedStorage.Events:FindFirstChild("SellItem")
		if SellItem then SellItem:FireServer(currentSellSlot) end
		sellFrame.Visible = false
		currentSellSlot = nil
	end
end)

local function promptSell(slotName, itemName)
	local itemData = ItemDatabase[itemName]
	local sellPrice = math.floor((itemData and itemData.Price or 0) / 2)

	if sellPrice <= 0 then
		sellInfo.Text = "Ezt a tárgyat nem lehet eladni!"
		sellYesBtn.Visible = false
		sellNoBtn.Text = "Rendben"
		currentSellSlot = nil
		sellFrame.Visible = true
		return
	end

	local slotVal = invFolder:FindFirstChild(slotName)
	local amount = slotVal:FindFirstChild("Amount") and slotVal.Amount.Value or 1
	local totalVal = sellPrice * amount

	sellInfo.Text = "Biztos eladod ezt: " .. itemName .. " (x" .. amount .. ")?\nKapsz érte: " .. totalVal .. " Pénzt."
	sellYesBtn.Visible = true
	sellNoBtn.Text = "Mégse"
	currentSellSlot = slotName
	sellFrame.Visible = true
end

-- ==========================================
-- 32 HELYES TÁSKA ÉS LAPOZÁS GENERÁLÁSA
-- ==========================================
local currentPage = 1
local maxPages = 4

local invGrid = invHud:FindFirstChild("UIGridLayout")
if not invGrid then
	invGrid = Instance.new("UIGridLayout", invHud)
	invGrid.CellSize = UDim2.new(0, 45, 0, 45)
	invGrid.CellPadding = UDim2.new(0, 5, 0, 5)
end

-- 32 darab UI rekesz létrehozása
for i = 1, 32 do
	if not invHud:FindFirstChild("InvSlot_" .. i) then
		local newSlot = Instance.new("Frame", invHud)
		newSlot.Name = "InvSlot_" .. i
		newSlot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		newSlot.BorderColor3 = Color3.fromRGB(80, 80, 80)
		newSlot.BorderSizePixel = 1
	end
end

-- Lapozó UI
local pageNav = Instance.new("Frame", invHud)
pageNav.Size = UDim2.new(1, 0, 0, 30)
pageNav.Position = UDim2.new(0, 0, 1, 10)
pageNav.BackgroundTransparency = 1

local prevBtn = Instance.new("TextButton", pageNav)
prevBtn.Size = UDim2.new(0, 30, 1, 0)
prevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prevBtn.TextColor3 = Color3.new(1,1,1)
prevBtn.Text = "<"
prevBtn.Font = Enum.Font.GothamBold

local nextBtn = Instance.new("TextButton", pageNav)
nextBtn.Size = UDim2.new(0, 30, 1, 0)
nextBtn.Position = UDim2.new(1, -30, 0, 0)
nextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nextBtn.TextColor3 = Color3.new(1,1,1)
nextBtn.Text = ">"
nextBtn.Font = Enum.Font.GothamBold

local pageLabel = Instance.new("TextLabel", pageNav)
pageLabel.Size = UDim2.new(1, -60, 1, 0)
pageLabel.Position = UDim2.new(0, 30, 0, 0)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
pageLabel.Text = "Oldal: 1 / 4"
pageLabel.Font = Enum.Font.GothamBold

-- Zárolt Képernyő
local lockOverlay = Instance.new("Frame", invHud)
lockOverlay.Size = UDim2.new(1, 0, 1, 0)
lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lockOverlay.BackgroundTransparency = 0.3
lockOverlay.ZIndex = 20
lockOverlay.Visible = false

local lockText = Instance.new("TextLabel", lockOverlay)
lockText.Size = UDim2.new(1, 0, 0, 40)
lockText.Position = UDim2.new(0, 0, 0.3, 0)
lockText.BackgroundTransparency = 1
lockText.TextColor3 = Color3.fromRGB(255, 100, 100)
lockText.Text = "EZ AZ OLDAL LE VAN ZÁRVA"
lockText.Font = Enum.Font.GothamBlack
lockText.TextSize = 16
lockText.ZIndex = 21

local buyGoldBtn = Instance.new("TextButton", lockOverlay)
buyGoldBtn.Size = UDim2.new(0.8, 0, 0, 35)
buyGoldBtn.Position = UDim2.new(0.1, 0, 0.5, 0)
buyGoldBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
buyGoldBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
buyGoldBtn.Font = Enum.Font.GothamBold
buyGoldBtn.ZIndex = 21

local buyRobuxBtn = Instance.new("TextButton", lockOverlay)
buyRobuxBtn.Size = UDim2.new(0.8, 0, 0, 35)
buyRobuxBtn.Position = UDim2.new(0.1, 0, 0.5, 45)
buyRobuxBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
buyRobuxBtn.TextColor3 = Color3.new(1, 1, 1)
buyRobuxBtn.Text = "Feloldás: 10 Robux"
buyRobuxBtn.Font = Enum.Font.GothamBold
buyRobuxBtn.ZIndex = 21

buyGoldBtn.MouseButton1Click:Connect(function() Events:WaitForChild("UnlockPageGold"):FireServer() end)
buyRobuxBtn.MouseButton1Click:Connect(function() Events:WaitForChild("PromptRobuxUnlock"):FireServer() end)

local function renderItems()
	local stats = player:WaitForChild("PlayerStats", 5)
	local unlockedPages = stats and stats:WaitForChild("UnlockedPages", 5)

	pageLabel.Text = "Oldal: " .. currentPage .. " / " .. maxPages

	if unlockedPages and currentPage > unlockedPages.Value then
		lockOverlay.Visible = true
		local cost = unlockedPages.Value * 25000
		buyGoldBtn.Text = "Feloldás: " .. cost .. " Arany"
	else
		lockOverlay.Visible = false
	end

	-- 1. Táska rajzolás
	for i = 1, 32 do
		local serverSlotNum = ((currentPage - 1) * 32) + i
		local slotVal = invFolder:FindFirstChild("Slot_" .. serverSlotNum)
		local uiSlot = invHud:FindFirstChild("InvSlot_" .. i)

		if slotVal and uiSlot then
			uiSlot:ClearAllChildren()
			if slotVal.Value ~= "" then
				local itemIcon = Instance.new("TextLabel")
				itemIcon.Name = "ItemIcon"
				itemIcon.Size = UDim2.new(1, -4, 1, -4)
				itemIcon.Position = UDim2.new(0, 2, 0, 2)
				itemIcon.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				itemIcon.TextColor3 = Color3.new(1, 1, 1)
				itemIcon.Text = slotVal.Value
				itemIcon.TextScaled = true
				itemIcon.Font = Enum.Font.GothamBold
				itemIcon.Parent = uiSlot

				local amtVal = slotVal:FindFirstChild("Amount")
				if amtVal and amtVal.Value > 1 then
					local amtLabel = Instance.new("TextLabel")
					amtLabel.Size = UDim2.new(0, 15, 0, 15)
					amtLabel.Position = UDim2.new(1, -15, 1, -15) 
					amtLabel.BackgroundTransparency = 1
					amtLabel.TextColor3 = Color3.new(1, 1, 1)
					amtLabel.TextStrokeTransparency = 0 
					amtLabel.Text = tostring(amtVal.Value)
					amtLabel.Font = Enum.Font.GothamBold
					amtLabel.TextSize = 12
					amtLabel.Parent = itemIcon
				end

				itemIcon.MouseEnter:Connect(function()
					tooltipTitle.Text = slotVal.Value
					tooltipDesc.Text = getTooltipText(slotVal.Value)
					tooltip.Visible = true
				end)
				itemIcon.MouseLeave:Connect(function() tooltip.Visible = false end)
			end
		end
	end

	-- 2. Felszerelés rajzolás
	for uiName, serverName in pairs(eqNameToServer) do
		local slotVal = eqFolder:FindFirstChild(serverName)
		local uiSlot = eqHud:FindFirstChild(uiName, true)
		if slotVal and uiSlot then
			local oldIcon = uiSlot:FindFirstChild("ItemIcon")
			if oldIcon then oldIcon:Destroy() end

			if slotVal.Value ~= "" then
				local itemIcon = Instance.new("TextLabel")
				itemIcon.Name = "ItemIcon"
				itemIcon.Size = UDim2.new(1, -4, 1, -4)
				itemIcon.Position = UDim2.new(0, 2, 0, 2)
				itemIcon.BackgroundColor3 = Color3.fromRGB(100, 80, 80)
				itemIcon.TextColor3 = Color3.new(1, 1, 1)
				itemIcon.Text = slotVal.Value
				itemIcon.TextScaled = true
				itemIcon.Font = Enum.Font.GothamBold
				itemIcon.ZIndex = 2
				itemIcon.Parent = uiSlot

				itemIcon.MouseEnter:Connect(function()
					tooltipTitle.Text = slotVal.Value
					tooltipDesc.Text = getTooltipText(slotVal.Value) .. "\n\n[Felszerelve]"
					tooltip.Visible = true
				end)
				itemIcon.MouseLeave:Connect(function() tooltip.Visible = false end)
			end
		end
	end
end

nextBtn.MouseButton1Click:Connect(function()
	if currentPage < maxPages then
		currentPage += 1
		renderItems()
	end
end)

prevBtn.MouseButton1Click:Connect(function()
	if currentPage > 1 then
		currentPage -= 1
		renderItems()
	end
end)

local function bindInvEvents()
	for _, child in pairs(invFolder:GetChildren()) do
		child.Changed:Connect(renderItems)
		local amt = child:WaitForChild("Amount", 2)
		if amt then amt.Changed:Connect(renderItems) end
	end
end
task.spawn(bindInvEvents)

invFolder.ChildAdded:Connect(renderItems)
eqFolder.ChildAdded:Connect(renderItems)
for _, child in pairs(invFolder:GetChildren()) do child.Changed:Connect(renderItems) end
for _, child in pairs(eqFolder:GetChildren()) do child.Changed:Connect(renderItems) end

-- Várunk kicsit, hogy a statok felálljanak
task.delay(1, function()
	local stats = player:WaitForChild("PlayerStats")
	if stats:FindFirstChild("UnlockedPages") then
		stats.UnlockedPages.Changed:Connect(renderItems)
	end
	renderItems()
end)

-- ==========================================
-- EGÉR KATTINTÁSOK (DRAG, ELADÁS, DUPLA KLIKK, SHIFT SPLIT)
-- ==========================================
local dragging = false
local dragClone = nil
local originSlotUI = nil
local dragConnection = nil
local dragSplitAmount = nil

local lastClickTime = 0
local lastClickedSlot = nil

local function getSlotData(guiObject)
	if guiObject.Name:match("InvSlot_") then
		local num = tonumber(guiObject.Name:match("%d+"))
		local serverSlotNum = ((currentPage - 1) * 32) + num
		return "Inventory", "Slot_" .. serverSlotNum, invFolder:FindFirstChild("Slot_" .. serverSlotNum)
	elseif eqNameToServer[guiObject.Name] then
		local serverName = eqNameToServer[guiObject.Name]
		return "Equipment", serverName, eqFolder:FindFirstChild(serverName)
	elseif guiObject.Name:match("HotbarSlotUI_") then
		local num = guiObject.Name:match("%d+")
		local hotbarFolder = player:FindFirstChild("Hotbar")
		if hotbarFolder then
			return "Hotbar", "Hotbar_" .. num, hotbarFolder:FindFirstChild("Hotbar_" .. num)
		end
	end
	return nil, nil, nil
end

UserInputService.InputBegan:Connect(function(input)
	local pos = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	local guisAtPosition = playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - inset.Y)

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local shopHUD = playerGui:FindFirstChild("ShopHUD")
		local shopFrame = shopHUD and shopHUD:FindFirstChild("ShopFrame")
		local sellMode = shopFrame and shopFrame:FindFirstChild("SellMode")

		if shopFrame and shopFrame.Visible and sellMode and sellMode.Value then
			for _, gui in pairs(guisAtPosition) do
				local folderStr, slotName, slotVal = getSlotData(gui)
				if folderStr == "Inventory" and slotVal and slotVal.Value ~= "" then
					promptSell(slotName, slotVal.Value)
					return
				end
			end
		end
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		for _, gui in pairs(guisAtPosition) do
			local folderStr, slotName, slotVal = getSlotData(gui)

			if folderStr and slotVal and slotVal.Value ~= "" then

				local currentTime = tick()
				if lastClickedSlot == gui and (currentTime - lastClickTime) < 0.4 then
					lastClickedSlot = nil 
					local itemName = slotVal.Value
					local itemData = ItemDatabase[itemName]

					if itemData then
						if itemData.Type == "Fogyóeszköz" then
							local UseItem = Events:FindFirstChild("UseItem")
							if UseItem then UseItem:FireServer(itemName) end
						elseif eqNameToServer[itemData.Type] then
							if folderStr == "Inventory" then
								MoveItem:FireServer("Inventory", slotName, "Equipment", eqNameToServer[itemData.Type])
							elseif folderStr == "Equipment" then
								local stats = player:FindFirstChild("PlayerStats")
								local maxUnlocked = (stats and stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32

								local freeSlot = nil
								for i = 1, maxUnlocked do
									local s = invFolder:FindFirstChild("Slot_" .. i)
									if s and s.Value == "" then freeSlot = "Slot_" .. i break end
								end
								if freeSlot then MoveItem:FireServer("Equipment", slotName, "Inventory", freeSlot) end
							end
						end
					end
					return 
				end

				lastClickTime = currentTime
				lastClickedSlot = gui
				dragging = true
				originSlotUI = gui
				tooltip.Visible = false

				local isShiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				local currentAmtObj = slotVal:FindFirstChild("Amount")
				local currentAmt = currentAmtObj and currentAmtObj.Value or 1
				dragSplitAmount = nil

				if isShiftDown and currentAmt > 1 and folderStr == "Inventory" then
					dragSplitAmount = math.floor(currentAmt / 2)
				end

				dragClone = Instance.new("TextLabel")
				dragClone.Size = UDim2.new(0, 40, 0, 40)
				dragClone.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
				dragClone.Text = slotVal.Value
				dragClone.TextScaled = true
				dragClone.Font = Enum.Font.GothamBold
				dragClone.ZIndex = 10
				dragClone.Parent = invHud
				dragClone.Active = false 

				local showAmt = dragSplitAmount or currentAmt
				if showAmt > 1 then
					local amtLabel = Instance.new("TextLabel")
					amtLabel.Size = UDim2.new(0, 15, 0, 15)
					amtLabel.Position = UDim2.new(1, -15, 1, -15) 
					amtLabel.BackgroundTransparency = 1
					amtLabel.TextColor3 = Color3.new(1, 1, 1)
					amtLabel.TextStrokeTransparency = 0 
					amtLabel.Text = tostring(showAmt)
					amtLabel.Font = Enum.Font.GothamBold
					amtLabel.TextSize = 12
					amtLabel.Parent = dragClone
				end

				dragConnection = RunService.RenderStepped:Connect(function()
					local mousePos = UserInputService:GetMouseLocation()
					dragClone.Position = UDim2.new(0, mousePos.X - 20, 0, mousePos.Y - inset.Y - 20)
				end)
				break
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
		dragging = false
		if dragConnection then dragConnection:Disconnect() end
		if dragClone then dragClone:Destroy() end

		local pos = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local guisAtPosition = playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - inset.Y)
		local targetSlotUI = nil

		for _, gui in pairs(guisAtPosition) do
			if getSlotData(gui) then targetSlotUI = gui break end
		end

		local fromFolderStr, fromSlotName = getSlotData(originSlotUI)
		local itemName = nil

		if fromFolderStr == "Inventory" then 
			itemName = invFolder:FindFirstChild(fromSlotName).Value 
		elseif fromFolderStr == "Equipment" then 
			itemName = eqFolder:FindFirstChild(fromSlotName).Value 
		elseif fromFolderStr == "Hotbar" then 
			local hbFolder = player:FindFirstChild("Hotbar")
			if hbFolder and hbFolder:FindFirstChild(fromSlotName) then itemName = hbFolder[fromSlotName].Value end
		end

		if targetSlotUI then
			local toFolderStr, toSlotName = getSlotData(targetSlotUI)

			if fromFolderStr == "Hotbar" then
				local hbFolder = player:FindFirstChild("Hotbar")
				if hbFolder and hbFolder:FindFirstChild(fromSlotName) then hbFolder[fromSlotName].Value = "" end
				if toFolderStr == "Hotbar" then
					local targetHb = player.Hotbar:FindFirstChild(toSlotName)
					if targetHb then targetHb.Value = itemName end
				end
			elseif toFolderStr == "Hotbar" and fromFolderStr == "Inventory" then
				local hotbarSlot = player.Hotbar:FindFirstChild(toSlotName)
				if hotbarSlot then hotbarSlot.Value = itemName end
			elseif fromFolderStr ~= "Hotbar" and toFolderStr ~= "Hotbar" then
				if fromSlotName ~= toSlotName or fromFolderStr ~= toFolderStr then
					MoveItem:FireServer(fromFolderStr, fromSlotName, toFolderStr, toSlotName, dragSplitAmount)
				end
			end
		else
			if fromFolderStr == "Hotbar" then
				local hbFolder = player:FindFirstChild("Hotbar")
				if hbFolder and hbFolder:FindFirstChild(fromSlotName) then hbFolder[fromSlotName].Value = "" end
			else
				local droppedOnShop = false
				for _, gui in pairs(guisAtPosition) do
					if gui.Name == "ShopFrame" or gui:FindFirstAncestor("ShopFrame") then droppedOnShop = true break end
				end

				if droppedOnShop and fromFolderStr == "Inventory" then
					promptSell(fromSlotName, itemName)
				else
					local target3D = mouse.Target
					if target3D and (target3D.Name == "Kovacs" or target3D:FindFirstAncestor("Kovacs")) then
						local info = ItemDatabase[itemName]
						if info and info.UpgradeTo then
							currentUpgradeSlot = {Folder = fromFolderStr, Slot = fromSlotName}
							bsInfo.Text = "Tárgy: " .. itemName .. "\nCél: " .. info.UpgradeTo .. "\nEsély: " .. info.UpgradeChance .. "%\nÁr: " .. info.UpgradeCost .. " Pénz"
							if info.ReqItem then bsInfo.Text = bsInfo.Text .. "\nSzükséges: " .. info.ReqCount .. "x " .. info.ReqItem end
							bsFrame.Visible = true
						else
							bsInfo.Text = "Ezt a tárgyat nem tudom fejleszteni!"
							currentUpgradeSlot = {Folder = nil, Slot = nil}
							bsFrame.Visible = true
						end
					else
						DropItem:FireServer(fromFolderStr, fromSlotName, dragSplitAmount)
					end
				end
			end
		end
		originSlotUI = nil
		dragSplitAmount = nil
	end
end)