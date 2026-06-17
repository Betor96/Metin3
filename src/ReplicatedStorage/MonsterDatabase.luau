local MonsterDatabase = {

	-- ==========================================
	-- SZÖRNYEK
	-- ==========================================
	["Vadkutya"] = {
		Type = "Monster",
		MaxHealth = 50,
		WalkSpeed = 14,
		AggroRange = 40,
		AttackRange = 5,
		AttackDamage = 5,
		AttackCooldown = 1.5,
		ExpReward = 150,
		GoldMin = 15,
		GoldMax = 40,
		-- Miket dobhat? (Több tárgyat is beírhatsz később)
		Drops = {
			{Item = "Kutya Fog", Chance = 45} 
		}
	},

	-- Példának egy új szörny, amit később berakhatsz:
	["Farkas"] = {
		Type = "Monster",
		MaxHealth = 120,
		WalkSpeed = 16,
		AggroRange = 50,
		AttackRange = 5,
		AttackDamage = 12,
		AttackCooldown = 1.2,
		ExpReward = 300,
		GoldMin = 30,
		GoldMax = 80,
		Drops = {
			{Item = "Kutya Fog", Chance = 20},
			{Item = "Életerő Ital", Chance = 10}
		}
	},
	["Vadfarkas"] = {
		Type = "Monster",
		MaxHealth = 120,
		WalkSpeed = 16,
		AggroRange = 50,
		AttackRange = 5,
		AttackDamage = 12,
		AttackCooldown = 1.2,
		ExpReward = 300,
		GoldMin = 30,
		GoldMax = 80,
		Drops = {
			{Item = "Kutya Fog", Chance = 20},
			{Item = "Életerő Ital", Chance = 10}
		}
	},

	-- ==========================================
	-- METIN KÖVEK
	-- ==========================================
	["Metin Kő"] = {
		Type = "Stone",
		MaxHealth = 1000,
		ExpReward = 500,
		-- Miket idézzen magából sebződéskor?
		SpawnMonster = "Vadkutya",
		SpawnCountMin = 2,
		SpawnCountMax = 4,
		-- Milyen tárgyakat szórjon szét, ha megsemmisül?
		LootPool = {"Kezdőkard"},
		MinDrops = 1,
		MaxDrops = 1
	},

	["Fekete Metin Kő"] = {
		Type = "Stone",
		MaxHealth = 5000, -- Erősebb, mint a sima
		ExpReward = 2000,
		SpawnMonster = "Farkas", -- Ebből már Farkasok jönnek!
		SpawnCountMin = 3,
		SpawnCountMax = 6,
		LootPool = {"Hosszúkard", "Vas Páncél", "Kutya Fog"}, -- Jobb cuccokat ad
		MinDrops = 2,
		MaxDrops = 4
	},
	["Harci Metin"] = {
		Type = "Stone",
		MaxHealth = 5000, -- Erősebb, mint a sima
		ExpReward = 2000,
		SpawnMonster = "Farkas", -- Ebből már Farkasok jönnek!
		SpawnCountMin = 3,
		SpawnCountMax = 6,
		LootPool = {"Hosszúkard", "Vas Páncél", "Kutya Fog"}, -- Jobb cuccokat ad
		MinDrops = 2,
		MaxDrops = 4
	},
	
	-- ÉRCEK (10 HP azt jelenti, hogy pontosan 10-szer kell megütni a csákánnyal)
	["Gyémánt Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Gyémánt Érc"},
	["Arany Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Arany Érc"},
	["Vas Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Vas Érc"},
	["Kristály Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Kristály Érc"},
	["Ruby Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Ruby Érc"},
	["Smaragd Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Smaragd Érc"},
	["Jáde Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Jáde Érc"},
	["Ametiszt Érc"] = {Type = "Ore", MaxHealth = 10, DropItem = "Ametiszt Érc"},
}

return MonsterDatabase