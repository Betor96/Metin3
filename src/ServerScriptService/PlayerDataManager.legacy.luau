-- Fájl helye: ServerScriptService -> PlayerDataManager

local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerSaveData_V2")

local savingPlayers = {} 

local function setupPlayer(player)
	-- [A] LEADERSTATS (Jobb felső sarok a Tab menühöz)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local leaderLevel = Instance.new("IntValue")
	leaderLevel.Name = "Level"
	leaderLevel.Value = 1
	leaderLevel.Parent = leaderstats

	-- [B] MAPPÁK ÉS ALAPÉRTÉKEK LÉTREHOZÁSA
	local stats = Instance.new("Folder")
	stats.Name = "PlayerStats"
	stats.Parent = player

	Instance.new("IntValue", stats).Name = "Experience"
	Instance.new("IntValue", stats).Name = "Gold"

	local level = Instance.new("IntValue", stats)
	level.Name = "Level"
	level.Value = 1

	Instance.new("IntValue", stats).Name = "StatPoints"

	local str = Instance.new("IntValue", stats) str.Name = "STR" str.Value = 1
	local vit = Instance.new("IntValue", stats) vit.Name = "VIT" vit.Value = 1
	local int = Instance.new("IntValue", stats) int.Name = "INT" int.Value = 1
	local dex = Instance.new("IntValue", stats) dex.Name = "DEX" dex.Value = 1

	local mana = Instance.new("IntValue", stats) mana.Name = "Mana" mana.Value = 100
	local maxMana = Instance.new("IntValue", stats) maxMana.Name = "MaxMana" maxMana.Value = 100

	local inv = Instance.new("Folder", player)
	inv.Name = "Inventory"
	for i = 1, 8 do Instance.new("StringValue", inv).Name = "Slot_" .. i end

	local eq = Instance.new("Folder", player)
	eq.Name = "Equipment"
	local eqSlots = {"Sapka", "Pancel", "Cipo", "Fegyver", "Fulbevalo", "Nyaklanc", "Pajzs", "Karkoto"}
	for _, name in pairs(eqSlots) do Instance.new("StringValue", eq).Name = name end

	local hotbar = Instance.new("Folder", player)
	hotbar.Name = "Hotbar"
	for i = 1, 8 do Instance.new("StringValue", hotbar).Name = "Hotbar_" .. i end

	-- [C] ADATOK BETÖLTÉSE
	local success, data = pcall(function() 
		return playerDataStore:GetAsync("Player_" .. player.UserId) 
	end)

	if success and data then
		if data.Stats then
			for statName, statValue in pairs(data.Stats) do
				if player.PlayerStats:FindFirstChild(statName) then
					player.PlayerStats[statName].Value = statValue
				end
			end
			leaderLevel.Value = level.Value -- Szinkronizáljuk a Leaderstat-ot
		end
		if data.Inventory then
			for name, val in pairs(data.Inventory) do 
				if player.Inventory:FindFirstChild(name) then player.Inventory[name].Value = val end 
			end
		end
		if data.Equipment then
			for name, val in pairs(data.Equipment) do 
				if player.Equipment:FindFirstChild(name) then player.Equipment[name].Value = val end 
			end
		end
		print(player.Name .. " adatai sikeresen betöltve!")
	else
		-- [D] ÚJ JÁTÉKOS: Itt adjuk a Kezdőkardot!
		print(player.Name .. " új játékos, alapértékek beállítva.")
		inv.Slot_1.Value = "Kezdőkard"
	end
end

local function savePlayerData(player)
	if savingPlayers[player.UserId] then return end
	savingPlayers[player.UserId] = true

	local data = { Stats = {}, Inventory = {}, Equipment = {} }

	if player:FindFirstChild("PlayerStats") then
		for _, stat in pairs(player.PlayerStats:GetChildren()) do
			data.Stats[stat.Name] = stat.Value
		end
	end
	if player:FindFirstChild("Inventory") then
		for _, slot in pairs(player.Inventory:GetChildren()) do data.Inventory[slot.Name] = slot.Value end
	end
	if player:FindFirstChild("Equipment") then
		for _, slot in pairs(player.Equipment:GetChildren()) do data.Equipment[slot.Name] = slot.Value end
	end

	local success, errorMessage = pcall(function() 
		playerDataStore:SetAsync("Player_" .. player.UserId, data) 
	end)

	if success then
		print(player.Name .. " adatai elmentve!")
	else
		warn("Nem sikerült menteni " .. player.Name .. " adatait! Hiba: " .. tostring(errorMessage))
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