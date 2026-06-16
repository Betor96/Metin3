local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ProcessUpgrade = Events:WaitForChild("ProcessUpgrade")
local UpgradeResult = Events:WaitForChild("UpgradeResult")

-- BEKÖTJÜK A KÖZPONTI ADATBÁZIST
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

ProcessUpgrade.OnServerEvent:Connect(function(player, folderStr, slotName)
	local folder = (folderStr == "Inventory") and player:FindFirstChild("Inventory") or player:FindFirstChild("Equipment")
	if not folder then return end

	local slot = folder:FindFirstChild(slotName)
	if not slot or slot.Value == "" then return end

	local itemName = slot.Value
	local itemData = ItemDatabase[itemName]

	-- Ha nincs benne az adatbázisban, vagy nincs UpgradeTo kitöltve
	if not itemData or not itemData.UpgradeTo then
		UpgradeResult:FireClient(player, "Ezt a tárgyat nem lehet tovább fejleszteni!")
		return
	end

	local stats = player:FindFirstChild("PlayerStats")
	local inv = player:FindFirstChild("Inventory")
	local gold = stats:FindFirstChild("Gold")

	if gold.Value < itemData.UpgradeCost then
		UpgradeResult:FireClient(player, "Nincs elég pénzed a fejlesztéshez!")
		return
	end

	if itemData.ReqItem then
		local foundCount = 0
		for i = 1, 8 do
			local checkSlot = inv:FindFirstChild("Slot_" .. i)
			if checkSlot and checkSlot.Value == itemData.ReqItem then
				foundCount = foundCount + 1
			end
		end

		if foundCount < itemData.ReqCount then
			UpgradeResult:FireClient(player, "Nincs elég " .. itemData.ReqItem .. " a táskádban!")
			return
		end

		local removedCount = 0
		for i = 1, 8 do
			local remSlot = inv:FindFirstChild("Slot_" .. i)
			if remSlot and remSlot.Value == itemData.ReqItem then
				remSlot.Value = ""
				removedCount = removedCount + 1
				if removedCount >= itemData.ReqCount then break end
			end
		end
	end

	gold.Value = gold.Value - itemData.UpgradeCost

	local roll = math.random(1, 100)
	if roll <= itemData.UpgradeChance then
		slot.Value = itemData.UpgradeTo
		UpgradeResult:FireClient(player, "Sikeres fejlesztés: " .. itemData.UpgradeTo .. "!")
	else
		slot.Value = ""
		UpgradeResult:FireClient(player, "A fejlesztés elbukott. A tárgy megsemmisült!")
	end
end)