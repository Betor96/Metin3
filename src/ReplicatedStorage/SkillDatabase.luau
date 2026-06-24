-- Fájl helye: ReplicatedStorage -> SkillDatabase

local SkillDatabase = {}
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ShowDamage = Events:WaitForChild("ShowDamage") 

local protectedNPCs = {
	["Fegyverkereskedo"] = true, ["Pancelkereskedo"] = true, ["Vegyesbolt"] = true, 
	["Kovacs"] = true, ["Faluose"] = true, ["Varosor"] = true, ["Raktaros"] = true
}

SkillDatabase.Ranges = {
	["Shield Charge"] = 25, ["Earthbreaker"] = 15, ["Blade Spirit"] = 0, ["Iron Skin"] = 0,
	["Shadow Strike"] = 35, ["Whirling Blades"] = 12, ["Bloodlust"] = 0, ["Death Mark"] = 70,
	["Soul Orb"] = 60, ["Spirit Chain"] = 45, ["Spirit Blessing"] = 0, ["Soul Explosion"] = 25,
	["Seal of Power"] = 50, ["Seal of Protection"] = 50, ["Explosive Seal"] = 40, ["Dragon Shackles"] = 40
}

function SkillDatabase.isValidTarget(obj)
	if not obj or not obj:IsA("Model") then return false end
	local hum = obj:FindFirstChild("Humanoid")
	local root = obj:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return false end
	if protectedNPCs[obj.Name] or obj:GetAttribute("IsNPC") then return false end

	local nameLower = string.lower(obj.Name)
	if string.find(nameLower, "érc") or string.find(nameLower, "erc") or string.find(nameLower, "vein") then
		return false
	end
	if obj:GetAttribute("IsOre") then return false end

	return true
end

function SkillDatabase.getEnemiesInRadius(centerPos, radius, excludeChar)
	local enemies = {}

	-- Segédfüggvény, hogy egy entitást leellenőrizzünk
	local function checkObj(obj)
		if obj and obj ~= excludeChar and SkillDatabase.isValidTarget(obj) then
			local root = obj:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - centerPos).Magnitude <= radius then 
				table.insert(enemies, obj) 
			end
		end
	end

	-- Segédfüggvény, hogy könnyen átnézzünk több mappát is
	local function scanFolder(folder)
		if not folder then return end
		for _, obj in pairs(folder:GetChildren()) do
			checkObj(obj)
		end
	end

	-- 1. Átnézzük a játékosokat a hatalmas workspace mappa helyett (LAG MENTES)
	for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
		checkObj(plr.Character)
	end

	-- 2. Átnézzük a fő mappákat
	scanFolder(workspace:FindFirstChild("Monsters"))
	scanFolder(workspace:FindFirstChild("MetinStones")) 

	return enemies
end

