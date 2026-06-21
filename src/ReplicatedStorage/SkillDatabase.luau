-- Fájl helye: ReplicatedStorage -> SkillDatabase

local SkillDatabase = {}
local Debris = game:GetService("Debris")

-- Minden Képesség Hatótávja (A kliens és szerver is ezt nézi)
SkillDatabase.Ranges = {
	["Shield Charge"] = 25, ["Earthbreaker"] = 15, ["Blade Spirit"] = 0, ["Iron Skin"] = 0,
	["Shadow Strike"] = 35, ["Whirling Blades"] = 12, ["Bloodlust"] = 0, ["Death Mark"] = 50,
	["Soul Orb"] = 60, ["Spirit Chain"] = 45, ["Spirit Blessing"] = 0, ["Soul Explosion"] = 25,
	["Seal of Power"] = 50, ["Seal of Protection"] = 50, ["Explosive Seal"] = 40, ["Dragon Shackles"] = 40
}

function SkillDatabase.playVFX(part, color, size, duration)
	if not part then return end
	local att = Instance.new("Attachment", part)
	local emitter = Instance.new("ParticleEmitter", att)
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size or 3), NumberSequenceKeypoint.new(1, 0)})
	emitter.Texture = "rbxassetid://281983280" 
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(15, 30)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter:Emit(40)
	Debris:AddItem(att, duration or 1.5)
end

-- Egyedi Aura Buffokhoz (hogy látszódjon, hogy rajtad van)
function SkillDatabase.createAura(char, color)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local att = Instance.new("Attachment", root)
	local emitter = Instance.new("ParticleEmitter", att)
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(1.5)
	emitter.Texture = "rbxassetid://281983280"
	emitter.Rate = 15
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.LockedToPart = true
	return att
end

