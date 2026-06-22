-- Fájl helye: ServerScriptService -> StatHandler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local AddStatPoint = Events:WaitForChild("AddStatPoint")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local function recalculateStats(player)
	local stats = player:FindFirstChild("PlayerStats")
	local eq = player:FindFirstChild("Equipment")
	local char = player.Character
	if not stats or not eq then return end

	local str = stats.STR.Value
	local vit = stats.VIT.Value
	local int = stats.INT.Value
	local dex = stats.DEX.Value

	-- ==========================================
	-- JAVÍTÁS: Bolondbiztos Kaszt Lekérés!
	-- Mindent NAGYBETŰSRE alakít, hogy a büntetések garantáltan leforgassanak.
	-- ==========================================
	local rawClass = player:GetAttribute("Class") or "GUARDIAN"
	local pClass = string.upper(rawClass)

	-- Alap bónuszok nullázása
	local bDef, bMetin, bMonst, bHum, bLs, bCrit, bDD, bDG, bAs, bMs, bDodge, eqHp, eqMp = 0,0,0,0,0,0,0,0,0,0,0,0,0

	-- Tárgyak bónuszainak összeadása (Felszerelésből)
	for _, slot in pairs(eq:GetChildren()) do
		if slot.Value ~= "" then
			local dat = ItemDatabase[slot.Value]
			if dat then
				bDef += dat.Defense or 0
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
				eqHp += dat.MaxHealth or 0
				eqMp += dat.MaxMana or 0
			end
		end
	end

	-- ==========================================
	-- KASZTSPECIFIKUS SZÁMOLÁSOK ÉS BÜNTETÉSEK
	-- ==========================================
	local finalMaxHP = 100
	local finalDamage = 5
	local finalDefense = bDef
	local finalSpeed = 16 * (1 + (bMs / 100)) -- Alap sebesség + a cipő bónusza

	if pClass == "GUARDIAN" then
		finalMaxHP = 100 + (vit * 25)
		finalDamage = 5 + (str * 2.5)
		-- BÜNTETÉS: Magas INT csökkenti a páncélt (Minden 1 INT 10 felett = -2 Páncél)
		if int > 10 then
			local penalty = (int - 10) * 2
			finalDefense = math.max(0, finalDefense - penalty)
		end

	elseif pClass == "SHADOWBLADE" then
		finalMaxHP = 100 + (vit * 12)
		finalDamage = 5 + (str * 1.5) + (dex * 2.5)
		finalSpeed = finalSpeed + (dex * 0.1)

		-- BÜNTETÉS: Túl sok páncél (30 felett) drasztikusan lassít és gyengít!
		if finalDefense > 30 then
			local overArmor = finalDefense - 30
			local slowPenalty = overArmor * 0.3 -- Minden +1 extra Páncél = -0.3 Sebesség
			local dmgPenalty = overArmor * 0.03 -- Minden +1 extra Páncél = -3% Sebzés

			finalSpeed = math.max(5, finalSpeed - slowPenalty) -- Max 5-ig lassulhat (ne álljon meg teljesen)
			finalDamage = finalDamage * math.max(0.1, (1 - dmgPenalty))
		end

	elseif pClass == "SOULWEAVER" then
		finalMaxHP = 100 + (vit * 10) 
		finalDamage = 5 + (int * 3.5) + (dex * 0.5)

		-- BÜNTETÉS: Túl sok HP/VIT (20 felett) durván gyengíti a varázslatot
		if vit > 20 then
			local dmgPenalty = (vit - 20) * 0.05 -- Minden +1 VIT = -5% Sebzés
			finalDamage = finalDamage * math.max(0.1, (1 - dmgPenalty))
			finalDefense = math.max(0, finalDefense - (vit - 20)) -- Bónusz büntetés a páncélra
		end

	elseif pClass == "SEALER" then
		finalMaxHP = 100 + (vit * 15)
		finalDamage = 5 + (int * 2.5) + (str * 1)

		-- BÜNTETÉS: Magas DEX (15 felett) rontja az alap sebzést
		if dex > 15 then
			local dmgPenalty = (dex - 15) * 0.05 -- Minden +1 DEX = -5% Sebzés
			finalDamage = finalDamage * math.max(0.1, (1 - dmgPenalty))
		end
	end

	-- GUARDIAN JAVÍTÁS: Ha az Iron Will (HP) bónuszod aktív, hozzáadjuk, hogy ruhacserekor is megmaradjon!
	if pClass == "GUARDIAN" then
		local currentIronWillBonus = player:GetAttribute("IronWill_DefBonus") or 0
		finalDefense = finalDefense + currentIronWillBonus
	end

	-- Hozzáadjuk a kaszt által kapott HP-hoz a Felszerelés által adott bónuszt
	finalMaxHP = finalMaxHP + eqHp
	local finalMaxMana = 100 + (int * 10) + eqMp

	-- Értékek beállítása
	stats.Defense.Value = finalDefense
	stats.StrongVsMetin.Value = bMetin
	stats.StrongVsMonster.Value = bMonst
	stats.StrongVsPlayer.Value = bHum
	stats.LifeSteal.Value = bLs

	-- DEX adja a kritikus esélyt (Minden 10 DEX = +1% Crit)
	stats.CritChance.Value = math.clamp(math.floor(dex / 10) + bCrit, 0, 100)

	stats.DoubleDrop.Value = bDD
	stats.DoubleGold.Value = bDG
	stats.AttackSpeed.Value = bAs
	stats.MovementSpeed.Value = bMs
	stats.DodgeChance.Value = math.clamp(bDodge, 0, 100)
	stats.MaxMana.Value = finalMaxMana

	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid

		-- Kiszámoljuk az arányt, hogy szintlépéskor/cucc levételkor ne fogyjon el a HP-ja vizuálisan
		local currentHpPercent = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1

		hum.MaxHealth = finalMaxHP
		hum.Health = finalMaxHP * currentHpPercent
		hum.WalkSpeed = finalSpeed
	end

	-- Eltároljuk a végső statokat a játékoson, hogy a CombatHandler (Harcrendszer) ezekből számoljon!
	player:SetAttribute("AttackDamage", math.floor(finalDamage))
	player:SetAttribute("Armor", math.floor(finalDefense))
