local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase")) -- ÚJ: Bekötjük a küldetés adatbázist is!

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

-- 1. ADATOK LEKÉRÉSE A NEVE ALAPJÁN
local myData = MonsterDatabase[npc.Name]
if not myData then return end -- Ha nincs az adatbázisban, ne is fusson

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
			targetHumanoid:TakeDamage(myData.AttackDamage)
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

	-- 2. LOOT DOBÁSA AZ ADATBÁZIS ALAPJÁN
	if myData.Drops then
		for _, dropInfo in ipairs(myData.Drops) do
			if math.random(1, 100) <= dropInfo.Chance then
				local itemName = dropInfo.Item
				local itemData = ItemDatabase[itemName]

				local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
				droppedFolder.Name = "DroppedItems"

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.4, 0.4, 0.4) 
				droppedItem.Position = deathPosition + Vector3.new(math.random(-2,2), 2, math.random(-2,2))

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

	-- 3. JUTALMAZÁS ÉS KÜLDETÉS
	local killer = nil
	local shortestDist = 50

	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (deathPosition - player.Character.HumanoidRootPart.Position).Magnitude
			if dist < shortestDist then shortestDist = dist killer = player end
		end
	end

	if killer then
		local stats = killer:FindFirstChild("PlayerStats")
		if stats then
			if stats:FindFirstChild("Experience") then stats.Experience.Value += myData.ExpReward end
			if stats:FindFirstChild("Gold") then
				local goldAmount = math.random(myData.GoldMin, myData.GoldMax)
				stats.Gold.Value += goldAmount
				local Events = ReplicatedStorage:FindFirstChild("Events")
				if Events and Events:FindFirstChild("ShowGold") then Events.ShowGold:FireClient(killer, goldAmount) end
			end
		end

		-- ==========================================
		-- ÚJ, UNIVERZÁLIS KÜLDETÉS SZÁMLÁLÓ FIGYELŐ
		-- ==========================================
		local quests = killer:FindFirstChild("Quests")
		if quests then
			-- Végigmegyünk az összes létező küldetésen
			for _, qVal in pairs(quests:GetChildren()) do
				local qDataActual = QuestDatabase[qVal.Name]

				-- Ha a küldetés célpontja megegyezik a szörny nevével és folyamatban van
				if qDataActual and qDataActual.Type == "Kill" and qDataActual.Target == npc.Name then
					if qVal.Value >= 0 and qVal.Value < qDataActual.Count then
						qVal.Value = qVal.Value + 1
					end
				end
			end
		end
		-- ==========================================
	end

	npc:Destroy()
end)