local ItemDatabase = {}

-- ==========================================
-- SEGÉDFÜGGVÉNYEK
-- ==========================================

local function cloneTable(source)
	local copy = {}

	for key, value in pairs(source) do
		copy[key] = value
	end

	return copy
end

local upgradeChances = {
	[0] = 95,
	[1] = 85,
	[2] = 75,
	[3] = 65,
	[4] = 55,
	[5] = 45,
	[6] = 35,
	[7] = 28,
	[8] = 20,
}

local function getReqForUpgrade(currentPlus)
	if currentPlus <= 0 then
		return nil, nil
	elseif currentPlus <= 2 then
		return "Kutya Fog", currentPlus
	elseif currentPlus <= 4 then
		return "Farkasbőr", currentPlus - 1
	elseif currentPlus <= 6 then
		return "Metin Szilánk", currentPlus - 3
	elseif currentPlus <= 8 then
		return "Fénykristály", currentPlus - 5
	end

	return nil, nil
end

local scalableStats = {
	"MinDmg",
	"MaxDmg",
	"Defense",
	"MaxHealth",
	"MaxMana",

	"STR",
	"VIT",
	"INT",
	"DEX",

	"StrongVsMetin",
	"StrongVsMonster",
	"StrongVsPlayer",

	"LifeSteal",
	"CritChance",
	"DoubleDrop",
	"DoubleGold",
	"AttackSpeed",
	"MovementSpeed",
	"DodgeChance",
}

local function addUpgradeChain(baseName, baseData, growth)
	for plus = 0, 9 do
		local itemName = plus == 0 and baseName or (baseName .. " +" .. plus)
		local data = cloneTable(baseData)

		data.Description = baseData.Description

		for _, statName in ipairs(scalableStats) do
			local baseValue = baseData[statName]
			local growthValue = growth[statName]

			if baseValue ~= nil and growthValue ~= nil then
				data[statName] = math.floor(baseValue + (growthValue * plus))
			end
		end

		if baseData.Price then
			data.Price = math.floor(baseData.Price * (1 + plus * 0.35))
		end

		if plus < 9 then
			data.UpgradeTo = baseName .. " +" .. (plus + 1)
			data.UpgradeCost = math.floor((baseData.UpgradeCost or 100) * (1 + plus * 0.75))
			data.UpgradeChance = upgradeChances[plus] or 20

			local reqItem, reqCount = getReqForUpgrade(plus)
			if reqItem and reqCount then
				data.ReqItem = reqItem
				data.ReqCount = reqCount
			end
		else
			data.UpgradeTo = nil
			data.UpgradeCost = nil
			data.UpgradeChance = nil
			data.ReqItem = nil
			data.ReqCount = nil
		end

		ItemDatabase[itemName] = data
	end
end

-- ==========================================
-- FEGYVEREK
-- ==========================================

addUpgradeChain("Kezdőkard", {
	Type = "Fegyver",
	Level = 1,
	MinDmg = 10,
	MaxDmg = 15,
	Price = 50,
	AttackSpeed = 3,
	Description = "Egyszerű kezdőkard. Megbízható alapfegyver minden kasztnak.",
	UpgradeCost = 100,
}, {
	MinDmg = 3,
	MaxDmg = 4,
	AttackSpeed = 1,
})

addUpgradeChain("Hosszúkard", {
	Type = "Fegyver",
	Level = 5,
	MinDmg = 16,
	MaxDmg = 24,
	Price = 300,
	AttackSpeed = 4,
	StrongVsMonster = 2,
	Description = "Kiegyensúlyozott kard kezdő vadászoknak.",
	UpgradeCost = 450,
}, {
	MinDmg = 4,
	MaxDmg = 5,
	AttackSpeed = 1,
	StrongVsMonster = 1,
})

