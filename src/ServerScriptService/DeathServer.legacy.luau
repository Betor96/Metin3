-- Fájl helye: ServerScriptService -> DeathServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

-- Kikapcsoljuk az automata Roblox újraéledést (9999 másodpercre állítjuk)
Players.RespawnTime = 99999

local RespawnPlayer = Events:FindFirstChild("RespawnPlayer") or Instance.new("RemoteEvent", Events)
RespawnPlayer.Name = "RespawnPlayer"

local deathPositions = {}

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				-- Épp a halál pillanatában elmentjük a pozícióját
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

	-- Újrageneráljuk a karaktert
	player:LoadCharacter()

	local newChar = player.Character or player.CharacterAdded:Wait()
	local root = newChar:WaitForChild("HumanoidRootPart", 5)
	local hum = newChar:WaitForChild("Humanoid", 5)

	task.wait(0.1) -- Biztonsági várakozás, hogy a Roblox fizikája betöltsön

	if spawnType == "Here" then
		if root then
			root.CFrame = CFrame.new(dPos + Vector3.new(0, 3, 0))
		end
		if hum then
			hum.Health = hum.MaxHealth * 0.1 -- 10% HP
		end

		-- SÉRTHETETLENSÉG BEÁLLÍTÁSA
		newChar:SetAttribute("Invincible", true)
		task.spawn(function()
			task.wait(5)
			if newChar and newChar:GetAttribute("Invincible") then
				newChar:SetAttribute("Invincible", false)
			end
		end)

	elseif spawnType == "Town" then
		-- Megkeressük a legközelebbi falut
		local townFolder = workspace:FindFirstChild("TownSpawns")
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

			if root then
				root.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
			end
		else
			-- Ha elfelejtettél TownSpawn-t lerakni, ide dobja
			if root then root.CFrame = CFrame.new(0, 50, 0) end
		end
	end
end)