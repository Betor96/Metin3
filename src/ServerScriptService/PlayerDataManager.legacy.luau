-- Fájl helye: ServerScriptService -> PlayerDataManager

local DataStoreService = game:GetService("DataStoreService")
-- Új adatbázis név a 3 slotos rendszer miatt, hogy tiszta lappal induljunk!
local playerDataStore = DataStoreService:GetDataStore("Metin3_PlayerData_V1") 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local GetCharacterList = Events:WaitForChild("GetCharacterList")
local CreateCharacter = Events:WaitForChild("CreateCharacter")
local SelectCharacter = Events:WaitForChild("SelectCharacter")

-- ==========================================
-- TÖRLÉS EVENT LÉTREHOZÁSA ÉS BEKÖTÉSE
-- ==========================================
local DeleteCharacter = Events:FindFirstChild("DeleteCharacter")
if not DeleteCharacter then
	DeleteCharacter = Instance.new("RemoteEvent")
	DeleteCharacter.Name = "DeleteCharacter"
	DeleteCharacter.Parent = Events
end

local savingPlayers = {} 
local activeSlots = {} -- NYILVÁNTARTJUK: Ki melyik sloton játszik éppen!

-- JAVÍTÁS: Ebbe mentjük ideiglenesen a törölt slotokat, hogy a menü AZONNAL üresnek lássa őket (Késés ellen)
local deletedSlotsCache = {} 

-- ==========================================
-- 0. KARAKTER TÖRLÉSE
-- ==========================================
DeleteCharacter.OnServerEvent:Connect(function(player, slotId)
	if type(slotId) ~= "number" or slotId < 1 or slotId > 3 then return end

	-- Azonnal bejegyezzük a memóriába, hogy törölve lett (Így a menü egyből frissül!)
	if not deletedSlotsCache[player.UserId] then deletedSlotsCache[player.UserId] = {} end
	deletedSlotsCache[player.UserId][slotId] = true

	local success, errorMessage = pcall(function()
		playerDataStore:RemoveAsync("Player_" .. player.UserId .. "_Slot_" .. slotId)
	end)

	if success then
		print(player.Name .. " karakterét VÉGLEGESEN TÖRÖLTÜK a(z) " .. slotId .. ". slotról.")
		if activeSlots[player.UserId] == slotId then
			activeSlots[player.UserId] = nil
		end
	else
		warn("Hiba a karakter törlésekor: " .. tostring(errorMessage))
		deletedSlotsCache[player.UserId][slotId] = nil -- Hiba esetén visszavonjuk a memóriából
	end
end)

-- ==========================================
-- 1. KARAKTER LISTA LEKÉRÉSE A MENÜHÖZ (Kliens hívja meg)
-- ==========================================
GetCharacterList.OnServerInvoke = function(player)
	local charList = {}

	for slot = 1, 3 do
		-- JAVÍTÁS: Ha a slotot most törölték ki, azonnal üresnek mutatjuk a késés elkerülése végett!
		if deletedSlotsCache[player.UserId] and deletedSlotsCache[player.UserId][slot] then
			charList[slot] = { Exists = false }
		else
			local success, data = pcall(function() 
				return playerDataStore:GetAsync("Player_" .. player.UserId .. "_Slot_" .. slot) 
			end)

			if success and data then
				charList[slot] = {
					Exists = true,
					Class = data.Class or "Ismeretlen",
					Level = (data.Stats and data.Stats.Level) or 1
				}
			else
				charList[slot] = { Exists = false }
			end
		end
	end

	return charList
end

