local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local AcceptQuest = Events:WaitForChild("AcceptQuest")
local TurnInQuest = Events:WaitForChild("TurnInQuest")

local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

Players.PlayerAdded:Connect(function(player)
	local quests = Instance.new("Folder")
	quests.Name = "Quests"
	quests.Parent = player

	-- DINAMIKUS INICIALIZÁLÁS: Minden küldetést automatikusan felvesz -1-re (Nincs elkezdve)
	for questId, _ in pairs(QuestDatabase) do
		local qVal = Instance.new("IntValue")
		qVal.Name = questId
		qVal.Value = -1
		qVal.Parent = quests
	end
end)

AcceptQuest.OnServerEvent:Connect(function(player, questName)
	local q = player:FindFirstChild("Quests"):FindFirstChild(questName)
	if q and q.Value == -1 then
		q.Value = 0 -- Elindítva
	end
end)

TurnInQuest.OnServerEvent:Connect(function(player, questName)
	local q = player:FindFirstChild("Quests"):FindFirstChild(questName)
	local qData = QuestDatabase[questName]

	-- Ellenőrizzük, hogy elérte-e a szükséges darabszámot és nincs-e még leadva (9999)
	if q and qData and q.Value >= qData.Count and q.Value ~= 9999 then
		q.Value = 9999 -- FIXEN LEADVA / KÉSZ

		-- Jutalmak kiosztása az adatbázisból!
		local stats = player:FindFirstChild("PlayerStats")
		if stats then
			if qData.Rewards.Exp and stats:FindFirstChild("Experience") then
				stats.Experience.Value = stats.Experience.Value + qData.Rewards.Exp
			end
			if qData.Rewards.Gold and stats:FindFirstChild("Gold") then
				stats.Gold.Value = stats.Gold.Value + qData.Rewards.Gold
			end
		end

		-- Tárgy jutalom kezelése
		if qData.Rewards.Item and qData.Rewards.Item ~= "" then
			local inv = player:FindFirstChild("Inventory")
			if inv then
				for i = 1, 8 do
					local slot = inv:FindFirstChild("Slot_" .. i)
					if slot and slot.Value == "" then
						slot.Value = qData.Rewards.Item
						break
					end
				end
			end
		end
	end
end)