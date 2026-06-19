-- Fájl helye: ServerScriptService -> DeathServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

Players.RespawnTime = 99999

local RespawnPlayer = Events:FindFirstChild("RespawnPlayer") or Instance.new("RemoteEvent", Events)
RespawnPlayer.Name = "RespawnPlayer"

local deathPositions = {}

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
	local dPos = deathPositions[player.UserId] or Vector3.new(0, 50, 0)

	player:LoadCharacter()
	local newChar = player.Character or player.CharacterAdded:Wait()
	local root = newChar:WaitForChild("HumanoidRootPart", 5)
	local hum = newChar:WaitForChild("Humanoid", 5)

	-- JAVÍTÁS: Várunk 0.5 másodpercet, hogy a Te SpawnManager-ed befejezze a teleportálást!
	-- Csak UTÁNA ragadjuk meg a karaktert és rakjuk a jó helyre.
	task.wait(0.5)

	if spawnType == "Here" then

		-- ==========================================
		-- TÖKÉLETES SÉRTHETETLENSÉG ROBLOX FORCEFIELD-DEL
		-- ==========================================
		local ff = Instance.new("ForceField")
		ff.Visible = true -- Kék védőgömb a karakter körül
		ff.Parent = newChar
		game.Debris:AddItem(ff, 5) -- Pontosan 5 másodperc múlva automatikusan letörli!

		if root then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {newChar}
			local ray = workspace:Raycast(dPos + Vector3.new(0, 15, 0), Vector3.new(0, -50, 0), rayParams)

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
		local townFolder = workspace:FindFirstChild("TownSpawns")
		local targetPos = Vector3.new(0, 50, 0)

		if townFolder and #townFolder:GetChildren() > 0 then
			local spawns = townFolder:GetChildren()
			local nearest = spawns[1]
			local shortestDist = (nearest.Position - dPos).Magnitude

			for _, spwn in pairs(spawns) do
				local dist = (spwn.Position - dPos).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearest = spwn
				end
			end
			targetPos = nearest.Position
		end

		if root then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {newChar}
			local ray = workspace:Raycast(targetPos + Vector3.new(0, 50, 0), Vector3.new(0, -150, 0), rayParams)

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