-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> MainHUDClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- ÚJ: TOOLTIP MANAGER ÉS SKILL DATABASE
-- ==========================================
local SkillDatabase = require(ReplicatedStorage:WaitForChild("SkillDatabase"))
local TooltipManager = require(ReplicatedStorage:WaitForChild("TooltipManager"))
local Events = ReplicatedStorage:WaitForChild("Events")

local SyncHotbarSlot = Events:WaitForChild("SyncHotbarSlot", 5)

-- ==================================================
-- PASSZÍV KÉPESSÉG INDIKÁTOROK (ESZKÖZTÁR FÖLÖTT)
-- ==================================================
task.spawn(function()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	if playerGui:FindFirstChild("PassiveIndicatorHUD") then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PassiveIndicatorHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local indicatorFrame = Instance.new("Frame")
	indicatorFrame.Size = UDim2.new(0, 240, 0, 35)
	indicatorFrame.Position = UDim2.new(0.5, -120, 1, -140) 
	indicatorFrame.BackgroundTransparency = 0.3
	indicatorFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10) -- Metines háttér
	indicatorFrame.BorderSizePixel = 0
	indicatorFrame.Visible = false
	indicatorFrame.Parent = screenGui

	local uiCorner = Instance.new("UICorner", indicatorFrame)
	uiCorner.CornerRadius = UDim.new(0, 8)

	-- Arany keret a passzív ablaknak is!
	local stroke = Instance.new("UIStroke", indicatorFrame)
	stroke.Color = Color3.fromRGB(180, 140, 50)
	stroke.Thickness = 1.5

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	textLabel.Text = ""
	textLabel.Parent = indicatorFrame

	local function updateIndicator()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")

		local rawClass = localPlayer:GetAttribute("Class") or (char and char:GetAttribute("Class")) or ""
		local pClass = string.lower(rawClass)

		-- 1. SEALER
		if pClass == "sealer" then
			local charges = localPlayer:GetAttribute("SealCharges") or 0
			if charges > 0 then
				indicatorFrame.Visible = true
				textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
				local bonus = charges * 2
				textLabel.Text = "🔮 Seal Mastery: " .. charges .. "/5 (+" .. bonus .. "%)"
			else
				indicatorFrame.Visible = false
			end

			-- 2. GUARDIAN
		elseif pClass == "guardian" and hum then
			local hpPercent = hum.Health / hum.MaxHealth
			if hpPercent <= 0.50 then
				indicatorFrame.Visible = true
				textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

				local armorBonus = "+10%"
				if hpPercent <= 0.15 then
					armorBonus = "+30%"
				elseif hpPercent <= 0.30 then
					armorBonus = "+20%"
				end

				textLabel.Text = "🛡️ Iron Will Aktív (" .. armorBonus .. " Def)"
			else
				indicatorFrame.Visible = false
			end
		else
			indicatorFrame.Visible = false
		end
	end

	localPlayer:GetAttributeChangedSignal("SealCharges"):Connect(updateIndicator)
	localPlayer:GetAttributeChangedSignal("Class"):Connect(updateIndicator)

	local function setupCharacter(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then hum.HealthChanged:Connect(updateIndicator) end
		char:GetAttributeChangedSignal("Class"):Connect(updateIndicator)
		updateIndicator()
	end

	if localPlayer.Character then setupCharacter(localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(setupCharacter)

	updateIndicator()
end)

-- ==========================================
-- HOTBAR MAINSTREAM
-- ==========================================
local hotbarFolder = player:WaitForChild("Hotbar", 99999)
for i = 1, 8 do
	hotbarFolder:WaitForChild("Hotbar_" .. i, 99999)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MetinHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.Parent = playerGui

-- ==========================================
-- HUD HÁTTEREK METINESÍTÉSE
-- ==========================================
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 300, 0, 80)
statusContainer.AnchorPoint = Vector2.new(1, 1) 
statusContainer.Position = UDim2.new(0.5, -230, 1, -20) 
statusContainer.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
statusContainer.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany keret
statusContainer.BorderSizePixel = 2
statusContainer.Parent = screenGui

local hpBg = Instance.new("Frame", statusContainer)
hpBg.Size = UDim2.new(1, -20, 0, 20)
hpBg.Position = UDim2.new(0, 10, 0, 10)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
hpBg.BorderSizePixel = 1
hpBg.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany

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

local mpBg = Instance.new("Frame", statusContainer)
mpBg.Size = UDim2.new(1, -20, 0, 20)
mpBg.Position = UDim2.new(0, 10, 0, 35)
mpBg.BackgroundColor3 = Color3.fromRGB(10, 10, 40)
mpBg.BorderSizePixel = 1
mpBg.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany

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

local expBg = Instance.new("Frame", statusContainer)
expBg.Size = UDim2.new(1, -20, 0, 10)
expBg.Position = UDim2.new(0, 10, 0, 60)
expBg.BackgroundColor3 = Color3.fromRGB(30, 30, 15)
expBg.BorderSizePixel = 1
expBg.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany

local expBar = Instance.new("Frame", expBg)
expBar.Size = UDim2.new(0.5, 0, 1, 0)
expBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
expBar.BorderSizePixel = 0

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
	currentHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHP)
	updateHP()
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end

