-- Fájl helye: ServerScriptService -> CombatHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MeleeAttack = Events:WaitForChild("MeleeAttack")
local ShowDamage = Events:WaitForChild("ShowDamage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

MeleeAttack.OnServerEvent:Connect(function(player)
	local character = player.Character
	-- HA A JÁTÉKOS ÜT, ELVESZÍTI A SÉRTHETETLENSÉGET!
	if character and character:GetAttribute("Invincible") then
		character:SetAttribute("Invincible", false)
	end
	local stats = player:FindFirstChild("PlayerStats")
	local equipment = player:FindFirstChild("Equipment")
	if not character or not stats or not equipment then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local weaponName = equipment:FindFirstChild("Fegyver") and equipment.Fegyver.Value or ""

	local minDmg, maxDmg = 1, 5 
	if weaponName ~= "" and ItemDatabase[weaponName] then
		minDmg = ItemDatabase[weaponName].MinDmg or 1
		maxDmg = ItemDatabase[weaponName].MaxDmg or 5
	end

	local baseDamage = math.random(minDmg, maxDmg) + (stats.STR.Value * 2)

	local protectedNPCs = {
		["Fegyverkereskedo"] = true, 
		["Pancelkereskedo"] = true, 
		["Vegyesbolt"] = true, 
		["Kovacs"] = true, 
		["Faluose"] = true,
		["Varosor"] = true,
		["Raktaros"] = true
	}

	local possibleTargets = {}

	for _, obj in pairs(workspace:GetChildren()) do
		table.insert(possibleTargets, obj)
	end

	local mFolder = workspace:FindFirstChild("MetinStones")
	if mFolder then
		for _, stone in pairs(mFolder:GetChildren()) do
			table.insert(possibleTargets, stone)
		end
	end

	local monFolder = workspace:FindFirstChild("Monsters")
	if monFolder then
		for _, monster in pairs(monFolder:GetChildren()) do
			table.insert(possibleTargets, monster)
		end
	end

	-- ÚJ: ÉRCEK BEOLVASÁSA
	-- ÚJ: ÉRCEK BEOLVASÁSA
	local oFolder = workspace:FindFirstChild("Ores")
	if oFolder then
		for _, ore in pairs(oFolder:GetChildren()) do
			table.insert(possibleTargets, ore)
		end
	end

	local oreHitCount = 0 -- JAVÍTÁS: Számláló, hogy csak 1 ércet üthess egyszerre!

	for _, obj in pairs(possibleTargets) do
		if obj:IsA("Model") and obj ~= character and obj:FindFirstChild("Humanoid") then
			local targetRoot = obj:FindFirstChild("HumanoidRootPart")
			local targetHum = obj.Humanoid

			if targetRoot and targetHum.Health > 0 and not protectedNPCs[obj.Name] then

				-- ==========================================
				-- ÚJ: SÉRTHETETLENSÉG (VÉDELEM) ELLENŐRZÉSE
				-- ==========================================
				if obj:GetAttribute("Invincible") then continue end

				local distance = (rootPart.Position - targetRoot.Position).Magnitude
				local directionToTarget = (targetRoot.Position - rootPart.Position).Unit
				local facingDirection = rootPart.CFrame.LookVector
				local dotProduct = facingDirection:Dot(directionToTarget)

				if distance <= 12 and dotProduct > 0.3 then
					local finalDamage = 0
					local isCrit = false

					-- ==========================================
					-- JAVÍTÁS: BÁNYÁSZAT (ÉRC) ELLENŐRZÉSE
					-- ==========================================
					local isOre = (obj.Parent and obj.Parent.Name == "Ores") or obj:GetAttribute("IsOre")

					if isOre then
						if oreHitCount >= 1 then continue end -- Ha már ütöttünk egyet, a többit átugorjuk!

						local isPickaxe = false
						if weaponName ~= "" and ItemDatabase[weaponName] and ItemDatabase[weaponName].IsPickaxe then
							isPickaxe = true
						end

						-- Ha nincs csákány, átugorjuk (FONTOS: continue kell, nem return!)
						if not isPickaxe then continue end 

						finalDamage = 1 
						oreHitCount += 1
					else
						-- NORMÁL SZÖRNY / JÁTÉKOS SEBZÉS
						local defense = 0 
						finalDamage = math.max(1, baseDamage - defense)

						if math.random(1, 100) <= stats.CritChance.Value then
							finalDamage = finalDamage * 2
							isCrit = true
						end

						local isMetin = (obj.Parent and obj.Parent.Name == "MetinStones")

						if isMetin then
							finalDamage = finalDamage * (1 + (stats.StrongVsMetin.Value / 100))
						elseif obj:FindFirstChild("IsPlayer") then
							finalDamage = finalDamage * (1 + (stats.StrongVsPlayer.Value / 100))
						else
							finalDamage = finalDamage * (1 + (stats.StrongVsMonster.Value / 100))
						end

						finalDamage = math.floor(finalDamage)

						if stats.LifeSteal.Value > 0 then
							local healAmt = finalDamage * (stats.LifeSteal.Value / 100)
							character.Humanoid.Health = math.min(character.Humanoid.MaxHealth, character.Humanoid.Health + healAmt)
						end
					end

					-- Sebzés kiosztása és kliens értesítése
					targetHum:TakeDamage(finalDamage)
					ShowDamage:FireAllClients(finalDamage, targetRoot.Position, isCrit, false)
				end
			end
		end
	end
end)