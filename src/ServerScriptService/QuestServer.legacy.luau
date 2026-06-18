-- Fájl helye: ServerScriptService -> QuestServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

local AcceptQuest = Events:FindFirstChild("AcceptQuest") or Instance.new("RemoteEvent", Events)
AcceptQuest.Name = "AcceptQuest"

local CompleteQuest = Events:FindFirstChild("CompleteQuest") or Instance.new("RemoteEvent", Events)
CompleteQuest.Name = "CompleteQuest"

-- ==========================================
-- JÁTÉKOS MAPPÁINAK LÉTREHOZÁSA (EZ HIÁNYZOTT!)
-- ==========================================
local function onPlayerAdded(player)
	if not player:FindFirstChild("Quests") then
		local qFolder = Instance.new("Folder")
		qFolder.Name = "Quests"
		qFolder.Parent = player
	end
	if not player:FindFirstChild("CompletedQuests") then
		local cFolder = Instance.new("Folder")
		cFolder.Name = "CompletedQuests"
		cFolder.Parent = player
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in pairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

-- ==========================================
-- KÜLDETÉS FELVÉTELE
-- ==========================================
AcceptQuest.OnServerEvent:Connect(function(player, questName)
	local questData = QuestDatabase[questName]
	local questsFolder = player:FindFirstChild("Quests")
	if not questData or not questsFolder then return end

	if questsFolder:FindFirstChild(questName) then return end -- Már felvette

	-- ==========================================
	-- JAVÍTÁS: Végleges tiltás szerver oldalon, ha már kész van!
	-- ==========================================
	local completedFolder = player:FindFirstChild("CompletedQuests")
	if completedFolder and completedFolder:FindFirstChild(questName) then return end 

	-- SZINT ELLENŐRZÉS (+10 SZABÁLY)
	local playerLevel = 1
	if player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("Level") then
		playerLevel = player.PlayerStats.Level.Value
	elseif player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
		playerLevel = player.leaderstats.Level.Value
	end

	local reqLevel = questData.MinLevel or 1
	local maxLevel = reqLevel + 10 -- SZINT KORLÁT: Minimum szint + 10!

	if playerLevel < reqLevel or playerLevel > maxLevel then
		print(player.Name .. " szintje nem jó ehhez: " .. questName)
		return 
	end

	-- Sikeres felvétel!
	local qVal = Instance.new("IntValue")
	qVal.Name = questName
	qVal.Value = 0 
	qVal.Parent = questsFolder
end)

-- ==========================================
-- KÜLDETÉS LEADÁSA
-- ==========================================
CompleteQuest.OnServerEvent:Connect(function(player, questName)
	local questData = QuestDatabase[questName]
	local questsFolder = player:FindFirstChild("Quests")
	if not questData or not questsFolder then return end

	local qVal = questsFolder:FindFirstChild(questName)
	if not qVal then return end 

	local canComplete = false

	if questData.Type == "Kill" then
		if qVal.Value >= questData.Count then canComplete = true end

	elseif questData.Type == "Gather" then
		local inv = player:FindFirstChild("Inventory")
		local itemCount = 0
		for _, slot in pairs(inv:GetChildren()) do
			if slot.Value == questData.TargetItem then
				local amt = slot:FindFirstChild("Amount") and slot.Amount.Value or 1
				itemCount += amt
			end
		end

		if itemCount >= questData.Count then
			canComplete = true
			local itemsToTake = questData.Count
			for _, slot in pairs(inv:GetChildren()) do
				if itemsToTake <= 0 then break end
				if slot.Value == questData.TargetItem then
					local amtObj = slot:FindFirstChild("Amount")
					local amt = amtObj and amtObj.Value or 1
					if amt <= itemsToTake then
						itemsToTake -= amt
						slot.Value = ""
						if amtObj then amtObj.Value = 0 end
					else
						amtObj.Value -= itemsToTake
						itemsToTake = 0
					end
				end
			end
		end

	elseif questData.Type == "Talk" then
		canComplete = true
	end

	-- JUTALMAK
	if canComplete then
		local stats = player:FindFirstChild("PlayerStats")
		if stats then
			if questData.RewardExp and stats:FindFirstChild("Experience") then
				stats.Experience.Value += questData.RewardExp
			end
			if questData.RewardGold and stats:FindFirstChild("Gold") then
				stats.Gold.Value += questData.RewardGold
			end

			if questData.RewardItem then
				local inv = player:FindFirstChild("Inventory")
				local maxUnlocked = (stats:FindFirstChild("UnlockedPages") and stats.UnlockedPages.Value or 1) * 32
				for i = 1, maxUnlocked do
					local slot = inv:FindFirstChild("Slot_" .. i)
					if slot and slot.Value == "" then
						slot.Value = questData.RewardItem
						if questData.RewardItemCount and questData.RewardItemCount > 1 then
							local newAmt = Instance.new("IntValue", slot)
							newAmt.Name = "Amount"
							newAmt.Value = questData.RewardItemCount
						end
						break
					end
				end
			end
		end

		qVal:Destroy()

		qVal:Destroy()

		-- ==========================================
		-- JAVÍTÁS: Küldetés mentése a befejezettek közé (Minden küldetés csak 1x csinálható)
		-- ==========================================
		local completedFolder = player:FindFirstChild("CompletedQuests")
		if completedFolder and not completedFolder:FindFirstChild(questName) then
			local doneMark = Instance.new("StringValue")
			doneMark.Name = questName
			doneMark.Parent = completedFolder
		end
	end
end)