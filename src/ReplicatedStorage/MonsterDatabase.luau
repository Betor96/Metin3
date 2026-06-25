local MonsterDatabase = {

	-- ==========================================
	-- SZÖRNYEK - KEZDŐ TERÜLET
	-- ==========================================

	["Vadkutya"] = {
		Type = "Monster",
		MaxHealth = 50,
		WalkSpeed = 14,
		AggroRange = 40,
		AttackRange = 5,
		AttackDamage = 5,
		AttackCooldown = 1.5,
		ExpReward = 60,
		GoldMin = 10,
		GoldMax = 25,
		Drops = {
			{Item = "Kutya Fog", Chance = 45},
			{Item = "Életerő Ital", Chance = 8},
			{Item = "Kezdőkard", Chance = 3},
			{Item = "Bőr Sisak", Chance = 2},
		}
	},

	["Éhes Vadkutya"] = {
		Type = "Monster",
		MaxHealth = 70,
		WalkSpeed = 15,
		AggroRange = 42,
		AttackRange = 5,
		AttackDamage = 7,
		AttackCooldown = 1.45,
		ExpReward = 85,
		GoldMin = 15,
		GoldMax = 35,
		Drops = {
			{Item = "Kutya Fog", Chance = 55},
			{Item = "Életerő Ital", Chance = 10},
			{Item = "Bőrcipő", Chance = 3},
			{Item = "Bőr Karkötő", Chance = 2},
		}
	},

	["Farkas"] = {
		Type = "Monster",
		MaxHealth = 120,
		WalkSpeed = 16,
		AggroRange = 50,
		AttackRange = 5,
		AttackDamage = 12,
		AttackCooldown = 1.2,
		ExpReward = 130,
		GoldMin = 25,
		GoldMax = 60,
		Drops = {
			{Item = "Kutya Fog", Chance = 25},
			{Item = "Farkasbőr", Chance = 40},
			{Item = "Életerő Ital", Chance = 12},
			{Item = "Kezdőkard", Chance = 4},
			{Item = "Vadfarkas Páncél", Chance = 3},
			{Item = "Réz Nyaklánc", Chance = 2},
		}
	},

	["Vadfarkas"] = {
		Type = "Monster",
		MaxHealth = 160,
		WalkSpeed = 16,
		AggroRange = 55,
		AttackRange = 5,
		AttackDamage = 15,
		AttackCooldown = 1.15,
		ExpReward = 170,
		GoldMin = 35,
		GoldMax = 75,
		Drops = {
			{Item = "Farkasbőr", Chance = 50},
			{Item = "Kutya Fog", Chance = 20},
			{Item = "Életerő Ital", Chance = 10},
			{Item = "Hosszúkard", Chance = 4},
			{Item = "Vadfarkas Páncél", Chance = 4},
			{Item = "Fa Pajzs", Chance = 3},
			{Item = "Ezüst Fülbevaló", Chance = 2},
		}
	},

	["Alfa Farkas"] = {
		Type = "Monster",
		MaxHealth = 320,
		WalkSpeed = 17,
		AggroRange = 60,
		AttackRange = 5,
		AttackDamage = 24,
		AttackCooldown = 1.1,
		ExpReward = 320,
		GoldMin = 70,
		GoldMax = 130,
		Drops = {
			{Item = "Farkasbőr", Chance = 65},
			{Item = "Nagy Életerő Ital", Chance = 10},
			{Item = "Hosszúkard", Chance = 6},
			{Item = "Vadfarkas Páncél", Chance = 5},
			{Item = "Farkasjáró Csizma", Chance = 4},
			{Item = "Vadász Nyaklánc", Chance = 3},
			{Item = "Kezdőkard +1", Chance = 2},
		}
	},

	-- ==========================================
	-- SZÖRNYEK - ERDŐ / KÖZÉPSŐ KEZDŐ ZÓNA
	-- ==========================================

	["Erdei Bandita"] = {
		Type = "Monster",
		MaxHealth = 280,
		WalkSpeed = 15,
		AggroRange = 50,
		AttackRange = 5,
		AttackDamage = 22,
		AttackCooldown = 1.3,
		ExpReward = 280,
		GoldMin = 80,
		GoldMax = 150,
		Drops = {
			{Item = "Törött Penge", Chance = 35},
			{Item = "Életerő Ital", Chance = 12},
			{Item = "Hosszúkard", Chance = 6},
			{Item = "Harcos Sisak", Chance = 4},
			{Item = "Vas Páncél", Chance = 3},
			{Item = "Harcos Fülbevaló", Chance = 2},
		}
	},

	["Bandita Íjász"] = {
		Type = "Monster",
		MaxHealth = 230,
		WalkSpeed = 15,
		AggroRange = 55,
		AttackRange = 6,
		AttackDamage = 20,
		AttackCooldown = 1.4,
		ExpReward = 260,
		GoldMin = 75,
		GoldMax = 145,
		Drops = {
			{Item = "Törött Penge", Chance = 28},
			{Item = "Mana Ital", Chance = 10},
			{Item = "Árnyék Tőr", Chance = 3},
			{Item = "Árnyék Csuklya", Chance = 3},
			{Item = "Bőrcipő +1", Chance = 2},
			{Item = "Ügyesség itala", Chance = 6},
		}
	},

	["Erdei Medve"] = {
		Type = "Monster",
		MaxHealth = 520,
		WalkSpeed = 12,
		AggroRange = 45,
		AttackRange = 5,
		AttackDamage = 35,
		AttackCooldown = 1.6,
		ExpReward = 500,
		GoldMin = 120,
		GoldMax = 220,
		Drops = {
			{Item = "Farkasbőr", Chance = 30},
			{Item = "Nagy Életerő Ital", Chance = 12},
			{Item = "Vas Páncél", Chance = 5},
			{Item = "Vas Pajzs", Chance = 4},
			{Item = "Őrző Pallos", Chance = 3},
			{Item = "Bőr Karkötő +1", Chance = 2},
		}
	},

	["Kőgólem"] = {
		Type = "Monster",
		MaxHealth = 700,
		WalkSpeed = 10,
		AggroRange = 45,
		AttackRange = 5,
		AttackDamage = 42,
		AttackCooldown = 1.8,
		ExpReward = 650,
		GoldMin = 150,
		GoldMax = 280,
		Drops = {
			{Item = "Metin Szilánk", Chance = 35},
			{Item = "Vas Érc", Chance = 20},
			{Item = "Metinromboló Kard", Chance = 4},
			{Item = "Metin Pajzs", Chance = 4},
			{Item = "Vadász Karkötő", Chance = 3},
			{Item = "Metinromboló Ital", Chance = 8},
		}
	},

	-- ==========================================
	-- SZÖRNYEK - ÁRNYÉK / MÁGIKUS ZÓNA
	-- ==========================================

	["Árnyék Harcos"] = {
		Type = "Monster",
		MaxHealth = 850,
		WalkSpeed = 15,
		AggroRange = 55,
		AttackRange = 5,
		AttackDamage = 55,
		AttackCooldown = 1.25,
		ExpReward = 850,
		GoldMin = 200,
		GoldMax = 350,
		Drops = {
			{Item = "Árnyékpor", Chance = 35},
			{Item = "Nagy Életerő Ital", Chance = 10},
			{Item = "Árnyék Tőr", Chance = 5},
			{Item = "Árnyék Kabát", Chance = 4},
			{Item = "Árny Fülbevaló", Chance = 4},
			{Item = "Árnylépő Csizma", Chance = 3},
			{Item = "Kritikus Ital", Chance = 6},
		}
	},

	["Lélekmágus"] = {
		Type = "Monster",
		MaxHealth = 760,
		WalkSpeed = 13,
		AggroRange = 60,
		AttackRange = 6,
		AttackDamage = 60,
		AttackCooldown = 1.6,
		ExpReward = 900,
		GoldMin = 210,
		GoldMax = 370,
		Drops = {
			{Item = "Árnyékpor", Chance = 35},
			{Item = "Nagy Mana Ital", Chance = 12},
			{Item = "Lélekbot", Chance = 5},
			{Item = "Lélek Köntös", Chance = 4},
			{Item = "Bölcs Csuklya", Chance = 4},
			{Item = "Lélek Fülbevaló", Chance = 4},
			{Item = "Hold Nyaklánc", Chance = 3},
		}
	},

	["Elátkozott Lovag"] = {
		Type = "Monster",
		MaxHealth = 1200,
		WalkSpeed = 13,
		AggroRange = 55,
		AttackRange = 5,
		AttackDamage = 75,
		AttackCooldown = 1.45,
		ExpReward = 1200,
		GoldMin = 300,
		GoldMax = 500,
		Drops = {
			{Item = "Árnyékpor", Chance = 25},
			{Item = "Fénykristály", Chance = 18},
			{Item = "Vérivó Kard", Chance = 4},
			{Item = "Őrző Lemezvért", Chance = 4},
			{Item = "Vér Karkötő", Chance = 3},
			{Item = "Vas Pajzs +1", Chance = 2},
			{Item = "Nagy Életerő Ital", Chance = 12},
		}
	},

	-- ==========================================
	-- SZÖRNYEK - MAGASABB ALPHA TESZT ZÓNA
	-- ==========================================

	["Sárkányivadék"] = {
		Type = "Monster",
		MaxHealth = 1600,
		WalkSpeed = 14,
		AggroRange = 60,
		AttackRange = 5,
		AttackDamage = 95,
		AttackCooldown = 1.35,
		ExpReward = 1700,
		GoldMin = 450,
		GoldMax = 750,
		Drops = {
			{Item = "Sárkány Pikkely", Chance = 35},
			{Item = "Fénykristály", Chance = 20},
			{Item = "Sárkány Páncél", Chance = 4},
			{Item = "Metinromboló Kard +1", Chance = 2},
			{Item = "Lélekbot +1", Chance = 2},
			{Item = "Árnyék Tőr +1", Chance = 2},
			{Item = "Nagy Életerő Ital", Chance = 14},
		}
	},

	["Sárkányőr"] = {
		Type = "Monster",
		MaxHealth = 2300,
		WalkSpeed = 12,
		AggroRange = 60,
		AttackRange = 5,
		AttackDamage = 120,
		AttackCooldown = 1.5,
		ExpReward = 2400,
		GoldMin = 650,
		GoldMax = 1000,
		Drops = {
			{Item = "Sárkány Pikkely", Chance = 45},
			{Item = "Fénykristály", Chance = 25},
			{Item = "Sárkány Páncél", Chance = 5},
			{Item = "Párbajpenge", Chance = 3},
			{Item = "Párbaj Pajzs", Chance = 3},
			{Item = "Párbaj Karkötő", Chance = 3},
			{Item = "Nagy Mana Ital", Chance = 12},
		}
	},

	["Ősi Golem"] = {
		Type = "Monster",
		MaxHealth = 3000,
		WalkSpeed = 9,
		AggroRange = 50,
		AttackRange = 5,
		AttackDamage = 135,
		AttackCooldown = 1.8,
		ExpReward = 3000,
		GoldMin = 800,
		GoldMax = 1300,
		Drops = {
			{Item = "Metin Szilánk", Chance = 45},
			{Item = "Fénykristály", Chance = 25},
			{Item = "Gyémánt Érc", Chance = 8},
			{Item = "Ruby Érc", Chance = 8},
			{Item = "Metin Pajzs +1", Chance = 3},
			{Item = "Metinromboló Kard +1", Chance = 3},
			{Item = "Metinromboló Ital", Chance = 10},
		}
	},

	-- ==========================================
	-- BOSS / MINI BOSS ALPHA TESZTHEZ
	-- ==========================================

	["Farkaskirály"] = {
		Type = "Monster",
		MaxHealth = 2500,
		WalkSpeed = 15,
		AggroRange = 70,
		AttackRange = 6,
		AttackDamage = 95,
		AttackCooldown = 1.35,
		ExpReward = 3500,
		GoldMin = 1000,
		GoldMax = 1800,
		Drops = {
			{Item = "Farkasbőr", Chance = 100},
			{Item = "Fénykristály", Chance = 25},
			{Item = "Őrző Pallos", Chance = 8},
			{Item = "Árnyék Tőr", Chance = 8},
			{Item = "Lélekbot", Chance = 8},
			{Item = "Vadfarkas Páncél +2", Chance = 5},
			{Item = "Farkasjáró Csizma +1", Chance = 4},
			{Item = "Nagy Életerő Ital", Chance = 25},
		}
	},

	["Sárkány Árnyéka"] = {
		Type = "Monster",
		MaxHealth = 6000,
		WalkSpeed = 13,
		AggroRange = 80,
		AttackRange = 7,
		AttackDamage = 180,
		AttackCooldown = 1.6,
		ExpReward = 8500,
		GoldMin = 2500,
		GoldMax = 4500,
		Drops = {
			{Item = "Sárkány Pikkely", Chance = 100},
			{Item = "Fénykristály", Chance = 40},
			{Item = "Sárkány Páncél", Chance = 10},
			{Item = "Párbajpenge", Chance = 6},
			{Item = "Párbaj Pajzs", Chance = 6},
			{Item = "Vérivó Kard +1", Chance = 4},
			{Item = "Lélek Köntös +1", Chance = 4},
			{Item = "Árnyék Kabát +1", Chance = 4},
			{Item = "Szivárvány Kristály", Chance = 3},
		}
	},

	-- ==========================================
	-- METIN KÖVEK
	-- ==========================================

	["Metin Kő"] = {
		Type = "Stone",
		MaxHealth = 1000,
		ExpReward = 500,
		SpawnMonster = "Vadkutya",
		SpawnCountMin = 2,
		SpawnCountMax = 4,
		LootPool = {"Kezdőkard", "Bőr Sisak", "Bőrcipő", "Kutya Fog", "Életerő Ital"},
		MinDrops = 1,
		MaxDrops = 2
	},

	["Fekete Metin Kő"] = {
		Type = "Stone",
		MaxHealth = 5000,
		ExpReward = 2000,
		SpawnMonster = "Farkas",
		SpawnCountMin = 3,
		SpawnCountMax = 6,
		LootPool = {"Hosszúkard", "Vas Páncél", "Fa Pajzs", "Farkasjáró Csizma", "Farkasbőr", "Kutya Fog"},
		MinDrops = 2,
		MaxDrops = 4
	},

	["Harci Metin"] = {
		Type = "Stone",
		MaxHealth = 6500,
		ExpReward = 2500,
		SpawnMonster = "Erdei Bandita",
		SpawnCountMin = 3,
		SpawnCountMax = 6,
		LootPool = {"Hosszúkard +1", "Vas Páncél", "Harcos Sisak", "Harcos Fülbevaló", "Törött Penge", "Nagy Életerő Ital"},
		MinDrops = 2,
		MaxDrops = 4
	},

	["Farkas Metin"] = {
		Type = "Stone",
		MaxHealth = 3500,
		ExpReward = 1500,
		SpawnMonster = "Vadfarkas",
		SpawnCountMin = 3,
		SpawnCountMax = 5,
		LootPool = {"Vadfarkas Páncél", "Farkasjáró Csizma", "Vadász Nyaklánc", "Vadász Karkötő", "Farkasbőr", "Életerő Ital"},
		MinDrops = 2,
		MaxDrops = 3
	},

	["Árnyék Metin"] = {
		Type = "Stone",
		MaxHealth = 9000,
		ExpReward = 4000,
		SpawnMonster = "Árnyék Harcos",
		SpawnCountMin = 4,
		SpawnCountMax = 7,
		LootPool = {"Árnyék Tőr", "Árnyék Kabát", "Árnyék Csuklya", "Árny Fülbevaló", "Árnylépő Csizma", "Árnyékpor", "Kritikus Ital"},
		MinDrops = 3,
		MaxDrops = 5
	},

	["Lélek Metin"] = {
		Type = "Stone",
		MaxHealth = 8500,
		ExpReward = 4000,
		SpawnMonster = "Lélekmágus",
		SpawnCountMin = 4,
		SpawnCountMax = 7,
		LootPool = {"Lélekbot", "Lélek Köntös", "Bölcs Csuklya", "Lélek Fülbevaló", "Hold Nyaklánc", "Árnyékpor", "Nagy Mana Ital"},
		MinDrops = 3,
		MaxDrops = 5
	},

	["Sárkány Metin"] = {
		Type = "Stone",
		MaxHealth = 15000,
		ExpReward = 8500,
		SpawnMonster = "Sárkányivadék",
		SpawnCountMin = 5,
		SpawnCountMax = 8,
		LootPool = {"Sárkány Páncél", "Sárkány Pikkely", "Fénykristály", "Párbajpenge", "Párbaj Pajzs", "Vérivó Kard", "Szivárvány Kristály"},
		MinDrops = 4,
		MaxDrops = 6
	},

	["Ősi Metin"] = {
		Type = "Stone",
		MaxHealth = 22000,
		ExpReward = 12000,
		SpawnMonster = "Ősi Golem",
		SpawnCountMin = 5,
		SpawnCountMax = 9,
		LootPool = {"Metinromboló Kard +1", "Metin Pajzs +1", "Sárkány Páncél", "Gyémánt Érc", "Ruby Érc", "Smaragd Érc", "Szivárvány Kristály"},
		MinDrops = 4,
		MaxDrops = 7
	},

	-- ==========================================
	-- ÉRCEK - VÁLTOZATLANUL HAGYVA
	-- ==========================================

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