local QuestDatabase = {
	["VadkutyaVadaszat"] = {
		Title = "Vadkutya Vadászat",
		Type = "Kill",
		Target = "Vadkutya",
		Count = 5,
		Rewards = {
			Exp = 500,
			Gold = 100,
			Item = "Életerő Ital"
		}
	},
	["FarkasVadaszat"] = {
		Title = "Farkasok Ritkítása",
		Type = "Kill",
		Target = "Farkas",
		Count = 10,
		Rewards = {
			Exp = 1200,
			Gold = 300,
			Item = "Vas Páncél"
		}
	}
}

return QuestDatabase