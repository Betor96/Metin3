-- Fájl helye: ReplicatedStorage -> (A szörny modellje) -> MonsterAI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService") 
local Debris = game:GetService("Debris") -- ÚJ: Debris Service a memóriaszivárgás ellen!

local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

local myData = MonsterDatabase[npc.Name]
if not myData then return end 

humanoid.BreakJointsOnDeath = false 
humanoid.MaxHealth = myData.MaxHealth or 100
humanoid.Health = humanoid.MaxHealth
humanoid.WalkSpeed = myData.WalkSpeed or 14 

humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

pcall(function()
	PhysicsService:RegisterCollisionGroup("Monsters")
	PhysicsService:CollisionGroupSetCollidable("Monsters", "Monsters", false)
end)

for _, part in pairs(npc:GetDescendants()) do
	if part:IsA("BasePart") then part.CollisionGroup = "Monsters" end
end

local canAttack = true
local isDead = false

local spawnPosition = npc:GetPivot().Position 
local roamRadius = 25        
local dbAggro = myData.AggroRange or 20
local aggroRange = math.min(dbAggro, 10)  
local attackRange = myData.AttackRange or 5 
local leashDistance = 100   

local currentState = "IDLE" 
local currentTarget = nil
local nextRoamTime = tick() + math.random(1, 3)

-- ==========================================
-- ESEMÉNY TAKARÍTÓ RENDSZER (Garbage Collection)
-- ==========================================
local activeConnections = {}

local function cleanupConnections()
	for _, conn in pairs(activeConnections) do
		if conn then conn:Disconnect() end
	end
	table.clear(activeConnections)
end

local function getNearestTarget(overrideRange)
	local target = nil
	local shortestDistance = overrideRange or aggroRange

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

local function attack(target)
	if not target or not target.Parent then return end
	local playerChar = target.Parent
	if playerChar:FindFirstChildOfClass("ForceField") or playerChar:GetAttribute("Invincible") then return end

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
				if ShowDamage then ShowDamage:FireAllClients(0, target.Position, false, true) end
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

local function alertPack(targetInstance)
	local packID = npc:GetAttribute("PackID")
	if not packID then return end

	for _, otherNpc in pairs(workspace.Monsters:GetChildren()) do
		if otherNpc ~= npc and otherNpc:GetAttribute("PackID") == packID then
			local shared = otherNpc:FindFirstChild("SharedTarget")
			if not shared then
				shared = Instance.new("ObjectValue")
				shared.Name = "SharedTarget"
				shared.Parent = otherNpc
			end
			shared.Value = targetInstance
			otherNpc:SetAttribute("Alerted", true)
		end
	end
end

local hpConn = humanoid.HealthChanged:Connect(function(currentHp)
	if currentHp < humanoid.MaxHealth and not isDead then
		if not currentTarget then
			local target = getNearestTarget(150)
			if target then
				currentState = "CHASE"
				currentTarget = target
				alertPack(target)
			end
		else
			alertPack(currentTarget)
		end
	end
end)
table.insert(activeConnections, hpConn)

-- ==========================================
-- AI CIKLUS (Biztonsági kilépéssel)
-- ==========================================
task.spawn(function()
	-- JAVÍTÁS: Ha az NPC-t eltávolítják (npc.Parent == nil), a ciklus AZONNAL leáll!
	while npc and npc.Parent and humanoid and humanoid.Health > 0 and not isDead do

		if currentState == "IDLE" then
			local sharedTarget = npc:FindFirstChild("SharedTarget")

			if npc:GetAttribute("Alerted") and sharedTarget and sharedTarget.Value then
				npc:SetAttribute("Alerted", false)
				currentTarget = sharedTarget.Value
				currentState = "CHASE"
				sharedTarget.Value = nil
			else
				currentTarget = getNearestTarget()
				if currentTarget then
					currentState = "CHASE"
					alertPack(currentTarget)
				else
					if tick() >= nextRoamTime then
						local rx = spawnPosition.X + (math.random() * roamRadius * 2) - roamRadius
						local rz = spawnPosition.Z + (math.random() * roamRadius * 2) - roamRadius
						humanoid:MoveTo(Vector3.new(rx, spawnPosition.Y, rz))
						nextRoamTime = tick() + math.random(9, 12) 
					end
				end
			end

		elseif currentState == "CHASE" then
			if not currentTarget or not currentTarget.Parent or currentTarget.Parent:FindFirstChild("Humanoid").Health <= 0 then
				local newTarget = getNearestTarget()
				if newTarget then
					currentTarget = newTarget
					alertPack(newTarget)
				else
					currentState = "RETURN"
					currentTarget = nil
				end
			else
				if currentTarget.Parent:FindFirstChildOfClass("ForceField") or currentTarget.Parent:GetAttribute("Invincible") then
					local newTarget = getNearestTarget()
					if newTarget then
						currentTarget = newTarget
						alertPack(newTarget)
					else
						currentState = "RETURN"
						currentTarget = nil
					end
					continue 
				end

				local distToTarget = (rootPart.Position - currentTarget.Position).Magnitude
				local distToSpawn = (rootPart.Position - spawnPosition).Magnitude

				if distToSpawn > leashDistance or distToTarget > 50 then
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

		elseif currentState == "RETURN" then
			local newTarget = getNearestTarget()
			if newTarget then
				currentTarget = newTarget
				currentState = "CHASE"
				alertPack(newTarget)
			else
				humanoid:MoveTo(spawnPosition)
				humanoid.Health = humanoid.MaxHealth 

				local distToSpawn = Vector3.new(rootPart.Position.X - spawnPosition.X, 0, rootPart.Position.Z - spawnPosition.Z).Magnitude
				if distToSpawn < 5 then
					currentState = "IDLE"
					nextRoamTime = tick() + math.random(4, 6)
				end
			end
		end
		task.wait(0.2) 
	end
end)

