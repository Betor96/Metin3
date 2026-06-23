-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> CharacterUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local stats = player:WaitForChild("PlayerStats", 99999)
local Events = ReplicatedStorage:WaitForChild("Events")
local AddStatPoint = Events:WaitForChild("AddStatPoint")

-- ==========================================
-- KASZTOK ÉS A KÉPESSÉGEK LISTÁJA
-- ==========================================
local classSkills = {
	["GUARDIAN"] = {"Shield Charge", "Earthbreaker", "Blade Spirit", "Iron Skin"},
	["SHADOWBLADE"] = {"Shadow Strike", "Whirling Blades", "Bloodlust", "Death Mark"},
	["SOULWEAVER"] = {"Soul Orb", "Spirit Chain", "Spirit Blessing", "Soul Explosion"},
	["SEALER"] = {"Seal of Power", "Seal of Protection", "Explosive Seal", "Dragon Shackles"}
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterWindow"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.AnchorPoint = Vector2.new(0, 0.5) 
mainFrame.Position = UDim2.new(0.05, 0, 0.5, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true 
mainFrame.Visible = false
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "KARAKTER (C)"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Active = true 
titleLabel.Parent = mainFrame

local charCloseBtn = Instance.new("TextButton")
charCloseBtn.Size = UDim2.new(0, 30, 0, 30)
charCloseBtn.Position = UDim2.new(1, -5, 0, 5) 
charCloseBtn.AnchorPoint = Vector2.new(1, 0)
charCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30) 
charCloseBtn.TextColor3 = Color3.new(1, 1, 1)
charCloseBtn.Text = "X"
charCloseBtn.Font = Enum.Font.GothamBold
charCloseBtn.Parent = mainFrame 

charCloseBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- Ablak mozgatása
local draggingChar, dragInputChar, mousePosChar, framePosChar
titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingChar = true
		mousePosChar = input.Position
		framePosChar = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then draggingChar = false end end)
	end
end)
titleLabel.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputChar = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInputChar and draggingChar then
		local delta = input.Position - mousePosChar
		mainFrame.Position = UDim2.new(framePosChar.X.Scale, framePosChar.X.Offset + delta.X, framePosChar.Y.Scale, framePosChar.Y.Offset + delta.Y)
	end
end)

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local highest = 0
		for _, gui in pairs(player.PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= screenGui and gui.Name ~= "TooltipHUD" then
				if gui.DisplayOrder > highest then highest = gui.DisplayOrder end
			end
		end
		screenGui.DisplayOrder = highest + 1
	end
end)

-- ==========================================
-- OLDALAK (PAGES) LÉTREHOZÁSA (Alap, Bónusz, Képesség)
-- ==========================================
local page1 = Instance.new("Frame", mainFrame)
page1.Size = UDim2.new(1, 0, 1, -80)
page1.Position = UDim2.new(0, 0, 0, 40)
page1.BackgroundTransparency = 1

local page2 = Instance.new("Frame", mainFrame)
page2.Size = UDim2.new(1, 0, 1, -80)
page2.Position = UDim2.new(0, 0, 0, 40)
page2.BackgroundTransparency = 1
page2.Visible = false

local page3 = Instance.new("Frame", mainFrame)
page3.Size = UDim2.new(1, 0, 1, -80)
page3.Position = UDim2.new(0, 0, 0, 40)
page3.BackgroundTransparency = 1
page3.Visible = false

local togglePageBtn = Instance.new("TextButton", mainFrame)
togglePageBtn.Size = UDim2.new(1, 0, 0, 30)
togglePageBtn.Position = UDim2.new(0, 0, 1, -30)
togglePageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
togglePageBtn.TextColor3 = Color3.new(1, 1, 1)
togglePageBtn.Text = "Bónuszok mutatása >>>"
togglePageBtn.Font = Enum.Font.GothamBold

local currentPage = 1
togglePageBtn.MouseButton1Click:Connect(function()
	currentPage = currentPage + 1
	if currentPage > 3 then currentPage = 1 end

	page1.Visible = (currentPage == 1)
	page2.Visible = (currentPage == 2)
	page3.Visible = (currentPage == 3)

	if currentPage == 1 then togglePageBtn.Text = "Bónuszok mutatása >>>"
	elseif currentPage == 2 then togglePageBtn.Text = "Képességek mutatása >>>"
	else togglePageBtn.Text = "<<< Vissza az Alapokhoz" end
end)

-- 1. OLDAL (ALAP STATOK)
local pointsLabel = Instance.new("TextLabel", page1)
pointsLabel.Size = UDim2.new(1, 0, 0, 30)
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
pointsLabel.Text = "Elosztható pontok: 0"
pointsLabel.Font = Enum.Font.GothamBold

local function createBaseStatRow(statId, displayName, yPos)
	local row = Instance.new("Frame", page1)
	row.Size = UDim2.new(1, -20, 0, 40)
	row.Position = UDim2.new(0, 10, 0, yPos)
	row.BackgroundTransparency = 1

	local nameLabel = Instance.new("TextLabel", row)
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = displayName
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local valLabel = Instance.new("TextLabel", row)
	valLabel.Size = UDim2.new(0.2, 0, 1, 0)
	valLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.TextColor3 = Color3.new(1, 1, 1)
	valLabel.Text = "1"
	valLabel.Font = Enum.Font.GothamBold

	local plusBtn = Instance.new("TextButton", row)
	plusBtn.Size = UDim2.new(0, 30, 0, 30)
	plusBtn.Position = UDim2.new(0.85, 0, 0.5, -15)
	plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	plusBtn.TextColor3 = Color3.new(1, 1, 1)
	plusBtn.Text = "+"
	plusBtn.Font = Enum.Font.GothamBold

	plusBtn.MouseButton1Click:Connect(function() AddStatPoint:FireServer(statId) end)
	return valLabel
