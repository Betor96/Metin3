-- Fájl helye: ReplicatedStorage -> QuestDatabase

local QuestDatabase = {

	-- ==========================================
	-- VÁROSŐR KÜLDETÉSEI
	-- NPC: Varosor
	-- Főleg ölős / védelmi küldetések
	-- ==========================================

	["Farkasvadászat"] = {
		Type = "Kill",
		Target = "Vadfarkas",
		Count = 5,

		RewardExp = 150,
		RewardGold = 300,
		RewardItem = "Életerő Ital",
		RewardItemCount = 5,

		GiverNPC = "Varosor",
		MinLevel = 1,

		Description = "A város körül túl sok a farkas. Ölj meg 5 Vadfarkast!",
		AcceptText = "Üdvözöllek, kalandor! A város környékén elszaporodtak a vadfarkasok, és a lakosok félnek elhagyni a falut. Kérlek, ritkítsd meg a falkát, ölj meg 5 Vadfarkast!",
		CompleteText = "Nagyszerű munka! A lakosok máris nagyobb biztonságban érzik magukat. Itt a megérdemelt jutalmad!",
		IsRepeatable = true
	},

	["Vadkutyák ritkítása"] = {
		Type = "Kill",
		Target = "Vadkutya",
		Count = 8,

		RewardExp = 120,
		RewardGold = 180,
		RewardItem = "Életerő Ital",
		RewardItemCount = 3,

		GiverNPC = "Varosor",
		MinLevel = 1,

		Description = "Ölj meg 8 Vadkutyát a város környékén.",
		AcceptText = "A vadkutyák egyre bátrabbak. Már a kapuk közelében ólálkodnak. Intézz el 8 Vadkutyát, hogy biztonságosabb legyen az út!",
		CompleteText = "Szép munka! Kevesebb vadkutya, kevesebb baj. Fogadd el ezt a kis jutalmat!",
		IsRepeatable = true
	},

	["Éhes vadkutyák"] = {
		Type = "Kill",
		Target = "Éhes Vadkutya",
		Count = 6,

		RewardExp = 180,
		RewardGold = 260,
		RewardItem = "Nagy Életerő Ital",
		RewardItemCount = 2,

		GiverNPC = "Varosor",
		MinLevel = 2,

		Description = "Ölj meg 6 Éhes Vadkutyát.",
		AcceptText = "Az éhes vadkutyák sokkal agresszívebbek a többinél. Ha nem állítjuk meg őket, hamarosan megtámadják az utazókat. Ölj meg belőlük 6-ot!",
		CompleteText = "Jó látni, hogy visszatértél. A környék egy fokkal biztonságosabb lett.",
		IsRepeatable = true
	},

	["Alfa nyomában"] = {
		Type = "Kill",
		Target = "Alfa Farkas",
		Count = 3,

		RewardExp = 500,
		RewardGold = 700,
		RewardItem = "Hosszúkard",
		RewardItemCount = 1,

		GiverNPC = "Varosor",
		MinLevel = 5,

		Description = "Ölj meg 3 Alfa Farkast.",
		AcceptText = "A farkasfalkákat az Alfa Farkasok vezetik. Amíg ők élnek, a falkák nem fognak visszahúzódni. Ölj meg 3 Alfa Farkast!",
		CompleteText = "Ez már igazi harcoshoz méltó teljesítmény. Fogadd el ezt a fegyvert!",
		IsRepeatable = true
	},

	["Bandita veszély"] = {
		Type = "Kill",
		Target = "Erdei Bandita",
		Count = 8,

		RewardExp = 850,
		RewardGold = 1100,
		RewardItem = "Vas Páncél",
		RewardItemCount = 1,

		GiverNPC = "Varosor",
		MinLevel = 8,

		Description = "Ölj meg 8 Erdei Banditát.",
		AcceptText = "A banditák megtámadják a kereskedőket az erdei úton. Menj, és mutasd meg nekik, hogy a város védelme nem játék. Ölj meg 8 Erdei Banditát!",
		CompleteText = "A kereskedők hálásak lesznek. Ez a páncél hasznodra válhat a következő harcokban.",
		IsRepeatable = true
	},

	["Íjászok az erdőben"] = {
		Type = "Kill",
		Target = "Bandita Íjász",
		Count = 6,

		RewardExp = 900,
		RewardGold = 1200,
		RewardItem = "Ügyesség itala",
		RewardItemCount = 5,

		GiverNPC = "Varosor",
		MinLevel = 9,

		Description = "Ölj meg 6 Bandita Íjászt.",
		AcceptText = "A bandita íjászok messziről támadnak, és sok utazót megsebesítettek. Számolj le 6 Bandita Íjásszal!",
		CompleteText = "Jól van. Az erdei út most már kevésbé veszélyes.",
		IsRepeatable = true
	},

	["Árnyak a határban"] = {
		Type = "Kill",
		Target = "Árnyék Harcos",
		Count = 7,

		RewardExp = 1800,
		RewardGold = 2200,
		RewardItem = "Kritikus Ital",
		RewardItemCount = 5,

		GiverNPC = "Varosor",
		MinLevel = 15,

		Description = "Ölj meg 7 Árnyék Harcost.",
		AcceptText = "Sötét alakokat láttak a város határában. Nem egyszerű banditák, valami sokkal rosszabb. Ölj meg 7 Árnyék Harcost!",
		CompleteText = "A jelentések szerint visszaszorultak. Szép munka, harcos!",
		IsRepeatable = true
	},

	["Sárkányivadékok támadása"] = {
		Type = "Kill",
		Target = "Sárkányivadék",
		Count = 5,

		RewardExp = 3500,
		RewardGold = 4200,
		RewardItem = "Nagy Életerő Ital",
		RewardItemCount = 10,

		GiverNPC = "Varosor",
		MinLevel = 25,

		Description = "Ölj meg 5 Sárkányivadékot.",
		AcceptText = "A sárkányok árnyéka ismét megjelent a vidéken. Kezdd a fiatalabb példányokkal. Ölj meg 5 Sárkányivadékot!",
		CompleteText = "Ez már nem kezdőknek való feladat volt. A város nevében köszönöm.",
		IsRepeatable = true
	},

	["Jelentés a kovácsnak"] = {
		Type = "Talk",
		TargetNPC = "Kovacs",

		RewardExp = 80,
		RewardGold = 100,

		GiverNPC = "Varosor",
		MinLevel = 1,

		Description = "Menj el a Kovácshoz, és add át neki a Városőr üzenetét.",
		AcceptText = "A Kovácsnak tudnia kell, hogy több fegyverre lesz szükségünk. Menj el hozzá, és mondd meg neki, hogy készüljön fel!",
		CompleteText = "A Városőr küldött? Értem. Akkor ideje újra befűtenem a kohót.",
		IsRepeatable = false
	},

	["Jelentés a Falu Ősének"] = {
		Type = "Talk",
		TargetNPC = "Faluose",

		RewardExp = 120,
		RewardGold = 150,

		GiverNPC = "Varosor",
		MinLevel = 3,

		Description = "Menj el a Falu Őséhez, és jelentsd neki a környék veszélyeit.",
		AcceptText = "A Falu Ősének tudnia kell, mi történik a falakon kívül. Keresd meg őt, és mondd el neki, hogy a farkasok és banditák is mozgolódnak.",
		CompleteText = "Köszönöm, hogy szóltál. A jelek aggasztóak, de számítottam rá, hogy eljön ez az idő.",
		IsRepeatable = false
	},

	-- ==========================================
	-- KOVÁCS KÜLDETÉSEI
	-- NPC: Kovacs
	-- Főleg gyűjtögetős / alapanyag küldetések
	-- ==========================================

	["Kovács Alapanyag"] = {
		Type = "Gather",
		TargetItem = "Kutya Fog",
		Count = 3,

		RewardExp = 200,
		RewardGold = 500,
		RewardItem = "Vas Páncél",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 1,

		Description = "Szükségem van 3 Kutya Fogra a munkámhoz.",
		AcceptText = "Üdv! Épp kifogytam a Kutya Fogból, ami elengedhetetlen az alap felszerelések megerősítéséhez. Tudnál hozni nekem 3 darabot?",
		CompleteText = "Meg is hoztad? Tökéletes. Ahogy ígértem, itt a jutalmad!",
		IsRepeatable = true
	},

	["Farkasbőr pánthoz"] = {
		Type = "Gather",
		TargetItem = "Farkasbőr",
		Count = 5,

		RewardExp = 350,
		RewardGold = 650,
		RewardItem = "Farkasjáró Csizma",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 4,

		Description = "Gyűjts 5 Farkasbőrt a Kovácsnak.",
		AcceptText = "A jó csizma nem csak vasból készül. Kell hozzá erős, rugalmas bőr is. Hozz nekem 5 Farkasbőrt!",
		CompleteText = "Pont ilyen minőségre volt szükségem. Tessék, próbáld ki ezt a csizmát!",
		IsRepeatable = true
	},

	["Törött pengék újraöntése"] = {
		Type = "Gather",
		TargetItem = "Törött Penge",
		Count = 6,

		RewardExp = 700,
		RewardGold = 950,
		RewardItem = "Hosszúkard +1",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 8,

		Description = "Gyűjts 6 Törött Pengét.",
		AcceptText = "A banditák fegyverei rossz minőségűek, de az anyaguk még hasznos lehet. Hozz nekem 6 Törött Pengét, és újraöntöm őket.",
		CompleteText = "Ebből már lehet dolgozni. Fogadd el ezt a megerősített kardot!",
		IsRepeatable = true
	},

	["Metin szilánkok"] = {
		Type = "Gather",
		TargetItem = "Metin Szilánk",
		Count = 5,

		RewardExp = 1100,
		RewardGold = 1500,
		RewardItem = "Metinromboló Ital",
		RewardItemCount = 5,

		GiverNPC = "Kovacs",
		MinLevel = 12,

		Description = "Gyűjts 5 Metin Szilánkot.",
		AcceptText = "A Metin kövek darabjai különösen erős anyagok. Ha hozol 5 Metin Szilánkot, készítek belőlük valami hasznosat.",
		CompleteText = "Kiváló. Ezekben még mindig lüktet az energia. Vidd ezeket az italokat, jól jönnek majd a Metinek ellen.",
		IsRepeatable = true
	},

	["Fénykristály próba"] = {
		Type = "Gather",
		TargetItem = "Fénykristály",
		Count = 4,

		RewardExp = 1700,
		RewardGold = 2400,
		RewardItem = "Vadász Karkötő",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 16,

		Description = "Gyűjts 4 Fénykristályt.",
		AcceptText = "A Fénykristály ritka és érzékeny anyag. Hozz nekem 4 darabot, és készítek belőle egy hasznos felszerelést.",
		CompleteText = "Szép munka. Nem sokan tudnak ilyen kristályokat szerezni.",
		IsRepeatable = true
	},

	["Árnyékpor a pengéhez"] = {
		Type = "Gather",
		TargetItem = "Árnyékpor",
		Count = 6,

		RewardExp = 2200,
		RewardGold = 3000,
		RewardItem = "Árnyék Tőr",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 18,

		Description = "Gyűjts 6 Árnyékport.",
		AcceptText = "Egy különleges pengét akarok készíteni, de kell hozzá Árnyékpor. Hozz nekem 6 darabot, és adok egy fegyvert, amit nem felejtesz el.",
		CompleteText = "Pont erre volt szükségem. Vigyázz vele, ez nem hétköznapi penge.",
		IsRepeatable = true
	},

	["Sárkánypikkelyes megerősítés"] = {
		Type = "Gather",
		TargetItem = "Sárkány Pikkely",
		Count = 5,

		RewardExp = 4000,
		RewardGold = 5500,
		RewardItem = "Sárkány Páncél",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 25,

		Description = "Gyűjts 5 Sárkány Pikkelyt.",
		AcceptText = "A Sárkány Pikkelyből készült felszerelés rendkívül erős. Hozz nekem 5 darabot, és készítek belőle valamit, ami megvéd a legsúlyosabb csapásoktól is.",
		CompleteText = "Lenyűgöző. Ezekből már igazi mestermunkát lehet készíteni.",
		IsRepeatable = true
	},

	["Vasérc próbamunka"] = {
		Type = "Gather",
		TargetItem = "Vas Érc",
		Count = 10,

		RewardExp = 300,
		RewardGold = 700,
		RewardItem = "Fa Pajzs",
		RewardItemCount = 1,

		GiverNPC = "Kovacs",
		MinLevel = 3,

		Description = "Bányássz 10 Vas Ércet.",
		AcceptText = "Ha harcolni akarsz, értened kell az anyagokhoz is. Hozz nekem 10 Vas Ércet, és megmutatom, mire jó az alapanyag.",
		CompleteText = "Nem rossz. Látom, nem félsz a bányamunkától sem.",
		IsRepeatable = true
	},

	["Beszélj a Városőrrel"] = {
		Type = "Talk",
		TargetNPC = "Varosor",

		RewardExp = 100,
		RewardGold = 120,

		GiverNPC = "Kovacs",
		MinLevel = 1,

		Description = "Menj vissza a Városőrhöz.",
		AcceptText = "Elkészültem az üzenettel. Menj vissza a Városőrhöz, és mondd meg neki, hogy a fegyverek előkészítése elkezdődött.",
		CompleteText = "A Kovács már dolgozik? Jó hír. Akkor még van esélyünk felkészülni.",
		IsRepeatable = false
	},

	-- ==========================================
	-- FALU ŐSE KÜLDETÉSEI
	-- NPC: Faluose
	-- Főleg történeti / Metin / erősebb küldetések
	-- ==========================================

	["Falu Őse hívat"] = {
		Type = "Talk",
		TargetNPC = "Faluose",

		RewardExp = 50,
		RewardGold = 100,

		GiverNPC = "Varosor",
		MinLevel = 1,

		Description = "Menj el a Falu Őséhez, beszélni akar veled!",
		AcceptText = "Hé, te ott! A Falu Őse már napok óta téged keres. Valami fontos ügyben akar beszélni veled. Keresd meg őt!",
		CompleteText = "Ah, te lennél az az ifjú hős, akiről a Városőr beszélt? Örülök, hogy eljöttél.",
		IsRepeatable = false
	},

	["Első próbatétel"] = {
		Type = "Kill",
		Target = "Farkas",
		Count = 10,

		RewardExp = 450,
		RewardGold = 700,
		RewardItem = "Réz Nyaklánc",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 4,

		Description = "Ölj meg 10 Farkast.",
		AcceptText = "Minden hősnek bizonyítania kell. Kezdd egyszerű feladattal: ölj meg 10 Farkast, és térj vissza hozzám.",
		CompleteText = "Látom, van benned elszántság. Ez még csak a kezdet.",
		IsRepeatable = false
	},

	["A kövek suttogása"] = {
		Type = "Kill",
		Target = "Kőgólem",
		Count = 5,

		RewardExp = 1300,
		RewardGold = 1800,
		RewardItem = "Metinromboló Kard",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 12,

		Description = "Ölj meg 5 Kőgólemet.",
		AcceptText = "A kövek nem némák. Érzem, hogy valami megmozdult bennük. Menj, és semmisíts meg 5 Kőgólemet!",
		CompleteText = "A föld nyugtalan, de ezzel időt nyertünk.",
		IsRepeatable = true
	},

	["Lélekmágusok titka"] = {
		Type = "Kill",
		Target = "Lélekmágus",
		Count = 6,

		RewardExp = 2400,
		RewardGold = 3200,
		RewardItem = "Lélekbot",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 18,

		Description = "Ölj meg 6 Lélekmágust.",
		AcceptText = "A Lélekmágusok tiltott energiát használnak. Ha hagyjuk őket erősödni, a falu veszélybe kerül. Állíts meg 6 Lélekmágust!",
		CompleteText = "Érezhetően gyengült a sötét energia. Jól teljesítettél.",
		IsRepeatable = true
	},

	["Elátkozott páncélok"] = {
		Type = "Kill",
		Target = "Elátkozott Lovag",
		Count = 4,

		RewardExp = 3000,
		RewardGold = 4200,
		RewardItem = "Vér Karkötő",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 20,

		Description = "Ölj meg 4 Elátkozott Lovagot.",
		AcceptText = "Az Elátkozott Lovagok régi háborúk maradványai. Testük már nem él, de haragjuk igen. Pusztíts el közülük 4-et!",
		CompleteText = "Néhány lélek talán végre nyugalomra lelhet.",
		IsRepeatable = true
	},

	["Sárkányőrök próbája"] = {
		Type = "Kill",
		Target = "Sárkányőr",
		Count = 3,

		RewardExp = 5200,
		RewardGold = 6500,
		RewardItem = "Párbaj Pajzs",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 28,

		Description = "Ölj meg 3 Sárkányőrt.",
		AcceptText = "Ha a Sárkány Árnyékához akarsz közelebb jutni, előbb az őreit kell legyőznöd. Ölj meg 3 Sárkányőrt!",
		CompleteText = "Most már látom, hogy készen állsz a nagyobb veszélyekre is.",
		IsRepeatable = true
	},

	["Ősi törmelék"] = {
		Type = "Gather",
		TargetItem = "Metin Szilánk",
		Count = 10,

		RewardExp = 2200,
		RewardGold = 3000,
		RewardItem = "Fénykristály",
		RewardItemCount = 2,

		GiverNPC = "Faluose",
		MinLevel = 14,

		Description = "Gyűjts 10 Metin Szilánkot.",
		AcceptText = "A Metin Szilánkokból kiolvasható a kövek eredete. Hozz nekem 10 darabot, és talán közelebb kerülünk az igazsághoz.",
		CompleteText = "Igen... ezekből már érzem a torz energiát.",
		IsRepeatable = true
	},

	["Árnyék maradványok"] = {
		Type = "Gather",
		TargetItem = "Árnyékpor",
		Count = 8,

		RewardExp = 2800,
		RewardGold = 3900,
		RewardItem = "Hold Nyaklánc",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 18,

		Description = "Gyűjts 8 Árnyékport.",
		AcceptText = "Az Árnyékpor nem egyszerű anyag. A sötét erők nyomát hordozza. Hozz nekem 8 darabot belőle!",
		CompleteText = "Veszélyes anyag, de hasznos lehet a kutatásaimhoz.",
		IsRepeatable = true
	},

	["Sárkány jele"] = {
		Type = "Gather",
		TargetItem = "Sárkány Pikkely",
		Count = 3,

		RewardExp = 5000,
		RewardGold = 7000,
		RewardItem = "Sárkány Páncél",
		RewardItemCount = 1,

		GiverNPC = "Faluose",
		MinLevel = 27,

		Description = "Gyűjts 3 Sárkány Pikkelyt.",
		AcceptText = "A Sárkány Pikkely ritka és hatalmas erőt hordoz. Hozz nekem 3 darabot, és segítek felkészülni a közelgő veszélyre.",
		CompleteText = "Ezek valódi sárkánypikkelyek... akkor a veszély már sokkal közelebb van, mint gondoltam.",
		IsRepeatable = true
	},

	["Keresd fel a Kovácsot"] = {
		Type = "Talk",
		TargetNPC = "Kovacs",

		RewardExp = 150,
		RewardGold = 200,

		GiverNPC = "Faluose",
		MinLevel = 5,

		Description = "Menj el a Kovácshoz, és kérdezd meg a Metin Szilánkokról.",
		AcceptText = "A Kovács régóta dolgozik különleges anyagokkal. Keresd fel, és kérdezd meg, mit tud a Metin Szilánkokról.",
		CompleteText = "A Falu Őse küldött? Akkor komoly lehet a helyzet. Mesélek, amit tudok.",
		IsRepeatable = false
	},

	["Vissza a Városőrhöz"] = {
		Type = "Talk",
		TargetNPC = "Varosor",

		RewardExp = 180,
		RewardGold = 250,

		GiverNPC = "Faluose",
		MinLevel = 8,

		Description = "Menj vissza a Városőrhöz, és figyelmeztesd a közelgő veszélyre.",
		AcceptText = "A Városőrnek fel kell készülnie. Menj vissza hozzá, és mondd meg neki, hogy a Metin kövek aktivitása növekszik.",
		CompleteText = "A Falu Őse is aggódik? Akkor azonnal megerősítem az őrséget.",
		IsRepeatable = false
	},

	["A nagy figyelmeztetés"] = {
		Type = "Talk",
		TargetNPC = "Faluose",

		RewardExp = 300,
		RewardGold = 400,
		RewardItem = "Nagy Mana Ital",
		RewardItemCount = 5,

		GiverNPC = "Kovacs",
		MinLevel = 12,

		Description = "Menj vissza a Falu Őséhez a Kovács jelentésével.",
		AcceptText = "A szilánkok nem természetesek. Ezt azonnal el kell mondanod a Falu Ősének. Menj vissza hozzá!",
		CompleteText = "Értem... tehát a Kovács is érzi bennük a torzulást. Akkor nincs több időnk várni.",
		IsRepeatable = false
	}
}

return QuestDatabase