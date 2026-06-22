-- Fájl helye: ReplicatedStorage -> SkillDatabase

local SkillDatabase = {}
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

-- Védett NPC-k listája (Nehogy a boltosokat leüssük)
local protectedNPCs = {
	["Fegyverkereskedo"] = true, ["Pancelkereskedo"] = true, ["Vegyesbolt"] = true, 
	["Kovacs"] = true, ["Faluose"] = true, ["Varosor"] = true, ["Raktaros"] = true
}

-- ==========================================
-- 1. SEGÉDFÜGGVÉNYEK (Célzás, Sebzés, Látvány)
-- ==========================================

function SkillDatabase.isValidTarget(obj)
	if not obj or not obj:IsA("Model") then return false end
	local hum = obj:FindFirstChild("Humanoid")
	local root = obj:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return false end
	if protectedNPCs[obj.Name] or obj:GetAttribute("IsNPC") then return false end
	return true
end

function SkillDatabase.getEnemiesInRadius(centerPos, radius, excludeChar)
	local enemies = {}
	for _, obj in pairs(workspace:GetChildren()) do
		if obj ~= excludeChar and SkillDatabase.isValidTarget(obj) then
			if (obj.HumanoidRootPart.Position - centerPos).Magnitude <= radius then
				table.insert(enemies, obj)
			end
		end
	end
	if workspace:FindFirstChild("Monsters") then
		for _, obj in pairs(workspace.Monsters:GetChildren()) do
			if obj ~= excludeChar and SkillDatabase.isValidTarget(obj) then
				if (obj.HumanoidRootPart.Position - centerPos).Magnitude <= radius then
					table.insert(enemies, obj)
				end
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

	if targetModel:GetAttribute("DeathMark") then
		finalDmg = math.floor(finalDmg * (targetModel:FindFirstChild("IsPlayer") and 1.1 or 1.2))
	end

	hum:TakeDamage(finalDmg)

	-- Dinamikus lekérés a Deadlock (fagyás) elkerülésére!
	local ShowDamage = Events:FindFirstChild("ShowDamage")
	if ShowDamage then
		ShowDamage:FireAllClients(finalDmg, root.Position, isCrit, false)
	end
end

function SkillDatabase.playVFX(position, color, size, duration)
	local part = Instance.new("Part")
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

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

-- ==========================================
-- 2. KÉPESSÉGEK DEFINÍCIÓI
-- ==========================================
SkillDatabase.Ranges = {
	["Shield Charge"] = 25, ["Earthbreaker"] = 15, ["Blade Spirit"] = 0, ["Iron Skin"] = 0,
	["Shadow Strike"] = 35, ["Whirling Blades"] = 12, ["Bloodlust"] = 0, ["Death Mark"] = 50,
	["Soul Orb"] = 60, ["Spirit Chain"] = 45, ["Spirit Blessing"] = 0, ["Soul Explosion"] = 25,
	["Seal of Power"] = 50, ["Seal of Protection"] = 50, ["Explosive Seal"] = 40, ["Dragon Shackles"] = 40
}

