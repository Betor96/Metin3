	-- Fájl helye: ServerScriptService -> CombatHandler

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Events = ReplicatedStorage:WaitForChild("Events")
	local MeleeAttack = Events:WaitForChild("MeleeAttack")
	local ShowDamage = Events:WaitForChild("ShowDamage")
	local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
	local Players = game:GetService("Players")

	-- ==========================================
	-- BIZTONSÁG: Anti-Spam (Makró és Auto-clicker védelem)
	-- ==========================================
	local attackLocks = {}
	Players.PlayerRemoving:Connect(function(player)
		attackLocks[player.UserId] = nil
	end)

		MeleeAttack.OnServerEvent:Connect(function(player, clientTarget)
		-- Max 4 ütés / másodperc (0.25 mp cooldown az ütések között)
		if attackLocks[player.UserId] and tick() - attackLocks[player.UserId] < 0.25 then return end
		attackLocks[player.UserId] = tick()

		local character = player.Character
		
		if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then 
			return 
		end
		
		-- ==========================================
		-- HA A JÁTÉKOS ÜT, ELVESZÍTI A PAJZSÁT!
		-- ==========================================
		if character then
			local ff = character:FindFirstChildOfClass("ForceField")
			if ff then ff:Destroy() end
		end

		local stats = player:FindFirstChild("PlayerStats")
		local equipment = player:FindFirstChild("Equipment")
		if not character or not stats or not equipment then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local weaponName = equipment:FindFirstChild("Fegyver") and equipment.Fegyver.Value or ""

		local minDmg, maxDmg = 1, 5 
		if weaponName ~= "" and ItemDatabase[weaponName] then
			minDmg = ItemDatabase[weaponName].MinDmg or 1
			maxDmg = ItemDatabase[weaponName].MaxDmg or 5
		end

		local classDamage = player:GetAttribute("AttackDamage") or 5
		local baseDamage = classDamage + math.random(minDmg, maxDmg)

		local protectedNPCs = {
			["Fegyverkereskedo"] = true, 
			["Pancelkereskedo"] = true, 
			["Vegyesbolt"] = true, 
			["Kovacs"] = true, 
			["Faluose"] = true,
			["Varosor"] = true,
			["Raktaros"] = true
		}

	local function getTargetRoot(model)
		if not model or not model:IsA("Model") then
			return nil
		end

		return model:FindFirstChild("HumanoidRootPart")
			or model.PrimaryPart
			or model:FindFirstChildWhichIsA("BasePart", true)
	end

	local function getTargetHumanoid(model)
		if not model or not model:IsA("Model") then
			return nil
		end

		return model:FindFirstChildOfClass("Humanoid")
	end

	local function isAllowedCombatTarget(model, character)
		if not model or not model:IsA("Model") then
			return false
		end

		if model == character then
			return false
		end

		if protectedNPCs[model.Name] then
			return false
		end

		local hum = getTargetHumanoid(model)
		if not hum or hum.Health <= 0 then
			return false
		end

		local root = getTargetRoot(model)
		if not root then
			return false
		end

		local parent = model.Parent
		if not parent then
			return false
		end

		-- Csak ezekből a mappákból engedünk ütni
		if parent.Name == "Monsters" or parent.Name == "MetinStones" or parent.Name == "Ores" then
			return true
		end

		-- PvP karakterek
		if Players:GetPlayerFromCharacter(model) then
			return true
		end

		return false
	end

		-- ==========================================
		-- KASZT BIZTONSÁGOS LEKÉRÉSE ÉS KISBETŰSÍTÉSE
		-- ==========================================
		local playerClass = player:GetAttribute("Class") 
		if not playerClass and stats:FindFirstChild("Class") then
			playerClass = stats.Class.Value
		end
		-- Kisbetűsítjük, hogy a "ShadowBlade" és "shadowblade" ne okozzon gondot
		playerClass = playerClass and string.lower(tostring(playerClass)) or ""

		-- ==========================================
		-- OPTIMALIZÁLÁS: A workspace:GetChildren() helyett
		-- Csak a játékosokat és a specifikus mappákat nézzük át (O(N) gyorsítás)
		-- ==========================================
		local possibleTargets = {}


	-- Ha a kliens küldött kijelölt célpontot, azt tegyük a lista elejére.
	-- Így a Metin auto attack nem a vak körbekeresésre hagyatkozik.
	if typeof(clientTarget) == "Instance" and clientTarget:IsA("Model") then
		if isAllowedCombatTarget(clientTarget, character) then
			table.insert(possibleTargets, 1, clientTarget)
		end
	end
	
		-- 1. Másik játékosok
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr ~= player then
				table.insert(possibleTargets, plr.Character)
			end
		end

		-- 2. Metinkövek
		local mFolder = workspace:FindFirstChild("MetinStones")
		if mFolder then
			for _, stone in pairs(mFolder:GetChildren()) do table.insert(possibleTargets, stone) end
		end

		-- 3. Szörnyek
		local monFolder = workspace:FindFirstChild("Monsters")
		if monFolder then
			for _, monster in pairs(monFolder:GetChildren()) do table.insert(possibleTargets, monster) end
		end

		-- 4. Ércek
		local oFolder = workspace:FindFirstChild("Ores")
		if oFolder then
			for _, ore in pairs(oFolder:GetChildren()) do table.insert(possibleTargets, ore) end
		end

	local oreHitCount = 0 -- Számláló, hogy csak 1 ércet üthess egyszerre!
	local hitEnemyCount = 0 -- Számláló, hogy hányszor találtunk ellenséget

	-- BIZTONSÁG: ugyanazt a modellt egy ütés alatt csak egyszer dolgozzuk fel.
	-- Ez azért kell, mert a clientTarget bekerülhet külön is,
	-- miközben ugyanaz a Metin már benne van a MetinStones mappából is.
	local alreadyProcessedTargets = {}

	for _, obj in pairs(possibleTargets) do
		if alreadyProcessedTargets[obj] then
			continue
		end

		alreadyProcessedTargets[obj] = true
			-- ==========================================
			-- SHADOWBLADE SPECIFIKUS: Single Target (Csak 1 ellenséget üthet egyszerre)
			-- ==========================================
			if playerClass == "shadowblade" and hitEnemyCount >= 1 then continue end

			-- ==========================================
			-- JAVÍTÁS: A Távolságot nézzük meg legelőször, hogy kiszűrjük a pálya 99%-át!
			-- ==========================================
		local quickRoot = getTargetRoot(obj)
		if not quickRoot then continue end

		if (rootPart.Position - quickRoot.Position).Magnitude > 18 then
			continue
		end

		if isAllowedCombatTarget(obj, character) then
			local targetRoot = getTargetRoot(obj)
			local targetHum = getTargetHumanoid(obj)

			if targetRoot and targetHum then

					-- SÉRTHETETLENSÉG (VÉDELEM) ELLENŐRZÉSE
					if obj:GetAttribute("Invincible") then continue end

					local distance = (rootPart.Position - targetRoot.Position).Magnitude
					local directionToTarget = (targetRoot.Position - rootPart.Position).Unit
					local facingDirection = rootPart.CFrame.LookVector
					local dotProduct = facingDirection:Dot(directionToTarget)

					if distance <= 12 and dotProduct > 0.3 then
						local finalDamage = 0
						local isCrit = false

						-- BÁNYÁSZAT (ÉRC) ELLENŐRZÉSE
						local isOre = (obj.Parent and obj.Parent.Name == "Ores") or obj:GetAttribute("IsOre")

						if isOre then
							if oreHitCount >= 1 then continue end

							local isPickaxe = false
							if weaponName ~= "" and ItemDatabase[weaponName] and ItemDatabase[weaponName].IsPickaxe then
								isPickaxe = true
							end

							if not isPickaxe then continue end 

							finalDamage = 1 
							oreHitCount += 1
						else
							-- NORMÁL SZÖRNY / JÁTÉKOS SEBZÉS
							hitEnemyCount = hitEnemyCount + 1 -- Feljegyezzük, hogy eltaláltunk valakit

							local defense = 0 
							finalDamage = math.max(1, baseDamage - defense)

							if math.random(1, 100) <= stats.CritChance.Value then
								finalDamage = finalDamage * 2
								isCrit = true
							end

							-- ==========================================
							-- SHADOWBLADE: AUTO-ATTACK PASSZÍVOK
							-- ==========================================
							if playerClass == "shadowblade" then
								-- 1. HÁTBATÁMADÁS PONTOS MATEK:
								-- Megnézzük a vektor irányát a szörnytől a játékos felé
								local directionFromTargetToMe = (rootPart.Position - targetRoot.Position).Unit
								local targetLook = targetRoot.CFrame.LookVector

								-- Ha a dotProduct negatív (< -0.2), akkor a szörny HÁTA mögött állunk!
								if targetLook:Dot(directionFromTargetToMe) < -0.2 then
									finalDamage = math.floor(finalDamage * 1.5) -- +50% Bónusz sebzés!
									isCrit = true -- Nagyobbnak mutassa a számot
								end

								-- 2. DEATHMARK PROC
								-- Megnézzük, hogy a mi Death Mark-unk van-e rajta
								local markApplier = obj:GetAttribute("DeathMark_Applier")
								if markApplier == player.UserId then
									obj:SetAttribute("DeathMark_Applier", nil) -- Levesszük róla a jelet
									finalDamage = finalDamage + (classDamage * 3) -- Extrém bónusz sebzés (Robbanás)
									isCrit = true

									-- Vizuális effekt eltüntetése a feje felől
									local attachPart = obj:FindFirstChild("Head") or targetRoot or obj.PrimaryPart
									if attachPart and attachPart:FindFirstChild("DeathMarkVisual") then
										attachPart.DeathMarkVisual:Destroy()
									end
								end
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

						local attackersFolder = obj:FindFirstChild("Attackers")
						if not attackersFolder then
							attackersFolder = Instance.new("Folder")
							attackersFolder.Name = "Attackers"
							attackersFolder.Parent = obj
						end
						if not attackersFolder:FindFirstChild(player.Name) then
							local pTag = Instance.new("ObjectValue")
							pTag.Name = player.Name
							pTag.Value = player
							pTag.Parent = attackersFolder
						end


						targetHum:TakeDamage(finalDamage)
						ShowDamage:FireClient(player, finalDamage, targetRoot.Position, isCrit, false)

						-- Ha a célpont egy JÁTÉKOS (PvP), neki is elküldjük, hogy lássa, mennyit sebeztek rajta
						local targetPlayer = Players:GetPlayerFromCharacter(obj)
						if targetPlayer then
							ShowDamage:FireClient(targetPlayer, finalDamage, targetRoot.Position, isCrit, false)
						end
					end
				end
			end
		end
	end)