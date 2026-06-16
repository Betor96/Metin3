local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MeleeAttack = Events:WaitForChild("MeleeAttack")
local ShowDamage = Events:WaitForChild("ShowDamage")

-- BEKÖTJÜK A KÖZPONTI ADATBÁZIST
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local ATTACK_RANGE = 6 
local SERVER_COOLDOWN = 0.75 
local playerAttackTimes = {}

MeleeAttack.OnServerEvent:Connect(function(player)
	local currentTime = tick()
	local lastTime = playerAttackTimes[player.UserId] or 0
	if currentTime - lastTime < SERVER_COOLDOWN then return end
	playerAttackTimes[player.UserId] = currentTime

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local stats = player:FindFirstChild("PlayerStats")
	local str = (stats and stats:FindFirstChild("STR")) and stats.STR.Value or 1
	local baseMin = math.floor(5 + (str * 1.5))
	local baseMax = math.floor(10 + (str * 2))

	local wepMin, wepMax = 0, 0
	local eqFolder = player:FindFirstChild("Equipment")
	if eqFolder and eqFolder:FindFirstChild("Fegyver") then
		local wepName = eqFolder.Fegyver.Value

		-- ==========================================
		-- FEGYVER STATISZTIKA LEKÉRÉSE AZ ADATBÁZISBÓL!
		-- ==========================================
		local itemData = ItemDatabase[wepName]
		if itemData and itemData.Type == "Fegyver" then
			wepMin = itemData.MinDmg
			wepMax = itemData.MaxDmg
		end
	end

	local finalDamage = math.random(baseMin + wepMin, baseMax + wepMax)

	local protectedNPCs = {
		["Fegyverkereskedo"] = true, ["Pancelkereskedo"] = true, 
		["Vegyesbolt"] = true, ["Kovacs"] = true, ["Faluose"] = true, ["Varosor"] = true
	}

	for _, object in pairs(workspace:GetDescendants()) do
		if object:IsA("Humanoid") and object.Parent ~= character then
			if not protectedNPCs[object.Parent.Name] then
				local enemyRoot = object.Parent:FindFirstChild("HumanoidRootPart")
				if enemyRoot then
					local distance = (rootPart.Position - enemyRoot.Position).Magnitude
					if distance <= ATTACK_RANGE and object.Health > 0 then
						object:TakeDamage(finalDamage)
						ShowDamage:FireAllClients(enemyRoot, finalDamage)
					end
				end
			end
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	playerAttackTimes[player.UserId] = nil
end)