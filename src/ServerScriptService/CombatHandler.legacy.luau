-- Fájl helye: ServerScriptService -> CombatHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MeleeAttack = Events:WaitForChild("MeleeAttack")
local ShowDamage = Events:WaitForChild("ShowDamage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

MeleeAttack.OnServerEvent:Connect(function(player)
	local character = player.Character
	local stats = player:FindFirstChild("PlayerStats")
	local equipment = player:FindFirstChild("Equipment")
	if not character or not stats or not equipment then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local weaponName = equipment:FindFirstChild("Fegyver") and equipment.Fegyver.Value or ""

	local minDmg, maxDmg = 1, 5 -- Alap ökölsebzés
	if weaponName ~= "" and ItemDatabase[weaponName] then
		minDmg = ItemDatabase[weaponName].MinDmg or 1
		maxDmg = ItemDatabase[weaponName].MaxDmg or 5
	end

	-- Erő (STR) bónusz
	local baseDamage = math.random(minDmg, maxDmg) + (stats.STR.Value * 2)

	-- Az NPC-k védelme
	local protectedNPCs = {
		["Fegyverkereskedo"] = true, 
		["Pancelkereskedo"] = true, 
		["Vegyesbolt"] = true, 
		["Kovacs"] = true, 
		["Faluose"] = true,
		["Varosor"] = true,
		["Raktaros"] = true
	}

	-- ==========================================
	-- JAVÍTÁS: Célpontok kigyűjtése MINDEN mappából!
	-- ==========================================
	local possibleTargets = {}

	-- 1. Sima Workspace elemek (Játékosok, NPC-k)
	for _, obj in pairs(workspace:GetChildren()) do
		table.insert(possibleTargets, obj)
	end

	-- 2. Metinkövek
	local mFolder = workspace:FindFirstChild("MetinStones")
	if mFolder then
		for _, stone in pairs(mFolder:GetChildren()) do
			table.insert(possibleTargets, stone)
		end
	end

	-- 3. SZÖRNYEK (Ez hiányzott, emiatt nem sebezte a farkast!)
	local monFolder = workspace:FindFirstChild("Monsters")
	if monFolder then
		for _, monster in pairs(monFolder:GetChildren()) do
			table.insert(possibleTargets, monster)
		end
	end

	for _, obj in pairs(possibleTargets) do
		if obj:IsA("Model") and obj ~= character and obj:FindFirstChild("Humanoid") then
			local targetRoot = obj:FindFirstChild("HumanoidRootPart")
			local targetHum = obj.Humanoid

			if targetRoot and targetHum.Health > 0 and not protectedNPCs[obj.Name] then
				local distance = (rootPart.Position - targetRoot.Position).Magnitude

				-- ÚJ: Irányított (Frontális) sebzés számítása
				local directionToTarget = (targetRoot.Position - rootPart.Position).Unit
				local facingDirection = rootPart.CFrame.LookVector
				local dotProduct = facingDirection:Dot(directionToTarget)

				-- distance <= 12 (Távolság) ÉS dotProduct > 0.3 (Karakter előtt van, kb 120 fokos szögben)
				if distance <= 12 and dotProduct > 0.3 then
					local finalDamage = baseDamage
					local isCrit = false

					-- 1. Kritikus ütés ellenőrzése
					if math.random(1, 100) <= stats.CritChance.Value then
						finalDamage = finalDamage * 2
						isCrit = true
					end

					-- 2. Szörny / Metinkő / Ember elleni erő JAVÍTÁSA
					-- Mivel letöröltük a MetinStoneLogic scriptet a kövekről, a mappájuk alapján azonosítjuk őket!
					local isMetin = (obj.Parent and obj.Parent.Name == "MetinStones")

					if isMetin then
						finalDamage = finalDamage * (1 + (stats.StrongVsMetin.Value / 100))
					elseif obj:FindFirstChild("IsPlayer") then
						finalDamage = finalDamage * (1 + (stats.StrongVsPlayer.Value / 100))
					else
						finalDamage = finalDamage * (1 + (stats.StrongVsMonster.Value / 100))
					end

					finalDamage = math.floor(finalDamage)

					-- 3. Életvarázs (Life Steal)
					if stats.LifeSteal.Value > 0 then
						local healAmt = finalDamage * (stats.LifeSteal.Value / 100)
						character.Humanoid.Health = math.min(character.Humanoid.MaxHealth, character.Humanoid.Health + healAmt)
					end

					-- Sebzés kiosztása és kliens értesítése
					targetHum:TakeDamage(finalDamage)
					ShowDamage:FireAllClients(finalDamage, targetRoot.Position, isCrit, false)
				end
			end
		end
	end
end)