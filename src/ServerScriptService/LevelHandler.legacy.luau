-- Fájl helye: ServerScriptService -> LevelHandler

local Players = game:GetService("Players")

-- Tapasztalat pont szükséglet kiszámítása (Matematikai görbe)
local function getNextLevelXP(level)
	return (level ^ 2) * 100 + (level * 500)
end

-- HP frissítése a statok (Szint és VIT) alapján
local function updateCharacterStats(player)
	local character = player.Character
	local stats = player:FindFirstChild("PlayerStats")
	if character and stats then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local level = stats.Level.Value
			local vit = stats.VIT.Value
			-- Metin2 stílusú HP számítás
			local maxHp = 200 + (level * 30) + (vit * 40)
			humanoid.MaxHealth = maxHp
			humanoid.Health = maxHp -- Teljesre tölti
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local stats = player:WaitForChild("PlayerStats")
	local exp = stats:WaitForChild("Experience")
	local level = stats:WaitForChild("Level")
	local statPoints = stats:WaitForChild("StatPoints")
	local mana = stats:WaitForChild("Mana")
	local maxMana = stats:WaitForChild("MaxMana")
	local leaderstats = player:WaitForChild("leaderstats")
	local leaderLevel = leaderstats:WaitForChild("Level")

	local maxExp = stats:FindFirstChild("MaxExperience") or Instance.new("IntValue", stats)
	maxExp.Name = "MaxExperience"
	maxExp.Value = getNextLevelXP(level.Value)

	-- KARAKTER FEJE FELETTI NÉVTÁBLA LÉTREHOZÁSA
	local function createOverhead(character)
		local head = character:WaitForChild("Head", 5)
		if not head then return end

		local bgui = Instance.new("BillboardGui")
		bgui.Name = "PlayerTag"
		bgui.Size = UDim2.new(0, 150, 0, 30)
		bgui.StudsOffset = Vector3.new(0, 2.5, 0)
		bgui.AlwaysOnTop = true

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = "Lv." .. level.Value .. " " .. player.Name
		txt.TextColor3 = Color3.fromRGB(255, 215, 0)
		txt.Font = Enum.Font.GothamBold
		txt.TextScaled = true
		txt.TextStrokeTransparency = 0.2
		txt.Parent = bgui
		bgui.Parent = head

		level.Changed:Connect(function()
			if txt and txt.Parent then
				txt.Text = "Lv." .. level.Value .. " " .. player.Name
			end
		end)
	end

	player.CharacterAdded:Connect(function(char)
		createOverhead(char)
		updateCharacterStats(player) -- Újraéledéskor frissíti a HP-t
	end)

	if player.Character then 
		createOverhead(player.Character) 
		updateCharacterStats(player)
	end

	-- SZINTLÉPÉS LOGIKA
	exp.Changed:Connect(function()
		while exp.Value >= maxExp.Value do
			exp.Value = exp.Value - maxExp.Value
			level.Value = level.Value + 1
			leaderLevel.Value = level.Value -- Jobb felső sarok frissítése

			statPoints.Value = statPoints.Value + 3
			maxExp.Value = getNextLevelXP(level.Value)

			-- Feltöltjük a HP-t és a Manát szintlépéskor
			updateCharacterStats(player)
			if mana and maxMana then
				mana.Value = maxMana.Value
			end

			print(player.Name .. " szintet lépett! Új szint: " .. level.Value)
		end
	end)
end)