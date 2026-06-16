local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase")) 

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

local myData = MonsterDatabase[npc.Name]
if not myData then return end 

local canAttack = true

humanoid.MaxHealth = myData.MaxHealth
humanoid.Health = myData.MaxHealth
humanoid.WalkSpeed = myData.WalkSpeed 

local function getNearestTarget()
	local target = nil
	local shortestDistance = myData.AggroRange

	for _, player in pairs(game.Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local charRoot = char:FindFirstChild("HumanoidRootPart")
			if charRoot then
				local dist = (rootPart.Position - charRoot.Position).Magnitude
				if dist < shortestDistance then
					shortestDistance = dist
					target = charRoot
				end
			end
		end
	end
	return target
end

local function attack(target)
	if canAttack then
		canAttack = false
		local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
		if targetHumanoid then
			local player = game.Players:GetPlayerFromCharacter(target.Parent)
			local defense = 0
			local dodgeChance = 0

			-- Statok bekérése a játékostól
			if player and player:FindFirstChild("PlayerStats") then
				defense = player.PlayerStats:FindFirstChild("Defense") and player.PlayerStats.Defense.Value or 0
				dodgeChance = player.PlayerStats:FindFirstChild("DodgeChance") and player.PlayerStats.DodgeChance.Value or 0
			end

			-- 1. KITÉRÉS (Dodge)
			if math.random(1, 100) <= dodgeChance then
				local ShowDamage = ReplicatedStorage.Events:FindFirstChild("ShowDamage")
				if ShowDamage then
					ShowDamage:FireAllClients(0, target.Position, false, true) -- A 4. paraméter a "Mellé!" (Miss)
				end
			else
				-- 2. PÁNCÉLZAT (Defense) csökkenti a bekapott sebzést
				local finalDamage = math.max(1, myData.AttackDamage - defense)
				targetHumanoid:TakeDamage(finalDamage)
			end
		end
		task.wait(myData.AttackCooldown)
		canAttack = true
	end
end

task.spawn(function()
	while humanoid.Health > 0 do
		local target = getNearestTarget()
		if target then
			local dist = (rootPart.Position - target.Position).Magnitude
			if dist <= myData.AttackRange then
				humanoid:MoveTo(rootPart.Position) 
				attack(target)
			else
				humanoid:MoveTo(target.Position) 
			end
		end
		task.wait(0.1) 
	end
end)

humanoid.Died:Connect(function()
	local deathPosition = rootPart.Position

	-- 1. GYILKOS MEGVÁLASZTÁSA ELŐRE (Hogy beolvashassuk a bónuszait a Lootolás előtt)
	local killer = nil
	local shortestDist = 50
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (deathPosition - player.Character.HumanoidRootPart.Position).Magnitude
			if dist < shortestDist then shortestDist = dist killer = player end
		end
	end

	-- 2. BÓNUSZOK LEKÉRÉSE A JÁTÉKOSTÓL
	local dropMultiplier = 1
	local isDoubleGold = false

	if killer and killer:FindFirstChild("PlayerStats") then
		local dd = killer.PlayerStats:FindFirstChild("DoubleDrop")
		if dd and math.random(1, 100) <= dd.Value then
			dropMultiplier = 2 -- Dupla tárgy aktiválva!
		end

		local dg = killer.PlayerStats:FindFirstChild("DoubleGold")
		if dg and math.random(1, 100) <= dg.Value then
			isDoubleGold = true -- Dupla pénz aktiválva!
		end
	end

	-- 3. LOOT DOBÁSA AZ ADATBÁZIS ALAPJÁN
	if myData.Drops then
		for _, dropInfo in ipairs(myData.Drops) do
			if math.random(1, 100) <= dropInfo.Chance then

				-- HA DUPLA A DROP, A CIKLUS KÉTSZER FUT LE!
				for i = 1, dropMultiplier do
					local itemName = dropInfo.Item
					local itemData = ItemDatabase[itemName]

					local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
					droppedFolder.Name = "DroppedItems"

					local droppedItem = Instance.new("Part")
					droppedItem.Name = "LootPart"
					droppedItem.Size = Vector3.new(0.4, 0.4, 0.4) 
					-- Kicsit véletlenszerűbb helyre esik, hogy ne teljesen egymáson legyenek a dupla droppok
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
			end
		end
	end

	-- 4. JUTALMAZÁS ÉS KÜLDETÉS
	if killer then
		local stats = killer:FindFirstChild("PlayerStats")
		if stats then
			if stats:FindFirstChild("Experience") then stats.Experience.Value += myData.ExpReward end
			if stats:FindFirstChild("Gold") then
				local goldAmount = math.random(myData.GoldMin, myData.GoldMax)

				-- Ha aktiválódott a Dupla Pénz
				if isDoubleGold then
					goldAmount = goldAmount * 2
					killer:SetAttribute("DoubleGoldTriggered", true) -- Jelezzük a Kliens UI-nak
				end

				stats.Gold.Value += goldAmount
			end
		end

		local quests = killer:FindFirstChild("Quests")
		if quests then
			for _, qVal in pairs(quests:GetChildren()) do
				local qDataActual = QuestDatabase[qVal.Name]
				if qDataActual and qDataActual.Type == "Kill" and qDataActual.Target == npc.Name then
					if qVal.Value >= 0 and qVal.Value < qDataActual.Count then
						qVal.Value = qVal.Value + 1
					end
				end
			end
		end
	end

	npc:Destroy()
end)