-- ==========================================
-- 2. KARAKTER BETÖLTÉSE ÉS JÁTÉK INDÍTÁSA
-- ==========================================
local function setupPlayer(player, slotId)
	local success, data = pcall(function() 
		return playerDataStore:GetAsync("Player_" .. player.UserId .. "_Slot_" .. slotId) 
	end)

	if not success or not data then
		warn("HIBA: A játékos megpróbált betölteni egy üres vagy hibás slotot!")
		return
	end

	activeSlots[player.UserId] = slotId 

	player:SetAttribute("Class", data.Class)

	-- ==========================================
	-- STATOK LÉTREHOZÁSA 
	-- ==========================================
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local leaderLevel = Instance.new("IntValue", leaderstats)
	leaderLevel.Name = "Level"
	leaderLevel.Value = (data.Stats and data.Stats.Level) or 1

	local stats = Instance.new("Folder")
	stats.Name = "PlayerStats"
	stats.Parent = player

	local exp = Instance.new("IntValue", stats) exp.Name = "Experience" exp.Value = (data.Stats and data.Stats.Experience) or 0
	local gold = Instance.new("IntValue", stats) gold.Name = "Gold" gold.Value = (data.Stats and data.Stats.Gold) or 0
	local level = Instance.new("IntValue", stats) level.Name = "Level" level.Value = (data.Stats and data.Stats.Level) or 1
	local statPoints = Instance.new("IntValue", stats) statPoints.Name = "StatPoints" statPoints.Value = (data.Stats and data.Stats.StatPoints) or 0

	local str = Instance.new("IntValue", stats) str.Name = "STR" str.Value = (data.Stats and data.Stats.STR) or 1
	local vit = Instance.new("IntValue", stats) vit.Name = "VIT" vit.Value = (data.Stats and data.Stats.VIT) or 1
	local int = Instance.new("IntValue", stats) int.Name = "INT" int.Value = (data.Stats and data.Stats.INT) or 1
	local dex = Instance.new("IntValue", stats) dex.Name = "DEX" dex.Value = (data.Stats and data.Stats.DEX) or 1

	local unlockedPages = Instance.new("IntValue", stats) 
	unlockedPages.Name = "UnlockedPages" 
	unlockedPages.Value = (data.Stats and data.Stats.UnlockedPages) or 1

	local mana = Instance.new("IntValue", stats) mana.Name = "Mana" mana.Value = (data.Stats and data.Stats.Mana) or 100
	local maxMana = Instance.new("IntValue", stats) maxMana.Name = "MaxMana" maxMana.Value = (data.Stats and data.Stats.MaxMana) or 100

	local bonusStats = {"Defense", "StrongVsMetin", "StrongVsMonster", "StrongVsPlayer", "LifeSteal", "CritChance", "DoubleDrop", "DoubleGold", "AttackSpeed", "MovementSpeed", "DodgeChance"}
	for _, bStat in pairs(bonusStats) do
		local val = Instance.new("IntValue", stats)
		val.Name = bStat
		val.Value = (data.Stats and data.Stats[bStat]) or 0
	end

	-- ==========================================
	-- TÁSKA, BANK, FELSZERELÉS, KÜLDETÉS BETÖLTÉSE
	-- ==========================================
	local inv = Instance.new("Folder", player)
	inv.Name = "Inventory"
	for i = 1, 128 do 
		local slot = Instance.new("StringValue", inv)
		slot.Name = "Slot_" .. i
		slot.Value = ""
		local amt = Instance.new("IntValue", slot)
		amt.Name = "Amount"
		amt.Value = 0

		if data.Inventory and data.Inventory["Slot_" .. i] then
			local savedData = data.Inventory["Slot_" .. i]
			if type(savedData) == "string" then
				slot.Value = savedData
				amt.Value = (savedData ~= "") and 1 or 0
			else
				slot.Value = savedData.Name or ""
				amt.Value = savedData.Amount or 0
			end
		end
	end

	local eq = Instance.new("Folder", player)
	eq.Name = "Equipment"
	local eqSlots = {"Sapka", "Pancel", "Cipo", "Fegyver", "Fulbevalo", "Nyaklanc", "Pajzs", "Karkoto"}
	for _, name in pairs(eqSlots) do 
		local eqSlot = Instance.new("StringValue", eq)
		eqSlot.Name = name
		eqSlot.Value = (data.Equipment and data.Equipment[name]) or ""
	end

	local bankPwd = Instance.new("StringValue", stats)
	bankPwd.Name = "BankPassword"
	bankPwd.Value = data.BankPassword or "000000"

	local bankPages = Instance.new("IntValue", stats)
	bankPages.Name = "BankUnlockedPages"
	bankPages.Value = data.BankUnlockedPages or 1

	local bank = Instance.new("Folder", player)
	bank.Name = "Bank"
	for i = 1, 128 do
		local slot = Instance.new("StringValue", bank)
		slot.Name = "Slot_" .. i
		slot.Value = ""
		local amt = Instance.new("IntValue", slot)
		amt.Name = "Amount"
		amt.Value = 0

		if data.Bank and data.Bank[tostring(i)] then
			slot.Value = data.Bank[tostring(i)].Item
			amt.Value = data.Bank[tostring(i)].Amount
		end
	end

	local completedFolder = Instance.new("Folder", player)
	completedFolder.Name = "CompletedQuests"
	if data.CompletedQuests then
		for _, qName in ipairs(data.CompletedQuests) do
			local doneMark = Instance.new("StringValue")
			doneMark.Name = qName
			doneMark.Parent = completedFolder
		end
	end

	player:LoadCharacter()
