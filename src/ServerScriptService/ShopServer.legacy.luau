local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItem = Events:WaitForChild("BuyItem")

-- BEKÖTJÜK A KÖZPONTI ADATBÁZIST
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

BuyItem.OnServerEvent:Connect(function(player, itemName)
	local itemData = ItemDatabase[itemName]

	-- Ha nincs ára az adatbázisban, akkor nem megvehető!
	if not itemData or not itemData.Price or itemData.Price <= 0 then return end 

	local stats = player:FindFirstChild("PlayerStats")
	local inv = player:FindFirstChild("Inventory")
	if not stats or not inv then return end

	local gold = stats:FindFirstChild("Gold")

	-- Fájl helye: ServerScriptService -> ShopServer
	-- (A vásárlás ellenőrzésnél cseréld le a freeSlot keresést erre:)

	if gold.Value >= itemData.Price then
		local targetSlot = nil
		local maxStack = itemData.MaxStack or 1

		-- Keresünk nem teli stacket
		if maxStack > 1 then
			for i = 1, 8 do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == itemName and slot.Amount.Value < maxStack then
					targetSlot = slot
					break
				end
			end
		end

		-- Ha nincs, keresünk üres helyet
		if not targetSlot then
			for i = 1, 8 do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == "" then
					targetSlot = slot
					break
				end
			end
		end

		-- Levonjuk a pénzt és beadjuk a tárgyat
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