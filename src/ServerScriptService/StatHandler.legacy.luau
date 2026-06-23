-- Fájl helye: ServerScriptService -> StatHandler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local AddStatPoint = Events:WaitForChild("AddStatPoint")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local function updateWalkSpeed(player)
	local stats = player:FindFirstChild("PlayerStats")
	local char = player.Character
	if not stats or not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	local rawClass = player:GetAttribute("Class") or "GUARDIAN"
	local pClass = string.upper(rawClass)

	local ms = stats:FindFirstChild("MovementSpeed") and stats.MovementSpeed.Value or 0
	local def = stats:FindFirstChild("Defense") and stats.Defense.Value or 0

	local baseSpeed = 16
	local activeSpeed = baseSpeed * (1 + (ms / 100))

	if pClass == "SHADOWBLADE" then
		local armorThreshold = 30
		if def > armorThreshold then
			local overArmor = def - armorThreshold
			local penaltyStacks = math.floor(overArmor / 10)
			local penaltyPercent = penaltyStacks * 0.05
			activeSpeed = activeSpeed * (1 - penaltyPercent)
		end
	end

	if player:GetAttribute("IronSkin_Active") then
		activeSpeed = activeSpeed - 3.2
	end

	hum.WalkSpeed = math.max(baseSpeed * 0.25, activeSpeed)
	player:SetAttribute("TrueWalkSpeed", hum.WalkSpeed)
end

local function recalculateStats(player)
	local stats = player:FindFirstChild("PlayerStats")
	local eq = player:FindFirstChild("Equipment")
	local char = player.Character
	local leaderstats = player:FindFirstChild("leaderstats")
	if not stats or not eq then return end

	-- Szint lekérése (Ha 1-es szintű, nincs bónusz, 2-es szinttől kapja)
	local level = leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or 1

	local baseStr = stats.STR.Value
	local baseVit = stats.VIT.Value
	local baseInt = stats.INT.Value
	local baseDex = stats.DEX.Value

	local rawClass = player:GetAttribute("Class") or "GUARDIAN"
	local pClass = string.upper(rawClass)

	local bDef, bMetin, bMonst, bHum, bLs, bCrit, bDD, bDG, bAs, bMs, bDodge, eqHp, eqMp = 0,0,0,0,0,0,0,0,0,0,0,0,0
	local bVit, bInt, bStr, bDex = 0, 0, 0, 0

	for _, slot in pairs(eq:GetChildren()) do
		if (slot:IsA("ValueBase") or slot:IsA("StringValue")) and slot.Value ~= "" then
			local dat = ItemDatabase[slot.Value]
			if dat then
				bDef += (dat.Defense or dat.Armor or 0)
				bMetin += dat.StrongVsMetin or 0
				bMonst += dat.StrongVsMonster or 0
				bHum += dat.StrongVsPlayer or 0
				bLs += dat.LifeSteal or 0
				bCrit += dat.CritChance or 0
				bDD += dat.DoubleDrop or 0
				bDG += dat.DoubleGold or 0
				bAs += dat.AttackSpeed or 0
				bMs += dat.MovementSpeed or 0
				bDodge += dat.DodgeChance or 0

				eqHp += (dat.MaxHealth or dat.HP or 0)
				eqMp += (dat.MaxMana or dat.MP or 0)

				bVit += dat.VIT or 0
				bInt += dat.INT or 0
				bStr += dat.STR or 0
				bDex += dat.DEX or 0
			end
		end
	end

	local totalVit = baseVit + bVit
	local totalInt = baseInt + bInt
	local totalStr = baseStr + bStr
	local totalDex = baseDex + bDex

	-- ==========================================
	-- ALAPÉRTÉKEK (Szint bónusz hozzáadása)
	-- ==========================================
	-- Minden szintlépés ad +30 HP-t és +10 Manát teljesen ingyen!
	local levelBonusHP = (level - 1) * 30
	local levelBonusMana = (level - 1) * 10

	local finalMaxHP = 100 + levelBonusHP
	local finalMaxMana = 100 + levelBonusMana + (totalInt * 10) + eqMp

	local finalDamage = 5
	local finalDefense = bDef

	local baseSpeed = 16 
	local finalSpeed = baseSpeed * (1 + (bMs / 100))

	-- ==========================================
	-- KASZTSPECIFIKUS SZÁMOLÁSOK
	-- ==========================================
	if pClass == "GUARDIAN" then
		finalMaxHP = finalMaxHP + (totalVit * 25)
		finalDamage = 5 + (totalStr * 2.5)

		local effectiveInt = totalInt + math.floor(eqMp / 10)
		local intThreshold = 10

		if effectiveInt > intThreshold then
			local overInt = effectiveInt - intThreshold
			local penaltyStacks = math.floor(overInt / 10)
			finalDefense = finalDefense * (1 - (penaltyStacks * 0.10))
		end

	elseif pClass == "SHADOWBLADE" then
		finalMaxHP = finalMaxHP + (totalVit * 12)
		finalDamage = 5 + (totalStr * 1.5) + (totalDex * 2.5)
		finalSpeed = finalSpeed + (totalDex * 0.1)

		local armorThreshold = 30
		if finalDefense > armorThreshold then
			local overArmor = finalDefense - armorThreshold
			local penaltyStacks = math.floor(overArmor / 10) 
			local penaltyPercent = penaltyStacks * 0.05 
			finalSpeed = finalSpeed * (1 - penaltyPercent)
			finalDamage = finalDamage * (1 - penaltyPercent)
		end

	elseif pClass == "SOULWEAVER" then
		finalMaxHP = finalMaxHP + (totalVit * 10) 
		finalDamage = 5 + (totalInt * 3.5) + (totalDex * 0.5)

		-- JAVÍTÁS: A büntetést adó "effectiveVit" értékből KIVETTÜK a Szintlépés HP-t!
		-- Csak a kiosztott pont (totalVit) és a tárgyak (eqHp) büntetnek!
		local effectiveVit = totalVit + math.floor(eqHp / 10)
		local vitThreshold = 30

		if effectiveVit > vitThreshold then
			local overVit = effectiveVit - vitThreshold
			local penaltyStacks = math.floor(overVit / 10)
			local penaltyPercent = penaltyStacks * 0.15

			finalDamage = finalDamage * (1 - penaltyPercent)
			finalDefense = finalDefense - (penaltyStacks * 5)
		end

	elseif pClass == "SEALER" then
		finalMaxHP = finalMaxHP + (totalVit * 15)
		finalDamage = 5 + (totalInt * 2.5) + (totalStr * 1)

		local dexThreshold = 15
		if totalDex > dexThreshold then
			local overDex = totalDex - dexThreshold
			local penaltyStacks = math.floor(overDex / 10)
			finalDamage = finalDamage * (1 - (penaltyStacks * 0.15))
		end
	end

	if pClass == "GUARDIAN" then
		local currentIronWillBonus = player:GetAttribute("IronWill_DefBonus") or 0
		finalDefense = finalDefense + currentIronWillBonus
	end

	finalMaxHP = finalMaxHP + eqHp

	-- STATOK FRISSÍTÉSE
	stats.Defense.Value = math.max(0, finalDefense)
	stats.StrongVsMetin.Value = bMetin
	stats.StrongVsMonster.Value = bMonst
	stats.StrongVsPlayer.Value = bHum
	stats.LifeSteal.Value = bLs
	stats.CritChance.Value = math.clamp(math.floor(totalDex / 10) + bCrit, 0, 100)
	stats.DoubleDrop.Value = bDD
	stats.DoubleGold.Value = bDG
	stats.AttackSpeed.Value = bAs
	stats.MovementSpeed.Value = bMs
	stats.DodgeChance.Value = math.clamp(bDodge, 0, 100)
	stats.MaxMana.Value = math.max(0, finalMaxMana)

	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid
		local currentHpPercent = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1
		hum.MaxHealth = math.max(1, finalMaxHP)
		hum.Health = hum.MaxHealth * currentHpPercent
	end

	player:SetAttribute("AttackDamage", math.max(0, math.floor(finalDamage)))
	player:SetAttribute("Armor", math.max(0, math.floor(finalDefense)))

	updateWalkSpeed(player)
