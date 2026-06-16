-- Fájl helye: ReplicatedStorage -> QuestDatabase

local QuestDatabase = {

	-- 1. ÖLŐS KÜLDETÉS (Kill)
	["Farkasvadászat"] = {
		Type = "Kill", Target = "Vadfarkas", Count = 5, 
		RewardExp = 150, RewardGold = 300, RewardItem = "Életerő Ital", RewardItemCount = 5,
		GiverNPC = "Varosor", MinLevel = 1,
		Description = "A város körül túl sok a farkas. Ölj meg 5 Vadfarkast!",
		-- ÚJ: Szövegek a párbeszéd ablakhoz!
		AcceptText = "Üdvözöllek, kalandor! A város környékén elszaporodtak a vadfarkasok, és a lakosok félnek elhagyni a falut. Kérlek, ritkítsd meg a falkát, ölj meg 5 Vadfarkast! Jutalmad nem marad el.",
		CompleteText = "Nagyszerű munka! A lakosok máris nagyobb biztonságban érzik magukat. Itt a megérdemelt jutalmad!",
		IsRepeatable = true 
	},

	-- 2. GYŰJTÖGETŐS KÜLDETÉS (Gather)
	["Kovács Alapanyag"] = {
		Type = "Gather", TargetItem = "Kutya Fog", Count = 3, 
		RewardExp = 200, RewardGold = 500, RewardItem = "Vas Páncél", RewardItemCount = 1,
		GiverNPC = "Kovacs", MinLevel = 5,
		Description = "Szükségem van 3 Kutya Fogra a munkámhoz.",
		AcceptText = "Üdv! Épp kifogytam a Kutya Fogból, ami elengedhetetlen a páncélok megerősítéséhez. Tudnál hozni nekem 3 darabot? Egy remek páncéllal hálálom meg!",
		CompleteText = "Meg is hoztad? Tökéletes, ezekből remek fegyvereket fogok kovácsolni! Ahogy ígértem, itt a Vas Páncélod.",
		IsRepeatable = true
	},

	-- 3. BESZÉLGETŐS KÜLDETÉS (Talk)
	["Falu Őse hívat"] = {
		Type = "Talk", TargetNPC = "Faluose", 
		RewardExp = 50, RewardGold = 100, 
		GiverNPC = "Varosor", MinLevel = 10,
		Description = "Menj el a Falu Őséhez, beszélni akar veled!",
		AcceptText = "Hé, te ott! A Falu Őse már napok óta téged keres. Valami nagyon fontos és sürgős ügyben akar beszélni veled. Keresd meg őt azonnal!",
		CompleteText = "Ah, te lennél az az ifjú hős, akiről a Városőr beszélt? Örülök, hogy eljöttél, nagy feladatok várnak még rád...",
		IsRepeatable = false 
	}
}

return QuestDatabase