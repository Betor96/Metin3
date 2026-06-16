-- Fájl helye: ServerScriptService -> PickupHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PickupItems = ReplicatedStorage.Events:WaitForChild("PickupItems")

-- ÚJ: BEKÖTJÜK AZ ADATBÁZIST A STACKELÉSHEZ (Darabszámok miatt)
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

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
				local itemName = itemTag.Value

				-- Lekérjük, hogy max mennyi lehet belőle egy kupacban (ha nincs megadva, akkor csak 1)
				local itemData = ItemDatabase[itemName]
				local maxStack = (itemData and itemData.MaxStack) or 1

				-- A maxStack ellenőrzés után így nézzen ki:
				local stats = player:FindFirstChild("PlayerStats")
				local maxUnlockedSlots = (stats and stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32

				-- 1. ELŐSZÖR PRÓBÁLJUK MEGLÉVŐ STACK-HEZ ADNI
				if maxStack > 1 then
					for i = 1, maxUnlockedSlots do
						local slot = inv:FindFirstChild("Slot_" .. i)
						-- [...] (A többi része marad ugyanaz)
						if slot and slot.Value == itemName then
							local amt = slot:FindFirstChild("Amount")
							-- Ha van már ilyen tárgy, és még fér a stackbe
							if amt and amt.Value < maxStack then
								amt.Value = amt.Value + 1
								added = true
								itemPart:Destroy()
								-- print(player.Name .. " felvett +1 darabot ebből: " .. itemName)
								break
							end
						end
					end
				end

				-- ==========================================
				-- 2. HA NINCS STACK, VAGY TELE VAN, KERESÜNK ÜRES HELYET
				-- ==========================================
				if not added then
					for i = 1, 8 do
						local slot = inv:FindFirstChild("Slot_" .. i)
						if slot and slot.Value == "" then
							slot.Value = itemName

							local amt = slot:FindFirstChild("Amount")
							if amt then
								amt.Value = 1
							end

							added = true
							itemPart:Destroy()
							-- print(player.Name .. " felvette: " .. itemName)
							break -- Megvan a hely, jöhet a következő tárgy a földről!
						end
					end
				end

				-- ==========================================
				-- 3. HA EGYÁLTALÁN NEM FÉRT BE SEHOVA
				-- ==========================================
				if not added then
					-- Nem adunk "break"-et, mert lehet, hogy a következő tárgy a földön 
					-- egy stackelhető Poti lesz, amiből van helyünk!
					-- print(player.Name .. " táskájába nem fért be: " .. itemName)
				end
			end
		end
	end
end)