addUpgradeChain("Őrző Pallos", {
	Type = "Fegyver",
	Level = 10,
	MinDmg = 22,
	MaxDmg = 33,
	Price = 900,
	STR = 2,
	VIT = 3,
	MaxHealth = 80,
	LifeSteal = 2,
	AttackSpeed = -3,
	Description = "Lassabb, de erős tank fegyver. Guardian kasztnak különösen jó.",
	UpgradeCost = 900,
}, {
	MinDmg = 5,
	MaxDmg = 7,
	STR = 1,
	VIT = 1,
	MaxHealth = 35,
	LifeSteal = 1,
	AttackSpeed = 0,
})

addUpgradeChain("Árnyék Tőr", {
	Type = "Fegyver",
	Level = 10,
	MinDmg = 18,
	MaxDmg = 28,
	Price = 950,
	DEX = 4,
	CritChance = 4,
	AttackSpeed = 8,
	DodgeChance = 2,
	Description = "Gyors, kritikus találatokra építő fegyver. Shadowblade kasztnak erős.",
	UpgradeCost = 950,
}, {
	MinDmg = 4,
	MaxDmg = 5,
	DEX = 1,
	CritChance = 1,
	AttackSpeed = 2,
	DodgeChance = 1,
})

addUpgradeChain("Lélekbot", {
	Type = "Fegyver",
	Level = 10,
	MinDmg = 14,
	MaxDmg = 24,
	Price = 900,
	INT = 5,
	MaxMana = 120,
	CritChance = 2,
	StrongVsMonster = 2,
	Description = "Mágikus fókuszfegyver. Soulweaver és Sealer kasztnak ideális.",
	UpgradeCost = 900,
}, {
	MinDmg = 3,
	MaxDmg = 5,
	INT = 2,
	MaxMana = 45,
	CritChance = 1,
	StrongVsMonster = 1,
})

addUpgradeChain("Metinromboló Kard", {
	Type = "Fegyver",
	Level = 15,
	MinDmg = 25,
	MaxDmg = 38,
	Price = 1600,
	StrongVsMetin = 8,
	STR = 3,
	AttackSpeed = 4,
	Description = "Metinkövek ellen különösen hatékony fegyver.",
	UpgradeCost = 1600,
}, {
	MinDmg = 5,
	MaxDmg = 8,
	StrongVsMetin = 3,
	STR = 1,
	AttackSpeed = 1,
})

addUpgradeChain("Vérivó Kard", {
	Type = "Fegyver",
	Level = 20,
	MinDmg = 32,
	MaxDmg = 48,
	Price = 2600,
	LifeSteal = 6,
	CritChance = 3,
	MaxHealth = 120,
	Description = "Életvarázsra építő fegyver hosszabb harcokhoz.",
	UpgradeCost = 2600,
}, {
	MinDmg = 7,
	MaxDmg = 9,
	LifeSteal = 1,
	CritChance = 1,
	MaxHealth = 40,
})

addUpgradeChain("Párbajpenge", {
	Type = "Fegyver",
	Level = 25,
	MinDmg = 38,
	MaxDmg = 56,
	Price = 4000,
	StrongVsPlayer = 5,
	CritChance = 5,
	DEX = 3,
	Description = "PvP-re hangolt penge. Ember elleni sebzésben erős.",
	UpgradeCost = 4000,
}, {
	MinDmg = 8,
	MaxDmg = 11,
	StrongVsPlayer = 2,
	CritChance = 1,
	DEX = 1,
})

-- ==========================================
-- PÁNCÉLOK
-- ==========================================

addUpgradeChain("Vadfarkas Páncél", {
	Type = "Páncél",
	Level = 1,
	Defense = 10,
	Price = 200,
	MaxHealth = 30,
	Description = "Kezdő páncél, amely alap védelmet és kevés életerőt ad.",
	UpgradeCost = 150,
}, {
	Defense = 5,
	MaxHealth = 25,
})

addUpgradeChain("Vas Páncél", {
	Type = "Páncél",
	Level = 5,
	Defense = 25,
	Price = 500,
	MaxHealth = 70,
	VIT = 1,
	Description = "Stabil védelmet adó páncél kezdő tankoláshoz.",
	UpgradeCost = 400,
}, {
	Defense = 7,
	MaxHealth = 35,
	VIT = 1,
})

