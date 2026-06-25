-- Fájl helye: ServerScriptService -> SpawnManager

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnDatabase = require(ReplicatedStorage:WaitForChild("SpawnDatabase"))
local HttpService = game:GetService("HttpService")

local spawnZonesFolder = Workspace:WaitForChild("SpawnZones")

local function ensureFolder(folderName)
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = Workspace
	end
	return folder
end

local function getRandomGroundPosition(zonePart)
	if not zonePart or not zonePart.Parent then return Vector3.new(0, 50, 0) end
	local rx = zonePart.Position.X + (math.random() - 0.5) * zonePart.Size.X
	local rz = zonePart.Position.Z + (math.random() - 0.5) * zonePart.Size.Z
	local startY = zonePart.Position.Y + (zonePart.Size.Y / 2) + 20 

	local rayOrigin = Vector3.new(rx, startY, rz)
	local rayDirection = Vector3.new(0, -500, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {
		spawnZonesFolder, 
		ensureFolder("Monsters"), 
		ensureFolder("MetinStones"), 
		ensureFolder("Ores")
	}

	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then
		return result.Position
	else
		return Vector3.new(rx, zonePart.Position.Y, rz)
	end
end

local function spawnPack(zoneName, zoneData, zonePart)
	if not zonePart then 
		warn("❌ [" .. zoneName .. "] A Spawn Zóna (kocka) eltűnt a pályáról!")
		return 
	end

	local centerPos = getRandomGroundPosition(zonePart)
	local packID = HttpService:GenerateGUID(false)
	local MonsterDatabase = require(ReplicatedStorage:WaitForChild("MonsterDatabase"))

	local packEntities = {}

	for i, entityName in ipairs(zoneData.Pack) do
		local template = ReplicatedStorage:FindFirstChild(entityName)
		if template then
			local newEntity = template:Clone()
			newEntity:SetAttribute("PackID", packID)

			local angle = (i / #zoneData.Pack) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 4, 3, math.sin(angle) * 4)

			if newEntity:FindFirstChild("HumanoidRootPart") then
				newEntity.HumanoidRootPart.CFrame = CFrame.new(centerPos + offset)
			else
				newEntity:PivotTo(CFrame.new(centerPos + offset))
			end

			local dbData = MonsterDatabase[entityName]

			if dbData and dbData.Type == "Ore" then
				newEntity:SetAttribute("IsOre", true)
				newEntity.Parent = ensureFolder("Ores")
				if newEntity:FindFirstChild("HumanoidRootPart") then newEntity.HumanoidRootPart.Anchored = true end
			elseif zoneData.Type == "MetinStone" then
				newEntity.Parent = ensureFolder("MetinStones")
				if newEntity:FindFirstChild("HumanoidRootPart") then newEntity.HumanoidRootPart.Anchored = true end
			else
				newEntity.Parent = ensureFolder("Monsters")
				if newEntity:FindFirstChild("HumanoidRootPart") then newEntity.HumanoidRootPart.Anchored = false end
			end

			table.insert(packEntities, newEntity)
		else
			warn("❌ SPAWN HIBA: Nem talalhato a(z) " .. tostring(entityName) .. " nevu modell a ReplicatedStorage-ben!")
		end
	end

	print("✅ [" .. zoneName .. "] Sikeresen leidézve " .. #packEntities .. " szörny!")

	-- ==========================================
	-- AGRESSZÍV RESPAWN FIGYELŐ
	-- ==========================================
	task.spawn(function()
		if #packEntities == 0 then 
			warn("⚠️ [" .. zoneName .. "] Üres falka! Újrapróbálkozás 10 másodperc múlva...")
			task.wait(10)
			spawnPack(zoneName, zoneData, zonePart)
			return 
		end
		local waitTime = zoneData.RespawnTime or 15

		while true do
			task.wait(2) 
			local aliveCount = 0

			-- Ezt a részt cseréld ki a while ciklus belsejében:
			for _, entity in ipairs(packEntities) do
				-- Szigorú ellenőrzés:
				-- 1. Van-e még Parentje (ha törölted, a Parent nil lesz)
				-- 2. Benne van-e még a Workspace-ben?
				-- 3. Ha a Humanoid még ott van és él?
				if entity and entity.Parent ~= nil and entity:IsDescendantOf(Workspace) then
					local hum = entity:FindFirstChild("Humanoid")
					if hum and hum.Health > 0 then
						aliveCount = aliveCount + 1
					end
				end
			end

			-- Ha a szám nulla lett, akkor kitörölted őket vagy meghaltak!
			if aliveCount == 0 then
				print("💀 [" .. zoneName .. "] A falka teljesen eltűnt/meghalt! Várunk " .. waitTime .. " másodpercet...")

				-- Várunk
				task.wait(waitTime)

				print("✨ [" .. zoneName .. "] Az idő letelt, újraélesztés indítása!")
				spawnPack(zoneName, zoneData, zonePart)

				break -- Leállítjuk Ezt a ciklust, mert az új falkának már új ciklus kell
			end
		end
	end)
end

-- ==========================================
-- JÁTÉK INDULÁSA
-- ==========================================
task.spawn(function()
	task.wait(2) 
	print("🚀 SpawnManager elindult, zónák betöltése...")

	for zoneName, zoneData in pairs(SpawnDatabase) do
		local zonePart = spawnZonesFolder:FindFirstChild(zoneName)
		if zonePart then
			local maxPacks = zoneData.MaxPacks or 1 
			print("📌 [" .. zoneName .. "] Zóna megtalálva! " .. maxPacks .. " falka fog spawnolni.")
			for i = 1, maxPacks do
				task.wait(0.2) 
				spawnPack(zoneName, zoneData, zonePart)
			end
		else
			warn("❌ Hiba: Nem létezik '" .. zoneName .. "' nevű zóna a Workspace.SpawnZones mappában!")
		end
	end
end)