-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> MainHUDClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local SkillDatabase = require(ReplicatedStorage:WaitForChild("SkillDatabase"))
local Events = ReplicatedStorage:WaitForChild("Events")

-- 1. Hotbar mappa biztosítása
local hotbarFolder = player:FindFirstChild("Hotbar")
if not hotbarFolder then
	hotbarFolder = Instance.new("Folder")
	hotbarFolder.Name = "Hotbar"
	for i = 1, 8 do
		local slotVal = Instance.new("StringValue")
		slotVal.Name = "Hotbar_" .. i
		slotVal.Value = ""
		slotVal.Parent = hotbarFolder
	end
	hotbarFolder.Parent = player
end

-- 2. GUI Létrehozása (Azonnal, várakozás nélkül!)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MetinHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.Parent = playerGui

-- HP/MP/EXP Container
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 300, 0, 80)
statusContainer.AnchorPoint = Vector2.new(1, 1) 
statusContainer.Position = UDim2.new(0.5, -230, 1, -20) 
statusContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
statusContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
statusContainer.BorderSizePixel = 2
statusContainer.Parent = screenGui

-- Életerő
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
hpText.Text = "0 / 0"

-- Mana
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
mpText.Text = "0 / 0"

-- EXP
local expBg = Instance.new("Frame", statusContainer)
expBg.Size = UDim2.new(1, -20, 0, 10)
expBg.Position = UDim2.new(0, 10, 0, 60)
expBg.BackgroundColor3 = Color3.fromRGB(30, 30, 15)
expBg.BorderSizePixel = 0

local expBar = Instance.new("Frame", expBg)
expBar.Size = UDim2.new(0.5, 0, 1, 0)
expBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
expBar.BorderSizePixel = 0

-- 3. Frissítő függvények (Életerő és Mana számítás)
local currentHumanoid = nil

local function updateHP()
	if currentHumanoid then
		local percent = math.clamp(currentHumanoid.Health / currentHumanoid.MaxHealth, 0, 1)
		hpBar.Size = UDim2.new(percent, 0, 1, 0)
		hpText.Text = math.floor(currentHumanoid.Health) .. " / " .. math.floor(currentHumanoid.MaxHealth)
	end
end

local function setupCharacter(char)
	currentHumanoid = char:WaitForChild("Humanoid")
	currentHumanoid.HealthChanged:Connect(updateHP)
	updateHP()
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end

local function updateMPXP()
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")
		if mana and maxMana and maxMana.Value > 0 then
			local mPerc = math.clamp(mana.Value / maxMana.Value, 0, 1)
			mpBar.Size = UDim2.new(mPerc, 0, 1, 0)
			mpText.Text = math.floor(mana.Value) .. " / " .. math.floor(maxMana.Value)
		end

		local exp = stats:FindFirstChild("Experience")
		local maxExp = stats:FindFirstChild("MaxExperience")
		if exp and maxExp and maxExp.Value > 0 then
			local ePerc = math.clamp(exp.Value / maxExp.Value, 0, 1)
			expBar.Size = UDim2.new(ePerc, 0, 1, 0)
		end
	end
end

task.spawn(function()
	task.wait(0.5)
	updateMPXP()
	while task.wait(0.5) do updateMPXP() end
end)

-- 4. Hotbar UI és Gombok
local hotbarContainer = Instance.new("Frame")
hotbarContainer.Size = UDim2.new(0, 440, 0, 60)
hotbarContainer.AnchorPoint = Vector2.new(0.5, 1) 
hotbarContainer.Position = UDim2.new(0.5, 0, 1, -20) 
hotbarContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
hotbarContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
hotbarContainer.BorderSizePixel = 2
hotbarContainer.Active = true 
hotbarContainer.Parent = screenGui

local uiList = Instance.new("UIListLayout", hotbarContainer)
uiList.FillDirection = Enum.FillDirection.Horizontal
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 5)

for i = 1, 8 do
	if i == 5 then
		local gap = Instance.new("Frame")
		gap.Name = "HotbarGap"
		gap.Size = UDim2.new(0, 20, 0, 45) 
		gap.BackgroundTransparency = 1
		gap.Parent = hotbarContainer
	end

	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "HotbarSlotUI_" .. i
	slotFrame.Size = UDim2.new(0, 45, 0, 45)
	slotFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
	slotFrame.BorderColor3 = Color3.fromRGB(80, 60, 40)
	slotFrame.BorderSizePixel = 1
	slotFrame.Active = true 
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

	-- Sötétítő réteg a Cooldown animációkhoz
	local cdOverlay = Instance.new("Frame", slotFrame)
	cdOverlay.Name = "CDOverlay"
	cdOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.5
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1) 
	cdOverlay.ZIndex = 4
	cdOverlay.Visible = false
end

