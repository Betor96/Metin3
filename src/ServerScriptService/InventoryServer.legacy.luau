-- Fájl helye: ServerScriptService -> InventoryServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService") 
local Events = ReplicatedStorage:WaitForChild("Events")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")
local AutoStack = Events:FindFirstChild("AutoStack") or Instance.new("RemoteEvent", Events)
AutoStack.Name = "AutoStack"

local DestroyItem = Events:FindFirstChild("DestroyItem") or Instance.new("RemoteEvent", Events)
DestroyItem.Name = "DestroyItem"

local PAGE_UNLOCK_PRODUCT_ID = 3604998372 

local UnlockPageGold = Events:FindFirstChild("UnlockPageGold") or Instance.new("RemoteEvent", Events)
UnlockPageGold.Name = "UnlockPageGold"
local PromptRobuxUnlock = Events:FindFirstChild("PromptRobuxUnlock") or Instance.new("RemoteEvent", Events)
PromptRobuxUnlock.Name = "PromptRobuxUnlock"


local BANK_SESSION_SECONDS = 300 -- 5 perc

local function isBankSessionValid(player)
	local isUnlocked = player:GetAttribute("BankUnlocked")
	local unlockTime = player:GetAttribute("BankUnlockTime")

	if isUnlocked ~= true or type(unlockTime) ~= "number" then
		return false
	end

	if os.time() - unlockTime > BANK_SESSION_SECONDS then
		player:SetAttribute("BankUnlocked", false)
		player:SetAttribute("BankUnlockTime", nil)
		return false
	end

	return true
end


local typeToSlot = {
	["Sapka"] = "Sapka", ["Páncél"] = "Pancel", ["Cipő"] = "Cipo", 
	["Fegyver"] = "Fegyver", ["Fülbevaló"] = "Fulbevalo", ["Nyaklánc"] = "Nyaklanc", 
	["Pajzs"] = "Pajzs", ["Karkötő"] = "Karkoto"
}

-- ==========================================
-- BIZTONSÁG 1: ANTI-SPAM ÉS MEMÓRIA TAKARÍTÁS
-- ==========================================
local playerLocks = {}

local function checkSpam(player, cooldown)
	cooldown = cooldown or 0.1
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < cooldown then
		return true
	end
	playerLocks[player.UserId] = tick()
	return false
end

Players.PlayerRemoving:Connect(function(player)
	playerLocks[player.UserId] = nil
end)

-- ==========================================
-- BIZTONSÁG 2: BEMENETI ADATOK TISZTÍTÁSA (Sanitization)
-- ==========================================
local function sanitizeAmount(amt)
	if amt == nil then return nil end
	if type(amt) ~= "number" then return nil end
	if amt <= 0 then return nil end
	if amt ~= math.floor(amt) then return nil end
	return amt
end

-- ==========================================
-- BIZTONSÁG 3: SLOT NÉV VALIDÁCIÓ
-- ==========================================
local validEquipmentSlots = {}

for _, slotName in pairs(typeToSlot) do
	validEquipmentSlots[slotName] = true
end

local function isValidSlotForFolder(folderStr, slotName)
	if type(folderStr) ~= "string" or type(slotName) ~= "string" then
		return false
	end

	local safeFolderStr = tostring(folderStr)
	local safeSlotName = tostring(slotName)

	if #safeSlotName > 40 then
		return false
	end

	if safeFolderStr == "Inventory" or safeFolderStr == "Bank" then
		return safeSlotName:match("^Slot_%d+$") ~= nil
	end

	if safeFolderStr == "Equipment" then
		return validEquipmentSlots[safeSlotName] == true
	end

	return false
end

-- ==========================================
-- INVENTORY LOGIKA
-- ==========================================

UnlockPageGold.OnServerEvent:Connect(function(player)
	if checkSpam(player, 0.5) then return end

	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return end
	local gold = stats:FindFirstChild("Gold")
	local unlockedPages = stats:FindFirstChild("UnlockedPages")

	if gold and unlockedPages and unlockedPages.Value < 4 then
		local cost = unlockedPages.Value * 25000 
		if gold.Value >= cost then
			gold.Value -= cost
			unlockedPages.Value += 1
		end
	end
end)

PromptRobuxUnlock.OnServerEvent:Connect(function(player)
	if checkSpam(player, 1) then return end
	MarketplaceService:PromptProductPurchase(player, PAGE_UNLOCK_PRODUCT_ID)
end)

