local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local stone = script.Parent
local humanoid = stone:WaitForChild("Humanoid")
local rootPart = stone:WaitForChild("HumanoidRootPart")

rootPart.Anchored = true

local myData = MonsterDatabase[stone.Name]
if not myData then return end

local monsterTemplate = ReplicatedStorage:WaitForChild(myData.SpawnMonster)

humanoid.MaxHealth = myData.MaxHealth
humanoid.Health = myData.MaxHealth
humanoid.WalkSpeed = 0 

local billboard = Instance.new("BillboardGui")
billboard.Name = "StoneHPBar"
billboard.Size = UDim2.new(0, 150, 0, 20)
billboard.StudsOffset = Vector3.new(0, 8, 0) 
billboard.AlwaysOnTop = true
billboard.Parent = rootPart

local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bgFrame.Parent = billboard

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30) 
hpBar.BorderSizePixel = 0
hpBar.Parent = bgFrame

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Text = myData.MaxHealth .. " / " .. myData.MaxHealth
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.Font = Enum.Font.GothamBold
hpText.TextScaled = true
hpText.Parent = bgFrame

local spawnRate = stone:GetAttribute("SpawnRate") or 3 
local lastHitTime = 0
local isActive = false 

local function spawnMonsters()
	local spawnCount = math.random(myData.SpawnCountMin, myData.SpawnCountMax)
	for i = 1, spawnCount do
		if monsterTemplate then
			local newMonster = monsterTemplate:Clone()
			local spawnPosition = rootPart.CFrame * CFrame.new(math.random(-15, 15), 0, math.random(-15, 15))
			newMonster.HumanoidRootPart.CFrame = spawnPosition
			newMonster.Parent = workspace
		end
	end
end

humanoid.HealthChanged:Connect(function(currentHp)
	if currentHp < 0 then currentHp = 0 end
	local percent = currentHp / myData.MaxHealth
	hpBar.Size = UDim2.new(percent, 0, 1, 0)
	hpText.Text = math.floor(currentHp) .. " / " .. myData.MaxHealth

	lastHitTime = tick() 

	if not isActive then
		isActive = true
		task.spawn(function()
			while stone and stone.Parent and (tick() - lastHitTime < 5) do
				task.wait(spawnRate)
				spawnMonsters()
			end
			isActive = false 
		end)
	end
end)

humanoid.Died:Connect(function()
	billboard:Destroy()

	local killer = nil
	local shortestDist = 50

	for _, plr in pairs(game.Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
			if dist < shortestDist then shortestDist = dist killer = plr end
		end
	end

	local doubleDropActive = false
	if killer and killer:FindFirstChild("PlayerStats") then
		local dd = killer.PlayerStats:FindFirstChild("DoubleDrop")
		if dd and math.random(1, 100) <= dd.Value then doubleDropActive = true end
	end

	-- 1. NORMÁL DROPOK KIGYŰJTÉSE
	local dropCount = math.random(myData.MinDrops, myData.MaxDrops) 
	local dropsToSpawn = {}

	for i = 1, dropCount do
		local itemName = myData.LootPool[math.random(1, #myData.LootPool)]
		table.insert(dropsToSpawn, itemName)
	end

	-- 2. DUPLA DROP LOGIKA (Csak 1 db plusz, és csak alapanyag/poti)
	if doubleDropActive and #dropsToSpawn > 0 then
		local validForDouble = {}
		for _, itemName in ipairs(dropsToSpawn) do
			local itemData = ItemDatabase[itemName]
			-- Fegyver/Páncél tilos!
			if itemData and (itemData.Type == "Alapanyag" or itemData.Type == "Fogyóeszköz") then
				table.insert(validForDouble, itemName)
			end
		end

		if #validForDouble > 0 then
			local randomItemToDouble = validForDouble[math.random(1, #validForDouble)]
			table.insert(dropsToSpawn, randomItemToDouble) 
		end
	end

	-- 3. TÁRGYAK LEDOBÁSA A FÖLDRE
	local droppedFolder = workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", workspace)
	droppedFolder.Name = "DroppedItems"

	for _, itemName in ipairs(dropsToSpawn) do
		local itemData = ItemDatabase[itemName]

		local droppedItem = Instance.new("Part")
		droppedItem.Name = "LootPart"
		droppedItem.Size = Vector3.new(0.5, 0.2, 2)
		droppedItem.Position = rootPart.Position + Vector3.new(math.random(-8, 8), 5, math.random(-8, 8))

		local itemColor = Color3.fromRGB(150, 150, 150)
		local textColor = Color3.new(1, 1, 1)

		if itemData then
			if itemData.Type == "Fegyver" then textColor = Color3.fromRGB(220, 220, 220)
			elseif itemData.Type == "Páncél" then itemColor = Color3.fromRGB(80, 100, 80) textColor = Color3.fromRGB(100, 255, 100) end
		end

		droppedItem.Color = itemColor

		local itemTag = Instance.new("StringValue")
		itemTag.Name = "ItemName"
		itemTag.Value = itemName
		itemTag.Parent = droppedItem

		local textBillboard = Instance.new("BillboardGui")
		textBillboard.Size = UDim2.new(0, 150, 0, 25)
		textBillboard.StudsOffset = Vector3.new(0, 1.5, 0) 
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

	-- 4. JUTALMAZÁS
	if killer then
		local stats = killer:FindFirstChild("PlayerStats")
		if stats and stats:FindFirstChild("Experience") then
			stats.Experience.Value += myData.ExpReward
		end
	end

	task.wait(1)
	stone:Destroy()
end)