function SkillDatabase.applyDamage(attacker, targetModel, skillMultiplier)
	local hum = targetModel:FindFirstChild("Humanoid")
	local root = targetModel:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end

	local baseDmg = attacker:GetAttribute("AttackDamage") or 10
	local finalDmg = math.floor(baseDmg * skillMultiplier)
	local isCrit = false

	local stats = attacker:FindFirstChild("PlayerStats")
	if stats and stats:FindFirstChild("CritChance") then
		if math.random(1, 100) <= stats.CritChance.Value then
			finalDmg = finalDmg * 2
			isCrit = true
		end
	end

	-- =======================================
	-- KASZTOK ÉS KARAKTER BIZTONSÁGOS LEKÉRÉSE
	-- =======================================
	local attackerPlayer = attacker:IsA("Player") and attacker or Players:GetPlayerFromCharacter(attacker)
	local rawPlayerClass = attackerPlayer and attackerPlayer:GetAttribute("Class") or attacker:GetAttribute("Class") or ""
	local playerClass = string.lower(rawPlayerClass)

	local attackerChar = attackerPlayer and attackerPlayer.Character or attacker
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")

	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
	local targetRawClass = targetPlayer and targetPlayer:GetAttribute("Class") or targetModel:GetAttribute("Class") or ""
	local targetClass = string.lower(targetRawClass)

	-- =======================================
	-- TÁMADÓ BUFFOK ÉS PASSZÍVOK (OUTGOING DAMAGE)
	-- =======================================
	if attacker:GetAttribute("SealOfPower_Active") then
		local powerMulti = attacker:GetAttribute("SealOfPower_Multi") or 1.2
		finalDmg = math.floor(finalDmg * powerMulti)
	end

	if attacker:GetAttribute("BladeSpirit_Active") then
		finalDmg = math.floor(finalDmg * 1.25)
	end

	if attacker:GetAttribute("SpiritBlessing_Active") then
		finalDmg = math.floor(finalDmg * 1.15)
	end

	-- 👑 SEALER: Seal Mastery
	if playerClass == "sealer" then
		local sealCharges = attacker:GetAttribute("SealCharges") or 0
		if sealCharges > 0 then
			finalDmg = math.floor(finalDmg * (1 + (sealCharges * 0.02)))
		end
	end

	-- ⚔️ SHADOWBLADE: Shadow Mastery
	local isBackstab = false
	local isExecute = false

	if playerClass == "shadowblade" then
		if attackerRoot then
			-- 180 fokos félkör a szörny mögött
			local offset = Vector3.new(root.Position.X - attackerRoot.Position.X, 0, root.Position.Z - attackerRoot.Position.Z)
			if offset.Magnitude > 0.1 then
				local dirToTarget = offset.Unit
				local targetLook = root.CFrame.LookVector
				local targetDir = Vector3.new(targetLook.X, 0, targetLook.Z).Unit

				if dirToTarget:Dot(targetDir) > 0 then 
					finalDmg = math.floor(finalDmg * 1.10)
					isBackstab = true
				end
			end
		end

		if (hum.Health / hum.MaxHealth) < 0.3 then
			finalDmg = math.floor(finalDmg * 1.10)
			isExecute = true
		end
	end

	-- =======================================
	-- VÉDEKEZŐ BUFFOK ÉS PÁNCÉL LEVONÁS
	-- =======================================
	local damageReduction = 1
	if targetModel:GetAttribute("IronSkin_Active") then
		damageReduction = damageReduction * 0.5
	end

	local targetStats = targetModel:FindFirstChild("PlayerStats")
	local targetDefense = targetStats and targetStats:FindFirstChild("Defense") and targetStats.Defense.Value or 0

	-- 🛡️ GUARDIAN: Iron Will (Páncél %-os növelése)
	if targetClass == "guardian" then
		local hpPercent = hum.Health / hum.MaxHealth
		if hpPercent <= 0.15 then
			targetDefense = targetDefense + math.floor(targetDefense * 0.30)
		elseif hpPercent <= 0.30 then
			targetDefense = targetDefense + math.floor(targetDefense * 0.20)
		elseif hpPercent <= 0.50 then
			targetDefense = targetDefense + math.floor(targetDefense * 0.10)
		end
	end

	finalDmg = math.floor(finalDmg * damageReduction)
	finalDmg = math.max(1, finalDmg - targetDefense)

	-- =======================================
	-- DEATH MARK ÉS LIFE STEAL
	-- =======================================
	local totalDamageToDeal = finalDmg
	local bonusDmg = 0
	local hasDeathMark = false
	local markApplier = targetModel:GetAttribute("DeathMark_Applier")

	if markApplier and markApplier == attacker.UserId then
		hasDeathMark = true
		targetModel:SetAttribute("DeathMark_Applier", nil) 

		local attachPart = targetModel:FindFirstChild("Head") or targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
		if attachPart and attachPart:FindFirstChild("DeathMarkVisual") then attachPart.DeathMarkVisual:Destroy() end

		bonusDmg = math.floor(finalDmg * (targetModel:FindFirstChild("IsPlayer") and 0.5 or 0.8)) 
		totalDamageToDeal = finalDmg + bonusDmg
	end

	if attacker:GetAttribute("BladeSpirit_Active") then
		local aHum = attackerChar and attackerChar:FindFirstChild("Humanoid")
		if aHum and aHum.Health > 0 then
			local lsPercent = math.min(20, baseDmg * 0.05)
			local healAmount = math.floor(totalDamageToDeal * (lsPercent / 100))
			if healAmount > 0 then
				aHum.Health = math.min(aHum.MaxHealth, aHum.Health + healAmount)
			end
		end
	end

	hum:TakeDamage(totalDamageToDeal)

	-- =======================================
	-- SHADOWBLADE EGYEDI VIZUÁLIS SEBZÉS UI
	-- =======================================
	local function spawnCustomDamageUI(dmg, pos, color, suffix)
		local part = Instance.new("Part")
		part.Transparency = 1; part.Anchored = true; part.CanCollide = false
		part.Position = pos + Vector3.new(math.random(-10, 10)/10, 2, math.random(-10, 10)/10)

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 150, 0, 50); bb.AlwaysOnTop = true

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
		txt.Text = tostring(dmg) .. (suffix or "")
		txt.TextColor3 = color; txt.TextScaled = true; txt.Font = Enum.Font.GothamBlack

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2; stroke.Color = Color3.new(0, 0, 0)

		stroke.Parent = txt
		txt.Parent = bb
		bb.Parent = part
		part.Parent = workspace

		local ts = game:GetService("TweenService")
		ts:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = part.Position + Vector3.new(0, 3, 0)}):Play()
		ts:Create(txt, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		ts:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Transparency = 1}):Play()
		Debris:AddItem(part, 1)
	end

	local customColor = nil
	local customSuffix = ""

	if isBackstab and isExecute then
		customColor = Color3.fromRGB(200, 0, 0)
		customSuffix = " (KIVÉGZÉS!)"
	elseif isExecute then
		customColor = Color3.fromRGB(255, 120, 0)
		customSuffix = " (KIVÉGZÉS!)"
	elseif isBackstab then
		customColor = Color3.fromRGB(180, 50, 255)
		customSuffix = " (HÁTBATÁMADÁS!)"
	end

	if customColor then
		spawnCustomDamageUI(finalDmg, root.Position, customColor, customSuffix)
	else
		ShowDamage:FireAllClients(finalDmg, root.Position, isCrit, false)
	end

	if hasDeathMark then
		task.delay(0.15, function()
			if customColor then
				spawnCustomDamageUI(bonusDmg, root.Position + Vector3.new(0, 2, 0), customColor, customSuffix)
			else
				ShowDamage:FireAllClients(bonusDmg, root.Position + Vector3.new(0, 2, 0), true, false)
			end
		end)
	end

	-- =======================================
	-- 🔮 SOULWEAVER: Soul Echo
	-- =======================================
	if playerClass == "soulweaver" and skillMultiplier > 1 and not targetModel:GetAttribute("IsEchoHit") then
		if math.random(1, 100) <= 15 then
			task.delay(0.4, function()
				if targetModel and targetModel:FindFirstChild("Humanoid") and targetModel.Humanoid.Health > 0 then
					targetModel:SetAttribute("IsEchoHit", true)
					local echoDmg = math.max(1, math.floor(totalDamageToDeal * 0.35))
					targetModel.Humanoid:TakeDamage(echoDmg)
					SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 50, 255), 6)
					ShowDamage:FireAllClients(echoDmg, root.Position, false, false) 
					task.delay(0.2, function() targetModel:SetAttribute("IsEchoHit", nil) end)
				end
			end)
		end
	end
end

function SkillDatabase.playVFX(position, color, size, duration)
	local part = Instance.new("Part")
	part.Position = position
	part.Anchored = true; part.CanCollide = false; part.Transparency = 1; part.Parent = workspace
	local att = Instance.new("Attachment", part)
	local emitter = Instance.new("ParticleEmitter", att)
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 3), NumberSequenceKeypoint.new(1, 0)})
	emitter.Texture = "rbxassetid://281983280" 
	emitter.Lifetime = NumberRange.new(0.4, 0.6)
	emitter.Speed = NumberRange.new(10, 20)
	emitter:Emit(25)
	Debris:AddItem(part, duration or 1)
end

function SkillDatabase.sendBuffUI(player, skillName, effectType, duration)
	local ApplyEffect = Events:FindFirstChild("ApplyEffect")
	if ApplyEffect then ApplyEffect:FireClient(player, skillName, effectType, 0, duration) end
end

function SkillDatabase.applyBuffVFX(character, buffName, color, duration)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Eltávolítjuk a régit, ha már van rajta ilyen buff
	local existing = root:FindFirstChild(buffName .. "_VFX")
	if existing then existing:Destroy() end

	local att = Instance.new("Attachment", root)
	att.Name = buffName .. "_VFX"

	-- Látványos energia-aura beállítása
	local emitter = Instance.new("ParticleEmitter", att)
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)})
	emitter.Texture = "rbxassetid://281983280" -- Ugyanaz a szép particle textúra
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = 12
	emitter.Speed = NumberRange.new(2, 4)
	emitter.EmissionDirection = Enum.NormalId.Top

	-- A buff lejártakor (7200 mp) a rendszer automatikusan letörli az aurát
	Debris:AddItem(att, duration)
end

-- =======================================
-- ÚJ: SEALER TÖLTET IDŐZÍTŐ
-- =======================================
function SkillDatabase.resetChargeTimer(player)
	if player:FindFirstChild("ChargeTimer") then player.ChargeTimer:Destroy() end

	local timer = Instance.new("StringValue", player)
	timer.Name = "ChargeTimer"

	task.delay(10, function()
		if timer and timer.Parent then
			player:SetAttribute("SealCharges", 0)
			timer:Destroy()
		end
	end)