MoveItem.OnServerEvent:Connect(function(player, fromFolderStr, fromSlotName, toFolderStr, toSlotName, splitAmount)
	if checkSpam(player, 0.05) then return end

	-- BIZTONSÁG: Mappanév Whitelist
	if fromFolderStr ~= "Inventory" and fromFolderStr ~= "Equipment" and fromFolderStr ~= "Bank" then return end
	if toFolderStr ~= "Inventory" and toFolderStr ~= "Equipment" and toFolderStr ~= "Bank" then return end

	-- BIZTONSÁG: Név-injektálás védelem
	if not isValidSlotForFolder(fromFolderStr, fromSlotName) or not isValidSlotForFolder(toFolderStr, toSlotName) then
		return
	end

	local inv = player:FindFirstChild("Inventory")
	local eq = player:FindFirstChild("Equipment")
	local bank = player:FindFirstChild("Bank")
	local stats = player:FindFirstChild("PlayerStats")

	if not inv or not eq or not bank or not stats then
		return
	end

	-- BIZTONSÁG: Slot limit megkerülés elleni védelem
	local numStr = toSlotName:match("%d+")
	if numStr then
		local slotNum = tonumber(numStr)

		local isBank = (toFolderStr == "Bank")
		local unlockedPagesObj = isBank and stats:FindFirstChild("BankUnlockedPages") or stats:FindFirstChild("UnlockedPages")

		local maxAllowedSlots = (unlockedPagesObj and unlockedPagesObj.Value or 1) * 32

		if slotNum > maxAllowedSlots then
			warn("[EXPLOIT GYANÚ] " .. player.Name .. " feloldatlan (fizetős) slotba próbált pakolni!")
			return
		end
	end

	splitAmount = sanitizeAmount(splitAmount)

	local fromFolder = (fromFolderStr == "Inventory") and inv or ((fromFolderStr == "Equipment") and eq or bank)
	local toFolder = (toFolderStr == "Inventory") and inv or ((toFolderStr == "Equipment") and eq or bank)

	if fromFolderStr == "Bank" or toFolderStr == "Bank" then
		local unlockTime = player:GetAttribute("BankUnlockTime")
		local isUnlocked = player:GetAttribute("BankUnlocked")

		if not isUnlocked or not unlockTime or os.time() - unlockTime > 300 then
			player:SetAttribute("BankUnlocked", false)
			warn("[EXPLOIT GYANÚ] " .. player.Name .. " jelszó nélkül vagy lejárt bank sessionnel próbált a raktárhoz nyúlni!")
			return
		end
	end

	if toFolderStr == "Inventory" or toFolderStr == "Bank" then
		local toSlotNum = tonumber(toSlotName:match("%d+"))
		if toSlotNum then
			local pagesObj = (toFolderStr == "Inventory") and stats:FindFirstChild("UnlockedPages") or stats:FindFirstChild("BankUnlockedPages")
			local maxUnlocked = (pagesObj and pagesObj.Value or 1) * 32
			if toSlotNum > maxUnlocked then return end 
		end
	end

	local fromSlot = fromFolder:FindFirstChild(fromSlotName)
	local toSlot = toFolder:FindFirstChild(toSlotName)

	if fromSlot and toSlot and fromSlot.Value ~= "" then
		local itemName = fromSlot.Value
		local targetItemName = toSlot.Value
		local itemData = ItemDatabase[itemName]
		if not itemData then return end
		local maxStack = itemData.MaxStack or 1

		if toFolderStr == "Equipment" then
			local expectedSlot = typeToSlot[itemData.Type]
			if expectedSlot ~= toSlotName then return end 

			local playerLevel = stats:FindFirstChild("Level") and stats.Level.Value or 1
			local requiredLevel = itemData.Level or 1

			if playerLevel < requiredLevel then 
				return 
			end
		end

		if toFolderStr == "Inventory" and fromFolderStr == "Equipment" and targetItemName ~= "" then
			local targetItemData = ItemDatabase[targetItemName]
			if not targetItemData then return end
			if typeToSlot[targetItemData.Type] ~= fromSlotName then return end 
		end

		if splitAmount and (fromFolderStr == "Inventory" or fromFolderStr == "Bank") and (toFolderStr == "Inventory" or toFolderStr == "Bank") then
			local splitAmountValue = tonumber(splitAmount)
			if not splitAmountValue then return end

			local fromAmtObj = fromSlot:FindFirstChild("Amount")
			if not fromAmtObj or fromAmtObj.Value < splitAmountValue then return end

			if toSlot.Value == "" then
				toSlot.Value = itemName

				if not toSlot:FindFirstChild("Amount") then
					Instance.new("IntValue", toSlot).Name = "Amount"
				end

				toSlot.Amount.Value = splitAmountValue
				fromAmtObj.Value = fromAmtObj.Value - splitAmountValue

				if fromAmtObj.Value <= 0 then
					fromSlot.Value = ""
				end

				return

			elseif toSlot.Value == itemName and fromSlot ~= toSlot then
				local toAmtObj = toSlot:FindFirstChild("Amount")
				if not toAmtObj then
					toAmtObj = Instance.new("IntValue", toSlot)
					toAmtObj.Name = "Amount"
					toAmtObj.Value = 1
				end

				local spaceLeft = maxStack - toAmtObj.Value

				if spaceLeft > 0 then
					local transferAmt = math.min(splitAmountValue, spaceLeft)
					toAmtObj.Value = toAmtObj.Value + transferAmt
					fromAmtObj.Value = fromAmtObj.Value - transferAmt

					if fromAmtObj.Value <= 0 then
						fromSlot.Value = ""
					end
				end

				return
			else 
				return 
			end
		end

		if (fromFolderStr == "Inventory" or fromFolderStr == "Bank") and (toFolderStr == "Inventory" or toFolderStr == "Bank") and itemName == targetItemName and maxStack > 1 and fromSlot ~= toSlot then
			local fromAmt = fromSlot:FindFirstChild("Amount") and fromSlot.Amount.Value or 1
			local toAmt = toSlot:FindFirstChild("Amount") and toSlot.Amount.Value or 1
			local total = fromAmt + toAmt

			if total <= maxStack then
				toSlot.Amount.Value = total
				fromSlot.Value = ""
				fromSlot.Amount.Value = 0
			else
				toSlot.Amount.Value = maxStack
				if fromSlot:FindFirstChild("Amount") then fromSlot.Amount.Value = total - maxStack end
			end
			return 
		end

		local tempVal = toSlot.Value
		local tempAmt = (toSlot:FindFirstChild("Amount")) and toSlot.Amount.Value or 1
		local fromAmt = (fromSlot:FindFirstChild("Amount")) and fromSlot.Amount.Value or 1

		toSlot.Value = fromSlot.Value
		if toSlot:FindFirstChild("Amount") then toSlot.Amount.Value = fromAmt end
		fromSlot.Value = tempVal
		if fromSlot:FindFirstChild("Amount") then fromSlot.Amount.Value = tempAmt end
	end
end)