addUpgradeChain("Őrző Lemezvért", {
	Type = "Páncél",
	Level = 10,
	Defense = 40,
	Price = 1100,
	MaxHealth = 150,
	VIT = 4,
	DodgeChance = -2,
	Description = "Nehéz páncél Guardian stílushoz. Sok védelmet és életerőt ad, de kevésbé mozgékony.",
	UpgradeCost = 1000,
}, {
	Defense = 10,
	MaxHealth = 55,
	VIT = 1,
	DodgeChance = 0,
})

addUpgradeChain("Árnyék Kabát", {
	Type = "Páncél",
	Level = 10,
	Defense = 25,
	Price = 1000,
	DEX = 4,
	DodgeChance = 5,
	MovementSpeed = 4,
	CritChance = 2,
	Description = "Könnyű páncél Shadowblade játékstílushoz.",
	UpgradeCost = 1000,
}, {
	Defense = 6,
	DEX = 1,
	DodgeChance = 1,
	MovementSpeed = 1,
	CritChance = 1,
})

addUpgradeChain("Lélek Köntös", {
	Type = "Páncél",
	Level = 10,
	Defense = 22,
	Price = 1000,
	INT = 5,
	MaxMana = 180,
	StrongVsMonster = 3,
	Description = "Mágikus köntös Soulweaver és Sealer kasztnak.",
	UpgradeCost = 1000,
}, {
	Defense = 5,
	INT = 2,
	MaxMana = 60,
	StrongVsMonster = 1,
})

addUpgradeChain("Sárkány Páncél", {
	Type = "Páncél",
	Level = 25,
	Defense = 65,
	Price = 5000,
	MaxHealth = 250,
	MaxMana = 120,
	StrongVsMonster = 5,
	StrongVsMetin = 5,
	Description = "Erős középszintű páncél vegyes PvE tartalomhoz.",
	UpgradeCost = 4500,
}, {
	Defense = 13,
	MaxHealth = 75,
	MaxMana = 35,
	StrongVsMonster = 2,
	StrongVsMetin = 2,
})

-- ==========================================
-- SISAKOK / SAPKÁK
-- ==========================================

addUpgradeChain("Bőr Sisak", {
	Type = "Sapka",
	Level = 1,
	Defense = 4,
	Price = 120,
	MaxHealth = 20,
	Description = "Egyszerű kezdő fejvédő.",
	UpgradeCost = 120,
}, {
	Defense = 2,
	MaxHealth = 15,
})

addUpgradeChain("Harcos Sisak", {
	Type = "Sapka",
	Level = 8,
	Defense = 10,
	Price = 600,
	STR = 2,
	MaxHealth = 50,
	Description = "Harcosoknak készült sisak, kevés támadó statot is ad.",
	UpgradeCost = 550,
}, {
	Defense = 3,
	STR = 1,
	MaxHealth = 20,
})

addUpgradeChain("Árnyék Csuklya", {
	Type = "Sapka",
	Level = 10,
	Defense = 8,
	Price = 650,
	DEX = 3,
	CritChance = 3,
	DodgeChance = 2,
	Description = "Kritikus és kitérés alapú sisak Shadowblade kasztnak.",
	UpgradeCost = 650,
}, {
	Defense = 2,
	DEX = 1,
	CritChance = 1,
	DodgeChance = 1,
})

addUpgradeChain("Bölcs Csuklya", {
	Type = "Sapka",
	Level = 10,
	Defense = 7,
	Price = 650,
	INT = 4,
	MaxMana = 100,
	AttackSpeed = 2,
	Description = "Mágikus kasztoknak kedvező fejfedő.",
	UpgradeCost = 650,
}, {
	Defense = 2,
	INT = 1,
	MaxMana = 35,
	AttackSpeed = 1,
})

-- ==========================================
-- CIPŐK
-- ==========================================

addUpgradeChain("Bőrcipő", {
	Type = "Cipő",
	Level = 1,
	Price = 100,
	MovementSpeed = 6,
	DodgeChance = 1,
	Description = "Könnyű cipő, gyorsabb futást biztosít.",
	UpgradeCost = 100,
}, {
	MovementSpeed = 2,
	DodgeChance = 1,
})

