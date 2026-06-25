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
local playerLocks = {}

-- ==========================================
-- KASZT -> SKILL ENGEDÉLYEZÉS
-- ==========================================

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

-- ==========================================
-- SEGÉDFÜGGVÉNYEK
-- ==========================================

local function getPlayerClass(player, stats)
	local playerClass = player:GetAttribute("Class")

	if not playerClass and stats then
		local classObj = stats:FindFirstChild("Class")
		if classObj then
			playerClass = classObj.Value
		end
	end

	if not playerClass then
		return ""
	end

	return string.upper(tostring(playerClass))
end

local function getTargetModelAndRoot(target)
	if not target then
		return nil, nil
	end

	if typeof(target) ~= "Instance" then
		return nil, nil
	end

	local model = nil

	if target:IsA("Model") then
		model = target
	elseif target:IsA("BasePart") then
		model = target:FindFirstAncestorOfClass("Model")
	else
		return nil, nil
	end

	if not model or not model:IsA("Model") then
		return nil, nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end

	local rootPart =
		model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)

	if not rootPart then
		return nil, nil
	end

	return model, rootPart
end

local function getSkillCooldown(skill)
	local cooldown = tonumber(skill.Cooldown)

	if not cooldown or cooldown < 0 then
		return 1
	end

	return cooldown
end

local function getSkillMana(skill)
	local mana = tonumber(skill.Mana)

	if not mana or mana < 0 then
		return 0
	end

	return mana
end

local function getSkillRange(itemName, skill)
	local range = nil

	if SkillDatabase.Ranges and SkillDatabase.Ranges[itemName] then
		range = SkillDatabase.Ranges[itemName]
	else
		range = skill.Range
	end

	range = tonumber(range)

	if not range or range < 0 then
		return 0
	end

	return range
end

local function isSkillUnlocked(player, itemName)
	if SkillDatabase.playerHasUnlockedSkill then
		return SkillDatabase.playerHasUnlockedSkill(player, itemName)
	end

	return true
end

local function getRequiredSkillLevel(itemName)
	if SkillDatabase.getSkillRequiredLevel then
		return SkillDatabase.getSkillRequiredLevel(itemName)
	end

	return 1
end

local function getPlayerInventoryItemSlot(player, itemName, stats)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		return nil
	end

	local unlockedPages = 1
	local unlockedPagesObj = stats and stats:FindFirstChild("UnlockedPages")

	if unlockedPagesObj then
		unlockedPages = tonumber(unlockedPagesObj.Value) or 1
	end

	local maxUnlockedSlots = math.clamp(math.floor(unlockedPages * 32), 1, 999)

	for i = 1, maxUnlockedSlots do
		local slot = inv:FindFirstChild("Slot_" .. i)

		if slot and slot:IsA("StringValue") and slot.Value == itemName then
			return slot
		end
	end

	return nil
end

local function safeFireApplyEffect(player, itemName, effectName, value, duration)
	if ApplyEffect then
		ApplyEffect:FireClient(player, itemName, effectName, value, duration)
	end
end

local function safeFireSkillCooldown(player, itemName, cooldown)
	if SkillCooldown then
		SkillCooldown:FireClient(player, itemName, cooldown)
	end
end

-- ==========================================
-- FŐ HASZNÁLAT EVENT
-- ==========================================

