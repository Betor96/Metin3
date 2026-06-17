-- Fájl helye: ServerScriptService -> SpawnManager

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnDatabase = require(ReplicatedStorage:WaitForChild("SpawnDatabase"))

-- Mappák előkészítése
local spawnZonesFolder = Workspace:WaitForChild("SpawnZones")

local monstersFolder = Workspace:FindFirstChild("Monsters")
if not monstersFolder then
	monstersFolder = Instance.new("Folder")
	monstersFolder.Name = "Monsters"
	monstersFolder.Parent = Workspace
end

local metinFolder = Workspace:FindFirstChild("MetinStones")
if not metinFolder then
	metinFolder = Instance.new("Folder")
	metinFolder.Name = "MetinStones"
	metinFolder.Parent = Workspace
end

-- ==========================================
-- VÉLETLEN KOORDINÁTA KERESÉSE A ZÓNÁBAN
-- ==========================================
local function getRandomGroundPosition(zonePart)
	-- Kiszámolunk egy véletlen X és Z koordinátát a Part méretén belül
	local rx = zonePart.Position.X + (math.random() - 0.5) * zonePart.Size.X
	local rz = zonePart.Position.Z + (math.random() - 0.5) * zonePart.Size.Z
	local startY = zonePart.Position.Y + (zonePart.Size.Y / 2) + 20 -- Kicsit a Part teteje felől indulunk

	-- Sugárküldés (Raycast) lefelé, hogy megtaláljuk a fizikai talajt
	local rayOrigin = Vector3.new(rx, startY, rz)
	local rayDirection = Vector3.new(0, -500, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Kizárjuk a zóna dobozokat és a többi szörnyet a keresésből
	rayParams.FilterDescendantsInstances = {spawnZonesFolder, monstersFolder, metinFolder}

	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then
		return result.Position
	else
		-- Ha nem talált talajt (mert pl. a levegőben van a zóna), visszaadjuk az alap magasságot
		return Vector3.new(rx, zonePart.Position.Y, rz)
	end
end

-- ==========================================
-- EGY CSOPORT (PACK) LERAKÁSA ÉS FIGYELÉSE
-- ==========================================
local function spawnPack(zoneName, zoneData, zonePart)
	local centerPos = getRandomGroundPosition(zonePart)
	local aliveCount = #zoneData.Pack
	local spawnedEntities = {}

	for i, entityName in ipairs(zoneData.Pack) do
		-- Megkeressük a modellt a ReplicatedStorage-ben
		local template = ReplicatedStorage:FindFirstChild(entityName)
		if template then
			local newEntity = template:Clone()

			-- Ha több szörny van egy csoportban, körbe rakjuk őket a középpont körül
			local angle = (i / aliveCount) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 4, 3, math.sin(angle) * 4)

			if newEntity:FindFirstChild("HumanoidRootPart") then
				newEntity.HumanoidRootPart.CFrame = CFrame.new(centerPos + offset)
			else
				newEntity:PivotTo(CFrame.new(centerPos + offset))
			end

			-- Hova kerüljön? (Fontos a Metinkövek miatt!)
			if zoneData.Type == "MetinStone" then
				newEntity.Parent = metinFolder
			else
				newEntity.Parent = monstersFolder
			end

			table.insert(spawnedEntities, newEntity)

			-- HALÁL FIGYELÉSE
			local humanoid = newEntity:WaitForChild("Humanoid", 3)
			if humanoid then
				local isDead = false
				humanoid.Died:Connect(function()
					if isDead then return end
					isDead = true
					aliveCount -= 1

					-- ÚJRAÉLEDÉS LOGIKA: Ha a csoport UTOLSÓ tagja is meghal!
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

-- ==========================================
-- A RENDSZER ELINDÍTÁSA SZERVER INDULÁSKOR
-- ==========================================
task.spawn(function()
	task.wait(2) -- Várunk picit, hogy a pálya és a többi script betöltsön

	for zoneName, zoneData in pairs(SpawnDatabase) do
		local zonePart = spawnZonesFolder:FindFirstChild(zoneName)

		if zonePart then
			print("Zóna betöltése: " .. zoneName .. " (" .. zoneData.MaxPacks .. " db csoport)")
			-- Lefuttatjuk annyiszor, amennyi a MaxPacks
			for i = 1, zoneData.MaxPacks do
				task.wait(0.2) -- Pici szünet, hogy ne egyszerre laggoltassa le a szervert
				spawnPack(zoneName, zoneData, zonePart)
			end
		else
			warn("SPAWN HIBA: A(z) " .. zoneName .. " nevu Part nem talalhato a Workspace.SpawnZones mappaban!")
		end
	end
end)