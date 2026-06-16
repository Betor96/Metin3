local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local playerGui = player:WaitForChild("PlayerGui")

-- 1. KÉPERNYŐ LÉTREHOZÁSA
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MetinHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.Parent = playerGui

-- ==========================================
-- BAL ALSÓ SÁV (HP, MP, EXP)
-- ==========================================
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 300, 0, 80)
statusContainer.Position = UDim2.new(0, 20, 1, -100)
statusContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
statusContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
statusContainer.BorderSizePixel = 2
statusContainer.Parent = screenGui

-- Életerő (HP) Piros
local hpBg = Instance.new("Frame", statusContainer)
hpBg.Size = UDim2.new(1, -20, 0, 20)
hpBg.Position = UDim2.new(0, 10, 0, 10)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
hpBg.BorderSizePixel = 1
hpBg.BorderColor3 = Color3.fromRGB(80, 80, 80)

local hpBar = Instance.new("Frame", hpBg)
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
hpBar.BorderSizePixel = 0

local hpText = Instance.new("TextLabel", hpBg)
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.TextColor3 = Color3.new(1,1,1)
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 12
hpText.Text = "0 / 0" -- FIX: Ne maradjon ott a Label felirat az elején

-- Mana (MP) Kék
local mpBg = Instance.new("Frame", statusContainer)
mpBg.Size = UDim2.new(1, -20, 0, 20)
mpBg.Position = UDim2.new(0, 10, 0, 35)
mpBg.BackgroundColor3 = Color3.fromRGB(10, 10, 40)
mpBg.BorderSizePixel = 1
mpBg.BorderColor3 = Color3.fromRGB(80, 80, 80)

local mpBar = Instance.new("Frame", mpBg)
mpBar.Size = UDim2.new(1, 0, 1, 0)
mpBar.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
mpBar.BorderSizePixel = 0

local mpText = Instance.new("TextLabel", mpBg)
mpText.Size = UDim2.new(1, 0, 1, 0)
mpText.BackgroundTransparency = 1
mpText.TextColor3 = Color3.new(1,1,1)
mpText.Font = Enum.Font.GothamBold
mpText.TextSize = 12
mpText.Text = "0 / 0" -- FIX: Ne maradjon ott a Label felirat az elején

-- Tapasztalat (EXP) Arany
local expBg = Instance.new("Frame", statusContainer)
expBg.Size = UDim2.new(1, -20, 0, 10)
expBg.Position = UDim2.new(0, 10, 0, 60)
expBg.BackgroundColor3 = Color3.fromRGB(30, 30, 15)
expBg.BorderSizePixel = 0

local expBar = Instance.new("Frame", expBg)
expBar.Size = UDim2.new(0.5, 0, 1, 0)
expBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
expBar.BorderSizePixel = 0

-- Frissítő funkciók
local function updateHP()
	local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	hpBar.Size = UDim2.new(percent, 0, 1, 0)
	hpText.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
end

humanoid.HealthChanged:Connect(updateHP)
updateHP()

local function updateMPXP()
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		-- Mana frissítése
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")
		if mana and maxMana and maxMana.Value > 0 then
			local mPerc = math.clamp(mana.Value / maxMana.Value, 0, 1)
			mpBar.Size = UDim2.new(mPerc, 0, 1, 0)
			mpText.Text = mana.Value .. " / " .. maxMana.Value
		end

		-- ÚJ: XP Frissítése
		local exp = stats:FindFirstChild("Experience")
		local maxExp = stats:FindFirstChild("MaxExperience")
		if exp and maxExp and maxExp.Value > 0 then
			local ePerc = math.clamp(exp.Value / maxExp.Value, 0, 1)
			expBar.Size = UDim2.new(ePerc, 0, 1, 0)
		end
	end
end

-- Folyamatos frissítés bekapcsolása és azonnali indítás
task.spawn(function()
	task.wait(0.5) -- Egy pillanat türelmi idő a PlayerInit scriptnek
	updateMPXP()
	while task.wait(0.5) do updateMPXP() end
end)

-- ==========================================
-- KÖZÉPSŐ GYORSGOMBOK (HOTBAR 1-4)
-- ==========================================
local hotbarContainer = Instance.new("Frame")
hotbarContainer.Size = UDim2.new(0, 220, 0, 60)
hotbarContainer.Position = UDim2.new(0.5, -110, 1, -80)
hotbarContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
hotbarContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
hotbarContainer.BorderSizePixel = 2
hotbarContainer.Parent = screenGui

local uiList = Instance.new("UIListLayout", hotbarContainer)
uiList.FillDirection = Enum.FillDirection.Horizontal
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 5)

for i = 1, 4 do
	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "HotbarSlotUI_" .. i
	slotFrame.Size = UDim2.new(0, 45, 0, 45)
	slotFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
	slotFrame.BorderColor3 = Color3.fromRGB(80, 60, 40)
	slotFrame.BorderSizePixel = 1
	slotFrame.Parent = hotbarContainer

	local numLabel = Instance.new("TextLabel", slotFrame)
	numLabel.Size = UDim2.new(0, 15, 0, 15)
	numLabel.Position = UDim2.new(0, 2, 0, 2)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = tostring(i)
	numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	numLabel.Font = Enum.Font.GothamBold
	numLabel.TextSize = 10
	numLabel.TextXAlignment = Enum.TextXAlignment.Left
	numLabel.TextYAlignment = Enum.TextYAlignment.Top
	numLabel.ZIndex = 3

	local itemIcon = Instance.new("TextLabel", slotFrame)
	itemIcon.Name = "ItemIcon"
	itemIcon.Size = UDim2.new(1, -4, 1, -4)
	itemIcon.Position = UDim2.new(0, 2, 0, 2)
	itemIcon.BackgroundTransparency = 1
	itemIcon.TextColor3 = Color3.new(1,1,1)
	itemIcon.Text = ""
	itemIcon.TextScaled = true
	itemIcon.Font = Enum.Font.GothamBold
	itemIcon.ZIndex = 2
end

local function renderHotbar()
	local hotbarFolder = player:FindFirstChild("Hotbar")
	if not hotbarFolder then return end

	for i = 1, 4 do
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. i)
		local uiSlot = hotbarContainer:FindFirstChild("HotbarSlotUI_" .. i)

		if slotVal and uiSlot then
			local icon = uiSlot:FindFirstChild("ItemIcon")
			if icon then
				if slotVal.Value ~= "" then
					icon.Text = slotVal.Value
					icon.BackgroundTransparency = 0
					icon.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
				else
					icon.Text = ""
					icon.BackgroundTransparency = 1
				end
			end
		end
	end
end

player:WaitForChild("Hotbar").ChildAdded:Connect(renderHotbar)
for _, child in pairs(player:WaitForChild("Hotbar"):GetChildren()) do
	child.Changed:Connect(renderHotbar)
end
renderHotbar()