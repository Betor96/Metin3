-- Fájl helye: ServerScriptService -> AIManager

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")

local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

local Events = ReplicatedStorage:WaitForChild("Events")
local ShowDamage = Events:WaitForChild("ShowDamage")

-- ==========================================
-- KÖZPONTI AI TÁBLA (Itt tárolunk minden élő szörnyet)
-- ==========================================
local activeMonsters = {}

pcall(function()
	PhysicsService:RegisterCollisionGroup("Monsters")
	PhysicsService:CollisionGroupSetCollidable("Monsters", "Monsters", false)
end)

-- ==========================================
-- OPTIMALIZÁLT CÉLPONT KERESŐ (Csak a játékosokat nézi)
-- ==========================================
local function getNearestTarget(rootPart, aggroRange)
	local target = nil
	local shortestDistance = aggroRange

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			if char:FindFirstChildOfClass("ForceField") or char:GetAttribute("Invincible") then continue end

			local charRoot = char:FindFirstChild("HumanoidRootPart")
			if charRoot then
				local dist = (rootPart.Position - charRoot.Position).Magnitude
				if dist <= shortestDistance then
					shortestDistance = dist
					target = charRoot
				end
			end
		end
	end
	return target
end

-- ==========================================
-- FALKA RIASZTÓ FÜGGVÉNY (Lag-mentes, tábla alapú)
-- ==========================================
local function alertPack(packID, targetInstance)
	if not packID or not targetInstance then return end

	for npc, ai in pairs(activeMonsters) do
		if npc:GetAttribute("PackID") == packID and ai.State == "IDLE" then
			ai.Target = targetInstance
			ai.State = "CHASE"
		end
	end
end