SkillDatabase.Skills = {
	-- 🛡️ GUARDIAN
	["Shield Charge"] = {
		Mana = 15, Cooldown = 8,
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 200, 50), 5)
			local bv = Instance.new("BodyVelocity", root)
			bv.Velocity = root.CFrame.LookVector * 60
			bv.MaxForce = Vector3.new(100000, 0, 100000)
			Debris:AddItem(bv, 0.25)

			task.wait(0.25)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 8, char)
			for _, enemy in pairs(enemies) do
				SkillDatabase.applyDamage(player, enemy, 1.2)
				if enemy:FindFirstChild("IsPlayer") then
					local eHum = enemy:FindFirstChild("Humanoid")
					local oldSpeed = eHum.WalkSpeed
					eHum.WalkSpeed = math.max(0, oldSpeed - 4)
					task.delay(2, function() if eHum then eHum.WalkSpeed = oldSpeed end end)

					local ApplyEffect = Events:FindFirstChild("ApplyEffect")
					local enemyPlayer = game.Players:GetPlayerFromCharacter(enemy)
					if enemyPlayer and ApplyEffect then ApplyEffect:FireClient(enemyPlayer, "Shield Charge", "Lassítás", 0, 2) end
				end
			end
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
			local ApplyEffect = Events:FindFirstChild("ApplyEffect")
			if ApplyEffect then ApplyEffect:FireClient(player, "Iron Skin", "Buff", 0, 6) end
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
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(150, 0, 0), 5) 
			SkillDatabase.applyDamage(player, enemyModel, 2.5) 
			return true
		end
	},
	["Whirling Blades"] = {
		Mana = 25, Cooldown = 8,
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(200, 50, 50), 12)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 12, char)
			for _, enemy in pairs(enemies) do SkillDatabase.applyDamage(player, enemy, 1.4) end
			return true
		end
	},
	["Bloodlust"] = {
		Mana = 35, Cooldown = 2, IsToggle = true, ToggleAttribute = "Bloodlust_Active",
		Execute = function(player, char, root, mousePos, target)
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(255, 0, 0), 6)
			return true
		end
	},
	["Death Mark"] = {
		Mana = 30, Cooldown = 15,
		Execute = function(player, char, root, mousePos, target)
			local enemyModel = target and target.Parent
			if not SkillDatabase.isValidTarget(enemyModel) then return false end
			enemyModel:SetAttribute("DeathMark", true)
			SkillDatabase.playVFX(enemyModel.HumanoidRootPart.Position, Color3.fromRGB(50, 0, 0), 6)
			if enemyModel:FindFirstChild("IsPlayer") then
				local targetPlayer = game.Players:GetPlayerFromCharacter(enemyModel)
				local ApplyEffect = Events:FindFirstChild("ApplyEffect")
				if targetPlayer and ApplyEffect then ApplyEffect:FireClient(targetPlayer, "Death Mark", "Debuff", 0, 10) end
			end
			task.delay(10, function() if enemyModel then enemyModel:SetAttribute("DeathMark", false) end end)
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
			lv.Attachment0 = att; lv.MaxForce = 100000
			lv.VectorVelocity = (tRoot.Position - root.Position).Unit * 80
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
			SkillDatabase.playVFX(root.Position, Color3.fromRGB(200, 50, 255), 25)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 25, char) 
			for _, enemy in pairs(enemies) do
				SkillDatabase.applyDamage(player, enemy, 2.0)
				if enemy:FindFirstChild("IsPlayer") then
					local eHum = enemy:FindFirstChild("Humanoid")
					local oldSpeed = eHum.WalkSpeed
					eHum.WalkSpeed = math.max(0, oldSpeed - 6)
					task.delay(1.5, function() if eHum then eHum.WalkSpeed = oldSpeed end end)
					local enemyPlayer = game.Players:GetPlayerFromCharacter(enemy)
					local ApplyEffect = Events:FindFirstChild("ApplyEffect")
					if enemyPlayer and ApplyEffect then ApplyEffect:FireClient(enemyPlayer, "Soul Explosion", "Lassítás", 0, 1.5) end
				end
			end
			return true
		end
	},

	-- ⛓️ SEALER
	["Seal of Power"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then
				buffTarget = game.Players:GetPlayerFromCharacter(target.Parent) or player
			end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot.Position, Color3.fromRGB(255, 50, 50), 6) end
			buffTarget:SetAttribute("SealOfPower_Active", true)
			local ApplyEffect = Events:FindFirstChild("ApplyEffect")
			if ApplyEffect then ApplyEffect:FireClient(buffTarget, "Seal of Power", "Buff", 0, 7200) end
			task.delay(7200, function() if buffTarget then buffTarget:SetAttribute("SealOfPower_Active", false) end end)
			return true
		end
	},
	["Seal of Protection"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("IsPlayer") then
				buffTarget = game.Players:GetPlayerFromCharacter(target.Parent) or player
			end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot.Position, Color3.fromRGB(50, 100, 255), 6) end
			buffTarget:SetAttribute("SealOfProtection_Active", true)
			local ApplyEffect = Events:FindFirstChild("ApplyEffect")
			if ApplyEffect then ApplyEffect:FireClient(buffTarget, "Seal of Protection", "Buff", 0, 7200) end
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
			SkillDatabase.playVFX(eRoot.Position, Color3.fromRGB(255, 100, 50), 4)
			if enemyModel:FindFirstChild("IsPlayer") then
				local enemyPlayer = game.Players:GetPlayerFromCharacter(enemyModel)
				local ApplyEffect = Events:FindFirstChild("ApplyEffect")
				if enemyPlayer and ApplyEffect then ApplyEffect:FireClient(enemyPlayer, "Explosive Seal", "Bomba", 0, 3) end
			end
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
			if isPvP then
				local enemyPlayer = game.Players:GetPlayerFromCharacter(enemyModel)
				local ApplyEffect = Events:FindFirstChild("ApplyEffect")
				if enemyPlayer and ApplyEffect then ApplyEffect:FireClient(enemyPlayer, "Dragon Shackles", "Lefogva", 0, rootTime) end
			end
			task.delay(rootTime, function() if eHum then eHum.WalkSpeed = oldSpeed end end)
			return true
		end
	},
}

return SkillDatabase