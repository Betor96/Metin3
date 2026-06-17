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

	-- Életcsík az érc fölé
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OreHPBar"
	billboard.Size = UDim2.new(0, 100, 0, 15)
	billboard.StudsOffset = Vector3.new(0, 4, 0) 
	billboard.AlwaysOnTop = true
	billboard.Parent = rootPart

	local bgFrame = Instance.new("Frame", billboard)
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

	local hpBar = Instance.new("Frame", bgFrame)
	hpBar.Size = UDim2.new(1, 0, 1, 0)
	hpBar.BackgroundColor3 = Color3.fromRGB(200, 180, 50) -- Arany/Érc szín
	hpBar.BorderSizePixel = 0

	local hpText = Instance.new("TextLabel", bgFrame)
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Text = humanoid.MaxHealth .. " / " .. humanoid.MaxHealth
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true

	local isDead = false

	humanoid.HealthChanged:Connect(function(currentHp)
		if isDead then return end

		if currentHp <= 0 then
			isDead = true
			hpBar.Size = UDim2.new(0, 0, 1, 0)
			hpText.Text = "0 / " .. humanoid.MaxHealth
			billboard:Destroy()

			-- Ki ütötte le az ércet utoljára?
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

			-- Alapból 1 vagy 2 érc esik
			local dropCount = math.random(1, 2)

			-- Bónusz esély ellenőrzése a Csákányból!
			if killer and killer:FindFirstChild("Equipment") then
				local wSlot = killer.Equipment:FindFirstChild("Fegyver")
				if wSlot and wSlot.Value ~= "" then
					local wData = ItemDatabase[wSlot.Value]
					if wData and wData.IsPickaxe and wData.DoubleOreChance then
						if math.random(1, 100) <= wData.DoubleOreChance then
							dropCount = dropCount * 2 -- CSÁKÁNY DUPLÁZÁS SIKERES!
						end
					end
				end
			end

			local dropsToSpawn = {}
			for i = 1, dropCount do table.insert(dropsToSpawn, myData.DropItem) end

			-- 3.5% ESÉLY SZIVÁRVÁNY KRISTÁLYRA (1000-ből 35)
			if math.random(1, 1000) <= 35 then
				table.insert(dropsToSpawn, "Szivárvány Kristály")
			end

			for _, itemName in ipairs(dropsToSpawn) do
				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.5, 0.5)
				droppedItem.Position = rootPart.Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))

				local isRainbow = (itemName == "Szivárvány Kristály")
				droppedItem.Color = isRainbow and Color3.fromRGB(255, 100, 255) or Color3.fromRGB(150, 150, 150)
				droppedItem.Material = isRainbow and Enum.Material.Neon or Enum.Material.Plastic

				local itemTag = Instance.new("StringValue", droppedItem)
				itemTag.Name = "ItemName"
				itemTag.Value = itemName

				local textBillboard = Instance.new("BillboardGui", droppedItem)
				textBillboard.Size = UDim2.new(0, 150, 0, 25)
				textBillboard.StudsOffset = Vector3.new(0, 1.5, 0) 
				textBillboard.AlwaysOnTop = true 

				local nameLabel = Instance.new("TextLabel", textBillboard)
				nameLabel.Size = UDim2.new(1, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = itemName
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.TextColor3 = isRainbow and Color3.fromRGB(255, 150, 255) or Color3.fromRGB(200, 200, 100)

				droppedItem.Parent = droppedFolder
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