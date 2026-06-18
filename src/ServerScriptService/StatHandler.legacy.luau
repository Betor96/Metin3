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

	local vit = stats.VIT.Value
	local int = stats.INT.Value
	local dex = stats.DEX.Value

	-- Alap bónuszok nullázása
	local bDef, bMetin, bMonst, bHum, bLs, bCrit, bDD, bDG, bAs, bMs, bDodge, eqHp, eqMp = 0,0,0,0,0,0,0,0,0,0,0,0,0

	-- Tárgyak bónuszainak összeadása
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

	-- Értékek beállítása
	stats.Defense.Value = bDef
	stats.StrongVsMetin.Value = bMetin
	stats.StrongVsMonster.Value = bMonst
	stats.StrongVsPlayer.Value = bHum
	stats.LifeSteal.Value = bLs
	
	-- DEX adja a kritikus esélyt (Minden 10 DEX = +1% Crit, azaz 0.1/pont)
	stats.CritChance.Value = math.clamp(math.floor(dex / 10) + bCrit, 0, 100)

	stats.DoubleDrop.Value = bDD
	stats.DoubleGold.Value = bDG
	stats.AttackSpeed.Value = bAs
	stats.MovementSpeed.Value = bMs
	stats.DodgeChance.Value = math.clamp(bDodge, 0, 100)

	-- INT adja a maximális Manát (Minden INT = +10 Mana)
	stats.MaxMana.Value = 100 + (int * 10) + eqMp

	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid
		-- VIT adja a maximális HP-t (Minden VIT = +20 HP)
		hum.MaxHealth = 100 + (vit * 20) + eqHp
		if hum.Health > hum.MaxHealth then hum.Health = hum.MaxHealth end

		-- Alap sebesség 16 + a mozgási sebesség bónusz százaléka
		hum.WalkSpeed = 16 * (1 + (bMs / 100))
	end
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
	stats.VIT.Changed:Connect(function() recalculateStats(player) end)
	stats.INT.Changed:Connect(function() recalculateStats(player) end)
	stats.DEX.Changed:Connect(function() recalculateStats(player) end)

	for _, slot in pairs(eq:GetChildren()) do
		slot.Changed:Connect(function() recalculateStats(player) end)
	end

	-- ==========================================
	-- JAVÍTÁS: BIZTONSÁGOS KARAKTER BETÖLTÉS
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

	-- HA A KARAKTER MÁR LÉTEZIK a belépéskor (ez okozta a hibát!):
	if player.Character then
		task.spawn(function()
			onCharacterSpawned(player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
