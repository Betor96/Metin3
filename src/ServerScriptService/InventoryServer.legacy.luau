-- Fájl helye: ServerScriptService -> InventoryServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService") 
local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")
-- ÚJ: AutoStack RemoteEvent
local AutoStack = Events:FindFirstChild("AutoStack") or Instance.new("RemoteEvent", Events)
AutoStack.Name = "AutoStack"

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- IDE ÍRD BE A LÉTREHOZOTT ROBUX PRODUCT ID-DAT!
local PAGE_UNLOCK_PRODUCT_ID = 3604998372 

-- ÚJ: EVENTEK A VÁSÁRLÁSHOZ
local UnlockPageGold = Events:FindFirstChild("UnlockPageGold") or Instance.new("RemoteEvent", Events)
UnlockPageGold.Name = "UnlockPageGold"
local PromptRobuxUnlock = Events:FindFirstChild("PromptRobuxUnlock") or Instance.new("RemoteEvent", Events)
PromptRobuxUnlock.Name = "PromptRobuxUnlock"

local typeToSlot = {
	["Sapka"] = "Sapka", ["Páncél"] = "Pancel", ["Cipő"] = "Cipo", 
	["Fegyver"] = "Fegyver", ["Fülbevaló"] = "Fulbevalo", ["Nyaklánc"] = "Nyaklanc", 
	["Pajzs"] = "Pajzs", ["Karkötő"] = "Karkoto"
}

-- ==========================================
-- TÁSKA OLDAL FELOLDÁSA
-- ==========================================
UnlockPageGold.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return end
	local gold = stats:FindFirstChild("Gold")
	local unlockedPages = stats:FindFirstChild("UnlockedPages")

	if gold and unlockedPages and unlockedPages.Value < 4 then
		local cost = unlockedPages.Value * 25000 -- Árnövekedés (1->2 = 25k, 2->3 = 50k, 3->4 = 75k)
		if gold.Value >= cost then
			gold.Value -= cost
			unlockedPages.Value += 1
		end
	end
end)

