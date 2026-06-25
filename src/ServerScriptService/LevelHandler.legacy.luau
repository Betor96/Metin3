-- Fájl helye: ServerScriptService -> LevelHandler

local Players = game:GetService("Players")

-- ==========================================
-- BEÁLLÍTÁSOK
-- ==========================================
local MAX_LEVEL = 50 -- IDE ÍRHATOD MAJD A JÖVŐBEN AZ ÚJ SZINTKORLÁTOT!

-- Tapasztalat pont szükséglet kiszámítása (Matematikai görbe)
local function getNextLevelXP(level)
	return (level ^ 2) * 100 + (level * 500)
end

-- ==========================================
-- JAVÍTÁS: A HP számolást átadtuk a StatHandlernek!
-- Ez a függvény most már csak megvárja, amíg a StatHandler lefut,
-- majd felgyógyítja a játékost a maximális HP-ra és Manára.
-- ==========================================
local function healCharacter(player)
	task.wait(0.1) -- Várunk egy picit, hogy a StatHandler beállítsa az új maximumokat
	local character = player.Character
	local stats = player:FindFirstChild("PlayerStats")

	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth -- Teljes HP gyógyítás
		end
	end

	if stats then
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")
		if mana and maxMana then
			mana.Value = maxMana.Value -- Teljes Mana töltés
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local stats = player:WaitForChild("PlayerStats", 99999)
	local exp = stats:WaitForChild("Experience", 99999)
	local level = stats:WaitForChild("Level", 99999)
	local statPoints = stats:WaitForChild("StatPoints", 99999)
	local mana = stats:WaitForChild("Mana", 99999)
	local maxMana = stats:WaitForChild("MaxMana", 99999)
	local leaderstats = player:WaitForChild("leaderstats", 99999)
	local leaderLevel = leaderstats:WaitForChild("Level", 99999)

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
		healCharacter(player) -- Újraéledéskor felgyógyít
	end)

	if player.Character then 
		createOverhead(player.Character) 
		healCharacter(player)
	end

	-- ==========================================
	-- SZINTLÉPÉS LOGIKA (SZINTKORLÁTTAL)
	-- ==========================================
	exp.Changed:Connect(function()
		if level.Value >= MAX_LEVEL then
			if exp.Value > maxExp.Value then
				exp.Value = maxExp.Value 
			end
			return
		end

		local leveledUp = false -- JAVÍTÁS: Flag a gyógyításhoz

		while exp.Value >= maxExp.Value do
			if level.Value >= MAX_LEVEL then
				exp.Value = maxExp.Value
				break
			end

			exp.Value = exp.Value - maxExp.Value
			level.Value = level.Value + 1
			leaderLevel.Value = level.Value 

			statPoints.Value = statPoints.Value + 3
			maxExp.Value = getNextLevelXP(level.Value)

			leveledUp = true
			print(player.Name .. " szintet lépett! Új szint: " .. level.Value)
		end

		-- JAVÍTÁS: A gyógyítást (amiben task.wait van) csak a ciklus UTÁN, egyszer hívjuk meg!
		if leveledUp then
			task.spawn(function()
				healCharacter(player)
			end)
		end
	end)
end)