local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")
local ProcessUpgrade = Events:WaitForChild("ProcessUpgrade")
local UpgradeResult = Events:WaitForChild("UpgradeResult")

-- BEKÖTJÜK AZ ÚJ KÖZPONTI ADATBÁZIST A RÉGI HELYETT
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
-- KOVÁCS (UPGRADE) FELÜLET LÉTREHOZÁSA
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
bsFrame.Parent = playerGui:WaitForChild("InventoryHUD")

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

bsNoBtn.MouseButton1Click:Connect(function()
	bsFrame.Visible = false
end)

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
-- ÚJ RENDER ÉS TOOLTIP RENDSZER (ADATBÁZISBÓL)
-- ==========================================

local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 200, 0, 100)
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tooltip.BorderColor3 = Color3.fromRGB(100, 80, 50)
tooltip.BorderSizePixel = 2
tooltip.ZIndex = 100
tooltip.Visible = false
tooltip.Parent = playerGui:WaitForChild("InventoryHUD")

local tooltipTitle = Instance.new("TextLabel")
tooltipTitle.Size = UDim2.new(1, 0, 0, 25)
tooltipTitle.BackgroundTransparency = 1
tooltipTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
tooltipTitle.Font = Enum.Font.GothamBold
tooltipTitle.ZIndex = 101
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
tooltipDesc.ZIndex = 101
tooltipDesc.Parent = tooltip

RunService.RenderStepped:Connect(function()
	if tooltip.Visible then
		local pos = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		tooltip.Position = UDim2.new(0, pos.X + 15, 0, pos.Y - inset.Y + 15)
	end
end)

-- Okos Tooltip szöveg generáló az Adatbázisból
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

local function renderItems()
	for i = 1, 8 do
		local slotVal = invFolder:FindFirstChild("Slot_" .. i)
		local uiSlot = invHud:FindFirstChild("InvSlot_" .. i, true)
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

				itemIcon.MouseEnter:Connect(function()
					tooltipTitle.Text = slotVal.Value
					tooltipDesc.Text = getTooltipText(slotVal.Value)
					tooltip.Visible = true
				end)
				itemIcon.MouseLeave:Connect(function() tooltip.Visible = false end)
			end
		end
	end

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

invFolder.ChildAdded:Connect(renderItems)
eqFolder.ChildAdded:Connect(renderItems)
for _, child in pairs(invFolder:GetChildren()) do child.Changed:Connect(renderItems) end
for _, child in pairs(eqFolder:GetChildren()) do child.Changed:Connect(renderItems) end
renderItems()

-- ==========================================
-- DRAG AND DROP ÉS RÁHÚZÁS A KOVÁCSRA
-- ==========================================
local dragging = false
local dragClone = nil
local originSlotUI = nil
local dragConnection = nil

local function getSlotData(guiObject)
	-- Inventory (Táska)
	if guiObject.Name:match("InvSlot_") then
		local num = guiObject.Name:match("%d+")
		return "Inventory", "Slot_" .. num, invFolder:FindFirstChild("Slot_" .. num)
		-- Equipment (Felszerelés)
	elseif eqNameToServer[guiObject.Name] then
		local serverName = eqNameToServer[guiObject.Name]
		return "Equipment", serverName, eqFolder:FindFirstChild(serverName)
		-- ÚJ: Hotbar (Gyorsgombok)
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local guisAtPosition = playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - inset.Y)

		for _, gui in pairs(guisAtPosition) do
			local folderStr, slotName, slotVal = getSlotData(gui)

			if folderStr and slotVal and slotVal.Value ~= "" then
				dragging = true
				originSlotUI = gui
				tooltip.Visible = false

				dragClone = Instance.new("TextLabel")
				dragClone.Size = UDim2.new(0, 40, 0, 40)
				dragClone.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
				dragClone.Text = slotVal.Value
				dragClone.TextScaled = true
				dragClone.Font = Enum.Font.GothamBold
				dragClone.ZIndex = 10
				dragClone.Parent = playerGui:WaitForChild("InventoryHUD")

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
			if getSlotData(gui) then
				targetSlotUI = gui
				break
			end
		end

		local fromFolderStr, fromSlotName = getSlotData(originSlotUI)
		local itemName = nil
		if fromFolderStr == "Inventory" then itemName = invFolder:FindFirstChild(fromSlotName).Value end
		if fromFolderStr == "Equipment" then itemName = eqFolder:FindFirstChild(fromSlotName).Value end

		if targetSlotUI then
			local toFolderStr, toSlotName = getSlotData(targetSlotUI)

			-- Ha a táskából a HOTBAR-RA húzza:
			if toFolderStr == "Hotbar" and fromFolderStr == "Inventory" then
				-- Jelenleg kliens oldalon állítjuk be a shortcutot (később szerveresítjük mentéshez)
				local hotbarSlot = player.Hotbar:FindFirstChild(toSlotName)
				if hotbarSlot then
					hotbarSlot.Value = itemName
				end

				-- Sima tárgymozgatás táskán belül/felszerelésbe
			elseif fromSlotName ~= toSlotName or fromFolderStr ~= toFolderStr then
				MoveItem:FireServer(fromFolderStr, fromSlotName, toFolderStr, toSlotName)
			end
		else
			-- HA NINCS UI CÉLPONT, MEGNÉZZÜK, HOGY A KOVÁCSRA HÚZTUK-E!
			local target3D = mouse.Target
			if target3D and (target3D.Name == "Kovacs" or target3D:FindFirstAncestor("Kovacs")) then
				local info = ItemDatabase[itemName]
				if info and info.UpgradeTo then
					currentUpgradeSlot = {Folder = fromFolderStr, Slot = fromSlotName}
					bsInfo.Text = "Tárgy: " .. itemName .. "\nCél: " .. info.UpgradeTo .. "\nEsély: " .. info.UpgradeChance .. "%\nÁr: " .. info.UpgradeCost .. " Pénz"
					if info.ReqItem then
						bsInfo.Text = bsInfo.Text .. "\nSzükséges: " .. info.ReqCount .. "x " .. info.ReqItem
					end
					bsFrame.Visible = true
				else
					bsInfo.Text = "Ezt a tárgyat nem tudom fejleszteni!"
					currentUpgradeSlot = {Folder = nil, Slot = nil}
					bsFrame.Visible = true
				end
			else
				-- Ha csak a levegőbe húzta, akkor eldobja a földre
				DropItem:FireServer(fromFolderStr, fromSlotName)
			end
		end
		originSlotUI = nil
	end
end)