UseItem.OnServerEvent:Connect(function(player, itemName, mousePos, target)
	-- BIZTONSÁG: itemName validáció
	if type(itemName) ~= "string" then
		return
	end

	if itemName == "" or string.len(itemName) > 80 then
		return
	end

	-- Anti-Spam: max kb. 10 kérés / mp
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < 0.1 then
		return
	end

	playerLocks[player.UserId] = tick()

	if typeof(mousePos) ~= "Vector3" then
		mousePos = Vector3.zero
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stats = player:FindFirstChild("PlayerStats")

	if not stats or not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	-- ==========================================
	-- 1. SKILL HASZNÁLAT
	-- ==========================================

	if SkillDatabase.Skills and SkillDatabase.Skills[itemName] then
		local skill = SkillDatabase.Skills[itemName]

		if type(skill) ~= "table" then
			warn("[SKILL HIBA] Hibás skill adat: " .. tostring(itemName))
			return
		end

		if type(skill.Execute) ~= "function" then
			warn("[SKILL HIBA] A skillnek nincs Execute függvénye: " .. tostring(itemName))
			return
		end

		-- Kaszt validáció
		local playerClass = getPlayerClass(player, stats)
		local allowedSkills = classSkillMap[playerClass]

		if not allowedSkills or not allowedSkills[itemName] then
			warn("[EXPLOIT GYANÚ] " .. player.Name .. " (" .. tostring(playerClass) .. ") illegális skillt próbált használni: " .. tostring(itemName))
			return
		end

		-- Skill unlock validáció
		if not isSkillUnlocked(player, itemName) then
			local requiredLevel = getRequiredSkillLevel(itemName)

			warn("[SKILL LOCK] " .. player.Name .. " túl alacsony szinten próbálta használni ezt a skillt: " .. tostring(itemName) .. " | Szükséges szint: " .. tostring(requiredLevel))
			return
		end

		local targetModel, targetRoot = getTargetModelAndRoot(target)
		local safeTarget = targetRoot

		-- Range validáció
		local skillRange = getSkillRange(itemName, skill)

		if skillRange > 0 and targetRoot then
			local dist = (root.Position - targetRoot.Position).Magnitude

			if dist > skillRange + 5 then
				return
			end
		end

		-- Cooldown validáció
		if not playerCooldowns[player.UserId] then
			playerCooldowns[player.UserId] = {}
		end

		local skillCooldown = getSkillCooldown(skill)
		local lastUsed = playerCooldowns[player.UserId][itemName] or 0

		if tick() - lastUsed < skillCooldown then
			return
		end

		local skillMana = getSkillMana(skill)
		local manaStat = stats:FindFirstChild("Mana")

		if skillMana > 0 then
			if not manaStat or manaStat.Value < skillMana then
				return
			end
		end

		-- Toggle képességek
		if skill.IsToggle then
			local toggleAttribute = skill.ToggleAttribute

			if type(toggleAttribute) ~= "string" or toggleAttribute == "" then
				warn("[SKILL HIBA] Toggle skillnél hiányzik a ToggleAttribute: " .. tostring(itemName))
				return
			end

			local currentToggleState = player:GetAttribute(toggleAttribute)

			-- Ha bekapcsolás történik, kell mana.
			if not currentToggleState and skillMana > 0 then
				if not manaStat or manaStat.Value < skillMana then
					return
				end
			end

			playerCooldowns[player.UserId][itemName] = tick()

			local executeOk, executeResult = pcall(function()
				return skill.Execute(player, character, root, mousePos, safeTarget)
			end)

			if not executeOk then
				warn("[SKILL EXECUTE HIBA] " .. tostring(itemName) .. " | " .. tostring(executeResult))
				playerCooldowns[player.UserId][itemName] = 0
				return
			end

			if executeResult == false then
				playerCooldowns[player.UserId][itemName] = 0
				return
			end

			safeFireSkillCooldown(player, itemName, skillCooldown)

			if not currentToggleState then
				if manaStat and skillMana > 0 then
					manaStat.Value -= skillMana
				end

				safeFireApplyEffect(player, itemName, itemName, 0, 99999)
			else
				safeFireApplyEffect(player, itemName, itemName, 0, 0)
			end

			return
		end

		-- Normál aktív képességek
		playerCooldowns[player.UserId][itemName] = tick()

		local executeOk, executeResult = pcall(function()
			return skill.Execute(player, character, root, mousePos, safeTarget)
		end)

		if not executeOk then
			warn("[SKILL EXECUTE HIBA] " .. tostring(itemName) .. " | " .. tostring(executeResult))
			playerCooldowns[player.UserId][itemName] = 0
			return
		end

		if executeResult == false then
			playerCooldowns[player.UserId][itemName] = 0
			return
		end

		if manaStat and skillMana > 0 then
			manaStat.Value -= skillMana
		end

		safeFireSkillCooldown(player, itemName, skillCooldown)

		if skill.Duration then
			safeFireApplyEffect(player, itemName, itemName, 0, skill.Duration)
		end

		return
	end

	-- ==========================================
	-- 2. FOGYÓESZKÖZ HASZNÁLAT
	-- ==========================================

	local itemData = ItemDatabase[itemName]

	if type(itemData) ~= "table" or itemData.Type ~= "Fogyóeszköz" then
		return
	end

	local foundSlot = getPlayerInventoryItemSlot(player, itemName, stats)
	if not foundSlot then
		return
	end

	local amtObj = foundSlot:FindFirstChild("Amount")
	local currentAmt = amtObj and amtObj.Value or 1

	if currentAmt <= 0 then
		return
	end

	local function consumeOne()
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

	local applied = false
	local healAmount = tonumber(itemData.HealAmount) or 0

	-- ==========================================
	-- ÉLETERŐ ITALOK
	-- működik:
	-- Életerő Ital
	-- Nagy Életerő Ital
	-- minden olyan potion, aminek a nevében benne van: Életerő
	-- ==========================================

	if healAmount > 0 and string.find(itemName, "Életerő", 1, true) then
		humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
		applied = true

		-- ==========================================
		-- MANA ITALOK
		-- működik:
		-- Mana Ital
		-- Nagy Mana Ital
		-- minden olyan potion, aminek a nevében benne van: Mana
		-- ==========================================

	elseif healAmount > 0 and string.find(itemName, "Mana", 1, true) then
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")

		if mana and maxMana then
			mana.Value = math.min(mana.Value + healAmount, maxMana.Value)
			applied = true
		end

		-- ==========================================
		-- BUFF ITALOK
		-- Zöld Ital, Ügyesség itala, Kritikus Ital,
		-- Vadász Ital, Metinromboló Ital stb.
		-- ==========================================

	elseif itemData.Effect then
		if not itemData.Value or not itemData.Duration then
			return
		end

		local effectName = tostring(itemData.Effect)
		local effectValue = tonumber(itemData.Value)
		local effectDuration = tonumber(itemData.Duration)

		if not effectValue or not effectDuration or effectDuration <= 0 then
			return
		end

		local statObj = stats:FindFirstChild(effectName)

		if not statObj then
			warn("[ITEM USE] " .. player.Name .. " olyan buff italt használt, amihez nincs stat: " .. tostring(effectName))
			return
		end

		local userId = player.UserId

		if not activePlayerEffects[userId] then
			activePlayerEffects[userId] = {}
		end

		if activePlayerEffects[userId][effectName] then
			-- Már aktív ez a buff, ne fogyasszuk el feleslegesen.
			safeFireApplyEffect(player, itemName, effectName, effectValue, effectDuration)
			return
		end

		statObj.Value += effectValue
		activePlayerEffects[userId][effectName] = true
		applied = true

		if effectName == "MovementSpeed" and humanoid and humanoid.WalkSpeed > 0 then
			humanoid.WalkSpeed = 16 * (1 + (statObj.Value / 100))
		end

		safeFireApplyEffect(player, itemName, effectName, effectValue, effectDuration)

		task.spawn(function()
			task.wait(effectDuration)

			if player and player.Parent and player:FindFirstChild("PlayerStats") then
				local currentStats = player:FindFirstChild("PlayerStats")
				local currentStat = currentStats and currentStats:FindFirstChild(effectName)

				if currentStat then
					currentStat.Value = math.max(0, currentStat.Value - effectValue)

					if effectName == "MovementSpeed" and player.Character then
						local currentHumanoid = player.Character:FindFirstChildOfClass("Humanoid")

						if currentHumanoid and currentHumanoid.WalkSpeed > 0 then
							currentHumanoid.WalkSpeed = 16 * (1 + (currentStat.Value / 100))
						end
					end
				end
			end

			if activePlayerEffects[userId] then
				activePlayerEffects[userId][effectName] = nil
			end
		end)
	end

	if not applied then
		return
	end

	consumeOne()
end)

-- ==========================================
-- TAKARÍTÁS
-- ==========================================

Players.PlayerRemoving:Connect(function(player)
	activePlayerEffects[player.UserId] = nil
	playerCooldowns[player.UserId] = nil
	playerLocks[player.UserId] = nil
end)