-- Fájl helye: ServerScriptService -> ItemUseServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local UseItem = Events:WaitForChild("UseItem")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local SkillDatabase = require(ReplicatedStorage:WaitForChild("SkillDatabase"))

local ApplyEffect = Events:FindFirstChild("ApplyEffect")
if not ApplyEffect then
	ApplyEffect = Instance.new("RemoteEvent")
	ApplyEffect.Name = "ApplyEffect"
	ApplyEffect.Parent = Events
end

local SkillCooldown = Events:FindFirstChild("SkillCooldown")
if not SkillCooldown then
	SkillCooldown = Instance.new("RemoteEvent")
	SkillCooldown.Name = "SkillCooldown"
	SkillCooldown.Parent = Events
end

local activePlayerEffects = {}
local playerCooldowns = {} 

UseItem.OnServerEvent:Connect(function(player, itemName, mousePos, target)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("PlayerStats")

	if not stats or not humanoid or not root or humanoid.Health <= 0 then return end

	-- ==========================================
	-- 1. HA KÉPESSÉG (SKILL) LETT HASZNÁLVA
	-- ==========================================
	if SkillDatabase.Skills[itemName] then
		local skill = SkillDatabase.Skills[itemName]

		if not playerCooldowns[player.UserId] then playerCooldowns[player.UserId] = {} end
		local lastUsed = playerCooldowns[player.UserId][itemName] or 0

		-- Közös Cooldown (Újratöltés) ellenőrzés minden skillnél
		if tick() - lastUsed < skill.Cooldown then return end 

		local manaStat = stats:FindFirstChild("Mana")

		-- JAVÍTÁS: Toggle (Kibe/Bekapcsolós) képességek Cooldown kezelése
		if skill.IsToggle then
			local currentToggleState = player:GetAttribute(skill.ToggleAttribute)

			-- Ha BE akarjuk kapcsolni, ellenőrizzük, hogy van-e elég mana
			if not currentToggleState then
				if not manaStat or manaStat.Value < skill.Mana then return end
			end

			local success = skill.Execute(player, character, root, mousePos, target)

			if success then
				-- JAVÍTÁS: Sikeres használat után elindítjuk a Vizuális Cooldown-t a UI-on
				playerCooldowns[player.UserId][itemName] = tick()
				SkillCooldown:FireClient(player, itemName, skill.Cooldown)

				if not currentToggleState then
					-- Bekapcsolás: Mana levonása és Végtelen Buff ikon kirakása
					if manaStat then manaStat.Value -= skill.Mana end
					ApplyEffect:FireClient(player, itemName, itemName, 0, 99999) 
				else
					-- Kikapcsolás: Nem von manát, csak letörli a Buff ikont (0 mp)
					ApplyEffect:FireClient(player, itemName, itemName, 0, 0)
				end
			end
			return
		end

		-- Normál aktív képességek (Mik amik Manát vonnak)
		if manaStat and manaStat.Value >= skill.Mana then
			local success = skill.Execute(player, character, root, mousePos, target)

			if success then
				manaStat.Value -= skill.Mana
				playerCooldowns[player.UserId][itemName] = tick() 
				SkillCooldown:FireClient(player, itemName, skill.Cooldown)

				if skill.Duration then
					ApplyEffect:FireClient(player, itemName, itemName, 0, skill.Duration)
				end
			end
		end
		return
	end

	-- ==========================================
	-- 2. HA TÁRGY LETT HASZNÁLVA (Potik)
	-- ==========================================
	local itemData = ItemDatabase[itemName]
	if not itemData or itemData.Type ~= "Fogyóeszköz" then return end

	local inv = player:FindFirstChild("Inventory")
	if not inv then return end

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
	local usedSuccessfully = false

	if itemName == "Életerő Ital" and humanoid then
		humanoid.Health = math.min(humanoid.Health + (itemData.HealAmount or 0), humanoid.MaxHealth)
		usedSuccessfully = true

	elseif itemName == "Mana Ital" and stats:FindFirstChild("Mana") and stats:FindFirstChild("MaxMana") then
		stats.Mana.Value = math.min(stats.Mana.Value + (itemData.HealAmount or 0), stats.MaxMana.Value)
		usedSuccessfully = true

	elseif itemData.Effect then
		if not itemData.Value or not itemData.Duration then return end
		local statObj = stats:FindFirstChild(itemData.Effect)

		if statObj then
			local userId = player.UserId
			if not activePlayerEffects[userId] then activePlayerEffects[userId] = {} end

			if activePlayerEffects[userId][itemData.Effect] then
				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)
				usedSuccessfully = true
			else
				statObj.Value = statObj.Value + itemData.Value
				activePlayerEffects[userId][itemData.Effect] = true

				if itemData.Effect == "MovementSpeed" and humanoid and humanoid.WalkSpeed > 0 then
					humanoid.WalkSpeed = 16 * (1 + (statObj.Value / 100))
				end

				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)
				usedSuccessfully = true

				task.spawn(function()
					task.wait(itemData.Duration)
					if player and player.Parent and player:FindFirstChild("PlayerStats") then
						local currentStat = player.PlayerStats:FindFirstChild(itemData.Effect)
						if currentStat then
							currentStat.Value = currentStat.Value - itemData.Value
							if itemData.Effect == "MovementSpeed" and player.Character and player.Character:FindFirstChild("Humanoid") then
								local hum = player.Character.Humanoid
								if hum.WalkSpeed > 0 then
									hum.WalkSpeed = 16 * (1 + (currentStat.Value / 100))
								end
							end
						end
					end
					if activePlayerEffects[userId] then activePlayerEffects[userId][itemData.Effect] = nil end
				end)
			end
		end
	end

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
	playerCooldowns[player.UserId] = nil
end)