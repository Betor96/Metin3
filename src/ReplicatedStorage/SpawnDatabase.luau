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
	}

	-- IDE ÍRHATSZ BÁRMENNYI ZÓNÁT KÉSŐBB!
}

return SpawnDatabase