-- ==========================================
-- SZÖRNY INICIALIZÁLÁSA (Amikor lespawnol)
-- ==========================================
local function setupMonster(npc)
	if not npc:IsA("Model") then return end
	local myData = MonsterDatabase[npc.Name]
	if not myData then return end

	local humanoid = npc:WaitForChild("Humanoid", 5)
	local rootPart = npc:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart then return end

	humanoid.BreakJointsOnDeath = false 
	humanoid.MaxHealth = myData.MaxHealth or 100
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = myData.WalkSpeed or 14 
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	for _, part in pairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then part.CollisionGroup = "Monsters" end
	end

	-- Eltároljuk a szörny memóriáját a központi agyban!
	activeMonsters[npc] = {
		Humanoid = humanoid,
		RootPart = rootPart,
		Data = myData,
		State = "IDLE",
		Target = nil,
		NextAggroCheck = 0,
		SpawnPos = npc:GetPivot().Position,
		NextRoamTime = tick() + math.random(1, 3),
		CanAttack = true,
		IsDead = false,

		RoamRadius = 25,
		AggroRange = math.min(myData.AggroRange or 20, 10),
		AttackRange = myData.AttackRange or 5,
		LeashDistance = 100,
		AttackDamage = myData.AttackDamage or 5,
		AttackCooldown = myData.AttackCooldown or 1.5,
	}

	-- SEBZÉS ÉRZÉKELÉSE (Aggro felvétele)
	humanoid.HealthChanged:Connect(function(currentHp)
		local ai = activeMonsters[npc]
		if not ai or ai.IsDead then return end

		if currentHp < humanoid.MaxHealth then
			if not ai.Target then
				local target = getNearestTarget(rootPart, 150) -- 150 studos láthatóság ha megütik!
				if target then
					ai.State = "CHASE"
					ai.Target = target
					alertPack(npc:GetAttribute("PackID"), target)
				end
			else
				alertPack(npc:GetAttribute("PackID"), ai.Target)
			end
		end
	end)

	-- HALÁL ESEMÉNY (Loot és XP osztás)
	humanoid.Died:Connect(function()
		local ai = activeMonsters[npc]
		if not ai or ai.IsDead then return end
		ai.IsDead = true
		activeMonsters[npc] = nil -- Leválasztjuk az AI ciklusról!

		humanoid.WalkSpeed = 0 
		if npc:GetAttribute("NoDrop") then
			Debris:AddItem(npc, 0.5)
			return
		end

		local deathPosition = rootPart.Position
		local killer = nil
		local shortestDist = 50

		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (deathPosition - plr.Character.HumanoidRootPart.Position).Magnitude
				if dist < shortestDist then shortestDist = dist; killer = plr end
			end
		end

		-- Loot és Pénz (Mint a régi kódodban, csak most centralizálva)
		local doubleDropActive, isDoubleGold = false, false
		if killer and killer:FindFirstChild("PlayerStats") then
			local dd = killer.PlayerStats:FindFirstChild("DoubleDrop")
			if dd and math.random(1, 100) <= dd.Value then doubleDropActive = true end
			local dg = killer.PlayerStats:FindFirstChild("DoubleGold")
			if dg and math.random(1, 100) <= dg.Value then isDoubleGold = true end
		end

		local dropsToSpawn = {}
		if myData.Drops then
			for _, dropInfo in ipairs(myData.Drops) do
				if math.random(1, 100) <= dropInfo.Chance then table.insert(dropsToSpawn, dropInfo.Item) end
			end
		end

		if doubleDropActive and #dropsToSpawn > 0 then
			local validForDouble = {}
			for _, itemName in ipairs(dropsToSpawn) do
				local itemData = ItemDatabase[itemName]
				if itemData and (itemData.Type == "Alapanyag" or itemData.Type == "Fogyóeszköz") then table.insert(validForDouble, itemName) end
			end
			if #validForDouble > 0 then table.insert(dropsToSpawn, validForDouble[math.random(1, #validForDouble)]) end
		end

		local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
		droppedFolder.Name = "DroppedItems"

		for _, itemName in ipairs(dropsToSpawn) do
			local itemData = ItemDatabase[itemName]
			local droppedItem = Instance.new("Part")
			droppedItem.Name = "LootPart"
			droppedItem.Size = Vector3.new(0.4, 0.4, 0.4) 

			local dropPos = deathPosition + Vector3.new(math.random(-3,3), 3, math.random(-3,3))

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {npc, droppedFolder, Players:GetPlayers()}

			local ray = workspace:Raycast(dropPos, Vector3.new(0, -50, 0), rayParams)
			droppedItem.Position = ray and (ray.Position + Vector3.new(0, 0.2, 0)) or dropPos

			droppedItem.Anchored = true; droppedItem.CanCollide = false
			local itemColor, textColor = Color3.fromRGB(200, 200, 200), Color3.new(1, 1, 1)

			if itemData then
				if itemData.Type == "Alapanyag" then textColor = Color3.fromRGB(100, 200, 255)
				elseif itemData.Type == "Fegyver" then textColor = Color3.fromRGB(220, 220, 220)
				elseif itemData.Type == "Páncél" then textColor = Color3.fromRGB(100, 255, 100)
				elseif itemData.Type == "Fogyóeszköz" then textColor = Color3.fromRGB(255, 100, 100) end
			end

			droppedItem.Color = itemColor
			Instance.new("StringValue", droppedItem).Name = "ItemName"
			droppedItem.ItemName.Value = itemName

			local killerName = killer and killer.Name or ""
			local ownerTag = Instance.new("StringValue", droppedItem)
			ownerTag.Name = "Owner"; ownerTag.Value = killerName

			local textBillboard = Instance.new("BillboardGui", droppedItem)
			textBillboard.Size = UDim2.new(0, 150, 0, 40)
			textBillboard.StudsOffset = Vector3.new(0, 1.2, 0)
			textBillboard.AlwaysOnTop = true; textBillboard.MaxDistance = 60 

			local dropNameLabel = Instance.new("TextLabel", textBillboard)
			dropNameLabel.Size = UDim2.new(1, 0, 1, 0)
			dropNameLabel.BackgroundTransparency = 1; dropNameLabel.RichText = true
			dropNameLabel.Font = Enum.Font.GothamBold; dropNameLabel.TextScaled = true; dropNameLabel.TextStrokeTransparency = 0

			local r, g, b = math.floor(textColor.R*255), math.floor(textColor.G*255), math.floor(textColor.B*255)
			local baseColorStr = "rgb("..r..","..g..","..b..")"

			if killerName ~= "" then
				dropNameLabel.Text = '<font color="rgb(255, 255, 50)">' .. itemName .. '</font>\n<font color="rgb(200, 200, 200)">&lt;' .. killerName .. '&gt;</font>'
				task.delay(120, function()
					if ownerTag and ownerTag.Parent then
						ownerTag.Value = ""
						if dropNameLabel then dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>' end
					end
				end)
			else
				dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>'
			end

			droppedItem.Parent = droppedFolder
			Debris:AddItem(droppedItem, 180)
		end

		if killer then
			local stats = killer:FindFirstChild("PlayerStats")
			if stats then
				if stats:FindFirstChild("Experience") then stats.Experience.Value += (myData.ExpReward or 0) end
				if stats:FindFirstChild("Gold") then
					local goldAmount = math.random(myData.GoldMin or 1, myData.GoldMax or 5)
					if isDoubleGold then goldAmount = goldAmount * 2; killer:SetAttribute("DoubleGoldTriggered", true) end
					stats.Gold.Value += goldAmount
				end
			end
			local questsFolder = killer:FindFirstChild("Quests")
			if questsFolder then
				for _, qVal in pairs(questsFolder:GetChildren()) do
					local qData = QuestDatabase[qVal.Name]
					if qData and qData.Type == "Kill" and (qData.Target == npc.Name or qData.Target == myData.Name) then
						qVal.Value += 1
					end
				end
			end
		end

		Debris:AddItem(npc, 1.5)
	end)
end