end
SelectCharacter.OnServerEvent:Connect(setupPlayer)


-- ==========================================
-- 3. ÚJ KARAKTER LÉTREHOZÁSA
-- ==========================================
CreateCharacter.OnServerEvent:Connect(function(player, slotId, className)
	if slotId < 1 or slotId > 3 then return end

	local validClasses = {["GUARDIAN"] = true, ["SHADOWBLADE"] = true, ["SOULWEAVER"] = true, ["SEALER"] = true}
	if not validClasses[string.upper(className)] then return end

	local newData = {
		Class = string.upper(className),
		Stats = {Level = 1, Experience = 0, Gold = 0, StatPoints = 0, STR = 1, VIT = 1, INT = 1, DEX = 1, Mana = 100, MaxMana = 100, UnlockedPages = 1},
		Inventory = {Slot_1 = "Kezdőkard", Amount_1 = 1}, 
		Equipment = {},
		CompletedQuests = {},
		Bank = {},
		BankPassword = "000000",
		BankUnlockedPages = 1
	}

	local success, errorMessage = pcall(function() 
		playerDataStore:SetAsync("Player_" .. player.UserId .. "_Slot_" .. slotId, newData) 
	end)

	if success then
		print(player.Name .. " létrehozott egy új " .. className .. " karaktert a " .. slotId .. ". sloton!")

		-- JAVÍTÁS: Levesszük a törölt listáról, hiszen most hoztunk létre egy újat a helyére!
		if deletedSlotsCache[player.UserId] then deletedSlotsCache[player.UserId][slotId] = nil end

		setupPlayer(player, slotId)
	else
		warn("Hiba a karakter készítésekor: " .. tostring(errorMessage))
	end
end)


-- ==========================================
-- 4. ADATOK MENTÉSE AZ AKTÍV SLOTRA
-- ==========================================
local function savePlayerData(player)
	if savingPlayers[player.UserId] then return end

	local slotId = activeSlots[player.UserId]
	if not slotId then return end 

	savingPlayers[player.UserId] = true

	local data = { 
		Class = player:GetAttribute("Class") or "Ismeretlen",
		Stats = {}, Inventory = {}, Equipment = {}, CompletedQuests = {}, Bank = {} 
	}

	if player:FindFirstChild("PlayerStats") then
		for _, stat in pairs(player.PlayerStats:GetChildren()) do 
			if stat.Name == "BankPassword" then data.BankPassword = stat.Value
			elseif stat.Name == "BankUnlockedPages" then data.BankUnlockedPages = stat.Value
			else data.Stats[stat.Name] = stat.Value end
		end
	end

	if player:FindFirstChild("Inventory") then
		for _, slot in pairs(player.Inventory:GetChildren()) do 
			data.Inventory[slot.Name] = {Name = slot.Value, Amount = slot.Amount.Value}
		end
	end

	if player:FindFirstChild("Bank") then
		for i = 1, 128 do
			local slot = player.Bank:FindFirstChild("Slot_" .. i)
			if slot and slot.Value ~= "" then
				data.Bank[tostring(i)] = {Item = slot.Value, Amount = slot.Amount.Value}
			end
		end
	end

	if player:FindFirstChild("Equipment") then
		for _, slot in pairs(player.Equipment:GetChildren()) do 
			data.Equipment[slot.Name] = slot.Value 
		end
	end

	if player:FindFirstChild("CompletedQuests") then
		for _, q in pairs(player.CompletedQuests:GetChildren()) do
			table.insert(data.CompletedQuests, q.Name)
		end
	end

	local success, errorMessage = pcall(function() 
		playerDataStore:SetAsync("Player_" .. player.UserId .. "_Slot_" .. slotId, data) 
	end)

	if success then 
		print(player.Name .. " (" .. data.Class .. ") adatai elmentve a " .. slotId .. ". slotra!") 
	else 
		warn("Nem sikerült menteni! " .. tostring(errorMessage)) 
	end

	savingPlayers[player.UserId] = nil
end

game.Players.PlayerRemoving:Connect(function(player)
	deletedSlotsCache[player.UserId] = nil -- Takarítás memóriaszivárgás ellen
	savePlayerData(player)
end)

game:BindToClose(function()
	for _, player in pairs(game.Players:GetPlayers()) do 
		task.spawn(function() savePlayerData(player) end) 
	end
	task.wait(2) 
end)