addUpgradeChain("Farkasjáró Csizma", {
	Type = "Cipő",
	Level = 8,
	Price = 600,
	MovementSpeed = 10,
	DodgeChance = 3,
	StrongVsMonster = 2,
	Description = "PvE farmoláshoz jó mozgékony csizma.",
	UpgradeCost = 600,
}, {
	MovementSpeed = 2,
	DodgeChance = 1,
	StrongVsMonster = 1,
})

addUpgradeChain("Árnylépő Csizma", {
	Type = "Cipő",
	Level = 15,
	Price = 1400,
	MovementSpeed = 12,
	DodgeChance = 5,
	CritChance = 2,
	DEX = 2,
	Description = "Gyors és kitérésre építő csizma.",
	UpgradeCost = 1400,
}, {
	MovementSpeed = 3,
	DodgeChance = 1,
	CritChance = 1,
	DEX = 1,
})

-- ==========================================
-- PAJZSOK
-- ==========================================

addUpgradeChain("Fa Pajzs", {
	Type = "Pajzs",
	Level = 1,
	Defense = 8,
	Price = 120,
	MaxHealth = 25,
	Description = "Alap pajzs kezdőknek.",
	UpgradeCost = 120,
}, {
	Defense = 3,
	MaxHealth = 15,
})

addUpgradeChain("Vas Pajzs", {
	Type = "Pajzs",
	Level = 8,
	Defense = 18,
	Price = 700,
	MaxHealth = 80,
	VIT = 2,
	Description = "Stabil tank pajzs.",
	UpgradeCost = 700,
}, {
	Defense = 5,
	MaxHealth = 30,
	VIT = 1,
})

addUpgradeChain("Metin Pajzs", {
	Type = "Pajzs",
	Level = 15,
	Defense = 22,
	Price = 1500,
	StrongVsMetin = 5,
	MaxHealth = 100,
	Description = "Metinkövek elleni farmhoz hasznos pajzs.",
	UpgradeCost = 1500,
}, {
	Defense = 5,
	StrongVsMetin = 2,
	MaxHealth = 35,
})

addUpgradeChain("Párbaj Pajzs", {
	Type = "Pajzs",
	Level = 25,
	Defense = 30,
	Price = 3500,
	StrongVsPlayer = 4,
	DodgeChance = 3,
	Description = "PvP helyzetekre készült pajzs.",
	UpgradeCost = 3500,
}, {
	Defense = 7,
	StrongVsPlayer = 2,
	DodgeChance = 1,
})

-- ==========================================
-- NYAKLÁNCOK
-- ==========================================

addUpgradeChain("Réz Nyaklánc", {
	Type = "Nyaklánc",
	Level = 1,
	Price = 150,
	AttackSpeed = 4,
	MaxMana = 30,
	Description = "Kezdő nyaklánc támadási sebességgel és manával.",
	UpgradeCost = 150,
}, {
	AttackSpeed = 1,
	MaxMana = 15,
})

addUpgradeChain("Vadász Nyaklánc", {
	Type = "Nyaklánc",
	Level = 8,
	Price = 700,
	StrongVsMonster = 5,
	DoubleDrop = 2,
	MaxMana = 50,
	Description = "Farmoláshoz jó PvE nyaklánc.",
	UpgradeCost = 700,
}, {
	StrongVsMonster = 2,
	DoubleDrop = 1,
	MaxMana = 20,
})

addUpgradeChain("Rubin Nyaklánc", {
	Type = "Nyaklánc",
	Level = 15,
	Price = 1600,
	CritChance = 4,
	STR = 2,
	DEX = 2,
	Description = "Sebzésre és kritikus találatra építő nyaklánc.",
	UpgradeCost = 1600,
}, {
	CritChance = 1,
	STR = 1,
	DEX = 1,
})