-- Dinamikus Mana és XP csík frissítés!
task.spawn(function()
	local stats = player:WaitForChild("PlayerStats")
	local mana = stats:WaitForChild("Mana")
	local maxMana = stats:WaitForChild("MaxMana")
	local exp = stats:WaitForChild("Experience")
	local maxExp = stats:WaitForChild("MaxExperience", 10)

	local function updateMana()
		if maxMana and maxMana.Value > 0 then
			local mPerc = math.clamp(mana.Value / maxMana.Value, 0, 1)
			mpBar.Size = UDim2.new(mPerc, 0, 1, 0)
			mpText.Text = math.floor(mana.Value) .. " / " .. math.floor(maxMana.Value)
		end
	end

	local function updateXP()
		if maxExp and maxExp.Value > 0 then
			local ePerc = math.clamp(exp.Value / maxExp.Value, 0, 1)
			expBar.Size = UDim2.new(ePerc, 0, 1, 0)
		end
	end

	mana.Changed:Connect(updateMana)
	maxMana.Changed:Connect(updateMana)
	exp.Changed:Connect(updateXP)
	if maxExp then maxExp.Changed:Connect(updateXP) end

	updateMana()
	updateXP()
end)

local hotbarContainer = Instance.new("Frame")
hotbarContainer.Size = UDim2.new(0, 440, 0, 60)
hotbarContainer.AnchorPoint = Vector2.new(0.5, 1) 
hotbarContainer.Position = UDim2.new(0.5, 0, 1, -20) 
hotbarContainer.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
hotbarContainer.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany keret
hotbarContainer.BorderSizePixel = 2
hotbarContainer.Active = true 
hotbarContainer.Parent = screenGui

local uiList = Instance.new("UIListLayout", hotbarContainer)
uiList.FillDirection = Enum.FillDirection.Horizontal
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 5)

-- ==========================================
-- GOMBOK LÉTREHOZÁSA ÉS TOOLTIP BEKÖTÉSE
-- ==========================================
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
	slotFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 15) -- Sötét belső
	slotFrame.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany keret
	slotFrame.BorderSizePixel = 1
	slotFrame.Active = true 
	slotFrame.Parent = hotbarContainer

	local numLabel = Instance.new("TextLabel", slotFrame)
	numLabel.Size = UDim2.new(0, 15, 0, 15)
	numLabel.Position = UDim2.new(0, 2, 0, 2)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = tostring(i)
	numLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
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

	local cdOverlay = Instance.new("Frame", slotFrame)
	cdOverlay.Name = "CDOverlay"
	cdOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.5
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1) 
	cdOverlay.ZIndex = 4
	cdOverlay.Visible = false

	-- TOOLTIP HOVER ESEMÉNYEK
	slotFrame.MouseEnter:Connect(function()
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. i)
		if slotVal and slotVal.Value ~= "" then
			local sName = slotVal.Value
			local skillData = SkillDatabase.Skills[sName]

			-- Ha ez egy Képesség
			if skillData and skillData.GetTooltipData then
				TooltipManager.show(skillData.GetTooltipData(player))
			else
				-- Ha ez egy Tárgy (pl. Kis HP Ital)
				TooltipManager.show({
					Name = sName,
					Active = "Fogyóeszköz (Nyomd meg a használathoz)",
				})
			end
		end
	end)

	slotFrame.MouseLeave:Connect(function()
		TooltipManager.hide()
	end)
end

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

					-- Ha KÉPESSÉG van a sloton
					if SkillDatabase.Ranges[sVal] then
						icon.BackgroundTransparency = 0
						local isActive = false
						if sVal == "Blade Spirit" and player:GetAttribute("BladeSpirit_Active") then isActive = true end
						if sVal == "Bloodlust" and player:GetAttribute("Bloodlust_Active") then isActive = true end
						if sVal == "Spirit Blessing" and player:GetAttribute("SpiritBlessing_Active") then isActive = true end
						if sVal == "Iron Skin" and player:GetAttribute("IronSkin_Active") then isActive = true end
						if sVal == "Seal of Power" and player:GetAttribute("SealOfPower_Active") then isActive = true end
						if sVal == "Seal of Protection" and player:GetAttribute("SealOfProtection_Active") then isActive = true end

						if isActive then
							icon.BackgroundColor3 = Color3.fromRGB(150, 110, 30) -- Aktív, aranyos aura
						else
							icon.BackgroundColor3 = Color3.fromRGB(30, 25, 20) -- Alap, sötét gomb
						end
						icon.TextTransparency = 0

						-- Ha TÁRGY van a sloton
					else
						local totalAmount = 0
						for _, invSlot in pairs(invFolder:GetChildren()) do
							if invSlot:IsA("StringValue") and invSlot.Value == sVal then
								local amt = invSlot:FindFirstChild("Amount")
								totalAmount = totalAmount + (amt and amt.Value or 1)
							end
						end

						if totalAmount > 0 then
							icon.BackgroundTransparency = 0
							icon.BackgroundColor3 = Color3.fromRGB(40, 20, 20) -- Tárgy háttérszín
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
							icon.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
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

	-- SZINKRONIZÁLÁS A SZERVERREL
	for i = 1, 8 do
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. i)
		if slotVal then
			slotVal.Changed:Connect(function()
				triggerUpdate()
				if SyncHotbarSlot then
					SyncHotbarSlot:FireServer(i, slotVal.Value)
				end
			end)
		end
	end

	player.AttributeChanged:Connect(function(attr)
		if attr:match("_Active") then renderHotbar() end
	end)
end

task.spawn(setupHotbarConnections)
task.spawn(renderHotbar)

task.spawn(function()
	local SkillCooldown = Events:WaitForChild("SkillCooldown", 10) 
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