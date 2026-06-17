-- Fájl helye: ServerScriptService -> PlayerDataManager

local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerSaveData_V3") -- V3-ra váltva a tiszta indulásért

local savingPlayers = {} 

local function setupPlayer(player)
	-- ==========================================
	-- 1. ADATOK LEKÉRDEZÉSE A FELHŐBŐL
	-- Ezt az ELEJÉN kell csinálni, hogy tudjuk, van-e mentés!
	-- ==========================================
	local success, data = pcall(function() return playerDataStore:GetAsync("Player_" .. player.UserId) end)

	-- Ha nincs data (új játékos), csinálunk egy üreset, hogy ne fagyjon le a kód!
	if not success or not data then
		data = {
			Stats = {},
			Inventory = {},
			Equipment = {},
			CompletedQuests = {},
			Bank = {},
			BankPassword = "000000",
			BankUnlockedPages = 1
		}
	end

	-- ==========================================
	-- 2. ALAPVETŐ MAPPÁK ÉS STATOK LÉTREHOZÁSA
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

	-- Bónusz statisztikák
	local bonusStats = {"Defense", "StrongVsMetin", "StrongVsMonster", "StrongVsPlayer", "LifeSteal", "CritChance", "DoubleDrop", "DoubleGold", "AttackSpeed", "MovementSpeed", "DodgeChance"}
	for _, bStat in pairs(bonusStats) do
		local val = Instance.new("IntValue", stats)
		val.Name = bStat
		val.Value = (data.Stats and data.Stats[bStat]) or 0
	end

	-- ==========================================
	-- 3. TÁSKA (128 REKESZ)
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

	-- Új játékosnak kezdőkard adása (ha teljesen üres a mentés)
	if not success then
		print(player.Name .. " új játékos, alapértékek beállítva.")
		inv.Slot_1.Value = "Kezdőkard"
		inv.Slot_1.Amount.Value = 1
	else
		print(player.Name .. " adatai sikeresen betöltve!")
	end

	-- ==========================================
	-- 4. FELSZERELÉS ÉS HOTBAR
	-- ==========================================
	local eq = Instance.new("Folder", player)
	eq.Name = "Equipment"
	local eqSlots = {"Sapka", "Pancel", "Cipo", "Fegyver", "Fulbevalo", "Nyaklanc", "Pajzs", "Karkoto"}
	for _, name in pairs(eqSlots) do 
		local eqSlot = Instance.new("StringValue", eq)
		eqSlot.Name = name
		eqSlot.Value = (data.Equipment and data.Equipment[name]) or ""
	end

	local hotbar = Instance.new("Folder", player)
	hotbar.Name = "Hotbar"
	for i = 1, 8 do 
		Instance.new("StringValue", hotbar).Name = "Hotbar_" .. i 
		-- Ha mentettük volna a hotbart, ide jönne a betöltés
	end

	-- ==========================================
	-- 5. BANK (RAKTÁR) RENDSZER
	-- ==========================================
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

	-- ==========================================
	-- 6. KÉSZ KÜLDETÉSEK
	-- ==========================================
	local completedFolder = Instance.new("Folder", player)
	completedFolder.Name = "CompletedQuests"

	if data.CompletedQuests then
		for _, qName in ipairs(data.CompletedQuests) do
			local doneMark = Instance.new("StringValue")
			doneMark.Name = qName
			doneMark.Parent = completedFolder
		end
	end
end

-- ==========================================
-- ADATOK MENTÉSE
-- ==========================================
local function savePlayerData(player)
	if savingPlayers[player.UserId] then return end
	savingPlayers[player.UserId] = true

	local data = { Stats = {}, Inventory = {}, Equipment = {}, CompletedQuests = {}, Bank = {} }

	-- Statok
	if player:FindFirstChild("PlayerStats") then
		for _, stat in pairs(player.PlayerStats:GetChildren()) do 
			if stat.Name == "BankPassword" then
				data.BankPassword = stat.Value
			elseif stat.Name == "BankUnlockedPages" then
				data.BankUnlockedPages = stat.Value
			else
				data.Stats[stat.Name] = stat.Value 
			end
		end
	end

	-- Táska
	if player:FindFirstChild("Inventory") then
		for _, slot in pairs(player.Inventory:GetChildren()) do 
			data.Inventory[slot.Name] = {Name = slot.Value, Amount = slot.Amount.Value}
		end
	end

	-- Bank
	if player:FindFirstChild("Bank") then
		for i = 1, 128 do
			local slot = player.Bank:FindFirstChild("Slot_" .. i)
			if slot and slot.Value ~= "" then
				data.Bank[tostring(i)] = {Item = slot.Value, Amount = slot.Amount.Value}
			end
		end
	end

	-- Felszerelés
	if player:FindFirstChild("Equipment") then
		for _, slot in pairs(player.Equipment:GetChildren()) do 
			data.Equipment[slot.Name] = slot.Value 
		end
	end

	-- Küldetések
	if player:FindFirstChild("CompletedQuests") then
		for _, q in pairs(player.CompletedQuests:GetChildren()) do
			table.insert(data.CompletedQuests, q.Name)
		end
	end

	-- Mentés végrehajtása
	local success, errorMessage = pcall(function() playerDataStore:SetAsync("Player_" .. player.UserId, data) end)
	if success then 
		print(player.Name .. " adatai elmentve!") 
	else 
		warn("Nem sikerült menteni! " .. tostring(errorMessage)) 
	end

	savingPlayers[player.UserId] = nil
end

game.Players.PlayerAdded:Connect(setupPlayer)
game.Players.PlayerRemoving:Connect(savePlayerData)

game:BindToClose(function()
	for _, player in pairs(game.Players:GetPlayers()) do 
		task.spawn(function() savePlayerData(player) end) 
	end
	task.wait(2) 
end)