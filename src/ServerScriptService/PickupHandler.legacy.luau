local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PickupItems = ReplicatedStorage.Events:WaitForChild("PickupItems")

local PICKUP_RADIUS = 15 -- Milyen messziről szívja be a tárgyakat

PickupItems.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local inv = player:FindFirstChild("Inventory")
	local droppedFolder = workspace:FindFirstChild("DroppedItems")

	if not rootPart or not inv or not droppedFolder then return end

	-- Végigmegyünk a földön lévő összes tárgyon
	for _, itemPart in pairs(droppedFolder:GetChildren()) do
		local dist = (itemPart.Position - rootPart.Position).Magnitude

		-- Ha a sugarunkon belül van
		if dist <= PICKUP_RADIUS then
			local itemTag = itemPart:FindFirstChild("ItemName")
			if itemTag then
				local added = false

				-- Keresünk egy üres helyet a táskában
				for i = 1, 8 do
					local slot = inv:FindFirstChild("Slot_" .. i)
					if slot and slot.Value == "" then
						slot.Value = itemTag.Value
						added = true

						-- Tárgy felszedése (törlés a földről)
						itemPart:Destroy()
						print(player.Name .. " felvette: " .. itemTag.Value)
						break -- Megvan a hely, jöhet a következő tárgy a földről!
					end
				end

				-- Ha tele a táska, megszakítjuk a felszedést
				if not added then
					print(player.Name .. " táskája tele van!")
					break
				end
			end
		end
	end
end)