PromptRobuxUnlock.OnServerEvent:Connect(function(player)
	MarketplaceService:PromptProductPurchase(player, PAGE_UNLOCK_PRODUCT_ID)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if receiptInfo.ProductId == PAGE_UNLOCK_PRODUCT_ID then
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if player then
			local stats = player:FindFirstChild("PlayerStats")
			if stats and stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value < 4 then
				stats.UnlockedPages.Value += 1
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ==========================================
-- TÁRGYAK MOZGATÁSA, FELSZERELÉSE ÉS SZÉTBONTÁSA
-- ==========================================
MoveItem.OnServerEvent:Connect(function(player, fromFolderStr, fromSlotName, toFolderStr, toSlotName, splitAmount)
	local inv = player:FindFirstChild("Inventory")
	local eq = player:FindFirstChild("Equipment")
	local stats = player:FindFirstChild("PlayerStats")
	if not inv or not eq or not stats then return end

	-- BIZTONSÁG: Ne tudjon zárt oldalra mozgatni semmit!
	if toFolderStr == "Inventory" then
		local toSlotNum = tonumber(toSlotName:match("%d+"))
		if toSlotNum then
			local maxUnlocked = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32
			if toSlotNum > maxUnlocked then return end 
		end
	end

	local fromFolder = (fromFolderStr == "Inventory") and inv or eq
	local toFolder = (toFolderStr == "Inventory") and inv or eq

	local fromSlot = fromFolder:FindFirstChild(fromSlotName)
	local toSlot = toFolder:FindFirstChild(toSlotName)

	if fromSlot and toSlot and fromSlot.Value ~= "" then
		local itemName = fromSlot.Value
		local targetItemName = toSlot.Value

		local itemData = ItemDatabase[itemName]
		if not itemData then return end
		local maxStack = itemData.MaxStack or 1

		-- Felszerelés ellenőrzés
		if toFolderStr == "Equipment" then
			local expectedSlot = typeToSlot[itemData.Type]
			if expectedSlot ~= toSlotName then return end 
		end

		-- Csere ellenőrzés (táska -> felszerelésre húzva)
		if toFolderStr == "Inventory" and fromFolderStr == "Equipment" and targetItemName ~= "" then
			local targetItemData = ItemDatabase[targetItemName]
			if not targetItemData then return end
			local expectedSlot = typeToSlot[targetItemData.Type]
			if expectedSlot ~= fromSlotName then return end 
		end

		-- ÚJ: SHIFT + KLIKK SPLIT (Felezés)
		if splitAmount and splitAmount > 0 and fromFolderStr == "Inventory" and toFolderStr == "Inventory" then
			local fromAmtObj = fromSlot:FindFirstChild("Amount")
			if not fromAmtObj or fromAmtObj.Value < splitAmount then return end

			if toSlot.Value == "" then
				toSlot.Value = itemName
				if not toSlot:FindFirstChild("Amount") then
					local newAmt = Instance.new("IntValue", toSlot)
					newAmt.Name = "Amount"
				end
				toSlot.Amount.Value = splitAmount
				fromAmtObj.Value = fromAmtObj.Value - splitAmount
				if fromAmtObj.Value <= 0 then fromSlot.Value = "" end
				return
			elseif toSlot.Value == itemName and fromSlot ~= toSlot then
				local toAmtObj = toSlot:FindFirstChild("Amount")
				local toAmt = toAmtObj and toAmtObj.Value or 1
				local spaceLeft = maxStack - toAmt

				if spaceLeft > 0 then
					local transferAmt = math.min(splitAmount, spaceLeft)
					toAmtObj.Value = toAmtObj.Value + transferAmt
					fromAmtObj.Value = fromAmtObj.Value - transferAmt
					if fromAmtObj.Value <= 0 then fromSlot.Value = "" end
				end
				return
			else
				return -- Más tárgyra nem lehet ráhúzni a splitet
			end
		end

		-- KÉZI STACKELÉS (Egész kupac egyesítése)
		if fromFolderStr == "Inventory" and toFolderStr == "Inventory" and itemName == targetItemName and maxStack > 1 and fromSlot ~= toSlot then
			local fromAmt = fromSlot:FindFirstChild("Amount") and fromSlot.Amount.Value or 1
			local toAmt = toSlot:FindFirstChild("Amount") and toSlot.Amount.Value or 1
			local total = fromAmt + toAmt

			if total <= maxStack then
				toSlot.Amount.Value = total
				fromSlot.Value = ""
				fromSlot.Amount.Value = 0
			else
				toSlot.Amount.Value = maxStack
				if fromSlot:FindFirstChild("Amount") then
					fromSlot.Amount.Value = total - maxStack
				end
			end
			return 
		end

		-- NORMÁL CSERE (Drag & Drop)
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
-- TÁRGYAK ELDOBÁSA A FÖLDRE
-- ==========================================
DropItem.OnServerEvent:Connect(function(player, folderStr, slotName, splitAmount)
	local folder = (folderStr == "Inventory") and player:FindFirstChild("Inventory") or player:FindFirstChild("Equipment")
	if folder then
		local slot = folder:FindFirstChild(slotName)
		if slot and slot.Value ~= "" then
			local itemName = slot.Value
			local itemData = ItemDatabase[itemName]

			-- Levonás a táskából
			local dropQty = 1
			if slot:FindFirstChild("Amount") then
				if splitAmount and splitAmount > 0 and splitAmount <= slot.Amount.Value then
					dropQty = splitAmount
				else
					dropQty = 1 
				end

				slot.Amount.Value = slot.Amount.Value - dropQty
				if slot.Amount.Value <= 0 then slot.Value = "" end
			else
				slot.Value = "" 
			end

			-- Földre dobás
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPart = character.HumanoidRootPart
				local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
				droppedFolder.Name = "DroppedItems"

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.2, 3) 
				droppedItem.Position = rootPart.Position + (rootPart.CFrame.LookVector * 5) + Vector3.new(0, 3, 0)

				-- Belerakjuk, hogy mennyi van benne
				local amountTag = Instance.new("IntValue")
				amountTag.Name = "ItemAmount"
				amountTag.Value = dropQty
				amountTag.Parent = droppedItem

				local partColor = Color3.fromRGB(150, 150, 150)
				local textColor = Color3.new(1, 1, 1)

				if itemData then
					if itemData.Type == "Fegyver" then 
						partColor = Color3.fromRGB(150, 150, 150)
						textColor = Color3.fromRGB(220, 220, 220)
					elseif itemData.Type == "Páncél" then 
						partColor = Color3.fromRGB(80, 100, 80)
						textColor = Color3.fromRGB(100, 255, 100)
					elseif itemData.Type == "Fogyóeszköz" then
						partColor = Color3.fromRGB(150, 50, 50)
						textColor = Color3.fromRGB(255, 100, 100)
					end
				end

				droppedItem.Color = partColor

				local itemTag = Instance.new("StringValue")
				itemTag.Name = "ItemName"
				itemTag.Value = itemName
				itemTag.Parent = droppedItem

				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.new(0, 150, 0, 25)
				billboard.StudsOffset = Vector3.new(0, 1.5, 0)
				billboard.AlwaysOnTop = true
				billboard.Adornee = droppedItem

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1

				if dropQty > 1 then
					nameLabel.Text = itemName .. " (x" .. dropQty .. ")"
				else
					nameLabel.Text = itemName
				end

				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.TextStrokeTransparency = 0 
				nameLabel.TextColor3 = textColor

				nameLabel.Parent = billboard
				billboard.Parent = droppedItem
				droppedItem.Parent = droppedFolder
			end
		end
	end
end)

-- ==========================================
-- ÚJ JAVÍTÁS: TÁRGYAK AUTOMATIKUS ÖSSZEVONÁSA (DUPLA KLIKK)
-- ==========================================
AutoStack.OnServerEvent:Connect(function(player, targetSlotName)
	local inv = player:FindFirstChild("Inventory")
	if not inv then return end

	local targetSlot = inv:FindFirstChild(targetSlotName)
	if not targetSlot or targetSlot.Value == "" then return end

	local itemName = targetSlot.Value
	local itemData = ItemDatabase[itemName]

	-- Ha nem halmozható, vagy nincs értelme (MaxStack <= 1), kilépünk
	if not itemData or not itemData.MaxStack or itemData.MaxStack <= 1 then return end

	local targetAmtObj = targetSlot:FindFirstChild("Amount")
	if not targetAmtObj then return end

	-- Végignézzük az összes rekeszt a táskában
	for _, slot in pairs(inv:GetChildren()) do
		-- Ha találunk egy MÁSIK rekeszt, amiben UGYANAZ a tárgy van...
		if slot ~= targetSlot and slot.Value == itemName then
			local amtObj = slot:FindFirstChild("Amount")
			if amtObj and amtObj.Value > 0 then

				-- Kiszámoljuk, mennyi fér még be abba a rekeszbe, amire a játékos kattintott
				local spaceLeft = itemData.MaxStack - targetAmtObj.Value

				if spaceLeft > 0 then
					-- Átteszünk annyit, amennyi befér (vagy az egészet, ha elfér)
					local transferAmt = math.min(amtObj.Value, spaceLeft)
					targetAmtObj.Value = targetAmtObj.Value + transferAmt
					amtObj.Value = amtObj.Value - transferAmt

					-- Ha a másik rekesz teljesen kiürült, töröljük a tárgyat onnan
					if amtObj.Value <= 0 then
						slot.Value = ""
					end
				end
			end
		end
	end
end)