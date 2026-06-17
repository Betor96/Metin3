local ItemDatabase = {
	-- FEGYVEREK
	["Kezdőkard"] = {
		Type = "Fegyver", Level = 1, MinDmg = 10, MaxDmg = 15, Price = 50,
		
		AttackSpeed = 5, -- +5% támadási sebesség
		UpgradeTo = "Kezdőkard +1", UpgradeCost = 100, UpgradeChance = 90
	},
	["Kezdőkard +1"] = {
		Type = "Fegyver", Level = 1, MinDmg = 13, MaxDmg = 19, Price = 150,
		AttackSpeed = 8,
		UpgradeTo = "Kezdőkard +2", UpgradeCost = 250, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
	},
	["Vámpír Kard"] = {
		Type = "Fegyver", Level = 10, MinDmg = 20, MaxDmg = 30, Price = 1000,
		LifeSteal = 10, -- 10% Életvarázs
		CritChance = 5  -- 5% Kritikus esély
	},
	["Hosszúkard"] = {
		Type = "Fegyver", Level = 5, MinDmg = 15, MaxDmg = 22, Price = 300,
		AttackSpeed = 5,
		UpgradeTo = "Hosszúkard +1", UpgradeCost = 500, UpgradeChance = 80
	},
	-- PÁNCÉLOK
	["Vadfarkas Páncél"] = {
		Type = "Páncél", Level = 1, Defense = 10, Price = 200,
		UpgradeTo = "Vadfarkas Páncél +1", UpgradeCost = 150, UpgradeChance = 85
	},
	["Vadfarkas Páncél +1"] = {
		Type = "Páncél", Level = 1, Defense = 15, Price = 150, MaxHealth = 50, -- Ad 50 extra HP-t is!
		UpgradeTo = "Vadfarkas Páncél +2", UpgradeCost = 300, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
	},
	["Vas Páncél"] = {
		Type = "Páncél", Level = 5, Defense = 20, Price = 500,
		UpgradeTo = "Vas Páncél +1", UpgradeCost = 400, UpgradeChance = 80
	},
	["Vadfarkas Páncél +2"] = {
		Type = "Páncél", Level = 1, Defense = 22, Price = 0, MaxHealth = 100,
		-- Itt nincs UpgradeTo, mert ez a maximum szint!
	},
	
	["Jézus Páncél"] = {
		Type = "Páncél",
		Level = 1,
		Price = 1, -- Teszt tárgy, nem kerül pénzbe

		-- ALAP STATOK
		Defense = 1000,       -- +10 Páncélzat
		MaxHealth = 100,     -- +10 Életerő
		MaxMana = 100,       -- +10 Mana

		-- BÓNUSZ STATOK
		StrongVsMetin = 1000,   -- +10% Metinkövek ellen
		StrongVsMonster = 100, -- +10% Szörnyek ellen
		StrongVsPlayer = 0,  -- +10% Ember ellen
		LifeSteal = 0,       -- 10% Életvarázs
		CritChance = 0,      -- 10% Kritikus találat
		DoubleDrop = 100,      -- 10% Dupla Tárgy
		DoubleGold = 100,      -- 10% Dupla Pénz
		AttackSpeed = 0,     -- +10% Támadási sebesség
		MovementSpeed = 0,   -- +10% Mozgási sebesség
		DodgeChance = 0,     -- 10% Kitérés esély

		Description = "Egy isteni teszt páncél, ami minden létező statisztikát növel!"
	},

	-- ÚJ: KIEGÉSZÍTŐK
	["Bőrcipő"] = {
		Type = "Cipő", Level = 1, Price = 100,
		MovementSpeed = 100, -- +15% Mozgási sebesség
		DodgeChance = 5,    -- 5% Kitérés
		Description = "Könnyű cipő, gyorsabb futást biztosít."
	},
	["Réz Nyaklánc"] = {
		Type = "Nyaklánc", Level = 1, Price = 150,
		AttackSpeed = 10,
		StrongVsMonster = 10, -- +10% sebzés szörnyek ellen
		MaxMana = 50,
		Description = "Növeli a támadási sebességet és a szörnyek elleni erőt."
	},

	-- ITALOK ÉS ALAPANYAGOK (Ezek maradnak ahogy voltak)
	["Életerő Ital"] = { Type = "Fogyóeszköz", HealAmount = 50, Price = 20, MaxStack = 200 },
	["Mana Ital"] = { Type = "Fogyóeszköz", HealAmount = 50, Price = 20, MaxStack = 200 },
	["Kutya Fog"] = { Type = "Alapanyag", Price = 5, MaxStack = 50 },
	["Zöld Ital"] = { 
		Type = "Fogyóeszköz", 
		Price = 100, 
		MaxStack = 50,
		Effect = "MovementSpeed", -- Ezt fogja megnövelni
		Value = 50,               -- +50 Sebesség
		Duration = 10             -- 10 másodperc (direkt rövidre állítva a teszthez!)
	},
	["Ügyesség itala"] = { 
		Type = "Fogyóeszköz", 
		Price = 100, 
		MaxStack = 50,
		Effect = "AttackSpeed", -- Ezt fogja megnövelni
		Value = 50,               -- +50 Sebesség
		Duration = 10             -- 10 másodperc (direkt rövidre állítva a teszthez!)
	},
	
	-- ==========================================
	-- ÚJ: BÁNYÁSZAT (ÉRCEK ÉS CSÁKÁNYOK)
	-- ==========================================
	["Gyémánt Érc"] = {Type = "Érc", MaxStack = 250, Price = 500, Description = "Értékes bányászott érc."},
	["Arany Érc"] = {Type = "Érc", MaxStack = 250, Price = 400, Description = "Értékes bányászott érc."},
	["Vas Érc"] = {Type = "Érc", MaxStack = 250, Price = 100, Description = "Alapvető bányászott érc."},
	["Kristály Érc"] = {Type = "Érc", MaxStack = 250, Price = 300, Description = "Értékes bányászott érc."},
	["Ruby Érc"] = {Type = "Érc", MaxStack = 250, Price = 600, Description = "Értékes bányászott érc."},
	["Smaragd Érc"] = {Type = "Érc", MaxStack = 250, Price = 650, Description = "Értékes bányászott érc."},
	["Jáde Érc"] = {Type = "Érc", MaxStack = 250, Price = 550, Description = "Értékes bányászott érc."},
	["Ametiszt Érc"] = {Type = "Érc", MaxStack = 250, Price = 450, Description = "Értékes bányászott érc."},
	["Szivárvány Kristály"] = {Type = "Érc", MaxStack = 250, Price = 5000, Description = "Különleges és rendkívül ritka mágikus kristály."},

	-- Csákányok (A fegyver helyére megy, de külön jelöléssel: IsPickaxe)
	["Csákány+0"] = {Type = "Fegyver", Level = 1, MinDmg = 1, MaxDmg = 5, Price = 1000, UpgradeTo = "Csákány+1", UpgradeChance = 100, UpgradeCost = 500, IsPickaxe = true, DoubleOreChance = 0},
	["Csákány+1"] = {Type = "Fegyver", Level = 1, MinDmg = 1, MaxDmg = 6, Price = 2000, UpgradeTo = "Csákány+2", UpgradeChance = 90, UpgradeCost = 1000, IsPickaxe = true, DoubleOreChance = 0},
	["Csákány+2"] = {Type = "Fegyver", Level = 1, MinDmg = 2, MaxDmg = 7, Price = 3000, UpgradeTo = "Csákány+3", UpgradeChance = 80, UpgradeCost = 2000, IsPickaxe = true, DoubleOreChance = 0},
	["Csákány+3"] = {Type = "Fegyver", Level = 1, MinDmg = 2, MaxDmg = 8, Price = 4000, UpgradeTo = "Csákány+4", UpgradeChance = 70, UpgradeCost = 4000, IsPickaxe = true, DoubleOreChance = 10}, -- Innentől 10% dupla esély!
	["Csákány+4"] = {Type = "Fegyver", Level = 1, MinDmg = 3, MaxDmg = 9, Price = 5000, UpgradeTo = "Csákány+5", UpgradeChance = 60, UpgradeCost = 8000, IsPickaxe = true, DoubleOreChance = 15},
	["Csákány+5"] = {Type = "Fegyver", Level = 1, MinDmg = 3, MaxDmg = 10, Price = 6000, UpgradeTo = "Csákány+6", UpgradeChance = 50, UpgradeCost = 15000, IsPickaxe = true, DoubleOreChance = 20},
	["Csákány+6"] = {Type = "Fegyver", Level = 1, MinDmg = 4, MaxDmg = 12, Price = 7000, UpgradeTo = "Csákány+7", UpgradeChance = 40, UpgradeCost = 30000, IsPickaxe = true, DoubleOreChance = 25},
	["Csákány+7"] = {Type = "Fegyver", Level = 1, MinDmg = 4, MaxDmg = 14, Price = 8000, UpgradeTo = "Csákány+8", UpgradeChance = 30, UpgradeCost = 50000, IsPickaxe = true, DoubleOreChance = 30},
	["Csákány+8"] = {Type = "Fegyver", Level = 1, MinDmg = 5, MaxDmg = 16, Price = 9000, UpgradeTo = "Csákány+9", UpgradeChance = 20, UpgradeCost = 80000, IsPickaxe = true, DoubleOreChance = 40},
	["Csákány+9"] = {Type = "Fegyver", Level = 1, MinDmg = 6, MaxDmg = 20, Price = 10000, IsPickaxe = true, DoubleOreChance = 50},
}
return ItemDatabase