end

SkillDatabase.Skills = {

	-- 🛡️ GUARDIAN
	["Shield Charge"] = {
		Mana = 15, Cooldown = 8,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			local dashDir = root.CFrame.LookVector

			-- Célpont irányának és forgatásának beállítása
			if SkillDatabase.isValidTarget(enemyModel) then
				local tRoot = enemyModel:FindFirstChild("HumanoidRootPart")
				if tRoot then
					dashDir = (tRoot.Position - root.Position).Unit
					root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
				end
			end

			-- Indulás effekt
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 200, 50), 5)

			local dashDuration = 0.3
			local dashSpeed = 80 -- Kicsit felgyorsítottam, hogy biztosan odaérjen

			-- Roham (Dash) mozgás elindítása
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = dashDir * dashSpeed
			bv.MaxForce = Vector3.new(100000, 0, 100000)
			bv.Parent = root
			Debris:AddItem(bv, dashDuration)

			-- Háttérfolyamat a Dash és az Impact sebzésének kezelésére
			task.spawn(function()
				local hitDuringDash = {}
				local elapsed = 0

				-- 1. DASH SZAKASZ (Contact Damage & Megállítás)
				while elapsed < dashDuration do
					task.wait(0.05)
					elapsed = elapsed + 0.05
					if not root or not root.Parent then break end

					local hitPrimary = false
					local dashEnemies = SkillDatabase.getEnemiesInRadius(root.Position, 7, char)

					for _, enemy in pairs(dashEnemies) do
						if not hitDuringDash[enemy] then
							hitDuringDash[enemy] = true
							SkillDatabase.applyDamage(player, enemy, 0.5) 
						end
						-- Ha ütköztünk a kijelölt célponttal, álljunk meg!
						if enemy == enemyModel then
							hitPrimary = true
						end
					end

					-- Ha elértük a célpontot, azonnal állítsuk meg a rohamot!
					if hitPrimary then
						if bv and bv.Parent then bv:Destroy() end
						break
					end
				end

				-- 2. ÉRKEZÉS SZAKASZ (Impact AOE)
				if root and root.Parent then
					-- Látványos megérkezés effekt
					SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 100, 0), 12)

					local impactWave = Instance.new("Part")
					impactWave.Shape = Enum.PartType.Ball
					impactWave.Size = Vector3.new(2, 2, 2)
					impactWave.Color = Color3.fromRGB(255, 150, 0)
					impactWave.Material = Enum.Material.Neon
					impactWave.Anchored = true; impactWave.CanCollide = false; impactWave.Transparency = 0.2
					impactWave.Position = root.Position
					impactWave.Parent = workspace

					game:GetService("TweenService"):Create(impactWave, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Vector3.new(20, 20, 20), Transparency = 1
					}):Play()
					Debris:AddItem(impactWave, 0.4)

					-- Megérkezéskor a fő sebzés (1.5x)
					local primaryDamaged = false
					local impactEnemies = SkillDatabase.getEnemiesInRadius(root.Position, 12, char)

					for _, enemy in pairs(impactEnemies) do
						if enemy == enemyModel then primaryDamaged = true end
						SkillDatabase.applyDamage(player, enemy, 1.5)
					end

					-- ANTI-LAG GARANCIA: Ha célba vettük, de a Roblox fizikája miatt kimaradt a sugárból
					if enemyModel and not primaryDamaged and SkillDatabase.isValidTarget(enemyModel) then
						local dist = (enemyModel.HumanoidRootPart.Position - root.Position).Magnitude
						if dist <= 20 then -- Ha valamennyire a közelünkben van a roham végén
							SkillDatabase.applyDamage(player, enemyModel, 1.5)
						end
					end
				end
			end)

			return true
		end
	},
	["Earthbreaker"] = {
		Mana = 25, Cooldown = 12,
		Execute = function(player, char, root, mousePos, target)
			local range = 15
			local pos = root.Position - Vector3.new(0, 2.5, 0)

			-- Vizuális AOE Indikátor (Földrengés gyűrű)
			local indicator = Instance.new("Part")
			indicator.Shape = Enum.PartType.Cylinder
			indicator.Size = Vector3.new(0.5, range * 2, range * 2)
			indicator.Color = Color3.fromRGB(130, 80, 20)
			indicator.Material = Enum.Material.Neon
			indicator.Anchored = true; indicator.CanCollide = false; indicator.Transparency = 0.2
			indicator.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
			indicator.Parent = workspace

			local ts = game:GetService("TweenService")
			ts:Create(indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1, Size = Vector3.new(0.5, (range * 2) + 2, (range * 2) + 2)
			}):Play()
			Debris:AddItem(indicator, 0.5)

			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 80, 20), range)

			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, range, char)
			for _, enemy in pairs(enemies) do 
				-- JAVÍTVA: Megemelt sebzés (1.8 -> 2.5)
				SkillDatabase.applyDamage(player, enemy, 2.5) 

				-- JAVÍTVA: KÁBÍTÁS (Stun) 1.5 másodpercre
				local eHum = enemy:FindFirstChild("Humanoid")
				if eHum and eHum.Health > 0 and not enemy:GetAttribute("EarthbreakerStunned") then
					enemy:SetAttribute("EarthbreakerStunned", true)

					local originalSpeed = eHum.WalkSpeed
					eHum.WalkSpeed = 0 -- Kábítás (Odaszögezi a földhöz)

					task.delay(1.5, function()
						if enemy and enemy.Parent then enemy:SetAttribute("EarthbreakerStunned", nil) end
						if eHum and eHum.Health > 0 then
							eHum.WalkSpeed = originalSpeed
						end
					end)
				end
			end
			return true
		end
	},
	["Blade Spirit"] = {
		Mana = 30, Cooldown = 2, IsToggle = true, ToggleAttribute = "BladeSpirit_Active",
		Execute = function(player, char, root, mousePos, target)
			local isActive = player:GetAttribute("BladeSpirit_Active")
			local stats = player:FindFirstChild("PlayerStats")
			local lifeStealStat = stats and stats:FindFirstChild("LifeSteal")

			if not isActive then
				-- BEKAPCSOLÁS
				player:SetAttribute("BladeSpirit_Active", true)

				-- 1. Életlopás (Life Steal) stat megadása (+20%)
				if lifeStealStat then
					lifeStealStat.Value += 20
				end

				-- 2. Sebzés növelése (Az alap AttackDamage attribútumot húzzuk fel 25%-kal)
				local currentDmg = player:GetAttribute("AttackDamage") or 10
				local dmgBonus = math.floor(currentDmg * 0.25)
				if dmgBonus < 5 then dmgBonus = 5 end -- Minimum +5 bónusz sebzés garantált

				player:SetAttribute("BladeSpirit_DmgBonus", dmgBonus)
				player:SetAttribute("AttackDamage", currentDmg + dmgBonus)

				-- Végtelen vizuális aura (amíg ki nem kapcsolják, most agresszívabb pirosas színnel)
				SkillDatabase.applyBuffVFX(char, "BladeSpirit", Color3.fromRGB(255, 50, 50), 999999)
			else
				-- KIKAPCSOLÁS
				player:SetAttribute("BladeSpirit_Active", false)

				-- Életlopás visszavétele
				if lifeStealStat then
					lifeStealStat.Value = math.max(0, lifeStealStat.Value - 20)
				end

				-- Sebzés bónusz pontos visszavétele
				local dmgBonus = player:GetAttribute("BladeSpirit_DmgBonus") or 0
				local currentDmg = player:GetAttribute("AttackDamage") or 10
				player:SetAttribute("AttackDamage", math.max(1, currentDmg - dmgBonus))
				player:SetAttribute("BladeSpirit_DmgBonus", nil)

				-- Aura azonnali eltüntetése
				local vfx = root:FindFirstChild("BladeSpirit_VFX")
				if vfx then vfx:Destroy() end
			end
			return true
		end
	},
	["Iron Skin"] = {
		Mana = 40, Cooldown = 20, Duration = 6,
		Execute = function(player, char, root, mousePos, target)
			-- Vasbőr bekapcsolása (a passzív védelem bónuszt a háttérrendszer kezeli)
			player:SetAttribute("IronSkin_Active", true)

			-- 1. IGAZI BARNA PAJZS LÉTREHOZÁSA A KARAKTER KÖRÜL
			local shieldPart = Instance.new("Part")
			shieldPart.Name = "IronSkinShield"
			shieldPart.Shape = Enum.PartType.Ball
			shieldPart.Size = Vector3.new(7, 7, 7) -- Elég nagy, hogy befedje a karaktert
			shieldPart.Color = Color3.fromRGB(139, 69, 19) -- Barna szín
			shieldPart.Material = Enum.Material.ForceField -- Erőtér textúra, ami animálva van a Robloxban
			shieldPart.Transparency = 0.3
			shieldPart.Anchored = false
			shieldPart.CanCollide = false
			shieldPart.Massless = true
			shieldPart.CFrame = root.CFrame
			shieldPart.Parent = char

			-- Hozzákötjük a játékoshoz, hogy vele mozogjon (Weld)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = shieldPart
			weld.Part1 = root
			weld.Parent = shieldPart

			-- 6 másodperc múlva Robbanás
			task.delay(6, function()
				if player and player.Parent then
					player:SetAttribute("IronSkin_Active", false)
				end

				-- Pajzs eltüntetése
				if shieldPart then shieldPart:Destroy() end

				-- Robbanás és Lassítás
				if char and root and root.Parent then
					local range = 15
					local pos = root.Position - Vector3.new(0, 2.5, 0) -- Földszint
					local ts = game:GetService("TweenService")

					-- 2. VIZUÁLIS FÖLDI INDIKÁTOR (A robbanás területe a talajon)
					local indicator = Instance.new("Part")
					indicator.Shape = Enum.PartType.Cylinder
					indicator.Size = Vector3.new(0.5, range * 2, range * 2)
					indicator.Color = Color3.fromRGB(139, 69, 19)
					indicator.Material = Enum.Material.Neon
					indicator.Anchored = true
					indicator.CanCollide = false
					indicator.Transparency = 0.2
					indicator.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
					indicator.Parent = workspace

					ts:Create(indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1, Size = Vector3.new(0.5, (range * 2) + 2, (range * 2) + 2)
					}):Play()
					Debris:AddItem(indicator, 0.5)

					-- 3. LÁTVÁNYOS ROBBANÓ GÖMB (Shockwave)
					local wave = Instance.new("Part")
					wave.Shape = Enum.PartType.Ball
					wave.Size = Vector3.new(4, 4, 4)
					wave.Color = Color3.fromRGB(180, 90, 30)
					wave.Material = Enum.Material.Neon
					wave.Anchored = true; wave.CanCollide = false; wave.Transparency = 0.1
					wave.Position = root.Position
					wave.Parent = workspace

					ts:Create(wave, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Size = Vector3.new(range * 2, range * 2, range * 2), Transparency = 1
					}):Play()
					Debris:AddItem(wave, 0.5)

					-- Alap particle burst
					SkillDatabase.playVFX(root.Position, Color3.fromRGB(139, 69, 19), range)

					-- 4. SEBZÉS ÉS LASSÍTÁS KIOSZTÁSA
					local enemies = SkillDatabase.getEnemiesInRadius(root.Position, range, char)
					for _, enemy in pairs(enemies) do
						-- Pajzs robbanás sebzése
						SkillDatabase.applyDamage(player, enemy, 1.5)

						-- Lassítás 2 másodpercre
						local eHum = enemy:FindFirstChild("Humanoid")
						if eHum and eHum.Health > 0 and not enemy:GetAttribute("IronSkinSlowed") then
							enemy:SetAttribute("IronSkinSlowed", true)
							local originalSpeed = eHum.WalkSpeed
							eHum.WalkSpeed = originalSpeed * 0.5 -- 50% Lassítás

							task.delay(2, function()
								if enemy and enemy.Parent then enemy:SetAttribute("IronSkinSlowed", nil) end
								if eHum and eHum.Health > 0 then eHum.WalkSpeed = originalSpeed end
							end)
						end
					end
				end
			end)
			return true
		end
	},

	-- ⚔️ SHADOWBLADE
	["Shadow Strike"] = {
		Mana = 20, Cooldown = 10,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			local tRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(30, 30, 30), 4) 
			root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
			root.CFrame = CFrame.lookAt(root.Position, tRoot.Position)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 0, 0), 5) 
			SkillDatabase.applyDamage(player, enemyModel, 2.5) 
			return true
		end
	},
	["Whirling Blades"] = {
		Mana = 25, Cooldown = 8,
		Execute = function(player, char, root, mousePos, target)
			local hum = char:FindFirstChild("Humanoid")
			if not hum then return false end

			local oldWalkSpeed = hum.WalkSpeed
			hum.WalkSpeed = 0 

			local function createRedAura()
				local circle = Instance.new("Part")
				circle.Size = Vector3.new(0.5, 24, 24) 
				circle.Position = root.Position - Vector3.new(0, 2.5, 0)
				circle.Anchored = true; circle.CanCollide = false; circle.Color = Color3.fromRGB(200, 20, 20)
				circle.Material = Enum.Material.Neon; circle.Shape = Enum.PartType.Cylinder
				circle.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
				circle.Transparency = 0.5; circle.Parent = workspace
				game:GetService("TweenService"):Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Size = Vector3.new(0.5, 26, 26)}):Play()
				Debris:AddItem(circle, 0.6)
			end

			task.spawn(function()
				for i = 1, 3 do
					createRedAura()
					SkillDatabase.playVFX(root.Position, Color3.fromRGB(200, 50, 50), 12)
					local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 12, char)
					for _, enemy in pairs(enemies) do 
						SkillDatabase.applyDamage(player, enemy, 0.6) 

						-- ==========================================
						-- ÚJ: LASSÍTÁS A WHIRLING BLADES HULLÁMAINÁL
						-- ==========================================
						local eHum = enemy:FindFirstChild("Humanoid")
						if eHum and eHum.Health > 0 and not enemy:GetAttribute("WhirlingSlowed") then
							enemy:SetAttribute("WhirlingSlowed", true)
							local originalSpeed = eHum.WalkSpeed
							eHum.WalkSpeed = originalSpeed * 0.6 -- 40%-os lassítás

							task.delay(3, function()
								if enemy and enemy.Parent then
									enemy:SetAttribute("WhirlingSlowed", nil)
								end
								if eHum and eHum.Health > 0 then
									eHum.WalkSpeed = originalSpeed
								end
							end)
						end
					end
					task.wait(2/3) 
				end
				if hum then hum.WalkSpeed = oldWalkSpeed end 
			end)
			return true
		end
	},
	["Bloodlust"] = {
		Mana = 35, Cooldown = 5, IsToggle = true, ToggleAttribute = "Bloodlust_Active",
		Execute = function(player, char, root, mousePos, target)
			local stats = player:FindFirstChild("PlayerStats")
			if not stats then return false end

			local movementSpeed = stats:FindFirstChild("MovementSpeed")
			local attackSpeed = stats:FindFirstChild("AttackSpeed")
			if not movementSpeed or not attackSpeed then return false end

			local isActive = player:GetAttribute("Bloodlust_Active")

			if not isActive then
				-- BEKAPCSOLÁS
				player:SetAttribute("Bloodlust_Active", true)
				SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 0, 0), 6)

				movementSpeed.Value += 15 -- +15% Mozgási sebesség
				attackSpeed.Value += 30   -- +30% Támadási sebesség
			else
				-- KIKAPCSOLÁS
				player:SetAttribute("Bloodlust_Active", false)

				movementSpeed.Value = math.max(0, movementSpeed.Value - 15)
				attackSpeed.Value = math.max(0, attackSpeed.Value - 30)
			end
			return true
		end
	},
	["Death Mark"] = {
		Mana = 30, Cooldown = 15,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			enemyModel:SetAttribute("DeathMark_Applier", player.UserId)

			local attachPart = enemyModel:FindFirstChild("Head") or enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel.PrimaryPart
			if attachPart then
				local existing = attachPart:FindFirstChild("DeathMarkVisual")
				if existing then existing:Destroy() end

				local bb = Instance.new("BillboardGui")
				bb.Name = "DeathMarkVisual"
				bb.Size = UDim2.new(0, 60, 0, 60)
				bb.AlwaysOnTop = true

				local isMetinStone = (enemyModel.Parent and enemyModel.Parent.Name == "MetinStones") or string.match(string.lower(enemyModel.Name), "metin")
				if isMetinStone then
					local height = enemyModel:GetExtentsSize().Y
					bb.StudsOffset = Vector3.new(0, (height / 2) + 2, 0)
				else
					bb.StudsOffset = Vector3.new(0, 3.5, 0)
				end

				bb.Parent = attachPart

				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1, 0, 1, 0)
				txt.BackgroundTransparency = 1
				txt.Text = "☠️"
				txt.TextColor3 = Color3.fromRGB(255, 50, 50)
				txt.TextScaled = true
				txt.Parent = bb

				Debris:AddItem(bb, 5) 
			end

			SkillDatabase.playVFX(enemyModel.HumanoidRootPart.Position, Color3.fromRGB(150, 0, 0), 6)
			task.delay(5, function() 
				if enemyModel and enemyModel:GetAttribute("DeathMark_Applier") == player.UserId then enemyModel:SetAttribute("DeathMark_Applier", nil) end 
			end)
			return true
		end
	},

	-- 🔮 SOULWEAVER
	["Soul Orb"] = {
		Mana = 10, Cooldown = 3,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end

			local tRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			if not tRoot then return false end

			-- Gömb létrehozása (Fizika kikapcsolva, Anchored = true)
			local orb = Instance.new("Part")
			orb.Size = Vector3.new(1.5, 1.5, 1.5)
			orb.Shape = Enum.PartType.Ball
			orb.Color = Color3.fromRGB(150, 50, 255)
			orb.Material = Enum.Material.Neon
			orb.CanCollide = false
			orb.Anchored = true 
			orb.CFrame = root.CFrame * CFrame.new(0, 0, -3)
			orb.Parent = workspace

			-- Célkövető (Homing) és Ütközésvizsgáló folyamat
			task.spawn(function()
				local speed = 80
				local maxTime = 3 -- Max 3 másodpercig repül
				local elapsed = 0
				local hitOnce = false

				while orb and orb.Parent and elapsed < maxTime do
					local dt = task.wait()
					elapsed = elapsed + dt

					-- Ha a célpont eltűnt (meghalt/kilépett), semmisítsük meg a gömböt
					if not tRoot or not tRoot.Parent or not enemyModel.Parent then 
						break 
					end

					-- Folyamatos irányszámítás a célpont AKTUÁLIS pozíciója felé
					local currentPos = orb.Position
					local targetPos = tRoot.Position
					local direction = (targetPos - currentPos).Unit

					-- Gömb mozgatása
					orb.CFrame = orb.CFrame + (direction * speed * dt)

					-- Kézi távolságmérés a 100% garantált találathoz (ha 3 studon belülre ér)
					if (orb.Position - targetPos).Magnitude < 3 then
						hitOnce = true
						SkillDatabase.playVFX(orb.Position, Color3.fromRGB(200, 100, 255), 6)
						SkillDatabase.applyDamage(player, enemyModel, 1.5)
						break
					end
				end

				-- Ha becsapódott, vagy lejárt az idő, takarítsunk el
				if orb then orb:Destroy() end
			end)

			return true
		end
	},
	["Spirit Chain"] = {
		Mana = 30, Cooldown = 12,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end

			local eRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			if not eRoot then return false end

			-- Segédfüggvény a villám rajzolására két pont közé
			local function drawLightning(part1, part2)
				if not part1 or not part2 then return end
				local att0 = Instance.new("Attachment", part1)
				local att1 = Instance.new("Attachment", part2)
				local beam = Instance.new("Beam", part1)
				beam.Attachment0 = att0
				beam.Attachment1 = att1
				beam.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
				beam.FaceCamera = true
				beam.Width0 = 0.5
				beam.Width1 = 0.5
				beam.LightEmission = 1

				Debris:AddItem(att0, 0.4)
				Debris:AddItem(att1, 0.4)
				Debris:AddItem(beam, 0.4)
			end

			-- 1. Ugrás: Játékostól a célpontig
			drawLightning(root, eRoot)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(100, 150, 255), 6)
			SkillDatabase.applyDamage(player, enemyModel, 1.3)
			SkillDatabase.playVFX(eRoot.Position, Color3.fromRGB(100, 150, 255), 5)

			-- 2. Ugrás: Láncreakció a célpont körül
			task.spawn(function()
				local currentRoot = eRoot
				local enemies = SkillDatabase.getEnemiesInRadius(eRoot.Position, 25, char)
				local jumps = 0
				local visited = {[enemyModel] = true} -- A fő célpontot már megütöttük

				for _, enemy in pairs(enemies) do
					if not visited[enemy] and jumps < 4 then
						visited[enemy] = true
						jumps = jumps + 1
						task.wait(0.2) -- Késleltetés a "villám" ugrálása miatt

						local nRoot = enemy:FindFirstChild("HumanoidRootPart")
						if nRoot then
							drawLightning(currentRoot, nRoot)
							SkillDatabase.applyDamage(player, enemy, 1.3)
							SkillDatabase.playVFX(nRoot.Position, Color3.fromRGB(100, 150, 255), 5)
							currentRoot = nRoot
						end
					end
				end
			end)
			return true
		end
	},
	["Spirit Blessing"] = {
		Mana = 50, Cooldown = 2, IsToggle = true, ToggleAttribute = "SpiritBlessing_Active",
		Execute = function(player, char, root, mousePos, target)
			local isActive = player:GetAttribute("SpiritBlessing_Active")
			local stats = player:FindFirstChild("PlayerStats")
			local msStat = stats and stats:FindFirstChild("MovementSpeed")
			local hum = char:FindFirstChild("Humanoid")

			if not isActive then
				-- BEKAPCSOLÁS
				player:SetAttribute("SpiritBlessing_Active", true)
				if msStat then msStat.Value += 15 end
				if hum then hum.WalkSpeed += 15 end
				SkillDatabase.applyBuffVFX(char, "SpiritBlessing", Color3.fromRGB(50, 255, 255), 999999)
			else
				-- KIKAPCSOLÁS
				player:SetAttribute("SpiritBlessing_Active", false)
				if msStat then msStat.Value = math.max(16, msStat.Value - 15) end
				if hum then hum.WalkSpeed = math.max(16, hum.WalkSpeed - 15) end
				local vfx = root:FindFirstChild("SpiritBlessing_VFX")
				if vfx then vfx:Destroy() end
			end
			return true
		end
	},
	["Soul Explosion"] = {
		Mana = 60, Cooldown = 20,
		Execute = function(player, char, root, mousePos, target)
			local range = 25
			local pos = root.Position - Vector3.new(0, 2.5, 0)

			-- 1. Vizuális AOE Indikátor (Neon lila kör a földön)
			local indicator = Instance.new("Part")
			indicator.Shape = Enum.PartType.Cylinder
			indicator.Size = Vector3.new(0.5, range * 2, range * 2)
			indicator.Color = Color3.fromRGB(100, 50, 255)
			indicator.Material = Enum.Material.Neon
			indicator.Anchored = true
			indicator.CanCollide = false
			indicator.Transparency = 0.2
			indicator.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
			indicator.Parent = workspace

			local ts = game:GetService("TweenService")
			ts:Create(indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1, 
				Size = Vector3.new(0.5, (range * 2) + 5, (range * 2) + 5)
			}):Play()
			Debris:AddItem(indicator, 0.5)

			-- 2. Táguló Shockwave Gömb (Robbanás effekt)
			local wave = Instance.new("Part")
			wave.Shape = Enum.PartType.Ball
			wave.Size = Vector3.new(2, 2, 2)
			wave.Color = Color3.fromRGB(150, 50, 255)
			wave.Material = Enum.Material.Neon
			wave.Anchored = true; wave.CanCollide = false; wave.Transparency = 0.2
			wave.Position = root.Position
			wave.Parent = workspace

			ts:Create(wave, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				Size = Vector3.new(range * 2, range * 2, range * 2), Transparency = 1
			}):Play()
			Debris:AddItem(wave, 0.6)

			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 50, 255), 15)

			-- 3. Sebzés kiosztása késleltetve (Szinkronban az animációval)
			task.delay(0.2, function()
				local enemies = SkillDatabase.getEnemiesInRadius(root.Position, range, char)
				for _, enemy in pairs(enemies) do 
					SkillDatabase.applyDamage(player, enemy, 2.0) 
				end
			end)

			return true
		end
	},

	-- ⛓️ SEALER
	-- ⛓️ SEALER
	["Seal of Power"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local charges = math.min(5, (player:GetAttribute("SealCharges") or 0) + 1)
			player:SetAttribute("SealCharges", charges)
			SkillDatabase.resetChargeTimer(player)

			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then buffTarget = Players:GetPlayerFromCharacter(target.Parent) or player end

			local bChar = buffTarget.Character
			if not bChar then return false end

			local stats = player:FindFirstChild("PlayerStats")
			local intStat = stats and stats:FindFirstChild("INT")
			local dexStat = stats and stats:FindFirstChild("DEX")
			local intVal = intStat and intStat.Value or 1
			local dexVal = dexStat and dexStat.Value or 1

			local dexPenalty = 0
			if dexVal > 15 then dexPenalty = (dexVal - 15) * 1 end

			local masteryBonus = charges * 2
			local bonusPercent = math.max(1, 5 + math.floor(intVal / 10) + masteryBonus - dexPenalty)
			local multi = 1 + (bonusPercent / 100)

			-- IDŐZÍTŐ FRISSÍTÉSE (ha már rajta van a buff, csak az időt toljuk ki!)
			buffTarget:SetAttribute("SealOfPower_Expiry", tick() + 7200)
			buffTarget:SetAttribute("SealOfPower_Multi", multi) 

			if buffTarget:GetAttribute("SealOfPower_Active") then
				return true -- Már aktív, nem futtatjuk le az aurát és a loopot még egyszer!
			end

			buffTarget:SetAttribute("SealOfPower_Active", true)
			SkillDatabase.applyBuffVFX(bChar, "SealOfPower", Color3.fromRGB(255, 50, 50), 7200)

			task.spawn(function()
				-- Folyamatosan nézi, hogy lejárt-e (újrakasztoláskor a tick() kitolódik)
				while buffTarget and buffTarget.Parent do
					local expiry = buffTarget:GetAttribute("SealOfPower_Expiry") or 0
					if tick() >= expiry then break end
					task.wait(1)
				end
				-- Ha végleg lejárt az idő:
				if buffTarget and buffTarget.Parent then 
					buffTarget:SetAttribute("SealOfPower_Active", false)
					buffTarget:SetAttribute("SealOfPower_Multi", nil)
				end 
			end)
			return true
		end
	},
	["Seal of Protection"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local charges = math.min(5, (player:GetAttribute("SealCharges") or 0) + 1)
			player:SetAttribute("SealCharges", charges)
			SkillDatabase.resetChargeTimer(player)

			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then buffTarget = Players:GetPlayerFromCharacter(target.Parent) or player end

			local bChar = buffTarget.Character
			local hum = bChar and bChar:FindFirstChild("Humanoid")
			if not bChar or not hum then return false end

			local stats = player:FindFirstChild("PlayerStats")
			local intStat = stats and stats:FindFirstChild("INT")
			local dexStat = stats and stats:FindFirstChild("DEX")
			local intVal = intStat and intStat.Value or 1
			local dexVal = dexStat and dexStat.Value or 1

			local dexPenalty = 0
			if dexVal > 15 then dexPenalty = (dexVal - 15) * 0.01 end 

			-- IDŐZÍTŐ FRISSÍTÉSE
			buffTarget:SetAttribute("SealOfProtection_Expiry", tick() + 7200)

			if buffTarget:GetAttribute("SealOfProtection_Active") then
				return true -- Már aktív, nem adjuk rá mégegyszer a statokat (nincs több infinite stack!)
			end

			buffTarget:SetAttribute("SealOfProtection_Active", true)
			SkillDatabase.applyBuffVFX(bChar, "SealOfProtection", Color3.fromRGB(255, 215, 0), 7200)

			local targetStats = buffTarget:FindFirstChild("PlayerStats")
			local defStat = targetStats and targetStats:FindFirstChild("Defense")

			local masteryBonus = charges * 0.02
			local finalMultiplier = math.max(0.1, 1 + masteryBonus - dexPenalty)

			local addedDef = math.floor((10 + (intVal * 0.15)) * finalMultiplier)
			local hpPercent = (0.05 + (intVal * 0.001)) * finalMultiplier 
			local addedHP = math.floor(hum.MaxHealth * hpPercent)

			if defStat then defStat.Value += addedDef end
			hum.MaxHealth += addedHP
			hum.Health += addedHP

			task.spawn(function()
				while buffTarget and buffTarget.Parent do
					local expiry = buffTarget:GetAttribute("SealOfProtection_Expiry") or 0
					if tick() >= expiry then break end
					task.wait(1)
				end

				if buffTarget and buffTarget.Parent then 
					buffTarget:SetAttribute("SealOfProtection_Active", false) 
					if defStat then defStat.Value = math.max(0, defStat.Value - addedDef) end
					if hum then
						hum.MaxHealth = math.max(100, hum.MaxHealth - addedHP)
						hum.Health = math.min(hum.Health, hum.MaxHealth)
					end
				end 
			end)
			return true
		end
	},
	["Explosive Seal"] = {
		Mana = 30, Cooldown = 7, -- JAVÍTVA: 15-ről 7 másodpercre felezve
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end

			local charges = math.min(5, (player:GetAttribute("SealCharges") or 0) + 1)
			player:SetAttribute("SealCharges", charges)
			SkillDatabase.resetChargeTimer(player)

			local eRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			local eHum = enemyModel:FindFirstChild("Humanoid")
			if not eRoot or not eHum then return false end

			-- JAVÍTVA: Lassítás alkalmazása (amíg a pecsét ketyeg)
			local originalSpeed = eHum.WalkSpeed
			eHum.WalkSpeed = originalSpeed * 0.5 -- 50%-os lassítás

			local attachPart = enemyModel:FindFirstChild("Head") or eRoot
			local bb = Instance.new("BillboardGui")
			bb.Name = "ExplosiveSealTimer"
			bb.Size = UDim2.new(0, 60, 0, 60)

			local isMetinStone = (enemyModel.Parent and enemyModel.Parent.Name == "MetinStones") or string.match(string.lower(enemyModel.Name), "metin")
			if isMetinStone then
				bb.StudsOffset = Vector3.new(0, (enemyModel:GetExtentsSize().Y / 2) + 2.5, 0)
			else
				bb.StudsOffset = Vector3.new(0, 4.5, 0)
			end
			bb.AlwaysOnTop = true

			local txt = Instance.new("TextLabel", bb)
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Text = "3"
			txt.TextColor3 = Color3.fromRGB(255, 200, 0)
			txt.TextStrokeTransparency = 0
			txt.TextScaled = true
			txt.Font = Enum.Font.GothamBlack

			bb.Parent = attachPart
			SkillDatabase.playVFX(eRoot.Position, Color3.fromRGB(255, 100, 50), 5)

			task.spawn(function()
				local ts = game:GetService("TweenService")

				for i = 3, 1, -1 do
					if not enemyModel or not enemyModel.Parent or not eRoot then break end
					txt.Text = tostring(i)
					txt.TextColor3 = Color3.fromRGB(255, math.floor(80 * i), 0) 

					txt.Size = UDim2.new(1.4, 0, 1.4, 0)
					ts:Create(txt, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()

					task.wait(1)
				end

				if bb then bb:Destroy() end

				-- JAVÍTVA: Robbanáskor visszakapja az eredeti sebességét
				if eHum and eHum.Health > 0 then
					eHum.WalkSpeed = originalSpeed
				end

				if enemyModel and eRoot and enemyModel.Parent then
					local explosionPos = eRoot.Position

					SkillDatabase.playVFX(explosionPos, Color3.fromRGB(255, 50, 0), 20)

					local wave = Instance.new("Part")
					wave.Shape = Enum.PartType.Ball; wave.Material = Enum.Material.Neon; wave.Color = Color3.fromRGB(255, 80, 20)
					wave.Anchored = true; wave.CanCollide = false; wave.Position = explosionPos; wave.Size = Vector3.new(2, 2, 2); wave.Transparency = 0.2; wave.Parent = workspace

					ts:Create(wave, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Size = Vector3.new(30, 30, 30), Transparency = 1
					}):Play()
					Debris:AddItem(wave, 0.6)

					local enemies = SkillDatabase.getEnemiesInRadius(explosionPos, 15, char)
					for _, enemy in pairs(enemies) do
						-- JAVÍTVA: Kisebb, spammelhetőbb sebzés (2.2 helyett 1.2, AOE 1.2 helyett 0.6)
						if enemy == enemyModel then
							SkillDatabase.applyDamage(player, enemy, 1.2)
						else
							SkillDatabase.applyDamage(player, enemy, 0.6)
						end
					end
				end
			end)
			return true
		end
	},
	["Dragon Shackles"] = {
		Mana = 35, Cooldown = 15,
		Execute = function(player, char, root, mousePos, target)
			local primaryTarget = target and target.Parent
			if not SkillDatabase.isValidTarget(primaryTarget) then return false end

			-- Töltet generálás
			local charges = math.min(5, (player:GetAttribute("SealCharges") or 0) + 1)
			player:SetAttribute("SealCharges", charges)
			SkillDatabase.resetChargeTimer(player)

			local maxTargets = primaryTarget:FindFirstChild("IsPlayer") and 3 or 5
			local chainRadius = 15
			local visited = {}
			visited[primaryTarget] = true

			task.spawn(function()
				local currentTarget = primaryTarget
				local jumps = 1
				local currentDmgMulti = 2.5 -- Kezdeti sebzés szorzó

				while currentTarget and jumps <= maxTargets do
					local cRoot = currentTarget:FindFirstChild("HumanoidRootPart")
					local cHum = currentTarget:FindFirstChild("Humanoid")
					if not cRoot or not cHum then break end

					local currentPos = cRoot.Position
					local isPrimary = (jumps == 1)

					local bb = Instance.new("BillboardGui", cRoot)
					bb.Size = UDim2.new(0, 60, 0, 60); bb.StudsOffset = Vector3.new(0, 4.5, 0); bb.AlwaysOnTop = true
					local txt = Instance.new("TextLabel", bb)
					txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextScaled = true; txt.TextColor3 = Color3.fromRGB(255, 165, 0)
					txt.Text = isPrimary and "🐲" or "🔗"

					local ring = Instance.new("Part")
					ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.2, 6, 6); ring.Color = Color3.fromRGB(255, 215, 0); ring.Material = Enum.Material.Neon; ring.Anchored = false; ring.CanCollide = false
					ring.CFrame = cRoot.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
					ring.Parent = cRoot
					local w = Instance.new("WeldConstraint", ring); w.Part0 = ring; w.Part1 = cRoot

					local oldSpeed = cHum.WalkSpeed
					cHum.WalkSpeed = 0

					local elapsed = 0
					while elapsed < 2 do
						task.wait(0.1)
						elapsed = elapsed + 0.1
						if not cHum or cHum.Health <= 0 then break end
					end

					if bb then bb:Destroy() end
					if ring then ring:Destroy() end
					if cHum and cHum.Health > 0 then cHum.WalkSpeed = oldSpeed end
					if cRoot and cRoot.Parent then currentPos = cRoot.Position end

					SkillDatabase.playVFX(currentPos, Color3.fromRGB(255, 150, 0), 10)

					if cHum and cHum.Health > 0 then
						-- Sebzés kiosztása az aktuális szorzóval
						SkillDatabase.applyDamage(player, currentTarget, currentDmgMulti) 
					end

					-- Sebzés csökkentése a következő ugrásra (-15%)
					currentDmgMulti = currentDmgMulti * 0.85 

					if jumps < maxTargets then
						local enemies = SkillDatabase.getEnemiesInRadius(currentPos, chainRadius, char)
						local nextTarget = nil
						local closestDist = math.huge

						for _, enemy in pairs(enemies) do
							if not visited[enemy] then
								local eRoot = enemy:FindFirstChild("HumanoidRootPart")
								if eRoot then
									local dist = (eRoot.Position - currentPos).Magnitude
									if dist < closestDist then
										closestDist = dist
										nextTarget = enemy
									end
								end
							end
						end

						if nextTarget then
							visited[nextTarget] = true
							local nRoot = nextTarget:FindFirstChild("HumanoidRootPart")
							if cRoot and nRoot then
								local att0 = Instance.new("Attachment", cRoot)
								local att1 = Instance.new("Attachment", nRoot)
								local beam = Instance.new("Beam", cRoot)
								beam.Attachment0 = att0; beam.Attachment1 = att1; beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0)); beam.FaceCamera = true; beam.Width0 = 0.5; beam.Width1 = 0.5; beam.LightEmission = 1; beam.LightInfluence = 0
								Debris:AddItem(att0, 0.5); Debris:AddItem(att1, 0.5); Debris:AddItem(beam, 0.5)
							end
							currentTarget = nextTarget
							jumps = jumps + 1
						else
							break 
						end
					else
						break 
					end
				end
			end)
			return true
		end
	},
}