-- ==========================================
-- Gombok frissítése (Mennyiség, Színek, Ikonok)
-- ==========================================
local function renderHotbar()
	local hbFolder = player:FindFirstChild("Hotbar")
	local invFolder = player:FindFirstChild("Inventory")
	if not hbFolder or not invFolder then return end

	for i = 1, 8 do
		local slotVal = hbFolder:FindFirstChild("Hotbar_" .. i)
		local uiSlot = hotbarContainer:FindFirstChild("HotbarSlotUI_" .. i)

		if slotVal and uiSlot then
			local icon = uiSlot:FindFirstChild("ItemIcon")
			if icon then
				for _, c in pairs(icon:GetChildren()) do c:Destroy() end 

				if slotVal.Value ~= "" then
					icon.Text = slotVal.Value
					local sVal = slotVal.Value

					-- ELLENŐRZÉS: Benne van-e a Képesség Adatbázisban?
					if SkillDatabase.Ranges[sVal] then
						-- KÉPESSÉG (Nincs darabszám)
						icon.BackgroundTransparency = 0
						local isActive = false
						if sVal == "Blade Spirit" and player:GetAttribute("BladeSpirit_Active") then isActive = true end
						if sVal == "Bloodlust" and player:GetAttribute("Bloodlust_Active") then isActive = true end
						if sVal == "Spirit Blessing" and player:GetAttribute("SpiritBlessing_Active") then isActive = true end
						if sVal == "Iron Skin" and player:GetAttribute("IronSkin_Active") then isActive = true end
						if sVal == "Seal of Power" and player:GetAttribute("SealOfPower_Active") then isActive = true end
						if sVal == "Seal of Protection" and player:GetAttribute("SealOfProtection_Active") then isActive = true end

						if isActive then
							icon.BackgroundColor3 = Color3.fromRGB(200, 150, 20) -- ARANY szín, ha aktív a Buff!
						else
							icon.BackgroundColor3 = Color3.fromRGB(80, 40, 120) -- Alapértelmezett LILA szín
						end
						icon.TextTransparency = 0
					else
						-- TÁRGY (Poti, darabszámot számolunk)
						local totalAmount = 0
						for _, invSlot in pairs(invFolder:GetChildren()) do
							if invSlot:IsA("StringValue") and invSlot.Value == sVal then
								local amt = invSlot:FindFirstChild("Amount")
								totalAmount = totalAmount + (amt and amt.Value or 1)
							end
						end

						if totalAmount > 0 then
							icon.BackgroundTransparency = 0
							icon.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
							icon.TextTransparency = 0

							local amtLabel = Instance.new("TextLabel")
							amtLabel.Name = "AmountLabel"
							amtLabel.Size = UDim2.new(0, 20, 0, 20)
							amtLabel.Position = UDim2.new(1, -20, 1, -20) 
							amtLabel.BackgroundTransparency = 1
							amtLabel.TextColor3 = Color3.new(1, 1, 1) 
							amtLabel.TextStrokeColor3 = Color3.new(0, 0, 0) 
							amtLabel.TextStrokeTransparency = 0
							amtLabel.Text = tostring(totalAmount)
							amtLabel.Font = Enum.Font.GothamBold
							amtLabel.TextSize = 14
							amtLabel.ZIndex = 10 
							amtLabel.Parent = icon
						else
							icon.BackgroundTransparency = 0
							icon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
							icon.TextTransparency = 0.6 

							local amtLabel = Instance.new("TextLabel")
							amtLabel.Name = "AmountLabel"
							amtLabel.Size = UDim2.new(0, 20, 0, 20)
							amtLabel.Position = UDim2.new(1, -20, 1, -20)
							amtLabel.BackgroundTransparency = 1
							amtLabel.TextColor3 = Color3.fromRGB(255, 50, 50) 
							amtLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
							amtLabel.TextStrokeTransparency = 0
							amtLabel.Text = "0"
							amtLabel.Font = Enum.Font.GothamBold
							amtLabel.TextSize = 14
							amtLabel.ZIndex = 10 
							amtLabel.Parent = icon
						end
					end
				else
					icon.Text = ""
					icon.BackgroundTransparency = 1
				end
			end
		end
	end
end

-- ==========================================
-- Eseményfigyelők és Várakozás-mentesítés
-- ==========================================
local function setupHotbarConnections()
	local invFolder = player:WaitForChild("Inventory")

	local function triggerUpdate() renderHotbar() end

	invFolder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ValueBase") then descendant.Changed:Connect(triggerUpdate) end
		triggerUpdate()
	end)
	invFolder.DescendantRemoving:Connect(triggerUpdate)

	for _, descendant in pairs(invFolder:GetDescendants()) do
		if descendant:IsA("ValueBase") then descendant.Changed:Connect(triggerUpdate) end
	end
	for _, child in pairs(hotbarFolder:GetChildren()) do
		if child:IsA("ValueBase") then child.Changed:Connect(triggerUpdate) end
	end

	-- Figyeli, ha ránk kerül egy Buff (hogy arany színűre fesse az ikont)
	player.AttributeChanged:Connect(function(attr)
		if attr:match("_Active") then renderHotbar() end
	end)
end

task.spawn(setupHotbarConnections)
task.spawn(renderHotbar)

-- JAVÍTÁS: A Cooldown csatlakozás KÜLÖN SZÁLON várja az eseményt! Nem tud kifagyni a GUI!
task.spawn(function()
	local SkillCooldown = Events:WaitForChild("SkillCooldown", 10) -- 10 mp után feladja a várakozást, de nem fagy ki a script
	if SkillCooldown then
		SkillCooldown.OnClientEvent:Connect(function(skillName, cdTime)
			for i = 1, 8 do
				local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. i)
				local uiSlot = hotbarContainer:FindFirstChild("HotbarSlotUI_" .. i)

				if slotVal and slotVal.Value == skillName and uiSlot then
					local cdOverlay = uiSlot:FindFirstChild("CDOverlay")
					if cdOverlay then
						cdOverlay.Visible = true
						cdOverlay.Size = UDim2.new(1, 0, 1, 0) 

						local tweenInfo = TweenInfo.new(cdTime, Enum.EasingStyle.Linear)
						local tween = TweenService:Create(cdOverlay, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
						tween:Play()

						tween.Completed:Connect(function()
							cdOverlay.Visible = false
						end)
					end
				end
			end
		end)
	end
end)