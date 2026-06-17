-- Fájl helye: ServerScriptService -> MetinStoneLogic

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService") -- ÚJ: ID Generátor a kőnek

local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- ==========================================
-- MAPPÁK BEÁLLÍTÁSA (JAVÍTVA)
-- ==========================================
local droppedFolder = Workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", Workspace)
droppedFolder.Name = "DroppedItems"

local metinFolder = Workspace:FindFirstChild("MetinStones") or Instance.new("Folder", Workspace)
metinFolder.Name = "MetinStones"

-- JAVÍTÁS: Ez a mappa hiányzott, ezért fagyott le a script a 105. sorban!
local monstersFolder = Workspace:FindFirstChild("Monsters") or Instance.new("Folder", Workspace)
monstersFolder.Name = "Monsters"

-- ==========================================
-- KŐ ÉLETRE KELTÉSE
-- ==========================================
local function setupMetinStone(stone)
	local humanoid = stone:FindFirstChild("Humanoid")
	local rootPart = stone:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	local myData = MonsterDatabase[stone.Name]
	if not myData then return end

	local monsterTemplate = nil
	if myData.SpawnMonster then
		monsterTemplate = ReplicatedStorage:FindFirstChild(myData.SpawnMonster)
	end

	local stoneID = HttpService:GenerateGUID(false) -- Egyedi ID a kőnek!

	rootPart.Anchored = true
	humanoid.MaxHealth = myData.MaxHealth or 100
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 0 

	-- UI Készítése
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
	hpText.Text = humanoid.MaxHealth .. " / " .. humanoid.MaxHealth
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true
	hpText.Parent = bgFrame

	local spawnRate = stone:GetAttribute("SpawnRate") or 5 
	local lastHitTime = 0
	local isActive = false 
	local isDead = false

	local function spawnMonsters()
		if not monsterTemplate then return end
		local spawnCount = math.random(myData.SpawnCountMin or 1, myData.SpawnCountMax or 2)
		for i = 1, spawnCount do
			local newMonster = monsterTemplate:Clone()
			local spawnPosition = rootPart.CFrame * CFrame.new(math.random(-15, 15), 0, math.random(-15, 15))
			if newMonster:FindFirstChild("HumanoidRootPart") then
				newMonster.HumanoidRootPart.CFrame = spawnPosition
			end

			-- ÚJ: Összekötjük a szörnyet a kővel, és betesszük a jó mappába!
			newMonster:SetAttribute("StoneID", stoneID)
			newMonster.Parent = monstersFolder 
		end
	end

	local function onStoneDestroyed()
		if isDead then return end
		isDead = true
		isActive = false
		billboard:Destroy()

		-- ==========================================
		-- ÚJ: MARADÉK SZÖRNYEK MEGÖLÉSE LOOT NÉLKÜL
		-- ==========================================
		for _, monster in pairs(monstersFolder:GetChildren()) do
			if monster:GetAttribute("StoneID") == stoneID then
				monster:SetAttribute("NoDrop", true) -- Szólunk az AI-nak, hogy ne droppoljon semmit
				local mHum = monster:FindFirstChild("Humanoid")
				if mHum then mHum.Health = 0 end
			end
		end

		local killer = nil
		local shortestDist = 50

		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
				if dist < shortestDist then 
					shortestDist = dist 
					killer = plr 
				end
			end
		end

		local doubleDropActive = false
		if killer and killer:FindFirstChild("PlayerStats") then
			local dd = killer.PlayerStats:FindFirstChild("DoubleDrop")
			if dd and math.random(1, 100) <= dd.Value then doubleDropActive = true end
		end

		local dropCount = math.random(myData.MinDrops or 1, myData.MaxDrops or 2) 
		local dropsToSpawn = {}

		if myData.LootPool and #myData.LootPool > 0 then
			for i = 1, dropCount do
				local itemName = myData.LootPool[math.random(1, #myData.LootPool)]
				table.insert(dropsToSpawn, itemName)
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

		if killer then
			local stats = killer:FindFirstChild("PlayerStats")
			if stats and stats:FindFirstChild("Experience") then
				stats.Experience.Value += (myData.ExpReward or 0)
			end
		end

		task.wait(1)
		stone:Destroy()
	end

	humanoid.HealthChanged:Connect(function(currentHp)
		if isDead then return end

		if currentHp <= 0 then
			hpBar.Size = UDim2.new(0, 0, 1, 0)
			hpText.Text = "0 / " .. humanoid.MaxHealth
			onStoneDestroyed()
			return
		end

		local percent = currentHp / humanoid.MaxHealth
		hpBar.Size = UDim2.new(percent, 0, 1, 0)
		hpText.Text = math.floor(currentHp) .. " / " .. humanoid.MaxHealth

		lastHitTime = tick() 
		if not isActive then
			isActive = true
			task.spawn(function()
				while stone and stone.Parent and not isDead and (tick() - lastHitTime < 5) do
					task.wait(spawnRate)
					spawnMonsters()
				end
				isActive = false 
			end)
		end
	end)
end

for _, child in pairs(metinFolder:GetChildren()) do
	if child:IsA("Model") then
		setupMetinStone(child)
	end
end

metinFolder.ChildAdded:Connect(function(child)
	task.wait(0.1)
	if child:IsA("Model") then
		setupMetinStone(child)
	end
end)