end

local vitValue = createBaseStatRow("VIT", "VIT (Életerő):", 40)
local intValue = createBaseStatRow("INT", "INT (Mágia):", 80)
local strValue = createBaseStatRow("STR", "STR (Erő):", 120)
local dexValue = createBaseStatRow("DEX", "DEX (Ügyesség):", 160)

-- 2. OLDAL (BÓNUSZOK)
local layout2 = Instance.new("UIListLayout", page2)
layout2.Padding = UDim.new(0, 5)
layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center

local bonusLabels = {}
local function createBonusRow(statName, displayName, suffix)
	local row = Instance.new("Frame", page2)
	row.Size = UDim2.new(1, -20, 0, 20)
	row.BackgroundTransparency = 1

	local nameLabel = Instance.new("TextLabel", row)
	nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.Text = displayName
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local valLabel = Instance.new("TextLabel", row)
	valLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	valLabel.Text = "0" .. suffix
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 12
	valLabel.TextXAlignment = Enum.TextXAlignment.Right

	bonusLabels[statName] = {Label = valLabel, Suffix = suffix}
end

createBonusRow("Defense", "Páncélzat (Védelem):", "")
createBonusRow("StrongVsMonster", "Szörnyek elleni erő:", "%")
createBonusRow("StrongVsMetin", "Metinkövek elleni erő:", "%")
createBonusRow("StrongVsPlayer", "Ember elleni erő:", "%")
createBonusRow("CritChance", "Kritikus találat esélye:", "%")
createBonusRow("LifeSteal", "Életvarázs (Life Steal):", "%")
createBonusRow("AttackSpeed", "Támadási sebesség:", "%")
createBonusRow("MovementSpeed", "Valós mozgási sebesség:", "") -- JAVÍTÁS: Nincs %
createBonusRow("DodgeChance", "Kitérési esély:", "%")
createBonusRow("DoubleDrop", "Dupla tárgydobás esélye:", "%")
createBonusRow("DoubleGold", "Dupla pénz esélye:", "%")

-- ==========================================
-- 3. OLDAL (KÉPESSÉGEK HÚZÁSA)
-- ==========================================
local skillTitle = Instance.new("TextLabel", page3)
skillTitle.Size = UDim2.new(1, 0, 0, 40)
skillTitle.BackgroundTransparency = 1
skillTitle.TextColor3 = Color3.fromRGB(200, 150, 255)
skillTitle.Text = "KÉPESSÉGEK\n(Húzd le őket a Hotbarba!)"
skillTitle.Font = Enum.Font.GothamBold
skillTitle.TextSize = 14

local skillContainer = Instance.new("Frame", page3)
skillContainer.Size = UDim2.new(1, 0, 1, -50)
skillContainer.Position = UDim2.new(0, 0, 0, 50)
skillContainer.BackgroundTransparency = 1

local sLayout = Instance.new("UIGridLayout", skillContainer)
sLayout.CellSize = UDim2.new(0, 80, 0, 80)
sLayout.CellPadding = UDim2.new(0, 20, 0, 20)
sLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function renderSkills()
	for _, child in pairs(skillContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local pClass = player:GetAttribute("Class") or "GUARDIAN"
	local skills = classSkills[string.upper(pClass)] or classSkills["GUARDIAN"]

	for _, skillName in ipairs(skills) do
		local sFrame = Instance.new("Frame", skillContainer)
		sFrame.Name = "SkillUI_" .. skillName 
		sFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
		sFrame.BorderColor3 = Color3.fromRGB(150, 100, 255)
		sFrame.BorderSizePixel = 2
		sFrame.Active = true 

		local sLabel = Instance.new("TextLabel", sFrame)
		sLabel.Size = UDim2.new(1, -4, 1, -4)
		sLabel.Position = UDim2.new(0, 2, 0, 2)
		sLabel.BackgroundTransparency = 1
		sLabel.Text = skillName
		sLabel.TextScaled = true
		sLabel.TextColor3 = Color3.new(1, 1, 1)
		sLabel.Font = Enum.Font.GothamBold
	end
end

player:GetAttributeChangedSignal("Class"):Connect(renderSkills)
renderSkills()

-- ==========================================
-- UI FRISSÍTÉSE
-- ==========================================
local function updateUI()
	if not stats then return end
	pointsLabel.Text = "Elosztható pontok: " .. (stats:FindFirstChild("StatPoints") and stats.StatPoints.Value or 0)
	if stats:FindFirstChild("VIT") then vitValue.Text = tostring(stats.VIT.Value) end
	if stats:FindFirstChild("INT") then intValue.Text = tostring(stats.INT.Value) end
	if stats:FindFirstChild("STR") then strValue.Text = tostring(stats.STR.Value) end
	if stats:FindFirstChild("DEX") then dexValue.Text = tostring(stats.DEX.Value) end

	for statName, data in pairs(bonusLabels) do
		if statName == "MovementSpeed" then
			-- JAVÍTÁS: A szerver által kiszámolt valós sebességet olvassuk le!
			local trueMs = player:GetAttribute("TrueWalkSpeed") or 16
			-- Csak akkor ír tizedesjegyet, ha nem egész szám
			local formattedMs = (trueMs % 1 == 0) and tostring(trueMs) or string.format("%.1f", trueMs)
			data.Label.Text = formattedMs
		else
			local st = stats:FindFirstChild(statName)
			if st then data.Label.Text = tostring(st.Value) .. data.Suffix end
		end
	end
end

for _, child in pairs(stats:GetChildren()) do child.Changed:Connect(updateUI) end
player:GetAttributeChangedSignal("TrueWalkSpeed"):Connect(updateUI) -- Figyeli a valós sebesség változását!
updateUI()