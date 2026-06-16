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

	if gold.Value >= itemData.Price then
		local freeSlot = nil
		for i = 1, 8 do
			local slot = inv:FindFirstChild("Slot_" .. i)
			if slot and slot.Value == "" then
				freeSlot = slot
				break
			end
		end

		if freeSlot then
			gold.Value = gold.Value - itemData.Price
			freeSlot.Value = itemName
		end
	end
end)