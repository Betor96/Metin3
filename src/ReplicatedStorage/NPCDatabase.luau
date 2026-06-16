local NPCDatabase = {
	-- SIMA NPC-K (Csak mondanak valamit)
	["Faluose"] = {
		Name = "Falu Vénje",
		Type = "Regular",
		Dialogues = {
			"A kovács egy aljas ember... vigyázz vele! A múltkor is betörte a +8-as kardomat...",
			"Úgy hallottam, hogy a messzi barlangokban hatalmas kincsek rejtőznek!",
			"Fiatal koromban én is harcos voltam, de aztán kaptam egy nyilat a térdembe..."
		}
	},

	-- KÜLDETÉST ADÓ NPC-K
	["Varosor"] = {
		Name = "Városőr",
		Type = "QuestGiver",
		QuestName = "VadkutyaVadaszat", -- Összekötjük a fenti küldetéssel
		Dialogues = {
			NotStarted = "Hé te! Túl sok a Vadkutya a falu körül, veszélyeztetik a lakókat. Lenyomnál 5 darabot? Jól megfizetem!",
			InProgress = "Még nem végeztél a kutyákkal! Igyekezz, a lakók félnek!",
			ReadyToTurnIn = "Nagyszerű munka, igazi hős vagy! Itt vannak a jutalmaid.",
			Completed = "Köszönöm, hogy megmentetted a falut! Most végre béke van."
		}
	}
}

return NPCDatabase