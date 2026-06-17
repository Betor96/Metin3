-- Fájl helye: ServerScriptService -> SpawnManager

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnDatabase = require(ReplicatedStorage:WaitForChild("SpawnDatabase"))

local spawnZonesFolder = Workspace:WaitForChild("SpawnZones")

-- JAVÍTÁS: Mappa biztonságos lekérése!
local function getFolder(folderName)
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = Workspace
	end
	return folder
end

-- VÁRUNK EGY KICSIT! 
-- Ezzel megvárjuk, hogy a MetinStoneLogic is felébredjen, és ugyanazt a mappát használják!
task.wait(1) 
local monstersFolder = getFolder("Monsters")
local metinFolder = getFolder("MetinStones")

local function getRandomGroundPosition(zonePart)
	local rx = zonePart.Position.X + (math.random() - 0.5) * zonePart.Size.X
	local rz = zonePart.Position.Z + (math.random() - 0.5) * zonePart.Size.Z
	local startY = zonePart.Position.Y + (zonePart.Size.Y / 2) + 20 

	local rayOrigin = Vector3.new(rx, startY, rz)
	local rayDirection = Vector3.new(0, -500, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {spawnZonesFolder, monstersFolder, metinFolder}

	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then
		return result.Position
	else
		return Vector3.new(rx, zonePart.Position.Y, rz)
	end
end

local function spawnPack(zoneName, zoneData, zonePart)
	local centerPos = getRandomGroundPosition(zonePart)
	local aliveCount = #zoneData.Pack
	local spawnedEntities = {}

	for i, entityName in ipairs(zoneData.Pack) do
		local template = ReplicatedStorage:FindFirstChild(entityName)
		if template then
			local newEntity = template:Clone()

			local angle = (i / aliveCount) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 4, 3, math.sin(angle) * 4)

			if newEntity:FindFirstChild("HumanoidRootPart") then
				newEntity.HumanoidRootPart.CFrame = CFrame.new(centerPos + offset)
			else
				newEntity:PivotTo(CFrame.new(centerPos + offset))
			end

			-- JAVÍTÁS: Helyes Mappa ÉS Horgonyzás beállítása
			if zoneData.Type == "MetinStone" then
				newEntity.Parent = metinFolder
				-- A Köveket FIXEN a földhöz ragasztjuk
				if newEntity:FindFirstChild("HumanoidRootPart") then
					newEntity.HumanoidRootPart.Anchored = true 
				end
			else
				newEntity.Parent = monstersFolder
				-- A Szörnyeket kilazítjuk, hogy tudjanak futni feléd
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
			for i = 1, zoneData.MaxPacks do
				task.wait(0.2) 
				spawnPack(zoneName, zoneData, zonePart)
			end
		end
	end
end)