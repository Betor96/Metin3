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

-- ==========================================
-- BIZTONSÁG 1: ANTI-SPAM (Race Condition védelem)
-- Megakadályozza, hogy egy macro ezredmásodpercenként 100x használjon valamit
-- ==========================================
local playerLocks = {}

local classSkillMap = {
	GUARDIAN = {
		["Shield Charge"] = true,
		["Earthbreaker"] = true,
		["Blade Spirit"] = true,
		["Iron Skin"] = true,
	},
	SHADOWBLADE = {
		["Shadow Strike"] = true,
		["Whirling Blades"] = true,
		["Bloodlust"] = true,
		["Death Mark"] = true,
	},
	SOULWEAVER = {
		["Soul Orb"] = true,
		["Spirit Chain"] = true,
		["Spirit Blessing"] = true,
		["Soul Explosion"] = true,
	},
	SEALER = {
		["Seal of Power"] = true,
		["Seal of Protection"] = true,
		["Explosive Seal"] = true,
		["Dragon Shackles"] = true,
	}
}

UseItem.OnServerEvent:Connect(function(player, itemName, mousePos, target)
	-- Anti-Spam: Max 10 kérés másodpercenként (0.1 sec limit)
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < 0.1 then return end
	playerLocks[player.UserId] = tick()

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("PlayerStats")

	if not stats or not humanoid or not root or humanoid.Health <= 0 then return end

	-- ==========================================
	-- 1. HA KÉPESSÉG (SKILL) LETT HASZNÁLVA
	-- ==========================================
	if SkillDatabase.Skills[itemName] then

		-- JAVÍTÁS 1.a: Kaszt validáció
		local playerClass = player:GetAttribute("Class") or (stats:FindFirstChild("Class") and stats.Class.Value)
		playerClass = playerClass and string.upper(tostring(playerClass)) or ""

		local allowedSkills = classSkillMap[playerClass]
		if not allowedSkills or not allowedSkills[itemName] then
			warn("[EXPLOIT GYANÚ] " .. player.Name .. " (" .. playerClass .. ") egy illegális skillt próbált használni: " .. tostring(itemName))
			return
		end

		local skill = SkillDatabase.Skills[itemName]

		-- JAVÍTÁS 1.b: Szerver oldali távolság ellenőrzés
		local range = SkillDatabase.Ranges and SkillDatabase.Ranges[itemName] or skill.Range
		if range and range > 0 and target and target.Parent then
			local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart") or target.Parent.PrimaryPart
			if targetRoot then
				local dist = (root.Position - targetRoot.Position).Magnitude
				if dist > range + 5 then 
					return 
				end
			end
		end

		if not playerCooldowns[player.UserId] then playerCooldowns[player.UserId] = {} end
		local lastUsed = playerCooldowns[player.UserId][itemName] or 0

		-- Közös Cooldown ellenőrzés
		if tick() - lastUsed < skill.Cooldown then return end 

		local manaStat = stats:FindFirstChild("Mana")

		-- Toggle képességek
		if skill.IsToggle then
			local currentToggleState = player:GetAttribute(skill.ToggleAttribute)
			if not currentToggleState then
				if not manaStat or manaStat.Value < skill.Mana then return end
			end

			playerCooldowns[player.UserId][itemName] = tick()
			local success = skill.Execute(player, character, root, mousePos, target)

			if success then
				SkillCooldown:FireClient(player, itemName, skill.Cooldown)
				if not currentToggleState then
					if manaStat then manaStat.Value -= skill.Mana end
					ApplyEffect:FireClient(player, itemName, itemName, 0, 99999) 
				else
					ApplyEffect:FireClient(player, itemName, itemName, 0, 0)
				end
			else
				playerCooldowns[player.UserId][itemName] = 0
			end
			return
		end

		-- Normál aktív képességek
		if manaStat and manaStat.Value >= skill.Mana then
			playerCooldowns[player.UserId][itemName] = tick() 
			local success = skill.Execute(player, character, root, mousePos, target)

			if success then
				manaStat.Value -= skill.Mana
				SkillCooldown:FireClient(player, itemName, skill.Cooldown)
				if skill.Duration then
					ApplyEffect:FireClient(player, itemName, itemName, 0, skill.Duration)
				end
			else
				playerCooldowns[player.UserId][itemName] = 0
			end
		end
		return
	end

	-- ==========================================
	-- 2. HA TÁRGY LETT HASZNÁLVA (Potik, Buffok)
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

	local amtObj = foundSlot:FindFirstChild("Amount")
	local currentAmt = amtObj and amtObj.Value or 1
	if currentAmt <= 0 then return end

	if amtObj then
		amtObj.Value -= 1
		if amtObj.Value <= 0 then
			foundSlot.Value = ""
			amtObj.Value = 0
		end
	else
		foundSlot.Value = ""
	end

	if itemName == "Életerő Ital" and humanoid then
		humanoid.Health = math.min(humanoid.Health + (itemData.HealAmount or 0), humanoid.MaxHealth)
	elseif itemName == "Mana Ital" and stats:FindFirstChild("Mana") and stats:FindFirstChild("MaxMana") then
		stats.Mana.Value = math.min(stats.Mana.Value + (itemData.HealAmount or 0), stats.MaxMana.Value)
	elseif itemData.Effect then
		if not itemData.Value or not itemData.Duration then return end
		local statObj = stats:FindFirstChild(itemData.Effect)

		if statObj then
			local userId = player.UserId
			if not activePlayerEffects[userId] then activePlayerEffects[userId] = {} end

			if activePlayerEffects[userId][itemData.Effect] then
				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)
			else
				statObj.Value = statObj.Value + itemData.Value
				activePlayerEffects[userId][itemData.Effect] = true

				if itemData.Effect == "MovementSpeed" and humanoid and humanoid.WalkSpeed > 0 then
					humanoid.WalkSpeed = 16 * (1 + (statObj.Value / 100))
				end

				ApplyEffect:FireClient(player, itemName, itemData.Effect, itemData.Value, itemData.Duration)

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
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayerEffects[player.UserId] = nil
	playerCooldowns[player.UserId] = nil
	playerLocks[player.UserId] = nil -- Takarítjuk a memóriát kilépéskor
end)