-- ==========================================
-- TÁRGY ELDOBÁSA (Nincs rajta tulajdonos)
-- ==========================================
DropItem.OnServerEvent:Connect(function(player, folderStr, slotName, splitAmount)
	if checkSpam(player, 0.2) then return end

	-- BIZTONSÁG: Whitelist
	if folderStr ~= "Inventory" and folderStr ~= "Equipment" then return end 

	splitAmount = sanitizeAmount(splitAmount)

	local folder = (folderStr == "Inventory") and player:FindFirstChild("Inventory") or player:FindFirstChild("Equipment")

	if folder then
		local slot = folder:FindFirstChild(slotName)
		if slot and slot.Value ~= "" then
			local itemName = slot.Value 

			local dropQty = 1
			if slot:FindFirstChild("Amount") then
				dropQty = (splitAmount and splitAmount <= slot.Amount.Value) and splitAmount or slot.Amount.Value

				if dropQty <= 0 then return end

				slot.Amount.Value = slot.Amount.Value - dropQty
				if slot.Amount.Value <= 0 then slot.Value = "" end
			else
				slot.Value = "" 
			end

			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local root = char.HumanoidRootPart
				local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
				droppedFolder.Name = "DroppedItems"

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.2, 2) 
				droppedItem.Color = Color3.fromRGB(150, 150, 150)

				local dropPos = root.Position + (root.CFrame.LookVector * 5) + Vector3.new(0, 3, 0)
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local ignoreList = {char, droppedFolder}
				if workspace:FindFirstChild("Monsters") then table.insert(ignoreList, workspace.Monsters) end
				if workspace:FindFirstChild("MetinStones") then table.insert(ignoreList, workspace.MetinStones) end
				if workspace:FindFirstChild("Ores") then table.insert(ignoreList, workspace.Ores) end
				rayParams.FilterDescendantsInstances = ignoreList

				local ray = workspace:Raycast(dropPos, Vector3.new(0, -50, 0), rayParams)
				if ray then
					droppedItem.Position = ray.Position + Vector3.new(0, 0.2, 0)
				else
					droppedItem.Position = dropPos
				end

				droppedItem.Anchored = true    
				droppedItem.CanCollide = false 

				local itemTag = Instance.new("StringValue", droppedItem)
				itemTag.Name = "ItemName"
				itemTag.Value = itemName
				
				local amountTag = Instance.new("IntValue")
				amountTag.Name = "ItemAmount"
				amountTag.Value = dropQty
				amountTag.Parent = droppedItem

				game.Debris:AddItem(droppedItem, 300)

				local textBillboard = Instance.new("BillboardGui")
				textBillboard.Size = UDim2.new(0, 150, 0, 25)
				textBillboard.StudsOffset = Vector3.new(0, 1.5, 0) 
				textBillboard.AlwaysOnTop = true 
				textBillboard.MaxDistance = 60 
				textBillboard.Adornee = droppedItem
				textBillboard.Parent = droppedItem

				local nameLabel = Instance.new("TextLabel", textBillboard)
				nameLabel.Size = UDim2.new(1, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.RichText = true
				local displayName = itemName
				if dropQty > 1 then
					displayName = itemName .. " x" .. dropQty
				end

				nameLabel.Text = '<font color="rgb(180, 180, 180)">' .. displayName .. '</font>'
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.TextStrokeTransparency = 0

				droppedItem.Parent = droppedFolder
			end
		end
	end
end)

