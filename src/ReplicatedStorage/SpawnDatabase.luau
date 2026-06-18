-- Fájl helye: ReplicatedStorage -> SpawnDatabase

local SpawnDatabase = {

	-- PÉLDA 1: Farkasok zónája
	["FarkasZona_1"] = {
		Type = "Monster",
		-- Egy csoport (Pack) tartalma: 3 db Vadfarkas
		Pack = {"Vadfarkas", "Vadfarkas", "Vadfarkas"}, 
		MaxPacks = 8,      -- Maximum 8 db csoport lehet egyszerre ebben a zónában
		RespawnTime = 20   -- Ha egy csoport meghal, 20 másodperc múlva spawnol a helyére új
	},

	-- PÉLDA 2: Kezdő Metinkő zónája
	["MetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Harci Metin"}, -- Csak a kő neve (a kő egy 1 fős "csoport")
		MaxPacks = 3,       -- Maximum 3 kő lehet a zónában
		RespawnTime = 120   -- Ha egy követ betörnek, 2 perc (120 mp) múlva esik le egy új
	},

	-- PÉLDA EGY ÉRC ZÓNÁRA A PÁLYÁN:
	["Vas_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Vas Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Arany_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Arany Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Gyemant_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Gyémánt Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Kristály_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Kristály Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Ruby_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Ruby Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Smaragd_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Smaragd Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Jáde_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Jáde Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	["Ametiszt_Erc_Hegy"] = {
		Type = "Ore", -- Fontos, hogy tudd, ez egy érc
		Radius = 20,
		Pack = {"Ametiszt Érc"}, 
		SpawnRate = 5, -- TESZT: 5 másodperc alatt újraéled!
		MaxAlive = 3 
	},
	-- IDE ÍRHATSZ BÁRMENNYI ZÓNÁT KÉSŐBB!
}

return SpawnDatabase