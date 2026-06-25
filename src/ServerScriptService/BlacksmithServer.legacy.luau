local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ProcessUpgrade = Events:WaitForChild("ProcessUpgrade")
local UpgradeResult = Events:WaitForChild("UpgradeResult")

-- BEKÖTJÜK A KÖZPONTI ADATBÁZIST
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- ==========================================
-- BIZTONSÁGI ELLENŐRZÉS ÉS ANTI-SPAM
-- ==========================================
local playerLocks = {}
local function checkSpam(player, cooldown)
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < cooldown then return true end
	playerLocks[player.UserId] = tick()
	return false
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	playerLocks[player.UserId] = nil
end)

local function isNearBlacksmith(player)
	local char = player.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local npcFolder = workspace:FindFirstChild("NPCs")
	if npcFolder then
		local kovacs = npcFolder:FindFirstChild("Kovacs")
		if kovacs and kovacs:FindFirstChild("HumanoidRootPart") then
			return (root.Position - kovacs.HumanoidRootPart.Position).Magnitude <= 20
		end
	end
	return false
end

ProcessUpgrade.OnServerEvent:Connect(function(player, folderStr, slotName)
	-- JAVÍTÁS: Anti-Spam védelem (Makró/Auto-clicker ellen)
	if checkSpam(player, 0.2) then return end

	-- JAVÍTÁS: NPC távolság ellenőrzése (Exploit védelem távoli fejlesztés ellen)
	if not isNearBlacksmith(player) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " távolról próbált a Kováccsal fejleszteni!")
		return
	end

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

	if not stats or not inv then
		UpgradeResult:FireClient(player, "A karakter adatai még nem töltöttek be teljesen.")
		return
	end

	local gold = stats:FindFirstChild("Gold")
	if not gold then
		UpgradeResult:FireClient(player, "A pénz adat nem található.")
		return
	end

	if gold.Value < itemData.UpgradeCost then
		UpgradeResult:FireClient(player, "Nincs elég pénzed a fejlesztéshez!")
		return
	end

	if itemData.ReqItem then
		local maxUnlockedSlots = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32
		local foundAmount = 0

		-- Megszámoljuk, mennyi van összesen
		for i = 1, maxUnlockedSlots do
			local checkSlot = inv:FindFirstChild("Slot_" .. i)
			if checkSlot and checkSlot.Value == itemData.ReqItem then
				local amtObj = checkSlot:FindFirstChild("Amount")
				foundAmount += (amtObj and amtObj.Value or 1)
			end
		end

		if foundAmount < itemData.ReqCount then
			UpgradeResult:FireClient(player, "Nincs elég " .. itemData.ReqItem .. " a táskádban!")
			return
		end

		-- Levonjuk a szükséges mennyiséget
		local remainingToRemove = itemData.ReqCount
		for i = 1, maxUnlockedSlots do
			if remainingToRemove <= 0 then break end

			local remSlot = inv:FindFirstChild("Slot_" .. i)
			if remSlot and remSlot.Value == itemData.ReqItem then
				local amtObj = remSlot:FindFirstChild("Amount")
				local currentAmt = amtObj and amtObj.Value or 1

				if currentAmt <= remainingToRemove then
					-- Az egész slot kiürül
					remainingToRemove -= currentAmt
					remSlot.Value = ""
					if amtObj then amtObj.Value = 0 end
				else
					-- Csak egy részét vonjuk le a stackből
					amtObj.Value -= remainingToRemove
					remainingToRemove = 0
				end
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