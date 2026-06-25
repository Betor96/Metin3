-- Fájl helye: ServerScriptService -> MetinStoneLogic

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local droppedFolder = Workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", Workspace)
droppedFolder.Name = "DroppedItems"
local metinFolder = Workspace:FindFirstChild("MetinStones") or Instance.new("Folder", Workspace)
metinFolder.Name = "MetinStones"
local monstersFolder = Workspace:FindFirstChild("Monsters") or Instance.new("Folder", Workspace)
monstersFolder.Name = "Monsters"

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

	local stoneID = HttpService:GenerateGUID(false)

	rootPart.Anchored = true
	humanoid.MaxHealth = myData.MaxHealth or 100
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 0 

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StoneHPBar"
	billboard.Size = UDim2.new(0, 150, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 8, 0) 
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120 
	billboard.Parent = rootPart

	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = stone.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true

	local bgFrame = Instance.new("Frame", billboard)
	bgFrame.Size = UDim2.new(1, 0, 0, 20)
	bgFrame.Position = UDim2.new(0, 0, 0, 25) 
	bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

	local hpBar = Instance.new("Frame", bgFrame)
	hpBar.Size = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30) 
	hpBar.BorderSizePixel = 0

	local hpText = Instance.new("TextLabel", bgFrame)
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Text = humanoid.MaxHealth .. " / " .. humanoid.MaxHealth
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true

	local spawnRate = stone:GetAttribute("SpawnRate") or 5 
	local lastHitTime = 0
	local isActive = false 
	local isDead = false

	local lastHp = humanoid.MaxHealth

	local function spawnMonsters()
		if isDead then return end 
		if not monsterTemplate then return end

		local spawnCount = math.random(myData.SpawnCountMin or 1, myData.SpawnCountMax or 2)
		for i = 1, spawnCount do
			local newMonster = monsterTemplate:Clone()
			local spawnPosition = rootPart.CFrame * CFrame.new(math.random(-15, 15), 0, math.random(-15, 15))
			if newMonster:FindFirstChild("HumanoidRootPart") then
				newMonster.HumanoidRootPart.CFrame = spawnPosition
			end

			newMonster:SetAttribute("StoneID", stoneID)
			newMonster.Parent = monstersFolder 
		end
	end

	local function onStoneDestroyed()
		if isDead then return end
		isDead = true
		isActive = false
		billboard:Destroy()

		for _, monster in pairs(monstersFolder:GetChildren()) do
			if monster:GetAttribute("StoneID") == stoneID then
				monster:SetAttribute("NoDrop", true)
				local mHum = monster:FindFirstChild("Humanoid")
				if mHum then mHum.Health = 0 end
			end
		end

		-- ==========================================
		-- JAVÍTÁS: Támadók biztonságos kiolvasása a mappából! (AFK Leech védelem)
		-- ==========================================
		local attackers = {}
		local attFolder = stone:FindFirstChild("Attackers")
		if attFolder then
			for _, tag in pairs(attFolder:GetChildren()) do
				if tag.Value and tag.Value.Parent then table.insert(attackers, tag.Value) end
			end
		end

		-- Biztonsági ellenőrzés: ha valamiért üres lenne a lista, betesszük a legközelebbi játékost
		if #attackers == 0 then
			local shortestDist = 50
			local nearest = nil
			for _, plr in pairs(Players:GetPlayers()) do
				if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local dist = (rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
					if dist < shortestDist then 
						shortestDist = dist 
						nearest = plr 
					end
				end
			end
			if nearest then table.insert(attackers, nearest) end
		end

		local dropCount = math.random(myData.MinDrops or 1, myData.MaxDrops or 2) 
		local dropsToSpawn = {}

		if myData.LootPool and #myData.LootPool > 0 then
			for i = 1, dropCount do
				table.insert(dropsToSpawn, myData.LootPool[math.random(1, #myData.LootPool)])
			end
		end

		-- Dupla drop esély (ha BÁRMELYIK támadónak van bónusza, érvényesül!)
		local doubleDropActive = false
		for _, plr in ipairs(attackers) do
			if plr:FindFirstChild("PlayerStats") then
				local dd = plr.PlayerStats:FindFirstChild("DoubleDrop")
				if dd and math.random(1, 100) <= dd.Value then doubleDropActive = true break end
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

		-- ==========================================
		-- LOOT SZÉTOSZTÁSA A TÁMADÓK KÖZÖTT
		-- ==========================================
		-- Megkeverjük a támadókat, hogy a maradékot (pl. 3 item 2 emberre) mindig random kapja valaki
		local shuffledAttackers = {}
		for _, v in ipairs(attackers) do table.insert(shuffledAttackers, v) end
		table.sort(shuffledAttackers, function() return math.random() > 0.5 end)

		local currentAttackerIndex = 1

		for _, itemName in ipairs(dropsToSpawn) do
			local itemData = ItemDatabase[itemName]
			local droppedItem = Instance.new("Part")
			droppedItem.Name = "LootPart"
			droppedItem.Size = Vector3.new(0.5, 0.2, 2)

			local dropPos = rootPart.Position + Vector3.new(math.random(-8, 8), 5, math.random(-8, 8))
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {stone, droppedFolder, monstersFolder, Players:GetPlayers()}

			local ray = workspace:Raycast(dropPos, Vector3.new(0, -50, 0), rayParams)
			if ray then
				droppedItem.Position = ray.Position + Vector3.new(0, 0.2, 0)
			else
				droppedItem.Position = dropPos
			end

			droppedItem.Anchored = true
			droppedItem.CanCollide = false

			local itemColor = Color3.fromRGB(150, 150, 150)
			local textColor = Color3.new(1, 1, 1)

			if itemData then
				if itemData.Type == "Fegyver" then textColor = Color3.fromRGB(220, 220, 220)
				elseif itemData.Type == "Páncél" then itemColor = Color3.fromRGB(80, 100, 80) textColor = Color3.fromRGB(100, 255, 100) end
			end

			droppedItem.Color = itemColor
			local itemTag = Instance.new("StringValue", droppedItem)
			itemTag.Name = "ItemName"
			itemTag.Value = itemName

			-- Kijelöljük az ehavi gazdát
			local luckyPlayer = shuffledAttackers[currentAttackerIndex]
			local killerName = luckyPlayer and luckyPlayer.Name or ""

			-- Lépünk a következő támadóra (Kártyaosztás)
			currentAttackerIndex += 1
			if currentAttackerIndex > #shuffledAttackers then currentAttackerIndex = 1 end

			local ownerTag = Instance.new("StringValue", droppedItem)
			ownerTag.Name = "Owner"
			ownerTag.Value = killerName

			local textBillboard = Instance.new("BillboardGui", droppedItem)
			textBillboard.Size = UDim2.new(0, 150, 0, 40)
			textBillboard.StudsOffset = Vector3.new(0, 1.5, 0) 
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
			else
				dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>'
			end

			droppedItem.Parent = droppedFolder

			task.spawn(function()
				task.wait(120) 
				if droppedItem and droppedItem.Parent then
					ownerTag.Value = ""
					dropNameLabel.Text = '<font color="' .. baseColorStr .. '">' .. itemName .. '</font>' 
				end

				task.wait(180) 
				if droppedItem and droppedItem.Parent then
					droppedItem:Destroy()
				end
			end)
		end

		-- EXP kiosztása MINDEN támadónak
		for _, plr in ipairs(attackers) do
			local stats = plr:FindFirstChild("PlayerStats")
			if stats and stats:FindFirstChild("Experience") then
				stats.Experience.Value += (myData.ExpReward or 0)
			end
		end

		task.wait(1)
		stone:Destroy()
	end

	humanoid.HealthChanged:Connect(function(currentHp)
		if isDead then return end

		-- JAVÍTÁS: TÖRÖLTÜK a távolság alapú AFK játékos keresést (Óriási Teljesítmény javítás)
		lastHp = currentHp

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
					if isDead then break end 
					spawnMonsters()
				end
				isActive = false 
			end)
		end
	end)
end

for _, child in pairs(metinFolder:GetChildren()) do
	if child:IsA("Model") then setupMetinStone(child) end
end

metinFolder.ChildAdded:Connect(function(child)
	task.wait(0.1)
	if child:IsA("Model") then setupMetinStone(child) end
end)