-- ==========================================
-- HALÁL ÉS LOOT (Memóriabarát)
-- ==========================================
local deathConn
deathConn = humanoid.Died:Connect(function()
	if isDead then return end
	isDead = true

	cleanupConnections() -- Azonnal lekötünk minden rákötött eventet!
	humanoid.WalkSpeed = 0 

	if npc:GetAttribute("NoDrop") then
		Debris:AddItem(npc, 0.5)
		return
	end

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
			table.insert(dropsToSpawn, validForDouble[math.random(1, #validForDouble)]) 
		end
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
		if ray then
			droppedItem.Position = ray.Position + Vector3.new(0, 0.2, 0)
		else
			droppedItem.Position = dropPos
		end

		droppedItem.Anchored = true
		droppedItem.CanCollide = false

		local itemColor = Color3.fromRGB(200, 200, 200)
		local textColor = Color3.new(1, 1, 1)

		if itemData then
			if itemData.Type == "Alapanyag" then textColor = Color3.fromRGB(100, 200, 255)
			elseif itemData.Type == "Fegyver" then textColor = Color3.fromRGB(220, 220, 220)
			elseif itemData.Type == "Páncél" then textColor = Color3.fromRGB(100, 255, 100)
			elseif itemData.Type == "Fogyóeszköz" then textColor = Color3.fromRGB(255, 100, 100) end
		end

		droppedItem.Color = itemColor

		local itemTag = Instance.new("StringValue", droppedItem)
		itemTag.Name = "ItemName"
		itemTag.Value = itemName

		local killerName = killer and killer.Name or ""
		local ownerTag = Instance.new("StringValue", droppedItem)
		ownerTag.Name = "Owner"
		ownerTag.Value = killerName

		local textBillboard = Instance.new("BillboardGui")
		textBillboard.Size = UDim2.new(0, 150, 0, 40)
		textBillboard.StudsOffset = Vector3.new(0, 1.2, 0)
		textBillboard.AlwaysOnTop = true
		textBillboard.MaxDistance = 60 
		textBillboard.Adornee = droppedItem
		textBillboard.Parent = droppedItem

		local dropNameLabel = Instance.new("TextLabel", textBillboard)
		dropNameLabel.Size = UDim2.new(1, 0, 1, 0)
		dropNameLabel.BackgroundTransparency = 1
		dropNameLabel.RichText = true
		dropNameLabel.Font = Enum.Font.GothamBold
		dropNameLabel.TextScaled = true
		dropNameLabel.TextStrokeTransparency = 0

		local r, g, b = math.floor(textColor.R*255), math.floor(textColor.G*255), math.floor(textColor.B*255)
		local baseColorStr = "rgb("..r..","..g..","..b..")"

		if killerName ~= "" then
			dropNameLabel.Text = '<font color="rgb(255, 255, 50)">' .. itemName .. '</font>\n<font color="rgb(200, 200, 200)">&lt;' .. killerName .. '&gt;</font>'

			-- Tulajdonos tag eltávolítása C++ időzítővel
			task.delay(120, function()
				if ownerTag and ownerTag.Parent then
					ownerTag.Value = ""
					if dropNameLabel then
						dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>'
					end
				end
			end)
		else
			dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>'
		end

		droppedItem.Parent = droppedFolder

		-- JAVÍTÁS: Debris service automatikus, lag-mentes törléshez! (3 perc után eltűnik)
		Debris:AddItem(droppedItem, 180)
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

	Debris:AddItem(npc, 1.5)
end)
table.insert(activeConnections, deathConn)