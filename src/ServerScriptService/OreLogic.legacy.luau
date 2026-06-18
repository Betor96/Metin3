-- Fájl helye: ServerScriptService -> OreLogic

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local droppedFolder = Workspace:FindFirstChild("DroppedItems") or Instance.new("Folder", Workspace)
droppedFolder.Name = "DroppedItems"

local oresFolder = Workspace:FindFirstChild("Ores") or Instance.new("Folder", Workspace)
oresFolder.Name = "Ores"

local function setupOre(ore)
	local humanoid = ore:FindFirstChild("Humanoid")
	local rootPart = ore:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local myData = MonsterDatabase[ore.Name]
	if not myData or myData.Type ~= "Ore" then return end

	rootPart.Anchored = true
	humanoid.MaxHealth = myData.MaxHealth or 10
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 0 

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OreHPBar"
	billboard.Size = UDim2.new(0, 100, 0, 35) 
	billboard.StudsOffset = Vector3.new(0, 4, 0) 
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = rootPart

	local nameText = Instance.new("TextLabel", billboard)
	nameText.Size = UDim2.new(1, 0, 0, 15)
	nameText.BackgroundTransparency = 1
	nameText.Text = ore.Name
	nameText.TextColor3 = Color3.fromRGB(150, 255, 150)
	nameText.Font = Enum.Font.GothamBold
	nameText.TextScaled = true

	local bgFrame = Instance.new("Frame", billboard)
	bgFrame.Size = UDim2.new(1, 0, 0, 15)
	bgFrame.Position = UDim2.new(0, 0, 0, 20) 
	bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

	local hpBar = Instance.new("Frame", bgFrame)
	hpBar.Size = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3 = Color3.fromRGB(200, 180, 50)
	hpBar.BorderSizePixel = 0

	local hpText = Instance.new("TextLabel", bgFrame)
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Text = humanoid.MaxHealth .. " / " .. humanoid.MaxHealth
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true

	local isDead = false

	-- ÚJ: Támadók listája
	local attackers = {}
	local lastHp = humanoid.MaxHealth

	humanoid.HealthChanged:Connect(function(currentHp)
		if isDead then return end

		-- Támadók regisztrálása
		if currentHp < lastHp then
			for _, plr in pairs(Players:GetPlayers()) do
				if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local dist = (rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
					if dist <= 15 then 
						if not table.find(attackers, plr) then
							table.insert(attackers, plr)
						end
					end
				end
			end
		end
		lastHp = currentHp

		if currentHp <= 0 then
			isDead = true
			hpBar.Size = UDim2.new(0, 0, 1, 0)
			hpText.Text = "0 / " .. humanoid.MaxHealth
			billboard:Destroy()

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

			local dropCount = math.random(1, 2)

			-- Bármelyik támadónak van csákánya bónusszal? (Összeadjuk a legnagyobb esélyt)
			local bestDoubleChance = 0
			for _, plr in ipairs(attackers) do
				if plr:FindFirstChild("Equipment") then
					local wSlot = plr.Equipment:FindFirstChild("Fegyver")
					if wSlot and wSlot.Value ~= "" then
						local wData = ItemDatabase[wSlot.Value]
						if wData and wData.IsPickaxe and wData.DoubleOreChance then
							if wData.DoubleOreChance > bestDoubleChance then
								bestDoubleChance = wData.DoubleOreChance
							end
						end
					end
				end
			end

			if bestDoubleChance > 0 and math.random(1, 100) <= bestDoubleChance then
				dropCount = dropCount * 2 
			end

			local dropsToSpawn = {}
			for i = 1, dropCount do table.insert(dropsToSpawn, myData.DropItem) end

			if math.random(1, 1000) <= 35 then table.insert(dropsToSpawn, "Szivárvány Kristály") end

			-- ==========================================
			-- JAVÍTÁS: LOOT SZÉTOSZTÁSA A TÁMADÓK KÖZÖTT
			-- ==========================================
			local shuffledAttackers = {}
			for _, v in ipairs(attackers) do table.insert(shuffledAttackers, v) end
			table.sort(shuffledAttackers, function() return math.random() > 0.5 end)

			local currentAttackerIndex = 1

			for _, itemName in ipairs(dropsToSpawn) do
				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.5, 0.5)

				local dropPos = rootPart.Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {ore, droppedFolder, Players:GetPlayers()}

				local ray = workspace:Raycast(dropPos, Vector3.new(0, -50, 0), rayParams)
				if ray then
					droppedItem.Position = ray.Position + Vector3.new(0, 0.2, 0)
				else
					droppedItem.Position = dropPos
				end

				droppedItem.Anchored = true
				droppedItem.CanCollide = false

				local isRainbow = (itemName == "Szivárvány Kristály")
				droppedItem.Color = isRainbow and Color3.fromRGB(255, 100, 255) or Color3.fromRGB(150, 150, 150)
				droppedItem.Material = isRainbow and Enum.Material.Neon or Enum.Material.Plastic

				local itemTag = Instance.new("StringValue", droppedItem)
				itemTag.Name = "ItemName"
				itemTag.Value = itemName

				-- Tulajdonos kiválasztása kártyaosztással
				local luckyPlayer = shuffledAttackers[currentAttackerIndex]
				local killerName = luckyPlayer and luckyPlayer.Name or ""

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

				local r, g, b = 180, 180, 180
				if isRainbow then r, g, b = 255, 150, 255 end
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

			task.wait(0.5)
			ore:Destroy()
			return
		end

		local percent = currentHp / humanoid.MaxHealth
		hpBar.Size = UDim2.new(percent, 0, 1, 0)
		hpText.Text = math.floor(currentHp) .. " / " .. humanoid.MaxHealth
	end)
end

for _, child in pairs(oresFolder:GetChildren()) do
	if child:IsA("Model") then setupOre(child) end
end

oresFolder.ChildAdded:Connect(function(child)
	task.wait(0.1)
	if child:IsA("Model") then setupOre(child) end
end)