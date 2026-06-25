-- Fájl helye: ReplicatedStorage -> SpawnDatabase

local SpawnDatabase = {

	-- ==========================================
	-- KEZDŐ TERÜLET - KUTYÁK / FARKASOK
	-- ==========================================

	["VadkutyaZona_1"] = {
		Type = "Monster",
		Pack = {"Vadkutya", "Vadkutya", "Vadkutya"},
		MaxPacks = 6,
		RespawnTime = 15
	},

	["EhesVadkutyaZona_1"] = {
		Type = "Monster",
		Pack = {"Éhes Vadkutya", "Éhes Vadkutya", "Vadkutya"},
		MaxPacks = 5,
		RespawnTime = 18
	},

	["FarkasZona_1"] = {
		Type = "Monster",
		Pack = {"Vadfarkas", "Vadfarkas", "Vadfarkas"},
		MaxPacks = 8,
		RespawnTime = 20
	},

	["FarkasZona_2"] = {
		Type = "Monster",
		Pack = {"Farkas", "Farkas", "Vadfarkas"},
		MaxPacks = 6,
		RespawnTime = 22
	},

	["AlfaFarkasZona_1"] = {
		Type = "Monster",
		Pack = {"Alfa Farkas", "Vadfarkas", "Vadfarkas"},
		MaxPacks = 3,
		RespawnTime = 45
	},

	-- ==========================================
	-- ERDŐ / BANDITA ZÓNA
	-- ==========================================

	["BanditaZona_1"] = {
		Type = "Monster",
		Pack = {"Erdei Bandita", "Erdei Bandita", "Bandita Íjász"},
		MaxPacks = 5,
		RespawnTime = 35
	},

	["BanditaZona_2"] = {
		Type = "Monster",
		Pack = {"Bandita Íjász", "Erdei Bandita", "Erdei Bandita"},
		MaxPacks = 4,
		RespawnTime = 38
	},

	["ErdeiMedveZona_1"] = {
		Type = "Monster",
		Pack = {"Erdei Medve"},
		MaxPacks = 4,
		RespawnTime = 50
	},

	["KogolemZona_1"] = {
		Type = "Monster",
		Pack = {"Kőgólem"},
		MaxPacks = 4,
		RespawnTime = 60
	},

	["KogolemZona_2"] = {
		Type = "Monster",
		Pack = {"Kőgólem", "Kőgólem"},
		MaxPacks = 2,
		RespawnTime = 75
	},

	-- ==========================================
	-- ÁRNYÉK / MÁGIKUS ZÓNA
	-- ==========================================

	["ArnyekHarcosZona_1"] = {
		Type = "Monster",
		Pack = {"Árnyék Harcos", "Árnyék Harcos"},
		MaxPacks = 4,
		RespawnTime = 60
	},

	["ArnyekHarcosZona_2"] = {
		Type = "Monster",
		Pack = {"Árnyék Harcos", "Lélekmágus"},
		MaxPacks = 4,
		RespawnTime = 70
	},

	["LelekmagusZona_1"] = {
		Type = "Monster",
		Pack = {"Lélekmágus", "Lélekmágus"},
		MaxPacks = 4,
		RespawnTime = 70
	},

	["ElatkozottLovagZona_1"] = {
		Type = "Monster",
		Pack = {"Elátkozott Lovag"},
		MaxPacks = 3,
		RespawnTime = 90
	},

	["ElatkozottLovagZona_2"] = {
		Type = "Monster",
		Pack = {"Elátkozott Lovag", "Árnyék Harcos"},
		MaxPacks = 2,
		RespawnTime = 100
	},

	-- ==========================================
	-- SÁRKÁNY / MAGASABB ALPHA ZÓNA
	-- ==========================================

	["SarkanyivadekZona_1"] = {
		Type = "Monster",
		Pack = {"Sárkányivadék", "Sárkányivadék"},
		MaxPacks = 4,
		RespawnTime = 90
	},

	["SarkanyorZona_1"] = {
		Type = "Monster",
		Pack = {"Sárkányőr"},
		MaxPacks = 3,
		RespawnTime = 120
	},

	["SarkanyorZona_2"] = {
		Type = "Monster",
		Pack = {"Sárkányőr", "Sárkányivadék"},
		MaxPacks = 2,
		RespawnTime = 140
	},

	["OsiGolemZona_1"] = {
		Type = "Monster",
		Pack = {"Ősi Golem"},
		MaxPacks = 3,
		RespawnTime = 150
	},

	["OsiGolemZona_2"] = {
		Type = "Monster",
		Pack = {"Ősi Golem", "Kőgólem"},
		MaxPacks = 2,
		RespawnTime = 160
	},

	-- ==========================================
	-- BOSS ZÓNÁK
	-- Fontos:
	-- MaxPacks = 1 -> egyszerre csak 1 boss lehet lent.
	-- InitialDelay -> ne azonnal spawnoljon teszt indításkor.
	-- Ha a SpawnManager még nem kezeli az InitialDelay mezőt,
	-- azt külön be kell kötni.
	-- ==========================================

	["FarkaskiralyBossZona"] = {
		Type = "Monster",
		Boss = true,
		Pack = {"Farkaskirály"},
		MaxPacks = 1,
		InitialDelay = 300,
		RespawnTime = 900
	},

	["SarkanyArnyekaBossZona"] = {
		Type = "Monster",
		Boss = true,
		Pack = {"Sárkány Árnyéka"},
		MaxPacks = 1,
		InitialDelay = 600,
		RespawnTime = 1800
	},

	-- ==========================================
	-- METIN KÖVEK
	-- ==========================================

	["MetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Metin Kő"},
		MaxPacks = 4,
		RespawnTime = 120
	},

	["MetinZona_2"] = {
		Type = "MetinStone",
		Pack = {"Metin Kő"},
		MaxPacks = 3,
		RespawnTime = 120
	},

	["FarkasMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Farkas Metin"},
		MaxPacks = 3,
		RespawnTime = 180
	},

	["FeketeMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Fekete Metin Kő"},
		MaxPacks = 3,
		RespawnTime = 240
	},

	["HarciMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Harci Metin"},
		MaxPacks = 3,
		RespawnTime = 240
	},

	["HarciMetinZona_2"] = {
		Type = "MetinStone",
		Pack = {"Harci Metin"},
		MaxPacks = 2,
		RespawnTime = 260
	},

	["ArnyekMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Árnyék Metin"},
		MaxPacks = 2,
		RespawnTime = 360
	},

	["LelekMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Lélek Metin"},
		MaxPacks = 2,
		RespawnTime = 360
	},

	["SarkanyMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Sárkány Metin"},
		MaxPacks = 2,
		RespawnTime = 600
	},

	["OsiMetinZona_1"] = {
		Type = "MetinStone",
		Pack = {"Ősi Metin"},
		MaxPacks = 1,
		RespawnTime = 900
	},

	-- ==========================================
	-- ÉRCEK - VÁLTOZATLANUL HAGYVA
	-- ==========================================

	["Vas_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Vas Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Arany_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Arany Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Gyemant_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Gyémánt Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Kristály_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Kristály Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Ruby_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Ruby Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Smaragd_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Smaragd Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Jáde_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Jáde Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	["Ametiszt_Erc_Hegy"] = {
		Type = "Ore",
		Radius = 20,
		Pack = {"Ametiszt Érc"},
		SpawnRate = 5,
		MaxAlive = 3
	},

	-- IDE ÍRHATSZ BÁRMENNYI ZÓNÁT KÉSŐBB!
}

return SpawnDatabase