function SkillDatabase.getEnemiesInRadius(centerPos, radius)
	local enemies = {}
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
			if not obj:GetAttribute("IsNPC") then
				local dist = (obj.HumanoidRootPart.Position - centerPos).Magnitude
				if dist <= radius then table.insert(enemies, obj) end
			end
		end
	end
	if workspace:FindFirstChild("Monsters") then
		for _, obj in pairs(workspace.Monsters:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
				local dist = (obj.HumanoidRootPart.Position - centerPos).Magnitude
				if dist <= radius then table.insert(enemies, obj) end
			end
		end
	end
	return enemies
end

function SkillDatabase.applyDamage(attacker, targetHum, baseDmgMult)
	local atkDamage = attacker:GetAttribute("AttackDamage") or 5
	local finalDmg = math.floor(atkDamage * baseDmgMult)

	if targetHum.Parent:GetAttribute("DeathMark") then
		finalDmg = math.floor(finalDmg * (targetHum.Parent:FindFirstChild("IsPlayer") and 1.1 or 1.2)) 
	end
	targetHum:TakeDamage(finalDmg)
end

SkillDatabase.Skills = {

	-- 🛡️ GUARDIAN SKILLEK
	["Shield Charge"] = {
		Mana = 15, Cooldown = 8,
		Execute = function(player, char, root, hum, mousePos, target)
			SkillDatabase.playVFX(root, Color3.fromRGB(255, 200, 50), 5) 
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = root.CFrame.LookVector * 60
			bv.MaxForce = Vector3.new(100000, 0, 100000)
			bv.Parent = root
			Debris:AddItem(bv, 0.3)

			task.wait(0.3)
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 8)
			for _, enemy in pairs(enemies) do
				if enemy ~= char then
					SkillDatabase.applyDamage(player, enemy.Humanoid, 1.2)
					if enemy:FindFirstChild("IsPlayer") then
						local oldSpeed = enemy.Humanoid.WalkSpeed
						enemy.Humanoid.WalkSpeed = oldSpeed - 4
						task.delay(2, function() if enemy and enemy.Humanoid then enemy.Humanoid.WalkSpeed = oldSpeed end end)
					end
				end
			end
		end
	},
	["Earthbreaker"] = {
		Mana = 25, Cooldown = 12,
		Execute = function(player, char, root, hum, mousePos, target)
			local eff = Instance.new("Part")
			eff.Size = Vector3.new(15, 0.5, 15)
			eff.Position = root.Position - Vector3.new(0, 2.5, 0)
			eff.Anchored = true
			eff.CanCollide = false
			eff.Material = Enum.Material.Neon
			eff.Color = Color3.fromRGB(150, 80, 20)
			eff.Parent = workspace
			Debris:AddItem(eff, 0.3)
			SkillDatabase.playVFX(eff, Color3.fromRGB(150, 80, 20), 10) 

			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 15)
			for _, enemy in pairs(enemies) do
				if enemy ~= char then SkillDatabase.applyDamage(player, enemy.Humanoid, 1.8) end
			end
		end
	},
	["Blade Spirit"] = {
		Mana = 30, Cooldown = 2, IsToggle = true, ToggleAttribute = "BladeSpirit_Active",
		Execute = function(player, char, root, hum, mousePos, target)
			local current = player:GetAttribute("BladeSpirit_Active")
			player:SetAttribute("BladeSpirit_Active", not current)
			if not current then SkillDatabase.playVFX(root, Color3.fromRGB(255, 255, 100), 6) end
		end
	},
	["Iron Skin"] = {
		Mana = 40, Cooldown = 20, Duration = 6,
		Execute = function(player, char, root, hum, mousePos, target)
			SkillDatabase.playVFX(root, Color3.fromRGB(100, 100, 100), 5) 
			player:SetAttribute("IronSkin_Active", true)
			local aura = SkillDatabase.createAura(char, Color3.fromRGB(150, 150, 150))
			task.delay(6, function() 
				if player then player:SetAttribute("IronSkin_Active", false) end
				if aura then aura:Destroy() end
			end)
		end
	},

	-- ⚔️ SHADOWBLADE SKILLEK
	["Shadow Strike"] = {
		Mana = 20, Cooldown = 10,
		Execute = function(player, char, root, hum, mousePos, target)
			local tRoot = target and target.Parent:FindFirstChild("HumanoidRootPart")
			if tRoot and target.Parent ~= char then
				SkillDatabase.playVFX(root, Color3.fromRGB(30, 30, 30), 4) 
				root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
				SkillDatabase.playVFX(root, Color3.fromRGB(150, 0, 0), 4) 
				SkillDatabase.applyDamage(player, target.Parent.Humanoid, 2.5) 
			end
		end
	},
	["Whirling Blades"] = {
		Mana = 25, Cooldown = 8,
		Execute = function(player, char, root, hum, mousePos, target)
			SkillDatabase.playVFX(root, Color3.fromRGB(200, 50, 50), 12) 
			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 12)
			for _, enemy in pairs(enemies) do
				if enemy ~= char then SkillDatabase.applyDamage(player, enemy.Humanoid, 1.4) end
			end
		end
	},
	["Bloodlust"] = {
		Mana = 35, Cooldown = 2, IsToggle = true, ToggleAttribute = "Bloodlust_Active",
		Execute = function(player, char, root, hum, mousePos, target)
			local current = player:GetAttribute("Bloodlust_Active")
			player:SetAttribute("Bloodlust_Active", not current)
			if not current then SkillDatabase.playVFX(root, Color3.fromRGB(255, 0, 0), 6) end
		end
	},
	["Death Mark"] = {
		Mana = 30, Cooldown = 15,
		Execute = function(player, char, root, hum, mousePos, target)
			local enemyTarget = target and target.Parent
			if enemyTarget and enemyTarget:FindFirstChild("Humanoid") and enemyTarget ~= char then
				local eRoot = enemyTarget:FindFirstChild("HumanoidRootPart")
				if eRoot then SkillDatabase.playVFX(eRoot, Color3.fromRGB(50, 0, 0), 5) end
				enemyTarget:SetAttribute("DeathMark", true)
				task.delay(10, function() if enemyTarget then enemyTarget:SetAttribute("DeathMark", false) end end)
			end
		end
	},

	-- 🔮 SOULWEAVER SKILLEK
	["Soul Orb"] = {
		Mana = 10, Cooldown = 3,
		Execute = function(player, char, root, hum, mousePos, target)
			local orb = Instance.new("Part")
			orb.Size = Vector3.new(2, 2, 2)
			orb.Shape = Enum.PartType.Ball
			orb.Color = Color3.fromRGB(150, 50, 255)
			orb.Material = Enum.Material.Neon
			orb.CanCollide = false
			orb.Massless = true
			orb.CFrame = root.CFrame * CFrame.new(0, 0, -3)
			orb.Parent = workspace

			local bv = Instance.new("LinearVelocity", orb)
			local att = Instance.new("Attachment", orb)
			bv.Attachment0 = att
			bv.MaxForce = 100000
			bv.VectorVelocity = (mousePos - root.Position).Unit * 80
			Debris:AddItem(orb, 2)

			local hitOnce = false
			orb.Touched:Connect(function(hit)
				if hitOnce or hit:IsDescendantOf(char) then return end
				local eHum = hit.Parent:FindFirstChild("Humanoid")
				if eHum then
					hitOnce = true
					SkillDatabase.playVFX(orb, Color3.fromRGB(200, 100, 255), 6)
					SkillDatabase.applyDamage(player, eHum, 1.5)
					orb:Destroy()
				end
			end)
		end
	},
	["Spirit Chain"] = {
		Mana = 30, Cooldown = 12,
		Execute = function(player, char, root, hum, mousePos, target)
			SkillDatabase.playVFX(root, Color3.fromRGB(100, 150, 255), 6)
			local enemies = SkillDatabase.getEnemiesInRadius(mousePos, 20)
			local jumps = 0
			for _, enemy in pairs(enemies) do
				if enemy ~= char and jumps < 4 then
					SkillDatabase.applyDamage(player, enemy.Humanoid, 1.3)
					local tRoot = enemy:FindFirstChild("HumanoidRootPart")
					if tRoot then SkillDatabase.playVFX(tRoot, Color3.fromRGB(100, 150, 255), 4) end
					jumps += 1
					task.wait(0.2)
				end
			end
		end
	},
	["Spirit Blessing"] = {
		Mana = 50, Cooldown = 2, IsToggle = true, ToggleAttribute = "SpiritBlessing_Active",
		Execute = function(player, char, root, hum, mousePos, target)
			local current = player:GetAttribute("SpiritBlessing_Active")
			player:SetAttribute("SpiritBlessing_Active", not current)
			if not current then SkillDatabase.playVFX(root, Color3.fromRGB(50, 255, 255), 6) end
		end
	},
	["Soul Explosion"] = {
		Mana = 60, Cooldown = 20,
		Execute = function(player, char, root, hum, mousePos, target)
			local eff = Instance.new("Part")
			eff.Size = Vector3.new(25, 1, 25)
			eff.Position = root.Position - Vector3.new(0, 2.5, 0)
			eff.Anchored = true
			eff.CanCollide = false
			eff.Shape = Enum.PartType.Cylinder
			eff.Material = Enum.Material.Neon
			eff.Color = Color3.fromRGB(200, 50, 255)
			eff.Parent = workspace
			Debris:AddItem(eff, 0.4)
			SkillDatabase.playVFX(eff, Color3.fromRGB(200, 50, 255), 15)

			local enemies = SkillDatabase.getEnemiesInRadius(root.Position, 25) 
			for _, enemy in pairs(enemies) do
				if enemy ~= char then
					SkillDatabase.applyDamage(player, enemy.Humanoid, 2.0)
					if enemy:FindFirstChild("IsPlayer") then
						local oldSpeed = enemy.Humanoid.WalkSpeed
						enemy.Humanoid.WalkSpeed = oldSpeed - 6
						task.delay(1.5, function() if enemy and enemy:FindFirstChild("Humanoid") then enemy.Humanoid.WalkSpeed = oldSpeed end end)
					end
				end
			end
		end
	},

	-- ⛓️ SEALER SKILLEK
	["Seal of Power"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, hum, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("Humanoid") and target.Parent:FindFirstChild("IsPlayer") then
				buffTarget = game:GetService("Players"):GetPlayerFromCharacter(target.Parent) or player
			end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot, Color3.fromRGB(255, 50, 50), 5) end

			buffTarget:SetAttribute("SealOfPower_Active", true)
			local aura = SkillDatabase.createAura(buffTarget.Character, Color3.fromRGB(255, 50, 50))
			task.delay(7200, function() 
				if buffTarget then buffTarget:SetAttribute("SealOfPower_Active", false) end 
				if aura then aura:Destroy() end
			end)
		end
	},
	["Seal of Protection"] = {
		Mana = 40, Cooldown = 5, Duration = 7200,
		Execute = function(player, char, root, hum, mousePos, target)
			local buffTarget = player
			if target and target.Parent:FindFirstChild("Humanoid") and target.Parent:FindFirstChild("IsPlayer") then
				buffTarget = game:GetService("Players"):GetPlayerFromCharacter(target.Parent) or player
			end
			local bRoot = buffTarget.Character and buffTarget.Character:FindFirstChild("HumanoidRootPart")
			if bRoot then SkillDatabase.playVFX(bRoot, Color3.fromRGB(50, 100, 255), 5) end

			buffTarget:SetAttribute("SealOfProtection_Active", true)
			local aura = SkillDatabase.createAura(buffTarget.Character, Color3.fromRGB(50, 100, 255))
			task.delay(7200, function() 
				if buffTarget then buffTarget:SetAttribute("SealOfProtection_Active", false) end 
				if aura then aura:Destroy() end
			end)
		end
	},
	["Explosive Seal"] = {
		Mana = 30, Cooldown = 15,
		Execute = function(player, char, root, hum, mousePos, target)
			local enemyTarget = target and target.Parent
			if enemyTarget and enemyTarget ~= char and enemyTarget:FindFirstChild("Humanoid") then
				local eRoot = enemyTarget:FindFirstChild("HumanoidRootPart")
				if eRoot then SkillDatabase.playVFX(eRoot, Color3.fromRGB(255, 100, 50), 4) end

				task.delay(3, function() 
					if enemyTarget and enemyTarget:FindFirstChild("Humanoid") then
						if eRoot then SkillDatabase.playVFX(eRoot, Color3.fromRGB(255, 0, 0), 8) end
						SkillDatabase.applyDamage(player, enemyTarget.Humanoid, 3.0) 
					end
				end)
			end
		end
	},
	["Dragon Shackles"] = {
		Mana = 35, Cooldown = 25,
		Execute = function(player, char, root, hum, mousePos, target)
			local enemyTarget = target and target.Parent
			if enemyTarget and enemyTarget ~= char and enemyTarget:FindFirstChild("Humanoid") then
				local eRoot = enemyTarget:FindFirstChild("HumanoidRootPart")
				if eRoot then SkillDatabase.playVFX(eRoot, Color3.fromRGB(200, 200, 0), 6) end

				local isPvP = enemyTarget:FindFirstChild("IsPlayer")
				local rootTime = isPvP and 1 or 4

				local oldSpeed = enemyTarget.Humanoid.WalkSpeed
				enemyTarget.Humanoid.WalkSpeed = 0 

				task.delay(rootTime, function()
					if enemyTarget and enemyTarget:FindFirstChild("Humanoid") then
						enemyTarget.Humanoid.WalkSpeed = oldSpeed
					end
				end)
			end
		end
	},
}

return SkillDatabase