local ItemDatabase = {
	-- FEGYVEREK
	["Kezdőkard"] = {
		Type = "Fegyver", Level = 1, MinDmg = 10, MaxDmg = 15, Price = 50,
		AttackSpeed = 5, -- +5% támadási sebesség
		UpgradeTo = "Kezdőkard +1", UpgradeCost = 100, UpgradeChance = 90
	},
	["Kezdőkard +1"] = {
		Type = "Fegyver", Level = 1, MinDmg = 13, MaxDmg = 19, Price = 0,
		AttackSpeed = 8,
		UpgradeTo = "Kezdőkard +2", UpgradeCost = 250, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
	},
	["Vámpír Kard"] = {
		Type = "Fegyver", Level = 10, MinDmg = 20, MaxDmg = 30, Price = 1000,
		LifeSteal = 10, -- 10% Életvarázs
		CritChance = 5  -- 5% Kritikus esély
	},

	-- PÁNCÉLOK
	["Vadfarkas Páncél"] = {
		Type = "Páncél", Level = 1, Defense = 10, Price = 200,
		UpgradeTo = "Vadfarkas Páncél +1", UpgradeCost = 150, UpgradeChance = 85
	},
	["Vadfarkas Páncél +1"] = {
		Type = "Páncél", Level = 1, Defense = 15, Price = 0, MaxHealth = 50, -- Ad 50 extra HP-t is!
		UpgradeTo = "Vadfarkas Páncél +2", UpgradeCost = 300, UpgradeChance = 70, ReqItem = "Kutya Fog", ReqCount = 1
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
		StrongVsMetin = 100,   -- +10% Metinkövek ellen
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
		MovementSpeed = 15, -- +15% Mozgási sebesség
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
	["Kutya Fog"] = { Type = "Alapanyag", Price = 5, MaxStack = 50 }
}
return ItemDatabase