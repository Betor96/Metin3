-- Fájl helye: ServerScriptService -> ShopServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItem = Events:WaitForChild("BuyItem")

-- ÚJ: Eladás Event létrehozása automatikusan
local SellItem = Events:FindFirstChild("SellItem")
if not SellItem then
	SellItem = Instance.new("RemoteEvent")
	SellItem.Name = "SellItem"
	SellItem.Parent = Events
end

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

BuyItem.OnServerEvent:Connect(function(player, itemName)
	local itemData = ItemDatabase[itemName]
	if not itemData then return end

	local stats = player:FindFirstChild("PlayerStats")
	local gold = stats and stats:FindFirstChild("Gold")
	local inv = player:FindFirstChild("Inventory")

	if not gold or not inv then return end

	if gold.Value >= itemData.Price then
		local targetSlot = nil
		local maxStack = itemData.MaxStack or 1

		if maxStack > 1 then
			for i = 1, 8 do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == itemName and slot.Amount.Value < maxStack then
					targetSlot = slot
					break
				end
			end
		end

		if not targetSlot then
			for i = 1, 8 do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == "" then
					targetSlot = slot
					break
				end
			end
		end

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
-- ÚJ: TÁRGY ELADÁSA
-- ==========================================
SellItem.OnServerEvent:Connect(function(player, slotName)
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

	-- Ha stackelve van, megszorozzuk az árat a darabszámmal
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