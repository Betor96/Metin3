-- Fájl helye: ReplicatedStorage -> ItemDatabase

local ItemDatabase = {

	-- ==========================================
	-- FEGYVEREK
	-- ==========================================
	["Kezdőkard"] = {
		Type = "Fegyver",
		Level = 1,
		MinDmg = 10,
		MaxDmg = 15,
		Price = 50,
		Description = "Egy egyszerű, ütött-kopott kard, de a kutyák ellen megteszi.",
		UpgradeTo = "Kezdőkard +1", UpgradeCost = 100, UpgradeChance = 90, ReqItem = nil, ReqCount = 0
	},
	["Szabi farka"] = {
		Type = "Fegyver",
		Level = 1,
		MinDmg = 1000,
		MaxDmg = 1500,
		Price = 50,
		Description = "Egy hatalmas fehér farok",
		UpgradeTo = nil
	},
	["Kezdőkard +1"] = {
		Type = "Fegyver",
		Level = 1,
		MinDmg = 13,
		MaxDmg = 19,
		Price = 0, -- Nem vehető boltban
		Description = "Kicsit élesebb, mint az eredeti.",
		UpgradeTo = "Kezdőkard +2", UpgradeCost = 250, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
	},
	["Hosszúkard"] = {
		Type = "Fegyver",
		Level = 5,
		MinDmg = 20,
		MaxDmg = 30,
		Price = 150,
		Description = "Erős, fémből kovácsolt fegyver.",
		UpgradeTo = nil -- Egyelőre nincs tovább
	},

	-- ==========================================
	-- PÁNCÉLOK
	-- ==========================================
	["Vadfarkas Páncél"] = {
		Type = "Páncél",
		Level = 1,
		Defense = 10,
		Price = 200,
		Description = "Alapvető páncél, felfogja a kisebb ütéseket.",
		UpgradeTo = "Vadfarkas Páncél +1", UpgradeCost = 150, UpgradeChance = 85, ReqItem = nil, ReqCount = 0
	},
	-- EZ HIÁNYZOTT! Most már ismeri a rendszer a +1-et is!
	["Vadfarkas Páncél +1"] = {
		Type = "Páncél",
		Level = 1,
		Defense = 15, -- Nagyobb a védelme!
		Price = 0,
		Description = "Megerősített Vadfarkas Páncél.",
		UpgradeTo = "Vadfarkas Páncél +2", UpgradeCost = 300, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
	},
	["Vas Páncél"] = {
		Type = "Páncél",
		Level = 10,
		Defense = 25,
		Price = 500,
		Description = "Masszív, nehéz páncél profi harcosoknak.",
		UpgradeTo = "Vas Páncél +1", UpgradeCost = 1000, UpgradeChance = 80, ReqItem = nil, ReqCount = 0
	},
	["Vas Páncél +1"] = {
		Type = "Páncél",
		Level = 10,
		Defense = 32,
		Price = 0,
		Description = "Masszív, nehéz páncél profi harcosoknak. (+1)",
		UpgradeTo = nil
	},

	-- ==========================================
	-- FOGYÓESZKÖZÖK (POTIONOK)
	-- ==========================================
	["Életerő Ital"] = {
		Type = "Fogyóeszköz",
		HealAmount = 50,
		Price = 20,
		MaxStack = 200,
		Description = "Azonnal visszatölt 50 Életerőt."
	},
	["Mana Ital"] = {
		Type = "Fogyóeszköz",
		HealAmount = 50,
		Price = 20,
		MaxStack = 200,
		Description = "Azonnal visszatölt 50 Manát."
	},

	-- ==========================================
	-- FEJLESZTÉSI ANYAGOK (CRAFTING)
	-- ==========================================
	["Kutya Fog"] = {
		Type = "Alapanyag",
		Price = 5,
		MaxStack = 50,
		Description = "A Kovácsnak van rá szüksége a fejlesztésekhez."
	}
}

return ItemDatabase