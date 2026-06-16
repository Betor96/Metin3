-- Fájl helye: ServerScriptService -> ItemUseServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local UseItem = Events:WaitForChild("UseItem")

-- ADATBÁZIS BEKÖTÉSE (Hogy tudja, mennyi HP-t/Manát ad)
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

UseItem.OnServerEvent:Connect(function(player, itemName)
	local itemData = ItemDatabase[itemName]

	-- Ha nem létezik a tárgy, vagy nem Fogyóeszköz (hanem pl. kard), akkor nem lehet "meginni"
	if not itemData or itemData.Type ~= "Fogyóeszköz" then return end

	local inv = player:FindFirstChild("Inventory")
	if not inv then return end

	-- 1. BIZTONSÁGI ELLENŐRZÉS: Tényleg van a táskájában ebből a tárgyból?
	local foundSlot = nil
	for i = 1, 8 do
		local slot = inv:FindFirstChild("Slot_" .. i)
		if slot and slot.Value == itemName then
			foundSlot = slot
			break -- Megtaláltuk az elsőt, nem keresünk tovább
		end
	end

	-- Ha nincs a táskájában (mert elfogyott, de a gyorsgombról nem vette le), akkor megszakítjuk
	if not foundSlot then return end

	-- 2. A HATÁS ÉRVÉNYESÍTÉSE (HP vagy Mana visszatöltése)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local stats = player:FindFirstChild("PlayerStats")

	if itemName == "Életerő Ital" and humanoid then
		-- A math.min biztosítja, hogy ne gyógyuljon a Maximum életereje fölé!
		humanoid.Health = math.min(humanoid.Health + itemData.HealAmount, humanoid.MaxHealth)

	elseif itemName == "Mana Ital" and stats then
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")
		if mana and maxMana then
			mana.Value = math.min(mana.Value + itemData.HealAmount, maxMana.Value)
		end
	end

	-- 3. TÁRGY TÖRLÉSE A TÁSKÁBÓL (Mivel megitta)
	-- 3. TÁRGY FOGYASZTÁSA
	foundSlot.Amount.Value -= 1
	if foundSlot.Amount.Value <= 0 then
		foundSlot.Value = ""
	end
end)