if RunService:IsServer() then
	-- =======================================
	-- 🛡️ GUARDIAN: IRON WILL PÁNCÉL RENDSZER
	-- =======================================
	local function updateGuardianArmor(player, char, hum)
		if not player or not char or not hum then return end
		local rawClass = player:GetAttribute("Class") or char:GetAttribute("Class") or ""
		if string.lower(rawClass) ~= "guardian" then return end

		local stats = player:FindFirstChild("PlayerStats")
		local defStat = stats and stats:FindFirstChild("Defense")
		if not defStat then return end

		local hpPercent = hum.Health / hum.MaxHealth
		local currentBonus = player:GetAttribute("IronWill_DefBonus") or 0

		-- 1. Kiszámoljuk a tiszta (bónusz nélküli) alap páncélt
		local baseDef = defStat.Value - currentBonus

		-- 2. Kiszámoljuk az új bónuszt a HP alapján
		local newBonus = 0
		if hpPercent <= 0.15 then
			newBonus = math.floor(baseDef * 0.30)
		elseif hpPercent <= 0.30 then
			newBonus = math.floor(baseDef * 0.20)
		elseif hpPercent <= 0.50 then
			newBonus = math.floor(baseDef * 0.10)
		end

		-- 3. Ha változott a bónusz (pl. lement a HP vagy visszatöltött)
		if newBonus ~= currentBonus then
			defStat.Value = baseDef + newBonus
			player:SetAttribute("IronWill_DefBonus", newBonus)
		end
	end

	local function setupPlayer(player)
		player.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.HealthChanged:Connect(function()
					updateGuardianArmor(player, char, hum)
				end)
			end
		end)

		if player.Character then
			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then
				hum.HealthChanged:Connect(function()
					updateGuardianArmor(player, player.Character, hum)
				end)
			end
		end
	end

	for _, p in pairs(Players:GetPlayers()) do
		setupPlayer(p)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	-- =======================================
	-- ALAP MANA REGEN
	-- =======================================
	task.spawn(function()
		while task.wait(2) do
			for _, player in pairs(Players:GetPlayers()) do
				local stats = player:FindFirstChild("PlayerStats")
				if stats then
					local mana = stats:FindFirstChild("Mana")
					local maxMana = stats:FindFirstChild("MaxMana")
					if mana and maxMana and mana.Value < maxMana.Value then
						mana.Value = math.min(maxMana.Value, mana.Value + 10)
					end
				end
			end
		end
	end)
end

return SkillDatabase