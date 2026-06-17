-- Fájl helye: ReplicatedStorage -> (A szörny modellje, pl. Vadfarkas) -> MonsterAI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService") -- ÚJ: Fizikai motor betöltése
local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

local myData = MonsterDatabase[npc.Name]
if not myData then 
	warn("HIBA: A szörny nincs benne a MonsterDatabase-ben: " .. npc.Name)
	return 
end 

humanoid.BreakJointsOnDeath = false 
humanoid.MaxHealth = myData.MaxHealth or 100
humanoid.Health = humanoid.MaxHealth
humanoid.WalkSpeed = myData.WalkSpeed or 14 

-- ==========================================
-- ÚJ: EGYMÁSRA MÁSZÁS ELLENI VÉDELEM
-- ==========================================
-- 1. Kikapcsoljuk az ugrást és a falmászást
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

-- 2. "Szellem mód": A szörnyek ne ütközzenek egymással!
pcall(function()
	PhysicsService:RegisterCollisionGroup("Monsters")
	PhysicsService:CollisionGroupSetCollidable("Monsters", "Monsters", false)
end)

for _, part in pairs(npc:GetDescendants()) do
	if part:IsA("BasePart") then
		part.CollisionGroup = "Monsters"
	end
end
-- ==========================================

local canAttack = true
local isDead = false

local spawnPosition = npc:GetPivot().Position 
local roamRadius = 25       

-- JAVÍTÁS: Maximalizáljuk az észlelést 20 stud-ra (az adatbázisban lévő 40-50 túl nagy volt!)
local dbAggro = myData.AggroRange or 20
local aggroRange = math.min(dbAggro, 20)  

local attackRange = myData.AttackRange or 5 
local leashDistance = 100   

local currentState = "IDLE" 
local currentTarget = nil
local nextRoamTime = tick() + math.random(1, 3)

local function getNearestTarget()
	local target = nil
	local shortestDistance = aggroRange

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
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

local function attack(target)
	if canAttack and not isDead then
		canAttack = false
		local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
		if targetHumanoid and targetHumanoid.Health > 0 then
			local player = Players:GetPlayerFromCharacter(target.Parent)
			local defense = 0
			local dodgeChance = 0

			if player and player:FindFirstChild("PlayerStats") then
				defense = player.PlayerStats:FindFirstChild("Defense") and player.PlayerStats.Defense.Value or 0
				dodgeChance = player.PlayerStats:FindFirstChild("DodgeChance") and player.PlayerStats.DodgeChance.Value or 0
			end

			if math.random(1, 100) <= dodgeChance then
				local ShowDamage = ReplicatedStorage.Events:FindFirstChild("ShowDamage")
				if ShowDamage then
					ShowDamage:FireAllClients(0, target.Position, false, true) 
				end
			else
				local attackDamage = myData.AttackDamage or 5
				local finalDamage = math.max(1, attackDamage - defense)
				targetHumanoid:TakeDamage(finalDamage)
			end
		end
		task.wait(myData.AttackCooldown or 1.5)
		canAttack = true
	end
end

-- ==========================================
-- A MESTERSÉGES INTELLIGENCIA CIKLUSA
-- ==========================================
task.spawn(function()
	while humanoid.Health > 0 and not isDead do

		-- 1. ÁLLAPOT: SÉTÁLGATÁS / VÁRAKOZÁS
		if currentState == "IDLE" then
			currentTarget = getNearestTarget()
			if currentTarget then
				currentState = "CHASE"
			else
				-- JAVÍTÁS: Ha az idő letelt, elsétál...
				if tick() >= nextRoamTime then
					local rx = spawnPosition.X + (math.random() * roamRadius * 2) - roamRadius
					local rz = spawnPosition.Z + (math.random() * roamRadius * 2) - roamRadius
					humanoid:MoveTo(Vector3.new(rx, spawnPosition.Y, rz))

					-- ÚJ IDŐZÍTÉS: A séta hossza + garantált 6-8 másodperc egy helyben állás!
					nextRoamTime = tick() + math.random(9, 12) 
				end
			end

			-- 2. ÁLLAPOT: ÜLDÖZÉS ÉS HARC
		elseif currentState == "CHASE" then
			if not currentTarget or not currentTarget.Parent or currentTarget.Parent:FindFirstChild("Humanoid").Health <= 0 then
				currentState = "RETURN"
				currentTarget = nil
			else
				local distToTarget = (rootPart.Position - currentTarget.Position).Magnitude
				local distToSpawn = (rootPart.Position - spawnPosition).Magnitude

				if distToSpawn > leashDistance or distToTarget > (aggroRange * 1.5) then
					currentState = "RETURN"
					currentTarget = nil
				else
					if distToTarget <= attackRange then
						humanoid:MoveTo(rootPart.Position) 
						attack(currentTarget)
					else
						humanoid:MoveTo(currentTarget.Position)
					end
				end
			end

			-- 3. ÁLLAPOT: HAZATÉRÉS
		elseif currentState == "RETURN" then
			humanoid:MoveTo(spawnPosition)
			humanoid.Health = humanoid.MaxHealth 

			local distToSpawn = (rootPart.Position - spawnPosition).Magnitude
			if distToSpawn < 3 then
				currentState = "IDLE"
				-- Hazatérés után is pihen 5 másodpercet
				nextRoamTime = tick() + math.random(4, 6)
			end
		end

		task.wait(0.2) 
	end
end)