-- Eseményfigyelő a jövőben lespawnoló szörnyekhez
task.spawn(function()
	local workspaceMonsters = workspace:WaitForChild("Monsters", 999)
	for _, npc in pairs(workspaceMonsters:GetChildren()) do setupMonster(npc) end
	workspaceMonsters.ChildAdded:Connect(setupMonster)
end)

-- ==========================================
-- AZ EGYETLEN, KÖZPONTI AI CIKLUS (0 Lag!)
-- ==========================================
task.spawn(function()
	while true do
		task.wait(0.2) 

		for npc, ai in pairs(activeMonsters) do
			-- Ha valamiért eltűnt a pályáról, kivesszük a memóriából
			if not npc.Parent or not npc:IsDescendantOf(workspace) or ai.IsDead then
				activeMonsters[npc] = nil
				continue
			end

			local humanoid = ai.Humanoid
			local rootPart = ai.RootPart

			-- 1. ÁLLAPOT: SÉTÁLGATÁS / VÁRAKOZÁS
			-- 1. ÁLLAPOT: SÉTÁLGATÁS / VÁRAKOZÁS
			if ai.State == "IDLE" then
				-- JAVÍTÁS: Csak másodpercenként 1x pásztázzuk a játékosokat, nem 0.2 másodpercenként!
				if tick() >= (ai.NextAggroCheck or 0) then
					ai.Target = getNearestTarget(rootPart, ai.AggroRange)
					ai.NextAggroCheck = tick() + 1
				end

				if ai.Target then
					ai.State = "CHASE"
					alertPack(npc:GetAttribute("PackID"), ai.Target)
				else
					if tick() >= ai.NextRoamTime then
						local rx = ai.SpawnPos.X + (math.random() * ai.RoamRadius * 2) - ai.RoamRadius
						local rz = ai.SpawnPos.Z + (math.random() * ai.RoamRadius * 2) - ai.RoamRadius
						humanoid:MoveTo(Vector3.new(rx, ai.SpawnPos.Y, rz))
						ai.NextRoamTime = tick() + math.random(9, 12) 
					end
				end

				-- 2. ÁLLAPOT: ÜLDÖZÉS ÉS HARC
			elseif ai.State == "CHASE" then
				if not ai.Target or not ai.Target.Parent or ai.Target.Parent:FindFirstChild("Humanoid").Health <= 0 or ai.Target.Parent:FindFirstChildOfClass("ForceField") or ai.Target.Parent:GetAttribute("Invincible") then
					ai.Target = getNearestTarget(rootPart, ai.AggroRange)
					if not ai.Target then
						ai.State = "RETURN"
					else
						alertPack(npc:GetAttribute("PackID"), ai.Target)
					end
				else
					local distToTarget = (rootPart.Position - ai.Target.Position).Magnitude
					local distToSpawn = (rootPart.Position - ai.SpawnPos).Magnitude

					if distToSpawn > ai.LeashDistance or distToTarget > 50 then
						ai.State = "RETURN"
						ai.Target = nil
					else
						if distToTarget <= ai.AttackRange then
							humanoid:MoveTo(rootPart.Position) -- Megáll

							-- Támadás kiosztása
							if ai.CanAttack then
								ai.CanAttack = false
								local targetHum = ai.Target.Parent:FindFirstChild("Humanoid")
								if targetHum and targetHum.Health > 0 then
									local player = Players:GetPlayerFromCharacter(ai.Target.Parent)
									local defense = player and player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("Defense") and player.PlayerStats.Defense.Value or 0
									local dodgeChance = player and player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("DodgeChance") and player.PlayerStats.DodgeChance.Value or 0

									if math.random(1, 100) <= dodgeChance then
										ShowDamage:FireAllClients(0, ai.Target.Position, false, true) 
									else
										local finalDamage = math.max(1, ai.AttackDamage - defense)
										targetHum:TakeDamage(finalDamage)
									end
								end
								task.delay(ai.AttackCooldown, function()
									if activeMonsters[npc] then activeMonsters[npc].CanAttack = true end
								end)
							end
						else
							humanoid:MoveTo(ai.Target.Position)
						end
					end
				end

				-- 3. ÁLLAPOT: HAZATÉRÉS
			elseif ai.State == "RETURN" then
				ai.Target = getNearestTarget(rootPart, ai.AggroRange)
				if ai.Target then
					ai.State = "CHASE"
					alertPack(npc:GetAttribute("PackID"), ai.Target)
				else
					humanoid:MoveTo(ai.SpawnPos)
					humanoid.Health = humanoid.MaxHealth 
					local distToSpawn = Vector3.new(rootPart.Position.X - ai.SpawnPos.X, 0, rootPart.Position.Z - ai.SpawnPos.Z).Magnitude
					if distToSpawn < 5 then
						ai.State = "IDLE"
						ai.NextRoamTime = tick() + math.random(4, 6)
					end
				end
			end
		end
	end
end)