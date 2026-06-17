-- Fájl helye: ServerScriptService -> ItemUseServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local UseItem = Events:WaitForChild("UseItem")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local ApplyEffect = Events:FindFirstChild("ApplyEffect")
if not ApplyEffect then
	ApplyEffect = Instance.new("RemoteEvent")
	ApplyEffect.Name = "ApplyEffect"
	ApplyEffect.Parent = Events
end

local activePlayerEffects = {}

UseItem.OnServerEvent:Connect(function(player, itemName)
	local itemData = ItemDatabase[itemName]

	if not itemData or itemData.Type ~= "Fogyóeszköz" then return end

	local inv = player:FindFirstChild("Inventory")
	local stats = player:FindFirstChild("PlayerStats")
	if not inv or not stats then return end

	local maxUnlockedSlots = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32
	local foundSlot = nil

	for i = 1, maxUnlockedSlots do
		local slot = inv:FindFirstChild("Slot_" .. i)
		if slot and slot.Value == itemName then
			foundSlot = slot
			break 
		end
	end

	if not foundSlot then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local usedSuccessfully = false

	if itemName == "Életerő Ital" and humanoid then
		humanoid.Health = math.min(humanoid.Health + (itemData.HealAmount or 0), humanoid.MaxHealth)
		usedSuccessfully = true

	elseif itemName == "Mana Ital" and stats:FindFirstChild("Mana") and stats:FindFirstChild("MaxMana") then
		stats.Mana.Value = math.min(stats.Mana.Value + (itemData.HealAmount or 0), stats.MaxMana.Value)
		usedSuccessfully = true

		-- STAT-NÖVELŐ ITALOK LOGIKÁJA
	elseif itemData.Effect then
		if not itemData.Value or not itemData.Duration then
			warn("HIBA: A(z) " .. itemName .. " hianyzik a 'Value' vagy 'Duration' az ItemDatabase-bol!")
			return
		end

		local statObj = stats:FindFirstChild(itemData.Effect)

		if statObj then
			local userId = player.UserId
			if not activePlayerEffects[userId] then activePlayerEffects[userId] = {} end

			if activePlayerEffects[userId][itemData.Effect] then
				-- Ha már aktív, csak az időt frissíti a kliensen
				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)
				usedSuccessfully = true
			else
				-- ÚJ EFFEKT: Bónusz megadása
				statObj.Value = statObj.Value + itemData.Value
				activePlayerEffects[userId][itemData.Effect] = true

				-- JAVÍTÁS: Azonnali sebesség frissítése, ha MovementSpeed potit iszunk!
				if itemData.Effect == "MovementSpeed" and humanoid and humanoid.WalkSpeed > 0 then
					humanoid.WalkSpeed = 16 * (1 + (statObj.Value / 100))
				end

				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)
				usedSuccessfully = true

				-- Visszaszámláló a szerveren: Ha lejár, elveszi!
				task.spawn(function()
					task.wait(itemData.Duration)
					if player and player.Parent and player:FindFirstChild("PlayerStats") then
						local currentStat = player.PlayerStats:FindFirstChild(itemData.Effect)
						if currentStat then
							currentStat.Value = currentStat.Value - itemData.Value

							-- JAVÍTÁS: Sebesség visszaállítása, ha lejár a poti!
							if itemData.Effect == "MovementSpeed" and player.Character and player.Character:FindFirstChild("Humanoid") then
								local hum = player.Character.Humanoid
								if hum.WalkSpeed > 0 then
									hum.WalkSpeed = 16 * (1 + (currentStat.Value / 100))
								end
							end
						end
					end
					if activePlayerEffects[userId] then
						activePlayerEffects[userId][itemData.Effect] = nil
					end
				end)
			end
		end
	end

	-- Poti levonása, ha sikeresen ivott
	if usedSuccessfully then
		local amtObj = foundSlot:FindFirstChild("Amount")
		if amtObj then
			amtObj.Value -= 1
			if amtObj.Value <= 0 then
				foundSlot.Value = ""
				amtObj.Value = 0
			end
		else
			foundSlot.Value = ""
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayerEffects[player.UserId] = nil
end)