end

local function setupPlayer(player)
	local stats = player:WaitForChild("PlayerStats")
	local eq = player:WaitForChild("Equipment")

	-- Ha eloszt egy pontot
	AddStatPoint.OnServerEvent:Connect(function(plr, statName)
		if plr ~= player then return end
		local pts = stats:FindFirstChild("StatPoints")
		local targetStat = stats:FindFirstChild(statName)

		if pts and pts.Value > 0 and targetStat then
			pts.Value -= 1
			targetStat.Value += 1
		end
	end)

	-- Bármilyen stat vagy felszerelés változik, újraszámolunk!
	stats.STR.Changed:Connect(function() recalculateStats(player) end) -- ÚJ: STR is be lett kötve!
	stats.VIT.Changed:Connect(function() recalculateStats(player) end)
	stats.INT.Changed:Connect(function() recalculateStats(player) end)
	stats.DEX.Changed:Connect(function() recalculateStats(player) end)

	for _, slot in pairs(eq:GetChildren()) do
		slot.Changed:Connect(function() recalculateStats(player) end)
	end

	-- ==========================================
	-- BIZTONSÁGOS KARAKTER BETÖLTÉS
	-- ==========================================
	local function onCharacterSpawned(newChar)
		newChar:WaitForChild("Humanoid", 10)
		-- Várunk 1 másodpercet, hogy a Roblox alaprendszerei 
		-- biztosan beállítsák az alapértékeket, és csak utána írjuk felül!
		task.wait(1) 
		recalculateStats(player)
	end

	-- Ha meghalsz és újraéledsz, ez fog lefutni
	player.CharacterAdded:Connect(onCharacterSpawned)

	-- HA A KARAKTER MÁR LÉTEZIK a belépéskor:
	if player.Character then
		task.spawn(function()
			onCharacterSpawned(player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)