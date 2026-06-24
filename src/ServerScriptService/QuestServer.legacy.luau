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
-- BIZTONSÁG 1: ANTI-SPAM (Race Condition védelem)
-- Megakadályozza, hogy egy exploiter 1 sec alatt 50x kérje ki a jutalmat!
-- ==========================================
local playerLocks = {}

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
for _, p in pairs(Players:GetPlayers()) do onPlayerAdded(p) end

Players.PlayerRemoving:Connect(function(player)
	playerLocks[player.UserId] = nil -- Takarítjuk a memóriát kilépéskor
end)

-- ==========================================
-- BIZTONSÁG 2: NPC TÁVOLSÁG ELLENŐRZÉS
-- ==========================================
local function isNearNPC(player, npcName)
	if not npcName then return true end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
	local root = char.HumanoidRootPart

	-- OPTIMALIZÁLVA: Csak az NPCs mappát nézi át!
	local npcFolder = workspace:FindFirstChild("NPCs")
	if npcFolder then
		for _, obj in pairs(npcFolder:GetChildren()) do
			if obj.Name == npcName and obj:FindFirstChild("HumanoidRootPart") then
				local dist = (root.Position - obj.HumanoidRootPart.Position).Magnitude
				if dist <= 20 then
					return true
				end
			end
		end
	end
	return false
end

-- ==========================================
-- KÜLDETÉS FELVÉTELE
-- ==========================================
AcceptQuest.OnServerEvent:Connect(function(player, questName)
	-- Anti-Spam (0.5 sec)
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < 0.5 then return end
	playerLocks[player.UserId] = tick()

	local questData = QuestDatabase[questName]
	local questsFolder = player:FindFirstChild("Quests")
	if not questData or not questsFolder then return end

	-- Ha van StartNPC (Küldetést adó) a DB-ben, ellenőrizzük, hogy ott áll-e mellette!
	if questData.StartNPC and not isNearNPC(player, questData.StartNPC) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " messziről próbált felvenni egy küldetést!")
		return
	end

	if questsFolder:FindFirstChild(questName) then return end 

	local completedFolder = player:FindFirstChild("CompletedQuests")
	if completedFolder and completedFolder:FindFirstChild(questName) then return end 

	local playerLevel = 1
	if player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("Level") then
		playerLevel = player.PlayerStats.Level.Value
	elseif player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
		playerLevel = player.leaderstats.Level.Value
	end

	local reqLevel = questData.MinLevel or 1
	local maxLevel = reqLevel + 10 
	if playerLevel < reqLevel or playerLevel > maxLevel then
		return 
	end

	local qVal = Instance.new("IntValue")
	qVal.Name = questName
	qVal.Value = 0 
	qVal.Parent = questsFolder
end)

-- ==========================================
-- KÜLDETÉS LEADÁSA
-- ==========================================
CompleteQuest.OnServerEvent:Connect(function(player, questName)
	-- Anti-Spam (0.5 sec)
	if playerLocks[player.UserId] and tick() - playerLocks[player.UserId] < 0.5 then return end
	playerLocks[player.UserId] = tick()

	local questData = QuestDatabase[questName]
	local questsFolder = player:FindFirstChild("Quests")
	if not questData or not questsFolder then return end

	local qVal = questsFolder:FindFirstChild(questName)
	if not qVal then return end 

	-- Ha van TargetNPC (Akinek le kell adni), ellenőrizzük a távolságot!
	if questData.TargetNPC and not isNearNPC(player, questData.TargetNPC) then
		warn("[EXPLOIT GYANÚ] " .. player.Name .. " messziről próbálta leadni a küldetést!")
		return
	end

	local canComplete = false
	local itemsToTakeList = {} -- Ide gyűjtjük, miket kell majd levonni a Gathernél

	if questData.Type == "Kill" then
		if qVal.Value >= questData.Count then canComplete = true end

	elseif questData.Type == "Gather" then
		local inv = player:FindFirstChild("Inventory")
		local itemCount = 0
		local foundSlots = {}

		for _, slot in pairs(inv:GetChildren()) do
			if slot.Value == questData.TargetItem then
				local amt = slot:FindFirstChild("Amount") and slot.Amount.Value or 1
				itemCount += amt
				table.insert(foundSlots, {slot = slot, amt = amt, amtObj = slot:FindFirstChild("Amount")})
			end
		end

		if itemCount >= questData.Count then
			canComplete = true
			local itemsToTake = questData.Count

			-- Elmentjük, miket kell levonni, de Még NEM vonjuk le (Biztonság!)
			for _, data in ipairs(foundSlots) do
				if itemsToTake <= 0 then break end
				local takeAmt = math.min(data.amt, itemsToTake)
				table.insert(itemsToTakeList, {slot = data.slot, amtObj = data.amtObj, take = takeAmt})
				itemsToTake -= takeAmt
			end
		end

	elseif questData.Type == "Talk" then
		canComplete = true
	end

	if canComplete then
		-- BIZTONSÁG 3: AZONNAL letöröljük a questet, MIELŐTT bármit adnánk!
		qVal:Destroy()

		local completedFolder = player:FindFirstChild("CompletedQuests")
		if completedFolder and not completedFolder:FindFirstChild(questName) then
			local doneMark = Instance.new("StringValue")
			doneMark.Name = questName
			doneMark.Parent = completedFolder
		end

		-- Most vonjuk le a tárgyakat (Gather quest)
		for _, data in ipairs(itemsToTakeList) do
			if data.amtObj then
				data.amtObj.Value -= data.take
				if data.amtObj.Value <= 0 then
					data.slot.Value = ""
					data.amtObj.Value = 0
				end
			else
				data.slot.Value = ""
			end
		end

		-- BIZTONSÁG 4: Csak most adjuk meg a jutalmakat, amikor már 100% tiszta a terep!
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
	end
end)