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

	local maxUnlockedSlots = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32

	for _, itemPart in pairs(droppedFolder:GetChildren()) do
		local dist = (itemPart.Position - rootPart.Position).Magnitude

		if dist <= PICKUP_RADIUS then
			-- ==========================================
			-- ÚJ: TULAJDONJOG ELLENŐRZÉSE
			-- ==========================================
			local ownerTag = itemPart:FindFirstChild("Owner")
			if ownerTag and ownerTag.Value ~= "" and ownerTag.Value ~= player.Name then
				continue -- Ha van tulajdonosa, és az NEM a játékos, akkor nem veheti fel! (Ugrás a következőre)
			end

			local itemTag = itemPart:FindFirstChild("ItemName")
			if itemTag then
				local itemName = itemTag.Value
				local itemData = ItemDatabase[itemName]
				local maxStack = (itemData and itemData.MaxStack) or 1

				local amtTag = itemPart:FindFirstChild("ItemAmount")
				local dropAmount = amtTag and amtTag.Value or 1

				if maxStack > 1 then
					for i = 1, maxUnlockedSlots do
						local slot = inv:FindFirstChild("Slot_" .. i)
						if slot and slot.Value == itemName then
							local amt = slot:FindFirstChild("Amount")
							if amt and amt.Value < maxStack then
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