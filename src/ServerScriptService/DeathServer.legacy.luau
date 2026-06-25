-- Fájl helye: ServerScriptService -> DeathServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local respawnLocks = {}
Players.RespawnTime = 99999

local RespawnPlayer = Events:FindFirstChild("RespawnPlayer") or Instance.new("RemoteEvent", Events)
RespawnPlayer.Name = "RespawnPlayer"

local deathPositions = {}

local validRespawnTypes = {
	Here = true,
	Town = true,
}

local function canPlayerRespawn(player)
	local deathPos = deathPositions[player.UserId]
	if not deathPos then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Health > 0 then
		return false
	end

	return true
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					deathPositions[player.UserId] = root.Position
				end
			end)
		end
	end)
end)



RespawnPlayer.OnServerEvent:Connect(function(player, spawnType)
	if not validRespawnTypes[spawnType] then
		warn("[RESPAWN EXPLOIT GYANÚ] " .. player.Name .. " érvénytelen respawn típust küldött: " .. tostring(spawnType))
		return
	end

	if respawnLocks[player.UserId] and tick() - respawnLocks[player.UserId] < 3 then return end
	respawnLocks[player.UserId] = tick()

	if not canPlayerRespawn(player) then
		warn("[RESPAWN EXPLOIT GYANÚ] " .. player.Name .. " respawnolni próbált, de nincs halott állapotban.")
		return
	end

	local dPos = deathPositions[player.UserId]
	deathPositions[player.UserId] = nil

	player:LoadCharacter()
	local newChar = player.Character or player.CharacterAdded:Wait()
	local root = newChar:WaitForChild("HumanoidRootPart", 5)
	local hum = newChar:WaitForChild("Humanoid", 5)

	task.wait() -- Azonnali éledés villanás nélkül

	if spawnType == "Here" then

		-- ==========================================
		-- JAVÍTÁS: 10 MÁSODPERCES SÉRTHETETLENSÉG ÉS LÁTHATATLANSÁG
		-- ==========================================
		local ff = Instance.new("ForceField")
		ff.Visible = true 
		ff.Parent = newChar
		game.Debris:AddItem(ff,5) -- 10 másodperc múlva automatikusan letörli!

		-- Karakter átlátszóvá tétele
		for _, part in pairs(newChar:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0.5 
			end
		end

		task.spawn(function()
			task.wait(5) -- 10 másodperc múlva visszakapja a normál kinézetét
			if newChar then
				for _, part in pairs(newChar:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 0 
					end
				end
			end
		end)

		if root then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local ignoreList = {newChar}
			if workspace:FindFirstChild("Monsters") then table.insert(ignoreList, workspace.Monsters) end
			if workspace:FindFirstChild("MetinStones") then table.insert(ignoreList, workspace.MetinStones) end
			rayParams.FilterDescendantsInstances = ignoreList

			local ray = workspace:Raycast(dPos + Vector3.new(0, 15, 0), Vector3.new(0, -100, 0), rayParams)

			if ray then
				newChar:PivotTo(CFrame.new(ray.Position + Vector3.new(0, 3, 0)))
			else
				newChar:PivotTo(CFrame.new(dPos + Vector3.new(0, 3, 0)))
			end
		end

		task.spawn(function()
			task.wait(1.5)
			if hum then hum.Health = math.max(1, hum.MaxHealth * 0.1) end
		end)

	elseif spawnType == "Town" then

		local targetPos = nil 
		local validSpawns = {}

		for _, obj in pairs(workspace:GetDescendants()) do
			local name = string.lower(obj.Name) 

			if name == "townspawns" or name == "townspawn" then
				if obj:IsA("Folder") or obj:IsA("Model") then
					for _, child in pairs(obj:GetChildren()) do
						if child:IsA("BasePart") then
							table.insert(validSpawns, child.Position)
						elseif child:IsA("Model") and child.PrimaryPart then
							table.insert(validSpawns, child.PrimaryPart.Position)
						elseif child:IsA("Model") then
							table.insert(validSpawns, child:GetPivot().Position)
						end
					end
				elseif obj:IsA("BasePart") then
					table.insert(validSpawns, obj.Position)
				end
			end
		end

		if #validSpawns > 0 then
			targetPos = validSpawns[1]
			local shortestDist = (targetPos - dPos).Magnitude

			for _, pos in pairs(validSpawns) do
				local dist = (pos - dPos).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					targetPos = pos
				end
			end
		end

		if not targetPos then
			warn("FIGYELEM: A TownSpawns mappa/part nem található! Teleport a kezdőpontra...")
			local defSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
			if defSpawn then
				targetPos = defSpawn.Position
			else
				targetPos = Vector3.new(0, 50, 0)
			end
		end

		if root then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local ignoreList = {newChar}
			if workspace:FindFirstChild("Monsters") then table.insert(ignoreList, workspace.Monsters) end
			if workspace:FindFirstChild("MetinStones") then table.insert(ignoreList, workspace.MetinStones) end
			rayParams.FilterDescendantsInstances = ignoreList

			local ray = workspace:Raycast(targetPos + Vector3.new(0, 100, 0), Vector3.new(0, -500, 0), rayParams)

			if ray then
				newChar:PivotTo(CFrame.new(ray.Position + Vector3.new(0, 3, 0)))
			else
				newChar:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
			end
		end

		task.spawn(function()
			task.wait(1.5)
			if hum then hum.Health = hum.MaxHealth end
		end)
	end
end)

-- ==========================================
-- JAVÍTÁS: MEMORY LEAK TAKARÍTÁSA KILÉPÉSKOR
-- ==========================================
Players.PlayerRemoving:Connect(function(player)
	deathPositions[player.UserId] = nil
	if respawnLocks then respawnLocks[player.UserId] = nil end
end)