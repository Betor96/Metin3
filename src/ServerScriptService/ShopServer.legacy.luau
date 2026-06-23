-- Fájl helye: ServerScriptService -> ShopServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItem = Events:WaitForChild("BuyItem")

-- Eladás Event létrehozása automatikusan
local SellItem = Events:FindFirstChild("SellItem")
if not SellItem then
	SellItem = Instance.new("RemoteEvent")
	SellItem.Name = "SellItem"
	SellItem.Parent = Events
end

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- ==========================================
-- BIZTONSÁGI ELLENŐRZÉS: Közel van a játékos egy boltoshoz?
-- (A kliens nem hazudhatja azt, hogy boltban van!)
-- ==========================================
local validMerchants = {
	["Fegyverkereskedo"] = true,
	["Pancelkereskedo"] = true,
	["Vegyesbolt"] = true
}

local function isNearMerchant(player)
	local char = player.Character
	if not char then return false end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	-- Megnézzük a Workspace-ben, van-e boltos NPC a közelében (20 stud)
	for _, obj in pairs(workspace:GetChildren()) do
		if validMerchants[obj.Name] and obj:FindFirstChild("HumanoidRootPart") then
			local distance = (root.Position - obj.HumanoidRootPart.Position).Magnitude
			if distance <= 20 then
				return true
			end
		end
	end

	return false
end

-- ==========================================
-- TÁRGY VÁSÁRLÁSA
-- ==========================================
BuyItem.OnServerEvent:Connect(function(player, itemName)
	-- 1. SZIGORÚ VÉDELEM: NPC Távolság ellenőrzése
	if not isNearMerchant(player) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " távolról, NPC nélkül próbált vásárolni!")
		return 
	end

	local itemData = ItemDatabase[itemName]
	if not itemData then return end

	-- Biztosítás, hogy az itemnek van ára (ne vegyenek ingyen dolgokat)
	if not itemData.Price or itemData.Price <= 0 then return end

	local stats = player:FindFirstChild("PlayerStats")
	local gold = stats and stats:FindFirstChild("Gold")
	local inv = player:FindFirstChild("Inventory")

	if not gold or not inv then return end

	if gold.Value >= itemData.Price then
		local targetSlot = nil
		local maxStack = itemData.MaxStack or 1
		local maxUnlockedSlots = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32

		-- Ha stackelhető, keresünk egy félig teli stacket
		if maxStack > 1 then
			for i = 1, maxUnlockedSlots do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == itemName and slot.Amount.Value < maxStack then
					targetSlot = slot
					break
				end
			end
		end

		-- Ha nem találtunk stacket (vagy nem stackelhető), keresünk egy üres helyet
		if not targetSlot then
			for i = 1, maxUnlockedSlots do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == "" then
					targetSlot = slot
					break
				end
			end
		end

		-- Sikeres tranzakció (Nincs Race Condition, mert nem szakítjuk meg a folyamatot task.wait-tel)
		if targetSlot then
			gold.Value = gold.Value - itemData.Price
			if targetSlot.Value == itemName then
				targetSlot.Amount.Value = targetSlot.Amount.Value + 1
			else
				targetSlot.Value = itemName
				targetSlot.Amount.Value = 1
			end
		end
	end
end)

-- ==========================================
-- TÁRGY ELADÁSA
-- ==========================================
SellItem.OnServerEvent:Connect(function(player, slotName)
	-- 1. SZIGORÚ VÉDELEM: NPC Távolság ellenőrzése
	if not isNearMerchant(player) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " távolról, NPC nélkül próbált eladni!")
		return 
	end

	local inv = player:FindFirstChild("Inventory")
	local stats = player:FindFirstChild("PlayerStats")
	local gold = stats and stats:FindFirstChild("Gold")
	if not inv or not gold then return end

	local slot = inv:FindFirstChild(slotName)
	if not slot or slot.Value == "" then return end

	local itemName = slot.Value
	local itemData = ItemDatabase[itemName]
	if not itemData then return end

	-- Eladási ár: Az eredeti ár fele!
	local sellPrice = math.floor((itemData.Price or 0) / 2)
	if sellPrice <= 0 then return end

	-- A szerver mondja meg mennyi van belőle, nem a kliens! (Dupe védelem)
	local amount = slot:FindFirstChild("Amount") and slot.Amount.Value or 1
	local totalValue = sellPrice * amount

	-- Tárgy törlése
	slot.Value = ""
	if slot:FindFirstChild("Amount") then
		slot.Amount.Value = 0
	end

	-- Pénz jóváírása
	gold.Value = gold.Value + totalValue
end)