addUpgradeChain("Hold Nyaklánc", {
	Type = "Nyaklánc",
	Level = 15,
	Price = 1600,
	INT = 4,
	MaxMana = 160,
	AttackSpeed = 3,
	Description = "Mágikus kasztoknak készült nyaklánc.",
	UpgradeCost = 1600,
}, {
	INT = 1,
	MaxMana = 45,
	AttackSpeed = 1,
})

-- ==========================================
-- KARKÖTŐK
-- ==========================================

addUpgradeChain("Bőr Karkötő", {
	Type = "Karkötő",
	Level = 1,
	Price = 120,
	MaxHealth = 50,
	DoubleGold = 2,
	Description = "Kezdő karkötő kevés életerővel és pénzbónusszal.",
	UpgradeCost = 120,
}, {
	MaxHealth = 20,
	DoubleGold = 1,
})

addUpgradeChain("Vadász Karkötő", {
	Type = "Karkötő",
	Level = 8,
	Price = 750,
	StrongVsMonster = 4,
	DoubleDrop = 3,
	DoubleGold = 2,
	Description = "Farmoláshoz és szörnyek elleni harchoz jó karkötő.",
	UpgradeCost = 750,
}, {
	StrongVsMonster = 2,
	DoubleDrop = 1,
	DoubleGold = 1,
})

addUpgradeChain("Vér Karkötő", {
	Type = "Karkötő",
	Level = 15,
	Price = 1600,
	LifeSteal = 4,
	MaxHealth = 100,
	STR = 2,
	Description = "Életvarázsra és túlélésre építő karkötő.",
	UpgradeCost = 1600,
}, {
	LifeSteal = 1,
	MaxHealth = 35,
	STR = 1,
})

addUpgradeChain("Párbaj Karkötő", {
	Type = "Karkötő",
	Level = 25,
	Price = 3600,
	StrongVsPlayer = 4,
	CritChance = 3,
	DodgeChance = 2,
	Description = "PvP-re optimalizált karkötő.",
	UpgradeCost = 3600,
}, {
	StrongVsPlayer = 2,
	CritChance = 1,
	DodgeChance = 1,
})

-- ==========================================
-- FÜLBEVALÓK
-- ==========================================

addUpgradeChain("Ezüst Fülbevaló", {
	Type = "Fülbevaló",
	Level = 1,
	Price = 130,
	MaxMana = 60,
	INT = 1,
	Description = "Kezdő fülbevaló manával.",
	UpgradeCost = 130,
}, {
	MaxMana = 20,
	INT = 1,
})

addUpgradeChain("Harcos Fülbevaló", {
	Type = "Fülbevaló",
	Level = 8,
	Price = 750,
	STR = 3,
	AttackSpeed = 3,
	MaxHealth = 50,
	Description = "Harcos és Guardian jellegű karaktereknek jó.",
	UpgradeCost = 750,
}, {
	STR = 1,
	AttackSpeed = 1,
	MaxHealth = 20,
})

addUpgradeChain("Árny Fülbevaló", {
	Type = "Fülbevaló",
	Level = 10,
	Price = 850,
	DEX = 4,
	DodgeChance = 3,
	CritChance = 2,
	Description = "Shadowblade stílushoz erős fülbevaló.",
	UpgradeCost = 850,
}, {
	DEX = 1,
	DodgeChance = 1,
	CritChance = 1,
})

addUpgradeChain("Lélek Fülbevaló", {
	Type = "Fülbevaló",
	Level = 10,
	Price = 850,
	INT = 4,
	MaxMana = 120,
	StrongVsMonster = 2,
	Description = "Soulweaver és Sealer karaktereknek jó.",
	UpgradeCost = 850,
}, {
	INT = 1,
	MaxMana = 40,
	StrongVsMonster = 1,
})

-- ==========================================
-- FOGYÓESZKÖZÖK / ITALOK
-- ==========================================

ItemDatabase["Életerő Ital"] = {
	Type = "Fogyóeszköz",
	HealAmount = 50,
	Price = 20,
	MaxStack = 200,
	Description = "50 életerőt tölt vissza."
}

