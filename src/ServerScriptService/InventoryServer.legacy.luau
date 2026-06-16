-- Fájl helye: ServerScriptService -> InventoryServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local typeToSlot = {
	["Fegyver"] = "Fegyver",
	["Páncél"] = "Pancel",
	["Cipő"] = "Cipo",
	["Nyaklánc"] = "Nyaklanc",
	["Sapka"] = "Sapka",
	["Fülbevaló"] = "Fulbevalo",
	["Pajzs"] = "Pajzs",
	["Karkötő"] = "Karkoto"
}
-- (A fájl többi része marad ahogy volt!)

-- ==========================================
-- TÁRGYAK MOZGATÁSA ÉS FELSZERELÉSE
-- ==========================================
MoveItem.OnServerEvent:Connect(function(player, fromFolderStr, fromSlotName, toFolderStr, toSlotName)
	local inv = player:FindFirstChild("Inventory")
	local eq = player:FindFirstChild("Equipment")
	if not inv or not eq then return end

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

		-- HA A FELSZERELÉSBE HÚZZUK (Felvétel)
		if toFolderStr == "Equipment" then
			local expectedSlot = typeToSlot[itemData.Type]
			if expectedSlot ~= toSlotName then return end 
		end

		-- HA CSERÉLÜNK (Táskából Felszerelésbe, és a felszerelésen is van valami)
		if toFolderStr == "Inventory" and fromFolderStr == "Equipment" and targetItemName ~= "" then
			local targetItemData = ItemDatabase[targetItemName]
			if not targetItemData then return end
			local expectedSlot = typeToSlot[targetItemData.Type]
			if expectedSlot ~= fromSlotName then return end 
		end

		-- ==========================================
		-- ÚJ: KÉZI STACKELÉS (Egymásra húzás táskán belül)
		-- ==========================================
		if fromFolderStr == "Inventory" and toFolderStr == "Inventory" and itemName == targetItemName and maxStack > 1 and fromSlot ~= toSlot then
			local fromAmt = fromSlot:FindFirstChild("Amount") and fromSlot.Amount.Value or 1
			local toAmt = toSlot:FindFirstChild("Amount") and toSlot.Amount.Value or 1

			local total = fromAmt + toAmt

			-- Ha belefér egy stackbe
			if total <= maxStack then
				toSlot.Amount.Value = total
				fromSlot.Value = ""
				fromSlot.Amount.Value = 0
			else
				-- Ha nem fér bele, feltöltjük a stacket maximumra, a maradékot visszahagyjuk
				toSlot.Amount.Value = maxStack
				fromSlot.Amount.Value = total - maxStack
			end
			return -- Készen vagyunk a stackeléssel, megszakítjuk a további cserét!
		end

		-- ==========================================
		-- BIZTONSÁGOS CSERE (Duplikáció elleni védelemmel!)
		-- ==========================================
		local tempVal = toSlot.Value
		local tempAmt = (toSlot:FindFirstChild("Amount")) and toSlot.Amount.Value or 1

		local fromAmt = (fromSlot:FindFirstChild("Amount")) and fromSlot.Amount.Value or 1

		-- 1. Új hely feltöltése
		toSlot.Value = fromSlot.Value
		if toSlot:FindFirstChild("Amount") then 
			toSlot.Amount.Value = fromAmt 
		end

		-- 2. Régi hely felülírása (vagy kiürítése)
		fromSlot.Value = tempVal
		if fromSlot:FindFirstChild("Amount") then 
			fromSlot.Amount.Value = tempAmt 
		end
	end
end)

-- ==========================================
-- TÁRGYAK ELDOBÁSA A FÖLDRE
-- ==========================================
DropItem.OnServerEvent:Connect(function(player, folderStr, slotName)
	local folder = (folderStr == "Inventory") and player:FindFirstChild("Inventory") or player:FindFirstChild("Equipment")
	if folder then
		local slot = folder:FindFirstChild(slotName)
		if slot and slot.Value ~= "" then
			local itemName = slot.Value
			local itemData = ItemDatabase[itemName]

			-- Ha táskában van és van Amount, akkor csak 1 darabot dobunk el!
			if slot:FindFirstChild("Amount") then
				slot.Amount.Value = slot.Amount.Value - 1
				if slot.Amount.Value <= 0 then 
					slot.Value = "" 
				end
			else
				slot.Value = "" -- Ha felszerelésről dobja el, egyből törlődik
			end

			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPart = character.HumanoidRootPart
				local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
				droppedFolder.Name = "DroppedItems"

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.2, 3) 
				droppedItem.Position = rootPart.Position + (rootPart.CFrame.LookVector * 5) + Vector3.new(0, 3, 0)

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
				nameLabel.Text = itemName
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