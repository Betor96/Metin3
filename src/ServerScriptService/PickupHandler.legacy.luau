-- Fájl helye: ServerScriptService -> PickupHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PickupItems = ReplicatedStorage.Events:WaitForChild("PickupItems")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local PICKUP_RADIUS = 15 

PickupItems.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local inv = player:FindFirstChild("Inventory")
	local droppedFolder = workspace:FindFirstChild("DroppedItems")
	local stats = player:FindFirstChild("PlayerStats")

	if not rootPart or not inv or not droppedFolder or not stats then return end

	-- ÚJ: Kiszámoljuk hány hely van feloldva (pl. 2. oldal = 64 hely)
	local maxUnlockedSlots = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32

	for _, itemPart in pairs(droppedFolder:GetChildren()) do
		local dist = (itemPart.Position - rootPart.Position).Magnitude

		if dist <= PICKUP_RADIUS then
			local itemTag = itemPart:FindFirstChild("ItemName")
			if itemTag then
				local itemName = itemTag.Value
				local itemData = ItemDatabase[itemName]
				local maxStack = (itemData and itemData.MaxStack) or 1

				-- ÚJ: Kiolvassuk, hogy a földön lévő kupacban mennyi tárgy van!
				local amtTag = itemPart:FindFirstChild("ItemAmount")
				local dropAmount = amtTag and amtTag.Value or 1

				-- 1. STACKELÉS (Létező kupacba rakás)
				if maxStack > 1 then
					for i = 1, maxUnlockedSlots do
						local slot = inv:FindFirstChild("Slot_" .. i)
						if slot and slot.Value == itemName then
							local amt = slot:FindFirstChild("Amount")
							if amt and amt.Value < maxStack then
								-- Kiszámoljuk mennyi fér még be
								local spaceLeft = maxStack - amt.Value
								local transfer = math.min(dropAmount, spaceLeft)

								amt.Value = amt.Value + transfer
								dropAmount = dropAmount - transfer

								if dropAmount <= 0 then
									itemPart:Destroy()
									break
								end
							end
						end
					end
				end

				-- 2. ÜRES HELY KERESÉSE (Ha még maradt a kupacból)
				if dropAmount > 0 then
					for i = 1, maxUnlockedSlots do
						local slot = inv:FindFirstChild("Slot_" .. i)
						if slot and slot.Value == "" then
							slot.Value = itemName
							local amt = slot:FindFirstChild("Amount")
							if amt then
								amt.Value = dropAmount
							end

							dropAmount = 0
							itemPart:Destroy()
							break 
						end
					end
				end
			end
		end
	end
end)