ItemDatabase["Nagy Életerő Ital"] = {
	Type = "Fogyóeszköz",
	HealAmount = 150,
	Price = 75,
	MaxStack = 200,
	Description = "150 életerőt tölt vissza."
}

ItemDatabase["Mana Ital"] = {
	Type = "Fogyóeszköz",
	HealAmount = 50,
	Price = 20,
	MaxStack = 200,
	Description = "50 manát tölt vissza."
}

ItemDatabase["Nagy Mana Ital"] = {
	Type = "Fogyóeszköz",
	HealAmount = 150,
	Price = 75,
	MaxStack = 200,
	Description = "150 manát tölt vissza."
}

ItemDatabase["Zöld Ital"] = {
	Type = "Fogyóeszköz",
	Price = 100,
	MaxStack = 50,
	Effect = "MovementSpeed",
	Value = 25,
	Duration = 60,
	Description = "60 másodpercig növeli a mozgási sebességet."
}

ItemDatabase["Ügyesség itala"] = {
	Type = "Fogyóeszköz",
	Price = 100,
	MaxStack = 50,
	Effect = "AttackSpeed",
	Value = 25,
	Duration = 60,
	Description = "60 másodpercig növeli a támadási sebességet."
}

ItemDatabase["Kritikus Ital"] = {
	Type = "Fogyóeszköz",
	Price = 200,
	MaxStack = 50,
	Effect = "CritChance",
	Value = 10,
	Duration = 60,
	Description = "60 másodpercig növeli a kritikus találat esélyét."
}

ItemDatabase["Vadász Ital"] = {
	Type = "Fogyóeszköz",
	Price = 200,
	MaxStack = 50,
	Effect = "StrongVsMonster",
	Value = 10,
	Duration = 60,
	Description = "60 másodpercig növeli a szörnyek elleni sebzést."
}

ItemDatabase["Metinromboló Ital"] = {
	Type = "Fogyóeszköz",
	Price = 250,
	MaxStack = 50,
	Effect = "StrongVsMetin",
	Value = 12,
	Duration = 60,
	Description = "60 másodpercig növeli a Metinkövek elleni sebzést."
}

-- ==========================================
-- ALAPANYAGOK
-- ==========================================

ItemDatabase["Kutya Fog"] = {
	Type = "Alapanyag",
	Price = 5,
	MaxStack = 50,
	Description = "Alap fejlesztési anyag."
}

ItemDatabase["Farkasbőr"] = {
	Type = "Alapanyag",
	Price = 12,
	MaxStack = 100,
	Description = "Gyakori fejlesztési alapanyag."
}

ItemDatabase["Törött Penge"] = {
	Type = "Alapanyag",
	Price = 20,
	MaxStack = 100,
	Description = "Fegyverfejlesztéshez használható alapanyag."
}

ItemDatabase["Metin Szilánk"] = {
	Type = "Alapanyag",
	Price = 35,
	MaxStack = 100,
	Description = "Metinkövekből származó fejlesztési anyag."
}

ItemDatabase["Fénykristály"] = {
	Type = "Alapanyag",
	Price = 80,
	MaxStack = 100,
	Description = "Magasabb szintű fejlesztésekhez használt kristály."
}

ItemDatabase["Árnyékpor"] = {
	Type = "Alapanyag",
	Price = 90,
	MaxStack = 100,
	Description = "Ritkább mágikus fejlesztési anyag."
}

ItemDatabase["Sárkány Pikkely"] = {
	Type = "Alapanyag",
	Price = 150,
	MaxStack = 100,
	Description = "Ritka fejlesztési anyag erős felszerelésekhez."
}

-- ==========================================
-- BÁNYÁSZAT (ÉRCEK ÉS CSÁKÁNYOK) - VÁLTOZATLANUL HAGYVA
-- ==========================================

