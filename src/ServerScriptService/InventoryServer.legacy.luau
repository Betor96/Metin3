-- Fájl helye: ServerScriptService -> InventoryServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")

-- BEKÖTJÜK A KÖZPONTI ADATBÁZIST! (Itt dől el, hogy mi micsoda)
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- Magyar típusnevekből szerveres slot nevek
local typeToSlot = {
	["Fegyver"] = "Fegyver",
	["Páncél"] = "Pancel"
	-- Ide jöhet majd a "Cipő", "Sisak" stb.
}

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

		-- Megnézzük az adatbázisban, hogy létezik-e (és +1, +2 stb.)
		local itemData = ItemDatabase[itemName]
		if not itemData then return end

		-- HA A FELSZERELÉSBE HÚZZUK (Felvétel)
		if toFolderStr == "Equipment" then
			local expectedSlot = typeToSlot[itemData.Type]
			if expectedSlot ~= toSlotName then return end -- Ha nem a megfelelő helyre húzta, megszakítjuk!
		end

		-- HA CSERÉLÜNK (Táskából Felszerelésbe vagy fordítva, és mindkettőben van valami)
		if toFolderStr == "Inventory" and fromFolderStr == "Equipment" and targetItemName ~= "" then
			local targetItemData = ItemDatabase[targetItemName]
			if not targetItemData then return end
			local expectedSlot = typeToSlot[targetItemData.Type]
			if expectedSlot ~= fromSlotName then return end -- A táskában lévő tárgy nem mehet a felszerelés adott helyére!
		end

		-- Sikeres csere / áthelyezés
		local temp = toSlot.Value
		toSlot.Value = fromSlot.Value
		fromSlot.Value = temp
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

			slot.Value = "" -- Töröljük a táskából

			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPart = character.HumanoidRootPart
				local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
				droppedFolder.Name = "DroppedItems"

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.2, 3) 
				droppedItem.Position = rootPart.Position + (rootPart.CFrame.LookVector * 5) + Vector3.new(0, 3, 0)

				-- ==========================================
				-- DINAMIKUS SZÍNBEÁLLÍTÁS ADATBÁZISBÓL
				-- ==========================================
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
