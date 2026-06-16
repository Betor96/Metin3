local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local AddStatPoint = Events:WaitForChild("AddStatPoint")

AddStatPoint.OnServerEvent:Connect(function(player, statName)
	-- Csak ezt a 4 statot engedjük növelni
	local validStats = {VIT = true, INT = true, STR = true, DEX = true}
	if not validStats[statName] then return end

	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return end

	local statPoints = stats:FindFirstChild("StatPoints")
	local targetStat = stats:FindFirstChild(statName)

	-- Biztonsági ellenőrzés: Van-e elosztható pontja?
	if statPoints and statPoints.Value > 0 and targetStat then
		statPoints.Value = statPoints.Value - 1
		targetStat.Value = targetStat.Value + 1

		-- Ha a Vitalitást (VIT) növelte, azonnal frissítjük a Maximum HP-ját!
		if statName == "VIT" then
			local character = player.Character
			local leaderstats = player:FindFirstChild("leaderstats")
			if character and leaderstats then
				local humanoid = character:FindFirstChild("Humanoid")
				local level = leaderstats:FindFirstChild("Level").Value
				if humanoid then
					local maxHp = 200 + (level * 30) + (targetStat.Value * 40)
					humanoid.MaxHealth = maxHp
					humanoid.Health = humanoid.Health + 40 -- Plusz HP hozzáadása azonnal
				end
			end
		end

		print(player.Name .. " növelte ezt a statisztikát: " .. statName)
	end
end)