-- ==========================================
-- HALÁL ESEMÉNY (Loot, EXP, Küldetés)
-- ==========================================
humanoid.Died:Connect(function()
	if isDead then return end
	isDead = true

	humanoid.WalkSpeed = 0 
	local deathPosition = npc:GetPivot().Position

	local killer = nil
	local shortestDist = 50
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (deathPosition - plr.Character.HumanoidRootPart.Position).Magnitude
			if dist < shortestDist then 
				shortestDist = dist 
				killer = plr 
			end
		end
	end

	local doubleDropActive = false
	local isDoubleGold = false

	if killer and killer:FindFirstChild("PlayerStats") then
		local dd = killer.PlayerStats:FindFirstChild("DoubleDrop")
		if dd and math.random(1, 100) <= dd.Value then doubleDropActive = true end

		local dg = killer.PlayerStats:FindFirstChild("DoubleGold")
		if dg and math.random(1, 100) <= dg.Value then isDoubleGold = true end
	end

	local dropsToSpawn = {}
	if myData.Drops then
		for _, dropInfo in ipairs(myData.Drops) do
			if math.random(1, 100) <= dropInfo.Chance then
				table.insert(dropsToSpawn, dropInfo.Item)
			end
		end
	end

	if doubleDropActive and #dropsToSpawn > 0 then
		local validForDouble = {}
		for _, itemName in ipairs(dropsToSpawn) do
			local itemData = ItemDatabase[itemName]
			if itemData and (itemData.Type == "Alapanyag" or itemData.Type == "Fogyóeszköz") then
				table.insert(validForDouble, itemName)
			end
		end
		if #validForDouble > 0 then
			local randomItemToDouble = validForDouble[math.random(1, #validForDouble)]
			table.insert(dropsToSpawn, randomItemToDouble) 
		end
	end

	local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
	droppedFolder.Name = "DroppedItems"

	for _, itemName in ipairs(dropsToSpawn) do
		local itemData = ItemDatabase[itemName]
		local droppedItem = Instance.new("Part")
		droppedItem.Name = "LootPart"
		droppedItem.Size = Vector3.new(0.4, 0.4, 0.4) 
		droppedItem.Position = deathPosition + Vector3.new(math.random(-3,3), 2, math.random(-3,3))

		local itemColor = Color3.fromRGB(200, 200, 200)
		local textColor = Color3.new(1, 1, 1)

		if itemData then
			if itemData.Type == "Alapanyag" then textColor = Color3.fromRGB(100, 200, 255)
			elseif itemData.Type == "Fegyver" then textColor = Color3.fromRGB(220, 220, 220)
			elseif itemData.Type == "Páncél" then textColor = Color3.fromRGB(100, 255, 100)
			elseif itemData.Type == "Fogyóeszköz" then textColor = Color3.fromRGB(255, 100, 100) end
		end

		droppedItem.Color = itemColor

		local itemTag = Instance.new("StringValue")
		itemTag.Name = "ItemName"
		itemTag.Value = itemName
		itemTag.Parent = droppedItem

		local textBillboard = Instance.new("BillboardGui")
		textBillboard.Size = UDim2.new(0, 120, 0, 25)
		textBillboard.StudsOffset = Vector3.new(0, 1.2, 0)
		textBillboard.AlwaysOnTop = true
		textBillboard.Adornee = droppedItem

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = itemName
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextColor3 = textColor
		nameLabel.Parent = textBillboard

		textBillboard.Parent = droppedItem
		droppedItem.Parent = droppedFolder
	end

	if killer then
		local stats = killer:FindFirstChild("PlayerStats")
		if stats then
			if stats:FindFirstChild("Experience") then stats.Experience.Value += (myData.ExpReward or 0) end
			if stats:FindFirstChild("Gold") then
				local goldAmount = math.random(myData.GoldMin or 1, myData.GoldMax or 5)
				if isDoubleGold then
					goldAmount = goldAmount * 2
					killer:SetAttribute("DoubleGoldTriggered", true) 
				end
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

	task.wait(1.5)
	npc:Destroy()
end)