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
	-- KASZT LEKÉRÉSE
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
	-- KASZTSPECIFIKUS SZÁMOLÁSOK ÉS %-OS BÜNTETÉSEK
	-- ==========================================
	local finalMaxHP = 100
	local finalDamage = 5
	local finalDefense = bDef

	-- Alap, minden módosító nélküli séta sebesség (Roblox alap: 16)
	local baseSpeed = 16 
	local finalSpeed = baseSpeed * (1 + (bMs / 100)) -- Felszereléssel növelt sebesség

	if pClass == "GUARDIAN" then
		finalMaxHP = 100 + (vit * 25)
		finalDamage = 5 + (str * 2.5)

		-- BÜNTETÉS: Minden 10 INT = -10% Páncél
		if int >= 10 then
			local penaltyStacks = math.floor(int / 10)
			local penaltyPercent = penaltyStacks * 0.10
			finalDefense = finalDefense * (1 - penaltyPercent)
		end

	elseif pClass == "SHADOWBLADE" then
		finalMaxHP = 100 + (vit * 12)
		finalDamage = 5 + (str * 1.5) + (dex * 2.5)
		finalSpeed = finalSpeed + (dex * 0.1)

		-- BÜNTETÉS: Minden 10 Páncél (Defense) = -5% Mozgás és -5% Sebzés
		if finalDefense >= 10 then
			local penaltyStacks = math.floor(finalDefense / 10) 
			local penaltyPercent = penaltyStacks * 0.05 

			finalSpeed = finalSpeed * (1 - penaltyPercent)
			finalDamage = finalDamage * (1 - penaltyPercent)
		end

	elseif pClass == "SOULWEAVER" then
		finalMaxHP = 100 + (vit * 10) 
		finalDamage = 5 + (int * 3.5) + (dex * 0.5)

		-- BÜNTETÉS: Minden 10 VIT = -15% Sebzés és -5 Fix Páncél
		if vit >= 10 then
			local penaltyStacks = math.floor(vit / 10)
			local penaltyPercent = penaltyStacks * 0.15

			finalDamage = finalDamage * (1 - penaltyPercent)
			finalDefense = finalDefense - (penaltyStacks * 5)
		end

	elseif pClass == "SEALER" then
		finalMaxHP = 100 + (vit * 15)
		finalDamage = 5 + (int * 2.5) + (str * 1)

		-- BÜNTETÉS: Minden 10 DEX = -15% Sebzés
		if dex >= 10 then
			local penaltyStacks = math.floor(dex / 10)
			local penaltyPercent = penaltyStacks * 0.15

			finalDamage = finalDamage * (1 - penaltyPercent)
		end
	end

	-- GUARDIAN JAVÍTÁS: Ha az Iron Will (HP) bónuszod aktív, hozzáadjuk, hogy ruhacserekor is megmaradjon
	if pClass == "GUARDIAN" then
		local currentIronWillBonus = player:GetAttribute("IronWill_DefBonus") or 0
		finalDefense = finalDefense + currentIronWillBonus
	end

	finalMaxHP = finalMaxHP + eqHp
	local finalMaxMana = 100 + (int * 10) + eqMp

	-- ==========================================
	-- STATOK FRISSÍTÉSE A JÁTÉKOSBAN
	-- ==========================================
	stats.Defense.Value = math.max(0, finalDefense)
	stats.StrongVsMetin.Value = bMetin
	stats.StrongVsMonster.Value = bMonst
	stats.StrongVsPlayer.Value = bHum
	stats.LifeSteal.Value = bLs
	stats.CritChance.Value = math.clamp(math.floor(dex / 10) + bCrit, 0, 100)
	stats.DoubleDrop.Value = bDD
	stats.DoubleGold.Value = bDG
	stats.AttackSpeed.Value = bAs
	stats.MovementSpeed.Value = bMs
	stats.DodgeChance.Value = math.clamp(bDodge, 0, 100)
	stats.MaxMana.Value = math.max(0, finalMaxMana)

	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid

		-- Kiszámoljuk az arányt, hogy szintlépéskor/cucc levételkor ne fogyjon el a HP
		local currentHpPercent = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1

		hum.MaxHealth = math.max(1, finalMaxHP)
		hum.Health = hum.MaxHealth * currentHpPercent

		-- SZIGORÚ SEBESSÉG BEÁLLÍTÁS (Iron Skin aktív-e?)
		local activeSpeed = finalSpeed
		if player:GetAttribute("IronSkin_Active") then
			activeSpeed = activeSpeed - 3.2 
		end

		-- ÚJ KORLÁT: Az alap sebesség (16) 1/4-e a legkisebb sebesség, ameddig le lehet lassulni (4)
		local minSpeedLimit = baseSpeed * 0.25
		hum.WalkSpeed = math.max(minSpeedLimit, activeSpeed) 
	end

	-- A sebzést és páncélt is levédjük, hogy ne mehessen 0 alá (ne gyógyítsa az ellenfelet)
	player:SetAttribute("AttackDamage", math.max(0, math.floor(finalDamage)))
	player:SetAttribute("Armor", math.max(0, math.floor(finalDefense)))
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