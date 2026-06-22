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
	for _, obj in pairs(workspace:GetChildren()) do
		if obj ~= excludeChar and SkillDatabase.isValidTarget(obj) then
			if (obj.HumanoidRootPart.Position - centerPos).Magnitude <= radius then table.insert(enemies, obj) end
		end
	end
	if workspace:FindFirstChild("Monsters") then
		for _, obj in pairs(workspace.Monsters:GetChildren()) do
			if obj ~= excludeChar and SkillDatabase.isValidTarget(obj) then
				if (obj.HumanoidRootPart.Position - centerPos).Magnitude <= radius then table.insert(enemies, obj) end
			end
		end
	end
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

	local markApplier = targetModel:GetAttribute("DeathMark_Applier")
	if markApplier and markApplier == attacker.UserId then
		targetModel:SetAttribute("DeathMark_Applier", nil) 

		local attachPart = targetModel:FindFirstChild("Head") or targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart
		if attachPart and attachPart:FindFirstChild("DeathMarkVisual") then attachPart.DeathMarkVisual:Destroy() end

		local bonusDmg = math.floor(finalDmg * (targetModel:FindFirstChild("IsPlayer") and 0.5 or 0.8)) 

		hum:TakeDamage(finalDmg + bonusDmg)
		ShowDamage:FireAllClients(finalDmg, root.Position, isCrit, false)

		task.delay(0.15, function()
			ShowDamage:FireAllClients(bonusDmg, root.Position + Vector3.new(0, 2, 0), true, false)
		end)
		return 
	end

	hum:TakeDamage(finalDmg)
	ShowDamage:FireAllClients(finalDmg, root.Position, isCrit, false)
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