-- ==========================================
-- TÁRGY VÉGLEGES MEGSEMMISÍTÉSE
-- ==========================================
DestroyItem.OnServerEvent:Connect(function(player, folderStr, slotName, splitAmount)
	if checkSpam(player, 0.1) then return end

	-- BIZTONSÁG: Bank jelszó bypass védelem
	if folderStr == "Bank" and not isBankSessionValid(player) then 
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " jelszó nélkül vagy lejárt bank sessionnel próbált tárgyat törölni a raktárból!")
		return 
	end

	splitAmount = sanitizeAmount(splitAmount)

	local folder = nil
	if folderStr == "Inventory" then folder = player:FindFirstChild("Inventory")
	elseif folderStr == "Equipment" then folder = player:FindFirstChild("Equipment")
	elseif folderStr == "Bank" then folder = player:FindFirstChild("Bank") end

	if folder then
		local slot = folder:FindFirstChild(slotName)
		if slot and slot.Value ~= "" then
			local dropQty = 1
			if slot:FindFirstChild("Amount") then
				dropQty = (splitAmount and splitAmount <= slot.Amount.Value) and splitAmount or slot.Amount.Value
				if dropQty <= 0 then return end

				slot.Amount.Value = slot.Amount.Value - dropQty
				if slot.Amount.Value <= 0 then slot.Value = "" end
			else
				slot.Value = "" 
			end
		end
	end
end)

AutoStack.OnServerEvent:Connect(function(player, targetSlotName, isBank)
	if checkSpam(player, 0.2) then return end

	-- BIZTONSÁG: Bank jelszó bypass védelem
	if isBank and not isBankSessionValid(player) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " jelszó nélkül vagy lejárt bank sessionnel próbált stackelni a raktárban!")
		return
	end

	local folder = isBank and player:FindFirstChild("Bank") or player:FindFirstChild("Inventory")
	if not folder then return end

	local targetSlot = folder:FindFirstChild(targetSlotName)
	if not targetSlot or targetSlot.Value == "" then return end

	local itemData = ItemDatabase[targetSlot.Value]
	if not itemData or not itemData.MaxStack or itemData.MaxStack <= 1 then return end

	local targetAmtObj = targetSlot:FindFirstChild("Amount")
	if not targetAmtObj then return end

	for _, slot in pairs(folder:GetChildren()) do
		if slot ~= targetSlot and slot.Value == targetSlot.Value then
			local amtObj = slot:FindFirstChild("Amount")
			if amtObj and amtObj.Value > 0 then
				local spaceLeft = itemData.MaxStack - targetAmtObj.Value
				if spaceLeft > 0 then
					local transferAmt = math.min(amtObj.Value, spaceLeft)
					targetAmtObj.Value = targetAmtObj.Value + transferAmt
					amtObj.Value = amtObj.Value - transferAmt
					if amtObj.Value <= 0 then slot.Value = "" end
				end
			end
		end
	end
end)