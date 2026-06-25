-- Fájl helye: ReplicatedStorage -> TooltipManager

local TooltipManager = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local tooltipGui
local tooltipFrame
local mouseConnection

local uiElements = {}

local SkillDatabase = nil
do
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local skillModule = shared and shared:FindFirstChild("SkillDatabase") or ReplicatedStorage:FindFirstChild("SkillDatabase")

	if skillModule then
		local success, result = pcall(function()
			return require(skillModule)
		end)

		if success then
			SkillDatabase = result
		end
	end
end

function TooltipManager.init()
	tooltipGui = Instance.new("ScreenGui")
	tooltipGui.Name = "SkillTooltipGUI"
	tooltipGui.DisplayOrder = 999999 -- Mindig minden UI fölött legyen
	tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	tooltipGui.IgnoreGuiInset = true
	tooltipGui.ResetOnSpawn = false
	tooltipGui.Parent = player:WaitForChild("PlayerGui")

	-- Fő Ablak (Metines stílus)
	tooltipFrame = Instance.new("Frame", tooltipGui)
	tooltipFrame.Size = UDim2.new(0, 320, 0, 0)
	tooltipFrame.ZIndex = 999999
	tooltipFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10) 
	tooltipFrame.BackgroundTransparency = 0.1
	tooltipFrame.BorderColor3 = Color3.fromRGB(180, 140, 50) 
	tooltipFrame.BorderSizePixel = 2
	tooltipFrame.AutomaticSize = Enum.AutomaticSize.Y 
	tooltipFrame.Visible = false

	local layout = Instance.new("UIListLayout", tooltipFrame)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)

	local padding = Instance.new("UIPadding", tooltipFrame)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)

	-- FELSŐ SZEKCIÓ (Ikon, Név, Mana, CD)
	local topContainer = Instance.new("Frame", tooltipFrame)
	topContainer.Size = UDim2.new(1, 0, 0, 48)
	topContainer.BackgroundTransparency = 1
	topContainer.LayoutOrder = 1

	local icon = Instance.new("ImageLabel", topContainer)
	icon.Size = UDim2.new(0, 48, 0, 48)
	icon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	icon.BorderColor3 = Color3.fromRGB(180, 140, 50)
	uiElements.Icon = icon

	local nameLbl = Instance.new("TextLabel", topContainer)
	nameLbl.Size = UDim2.new(1, -60, 0, 24)
	nameLbl.Position = UDim2.new(0, 56, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 16
	nameLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	uiElements.Name = nameLbl

	local unlockLbl = Instance.new("TextLabel", topContainer)
	unlockLbl.Size = UDim2.new(1, -145, 0, 20)
	unlockLbl.Position = UDim2.new(0, 56, 0, 24)
	unlockLbl.BackgroundTransparency = 1
	unlockLbl.Font = Enum.Font.Gotham
	unlockLbl.TextSize = 13
	unlockLbl.TextColor3 = Color3.fromRGB(180, 220, 180)
	unlockLbl.TextXAlignment = Enum.TextXAlignment.Left
	unlockLbl.Visible = false
	uiElements.UnlockLevel = unlockLbl

	local cdLbl = Instance.new("TextLabel", topContainer)
	cdLbl.Size = UDim2.new(0, 60, 0, 20)
	cdLbl.Position = UDim2.new(1, -60, 0, 0)
	cdLbl.BackgroundTransparency = 1
	cdLbl.Font = Enum.Font.Gotham
	cdLbl.TextSize = 14
	cdLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	cdLbl.TextXAlignment = Enum.TextXAlignment.Right
	uiElements.Cooldown = cdLbl

	local manaLbl = Instance.new("TextLabel", topContainer)
	manaLbl.Size = UDim2.new(0, 80, 0, 20)
	manaLbl.Position = UDim2.new(1, -80, 0, 24)
	manaLbl.BackgroundTransparency = 1
	manaLbl.Font = Enum.Font.Gotham
	manaLbl.TextSize = 14
	manaLbl.TextColor3 = Color3.fromRGB(100, 150, 255) 
	manaLbl.TextXAlignment = Enum.TextXAlignment.Right
	uiElements.Mana = manaLbl

	-- KÖZÉPSŐ SZEKCIÓ (Leírások)
	local sep1 = Instance.new("Frame", tooltipFrame)
	sep1.Size = UDim2.new(1, 0, 0, 1)
	sep1.BackgroundColor3 = Color3.fromRGB(100, 80, 40)
	sep1.BorderSizePixel = 0
	sep1.LayoutOrder = 2

	local activeLbl = Instance.new("TextLabel", tooltipFrame)
	activeLbl.Size = UDim2.new(1, 0, 0, 0)
	activeLbl.AutomaticSize = Enum.AutomaticSize.Y
	activeLbl.BackgroundTransparency = 1
	activeLbl.Font = Enum.Font.Gotham
	activeLbl.TextSize = 14
	activeLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	activeLbl.TextWrapped = true
	activeLbl.RichText = true
	activeLbl.TextXAlignment = Enum.TextXAlignment.Left
	uiElements.Active = activeLbl
	activeLbl.LayoutOrder = 3

	local passiveLbl = Instance.new("TextLabel", tooltipFrame)
	passiveLbl.Size = UDim2.new(1, 0, 0, 0)
	passiveLbl.AutomaticSize = Enum.AutomaticSize.Y
	passiveLbl.BackgroundTransparency = 1
	passiveLbl.Font = Enum.Font.Gotham
	passiveLbl.TextSize = 14
	passiveLbl.TextColor3 = Color3.fromRGB(200, 255, 200)
	passiveLbl.TextWrapped = true
	passiveLbl.RichText = true
	passiveLbl.TextXAlignment = Enum.TextXAlignment.Left
	uiElements.Passive = passiveLbl
	passiveLbl.LayoutOrder = 4

	-- ALSÓ SZEKCIÓ (Táblázatos adatok)
	local sep2 = Instance.new("Frame", tooltipFrame)
	sep2.Size = UDim2.new(1, 0, 0, 1)
	sep2.BackgroundColor3 = Color3.fromRGB(100, 80, 40)
	sep2.BorderSizePixel = 0
	sep2.LayoutOrder = 5
	uiElements.Separator2 = sep2

	local bottomContainer = Instance.new("Frame", tooltipFrame)
	bottomContainer.Size = UDim2.new(1, 0, 0, 0)
	bottomContainer.AutomaticSize = Enum.AutomaticSize.Y
	bottomContainer.BackgroundTransparency = 1
	bottomContainer.LayoutOrder = 6
	uiElements.BottomContainer = bottomContainer

	local bottomLayout = Instance.new("UIListLayout", bottomContainer)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Padding = UDim.new(0, 4)

	for _, obj in pairs(tooltipFrame:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.ZIndex = 999999
		end
	end
end

function TooltipManager.show(data)
	if not tooltipGui then TooltipManager.init() end
	if not data then return end

	uiElements.Name.Text = data.Name or "Ismeretlen"
	uiElements.Icon.Image = data.Icon or ""

	-- ÚJ: Skill feloldási szint kijelzése
	local requiredLevel = nil
	local isSkill = false

	if SkillDatabase and SkillDatabase.Skills and data.Name and SkillDatabase.Skills[data.Name] then
		isSkill = true

		if SkillDatabase.getSkillRequiredLevel then
			requiredLevel = SkillDatabase.getSkillRequiredLevel(data.Name)
		else
			requiredLevel = 1
		end
	end

	if isSkill and requiredLevel then
		local stats = player:FindFirstChild("PlayerStats")
		local levelObj = stats and stats:FindFirstChild("Level")
		local playerLevel = levelObj and levelObj.Value or 1

		uiElements.UnlockLevel.Visible = true
		uiElements.UnlockLevel.Text = "Feloldás: " .. tostring(requiredLevel) .. ". szint"

		if playerLevel < requiredLevel then
			uiElements.UnlockLevel.TextColor3 = Color3.fromRGB(255, 100, 100)
		else
			uiElements.UnlockLevel.TextColor3 = Color3.fromRGB(180, 220, 180)
		end
	else
		uiElements.UnlockLevel.Visible = false
		uiElements.UnlockLevel.Text = ""
	end

	-- ÚJ: Csak akkor írjuk ki a Cooldown-t és a Manát, ha Képességről van szó!
	if data.Cooldown ~= nil or data.Mana ~= nil then
		uiElements.Cooldown.Visible = true
		uiElements.Mana.Visible = true
		uiElements.Cooldown.Text = (data.Cooldown and data.Cooldown > 0) and (data.Cooldown .. "s ⏳") or "Passzív"
		uiElements.Mana.Text = (data.Mana and data.Mana > 0) and (data.Mana .. " Mana") or "Nincs költség"
	else
		-- Ha tárgy (Item), elrejtjük a felső sarkot!
		uiElements.Cooldown.Visible = false
		uiElements.Mana.Visible = false
	end

	uiElements.Active.Text = data.Active and ("<b>Aktív:</b> " .. data.Active) or ""
	uiElements.Active.Visible = (data.Active ~= nil)

	uiElements.Passive.Text = data.Passive and ("<b>Hatás:</b> " .. data.Passive) or ""
	uiElements.Passive.Visible = (data.Passive ~= nil)

	for _, child in pairs(uiElements.BottomContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if data.BottomStats and #data.BottomStats > 0 then
		uiElements.Separator2.Visible = true
		for i, statPair in ipairs(data.BottomStats) do
			local row = Instance.new("Frame", uiElements.BottomContainer)
			row.Size = UDim2.new(1, 0, 0, 16)
			row.BackgroundTransparency = 1
			row.LayoutOrder = i
			row.ZIndex = 999999

			local lblLeft = Instance.new("TextLabel", row)
			lblLeft.Size = UDim2.new(0.5, 0, 1, 0)
			lblLeft.ZIndex = 999999
			lblLeft.BackgroundTransparency = 1
			lblLeft.Font = Enum.Font.Gotham
			lblLeft.TextSize = 13
			lblLeft.TextColor3 = Color3.fromRGB(180, 180, 180)
			lblLeft.TextXAlignment = Enum.TextXAlignment.Left
			lblLeft.Text = statPair[1]

			local lblRight = Instance.new("TextLabel", row)
			lblRight.Size = UDim2.new(0.5, 0, 1, 0)
			lblRight.ZIndex = 999999
			lblRight.Position = UDim2.new(0.5, 0, 0, 0)
			lblRight.BackgroundTransparency = 1
			lblRight.Font = Enum.Font.Gotham
			lblRight.TextSize = 13
			lblRight.TextColor3 = Color3.new(1, 1, 1)
			lblRight.TextXAlignment = Enum.TextXAlignment.Right
			lblRight.Text = "[ " .. statPair[2] .. " ]"
		end
	else
		uiElements.Separator2.Visible = false
	end

	tooltipFrame.Visible = true

	if not mouseConnection then
		mouseConnection = RunService.RenderStepped:Connect(function()
			local screenX = mouse.ViewSizeX
			local screenY = mouse.ViewSizeY

			local xPos = mouse.X + 15
			local yPos = mouse.Y + 15

			if xPos + tooltipFrame.AbsoluteSize.X > screenX then
				xPos = mouse.X - tooltipFrame.AbsoluteSize.X - 15
			end
			if yPos + tooltipFrame.AbsoluteSize.Y > screenY then
				yPos = screenY - tooltipFrame.AbsoluteSize.Y - 15
			end

			tooltipFrame.Position = UDim2.new(0, xPos, 0, yPos)
		end)
	end
end

function TooltipManager.hide()
	if tooltipFrame then tooltipFrame.Visible = false end
	if mouseConnection then
		mouseConnection:Disconnect()
		mouseConnection = nil
	end
end

return TooltipManager