SkillDatabase.Skills = {

	-- 🛡️ GUARDIAN
	["Shield Charge"] = {
		Mana = 15, Cooldown = 8,
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 200, 50), 5)
			local bv = Instance.new("BodyVelocity", root)
			bv.Velocity = root.CFrame.LookVector * 60; bv.MaxForce = Vector3.new(100000, 0, 100000); Debris:AddItem(bv, 0.25)
			task.wait(0.25)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 8, char)
			for _, enemy in pairs(enemies) do SkillDatabase.applyDamage(player, enemy, 1.2) end
			return true
		end
	},
	["Earthbreaker"] = {
		Mana = 25, Cooldown = 12,
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 80, 20), 15)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 15, char)
			for _, enemy in pairs(enemies) do SkillDatabase.applyDamage(player, enemy, 1.8) end
			return true
		end
	},
	["Blade Spirit"] = {
		Mana = 30, Cooldown = 2, IsToggle = true, ToggleAttribute = "BladeSpirit_Active",
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 255, 100), 6)
			return true
		end
	},
	["Iron Skin"] = {
		Mana = 40, Cooldown = 20, Duration = 6,
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 150, 150), 6)
			player:SetAttribute("IronSkin_Active", true)
			SkillDatabase.sendBuffUI(player, "Iron Skin", "Védelem", 6)
			task.delay(6, function() if player then player:SetAttribute("IronSkin_Active", false) end end)
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
					for _, enemy in pairs(enemies) do SkillDatabase.applyDamage(player, enemy, 0.6) end
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
				-- BEKAPCSOLÁS: Közvetlenül a PlayerStats-ot növeljük meg, így a CombatClient azonnal alkalmazza!
				player:SetAttribute("Bloodlust_Active", true)
				SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 0, 0), 6)

				movementSpeed.Value += 15 -- +15% Mozgási sebesség
				attackSpeed.Value += 30   -- +30% Támadási sebesség
			else
				-- KIKAPCSOLÁS: Levonjuk a bónuszt a statokból
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
			local tRoot = enemyModel.HumanoidRootPart
			local orb = Instance.new("Part", workspace)
			orb.Size = Vector3.new(1.5, 1.5, 1.5); orb.Shape = Enum.PartType.Ball; orb.Color = Color3.fromRGB(150, 50, 255); orb.Material = Enum.Material.Neon; orb.CanCollide = false; orb.Massless = true
			orb.CFrame = root.CFrame * CFrame.new(0, 0, -3)
			local lv = Instance.new("LinearVelocity", orb)
			local att = Instance.new("Attachment", orb)
			lv.Attachment0 = att; lv.MaxForce = 100000; lv.VectorVelocity = (tRoot.Position - root.Position).Unit * 80
			Debris:AddItem(orb, 2)
			local hitOnce = false
			orb.Touched:Connect(function(hit)
				if hitOnce or hit:IsDescendantOf(char) then return end
				if hit.Parent == enemyModel then
					hitOnce = true
					SkillDatabase.playVFX(orb.Position, Color3.fromRGB(200, 100, 255), 6)
					SkillDatabase.applyDamage(player, enemyModel, 1.5)
					orb:Destroy()
				end
			end)
			return true
		end
	},
	["Spirit Chain"] = {
		Mana = 30, Cooldown = 12,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(100, 150, 255), 6)
			SkillDatabase.applyDamage(player, enemyModel, 1.3)
			SkillDatabase.playVFX(enemyModel.HumanoidRootPart.Position, Color3.fromRGB(100, 150, 255), 5)
			local enemies = SkillDatabase.getEnemiesInRadius(enemyModel.HumanoidRootPart.Position, 20, char)
			local jumps = 0
			for _, enemy in pairs(enemies) do
				if enemy ~= enemyModel and jumps < 4 then
					jumps = jumps + 1
					task.wait(0.2)
					SkillDatabase.applyDamage(player, enemy, 1.3)
					SkillDatabase.playVFX(enemy.HumanoidRootPart.Position, Color3.fromRGB(100, 150, 255), 5)
				end
			end
			return true
		end
	},
	["Spirit Blessing"] = {
		Mana = 50, Cooldown = 2, IsToggle = true, ToggleAttribute = "SpiritBlessing_Active",
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(50, 255, 255), 6)
			return true
		end
	},
	["Soul Explosion"] = {
		Mana = 60, Cooldown = 20,
		Execute = function(player, char, root, mousePos, target)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 25, char) 
			for _, enemy in pairs(enemies) do SkillDatabase.applyDamage(player, enemy, 2.0) end
			return true
		end
	},

	-- ⛓️ SEALER
	["Seal of Power"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then buffTarget = Players:GetPlayerFromCharacter(target.Parent) or player end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot.Position, Color3.fromRGB(255, 50, 50), 6) end
			buffTarget:SetAttribute("SealOfPower_Active", true)
			SkillDatabase.sendBuffUI(buffTarget, "Seal of Power", "Sebzés Bónusz", 7200)
			task.delay(7200, function() if buffTarget then buffTarget:SetAttribute("SealOfPower_Active", false) end end)
			return true
		end
	},
	["Seal of Protection"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then buffTarget = Players:GetPlayerFromCharacter(target.Parent) or player end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot.Position, Color3.fromRGB(50, 100, 255), 6) end
			buffTarget:SetAttribute("SealOfProtection_Active", true)
			SkillDatabase.sendBuffUI(buffTarget, "Seal of Protection", "Védelem Bónusz", 7200)
			task.delay(7200, function() if buffTarget then buffTarget:SetAttribute("SealOfProtection_Active", false) end end)
			return true
		end
	},
	["Explosive Seal"] = {
		Mana = 30, Cooldown = 15,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			local eRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			SkillDatabase.playVFX(eRoot.Position, Color3.fromRGB(255, 100, 50), 5)
			task.delay(3, function() 
				if SkillDatabase.isValidTarget(enemyModel) then
					SkillDatabase.playVFX(enemyModel.HumanoidRootPart.Position, Color3.fromRGB(255, 0, 0), 10)
					SkillDatabase.applyDamage(player, enemyModel, 3.0) 
				end
			end)
			return true
		end
	},
	["Dragon Shackles"] = {
		Mana = 35, Cooldown = 25,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			local eRoot = enemyModel:FindFirstChild("HumanoidRootPart")
			SkillDatabase.playVFX(eRoot.Position, Color3.fromRGB(200, 200, 0), 7)
			local isPvP = enemyModel:FindFirstChild("IsPlayer")
			local rootTime = isPvP and 1 or 4
			local eHum = enemyModel:FindFirstChild("Humanoid")
			local oldSpeed = eHum.WalkSpeed
			eHum.WalkSpeed = 0 
			task.delay(rootTime, function() if eHum then eHum.WalkSpeed = oldSpeed end end)
			return true
		end
	},
}

if RunService:IsServer() then
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