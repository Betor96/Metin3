-- Fájl helye: ServerScriptService -> SpawnManager

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnDatabase = require(ReplicatedStorage:WaitForChild("SpawnDatabase"))

local spawnZonesFolder = Workspace:WaitForChild("SpawnZones")

local function getFolder(folderName)
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = Workspace
	end
	return folder
end

task.wait(1) 
local monstersFolder = getFolder("Monsters")
local metinFolder = getFolder("MetinStones")
local oresFolder = getFolder("Ores") -- ÚJ: Ércek mappája

local function getRandomGroundPosition(zonePart)
	local rx = zonePart.Position.X + (math.random() - 0.5) * zonePart.Size.X
	local rz = zonePart.Position.Z + (math.random() - 0.5) * zonePart.Size.Z
	local startY = zonePart.Position.Y + (zonePart.Size.Y / 2) + 20 

	local rayOrigin = Vector3.new(rx, startY, rz)
	local rayDirection = Vector3.new(0, -500, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- ÚJ: Az Ores mappát is kihagyjuk a Raycastból
	rayParams.FilterDescendantsInstances = {spawnZonesFolder, monstersFolder, metinFolder, oresFolder}

	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then
		return result.Position
	else
		return Vector3.new(rx, zonePart.Position.Y, rz)
	end
end

local HttpService = game:GetService("HttpService")

local function spawnPack(zoneName, zoneData, zonePart)
	local centerPos = getRandomGroundPosition(zonePart)
	local aliveCount = #zoneData.Pack
	local spawnedEntities = {}

	local packID = HttpService:GenerateGUID(false)
	local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))

	for i, entityName in ipairs(zoneData.Pack) do
		local template = ReplicatedStorage:FindFirstChild(entityName)
		if template then
			local newEntity = template:Clone()
			newEntity:SetAttribute("PackID", packID)

			local angle = (i / aliveCount) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 4, 3, math.sin(angle) * 4)

			if newEntity:FindFirstChild("HumanoidRootPart") then
				newEntity.HumanoidRootPart.CFrame = CFrame.new(centerPos + offset)
			else
				newEntity:PivotTo(CFrame.new(centerPos + offset))
			end

			-- ==========================================
			-- ÚJ: ÉRCEK KÜLÖNVÁLASZTÁSA ÉS HORGONYZÁSA
			-- ==========================================
			local dbData = MonsterDatabase[entityName]

			if dbData and dbData.Type == "Ore" then
				newEntity:SetAttribute("IsOre", true)
				newEntity.Parent = oresFolder
				if newEntity:FindFirstChild("HumanoidRootPart") then
					newEntity.HumanoidRootPart.Anchored = true 
				end
			elseif zoneData.Type == "MetinStone" then
				newEntity.Parent = metinFolder
				if newEntity:FindFirstChild("HumanoidRootPart") then
					newEntity.HumanoidRootPart.Anchored = true 
				end
			else
				newEntity.Parent = monstersFolder
				if newEntity:FindFirstChild("HumanoidRootPart") then
					newEntity.HumanoidRootPart.Anchored = false 
				end
			end

			table.insert(spawnedEntities, newEntity)

			local humanoid = newEntity:WaitForChild("Humanoid", 3)
			if humanoid then
				local isDead = false
				humanoid.Died:Connect(function()
					if isDead then return end
					isDead = true
					aliveCount -= 1

					if aliveCount <= 0 then
						task.spawn(function()
							task.wait(zoneData.RespawnTime)
							spawnPack(zoneName, zoneData, zonePart)
						end)
					end
				end)
			end
		else
			warn("SPAWN HIBA: Nem talalhato a(z) " .. entityName .. " nevu modell a ReplicatedStorage-ben!")
		end
	end
end

task.spawn(function()
	task.wait(2) 
	for zoneName, zoneData in pairs(SpawnDatabase) do
		local zonePart = spawnZonesFolder:FindFirstChild(zoneName)
		if zonePart then
			-- BIZTONSÁGI JAVÍTÁS: Ha a MaxPacks nil, akkor alapból 1-et használunk, hogy ne fagyjon le!
			local maxPacks = zoneData.MaxPacks or 1 

			for i = 1, maxPacks do
				task.wait(0.2) 
				spawnPack(zoneName, zoneData, zonePart)
			end
		end
	end
end)