ItemDatabase["Gyémánt Érc"] = {Type = "Érc", MaxStack = 250, Price = 500, Description = "Értékes bányászott érc."}
ItemDatabase["Arany Érc"] = {Type = "Érc", MaxStack = 250, Price = 400, Description = "Értékes bányászott érc."}
ItemDatabase["Vas Érc"] = {Type = "Érc", MaxStack = 250, Price = 100, Description = "Alapvető bányászott érc."}
ItemDatabase["Kristály Érc"] = {Type = "Érc", MaxStack = 250, Price = 300, Description = "Értékes bányászott érc."}
ItemDatabase["Ruby Érc"] = {Type = "Érc", MaxStack = 250, Price = 600, Description = "Értékes bányászott érc."}
ItemDatabase["Smaragd Érc"] = {Type = "Érc", MaxStack = 250, Price = 650, Description = "Értékes bányászott érc."}
ItemDatabase["Jáde Érc"] = {Type = "Érc", MaxStack = 250, Price = 550, Description = "Értékes bányászott érc."}
ItemDatabase["Ametiszt Érc"] = {Type = "Érc", MaxStack = 250, Price = 450, Description = "Értékes bányászott érc."}
ItemDatabase["Szivárvány Kristály"] = {Type = "Érc", MaxStack = 250, Price = 5000, Description = "Különleges és rendkívül ritka mágikus kristály."}

ItemDatabase["Csákány+0"] = {Type = "Fegyver", Level = 1, MinDmg = 1, MaxDmg = 5, Price = 1000, UpgradeTo = "Csákány+1", UpgradeChance = 100, UpgradeCost = 500, IsPickaxe = true, DoubleOreChance = 0}
ItemDatabase["Csákány+1"] = {Type = "Fegyver", Level = 1, MinDmg = 1, MaxDmg = 6, Price = 2000, UpgradeTo = "Csákány+2", UpgradeChance = 90, UpgradeCost = 1000, IsPickaxe = true, DoubleOreChance = 0}
ItemDatabase["Csákány+2"] = {Type = "Fegyver", Level = 1, MinDmg = 2, MaxDmg = 7, Price = 3000, UpgradeTo = "Csákány+3", UpgradeChance = 80, UpgradeCost = 2000, IsPickaxe = true, DoubleOreChance = 0}
ItemDatabase["Csákány+3"] = {Type = "Fegyver", Level = 1, MinDmg = 2, MaxDmg = 8, Price = 4000, UpgradeTo = "Csákány+4", UpgradeChance = 70, UpgradeCost = 4000, IsPickaxe = true, DoubleOreChance = 10}
ItemDatabase["Csákány+4"] = {Type = "Fegyver", Level = 1, MinDmg = 3, MaxDmg = 9, Price = 5000, UpgradeTo = "Csákány+5", UpgradeChance = 60, UpgradeCost = 8000, IsPickaxe = true, DoubleOreChance = 15}
ItemDatabase["Csákány+5"] = {Type = "Fegyver", Level = 1, MinDmg = 3, MaxDmg = 10, Price = 6000, UpgradeTo = "Csákány+6", UpgradeChance = 50, UpgradeCost = 15000, IsPickaxe = true, DoubleOreChance = 20}
ItemDatabase["Csákány+6"] = {Type = "Fegyver", Level = 1, MinDmg = 4, MaxDmg = 12, Price = 7000, UpgradeTo = "Csákány+7", UpgradeChance = 40, UpgradeCost = 30000, IsPickaxe = true, DoubleOreChance = 25}
ItemDatabase["Csákány+7"] = {Type = "Fegyver", Level = 1, MinDmg = 4, MaxDmg = 14, Price = 8000, UpgradeTo = "Csákány+8", UpgradeChance = 30, UpgradeCost = 50000, IsPickaxe = true, DoubleOreChance = 30}
ItemDatabase["Csákány+8"] = {Type = "Fegyver", Level = 1, MinDmg = 5, MaxDmg = 16, Price = 9000, UpgradeTo = "Csákány+9", UpgradeChance = 20, UpgradeCost = 80000, IsPickaxe = true, DoubleOreChance = 40}
ItemDatabase["Csákány+9"] = {Type = "Fegyver", Level = 1, MinDmg = 6, MaxDmg = 20, Price = 10000, IsPickaxe = true, DoubleOreChance = 50}

return ItemDatabase