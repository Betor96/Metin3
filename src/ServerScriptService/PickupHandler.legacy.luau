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
		if not itemPart:IsA("BasePart") then
			continue
		end

		local dist = (itemPart.Position - rootPart.Position).Magnitude
		if dist > PICKUP_RADIUS then
			continue
		end

		if itemPart:GetAttribute("PickedUp") then
			continue
		end

		local ownerTag = itemPart:FindFirstChild("Owner")
		if ownerTag and ownerTag.Value ~= "" and ownerTag.Value ~= player.Name then
			continue
		end

		local itemTag = itemPart:FindFirstChild("ItemName")
		if not itemTag then
			continue
		end

		local itemName = itemTag.Value
		local itemData = ItemDatabase[itemName]
		if not itemData then
			continue
		end

		local maxStack = itemData.MaxStack or 1
		local amtTag = itemPart:FindFirstChild("ItemAmount")
		local dropAmount = amtTag and amtTag.Value or 1

		if dropAmount <= 0 then
			itemPart:Destroy()
			continue
		end

		-- Csak most foglaljuk le ideiglenesen, amikor már tudjuk, hogy valid item.
		itemPart:SetAttribute("PickedUp", true)

		local originalDropAmount = dropAmount

		-- 1. Először próbáljuk meglévő stackekbe tölteni.
		if maxStack > 1 then
			for i = 1, maxUnlockedSlots do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == itemName then
					local amt = slot:FindFirstChild("Amount")
					if amt and amt.Value < maxStack then
						local spaceLeft = maxStack - amt.Value
						local transfer = math.min(dropAmount, spaceLeft)

						amt.Value += transfer
						dropAmount -= transfer

						if dropAmount <= 0 then
							break
						end
					end
				end
			end
		end

		-- 2. Ha maradt belőle, új üres slotba rakjuk.
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
					break
				end
			end
		end

		-- 3. Eredmény kezelése.
		if dropAmount <= 0 then
			itemPart:Destroy()
		elseif dropAmount < originalDropAmount then
			-- Részben sikerült felvenni, maradék marad a földön.
			if amtTag then
				amtTag.Value = dropAmount
			end

			local billboard = itemPart:FindFirstChildOfClass("BillboardGui")
			if billboard then
				local label = billboard:FindFirstChildOfClass("TextLabel")
				if label then
					local displayName = itemName
					if dropAmount > 1 then
						displayName = itemName .. " x" .. dropAmount
					end
					label.Text = '<font color="rgb(180, 180, 180)">' .. displayName .. '</font>'
				end
			end

			itemPart:SetAttribute("PickedUp", nil)
		else
			-- Semmit nem tudott felvenni, például tele az inventory.
			itemPart:SetAttribute("PickedUp", nil)
		end
	end
end)