end

local function setupPlayer(player)
	local stats = player:WaitForChild("PlayerStats")
	local eq = player:WaitForChild("Equipment")

	-- JAVÍTÁS: Figyeljük a szintlépést, és azonnal frissítjük a statokat!
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats and leaderstats:FindFirstChild("Level") then
		leaderstats.Level.Changed:Connect(function() recalculateStats(player) end)
	end

	AddStatPoint.OnServerEvent:Connect(function(plr, statName)
		if plr ~= player then return end
		local pts = stats:FindFirstChild("StatPoints")
		local targetStat = stats:FindFirstChild(statName)
		if pts and pts.Value > 0 and targetStat then
			pts.Value -= 1
			targetStat.Value += 1
		end
	end)

	stats.STR.Changed:Connect(function() recalculateStats(player) end) 
	stats.VIT.Changed:Connect(function() recalculateStats(player) end)
	stats.INT.Changed:Connect(function() recalculateStats(player) end)
	stats.DEX.Changed:Connect(function() recalculateStats(player) end)

	stats.Defense.Changed:Connect(function() updateWalkSpeed(player) end)
	stats.MovementSpeed.Changed:Connect(function() updateWalkSpeed(player) end)
	player:GetAttributeChangedSignal("IronSkin_Active"):Connect(function() updateWalkSpeed(player) end)
	player:GetAttributeChangedSignal("Class"):Connect(function() updateWalkSpeed(player) end)

	local function bindSlot(slot)
		if slot:IsA("ValueBase") or slot:IsA("StringValue") then
			slot.Changed:Connect(function() recalculateStats(player) end)
		end
	end

	for _, slot in pairs(eq:GetChildren()) do bindSlot(slot) end
	eq.ChildAdded:Connect(bindSlot)

	local function onCharacterSpawned(newChar)
		newChar:WaitForChild("Humanoid", 10)
		task.wait(0.5) 
		recalculateStats(player)
	end

	player.CharacterAdded:Connect(onCharacterSpawned)
	if player.Character then task.spawn(function() onCharacterSpawned(player.Character) end) end
end

Players.PlayerAdded:Connect(setupPlayer)