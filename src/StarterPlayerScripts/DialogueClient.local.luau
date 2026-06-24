-- Fájl helye: StarterPlayerScripts -> DialogueClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Events = ReplicatedStorage:WaitForChild("Events")
local AcceptQuest = Events:WaitForChild("AcceptQuest")
local CompleteQuest = Events:WaitForChild("CompleteQuest")
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

-- GUI Létrehozása
local gui = Instance.new("ScreenGui")
gui.Name = "DialogueHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ==========================================
-- 1. ABLAK: KÜLDETÉS LISTA (Középen)
-- ==========================================
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
mainFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
mainFrame.BorderSizePixel = 2
mainFrame.Visible = false
mainFrame.Active = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
title.BorderColor3 = Color3.fromRGB(180, 140, 50)
title.BorderSizePixel = 1
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -5, 0, 5)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
closeBtn.BorderSizePixel = 2
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- JAVÍTÁS: Középre igazítjuk a küldetéseket!

-- ==========================================
-- 2. ABLAK: PÁRBESZÉD ABLAK (Képernyő alján)
-- ==========================================
local dialogFrame = Instance.new("Frame", gui)
dialogFrame.Size = UDim2.new(0, 600, 0, 150)
dialogFrame.AnchorPoint = Vector2.new(0.5, 1) 
dialogFrame.Position = UDim2.new(0.5, 0, 1, -50) 
dialogFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
dialogFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
dialogFrame.BorderSizePixel = 2
dialogFrame.BackgroundTransparency = 0.1
dialogFrame.Visible = false
dialogFrame.Active = true

local npcNameText = Instance.new("TextLabel", dialogFrame)
npcNameText.Size = UDim2.new(1, -20, 0, 30)
npcNameText.Position = UDim2.new(0, 10, 0, 5)
npcNameText.BackgroundTransparency = 1
npcNameText.TextColor3 = Color3.fromRGB(255, 215, 0)
npcNameText.Font = Enum.Font.GothamBlack
npcNameText.TextSize = 18
npcNameText.TextXAlignment = Enum.TextXAlignment.Left

local dialogText = Instance.new("TextLabel", dialogFrame)
dialogText.Size = UDim2.new(1, -40, 1, -80)
dialogText.Position = UDim2.new(0, 20, 0, 40)
dialogText.BackgroundTransparency = 1
dialogText.TextColor3 = Color3.new(1, 1, 1)
dialogText.Font = Enum.Font.Gotham
dialogText.TextSize = 16
dialogText.TextWrapped = true
dialogText.TextXAlignment = Enum.TextXAlignment.Left
dialogText.TextYAlignment = Enum.TextYAlignment.Top

local buttonContainer = Instance.new("Frame", dialogFrame)
buttonContainer.Size = UDim2.new(1, -20, 0, 40)
buttonContainer.Position = UDim2.new(0, 10, 1, -45)
buttonContainer.BackgroundTransparency = 1

local uiListLayout = Instance.new("UIListLayout", buttonContainer)
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
uiListLayout.Padding = UDim.new(0, 10)


-- ==========================================
-- LOGIKA
-- ==========================================
-- Védett NPC-k listája (CSAK A KÜLDETÉS NPC-K MARADTAK!)
local protectedNPCs = {
	["Kovacs"] = true, 
	["Faluose"] = true,
	["Varosor"] = true
}

local currentInteractNPC = nil

-- Megmutatja az alsó beszélgető ablakot
local function showConversation(npcName, text, options)
	mainFrame.Visible = false -- Eltüntetjük a listát
	dialogFrame.Visible = true -- Hozzuk az alsó ablakot

	npcNameText.Text = npcName
	dialogText.Text = text

	-- Töröljük a régi válasz gombokat
	for _, child in pairs(buttonContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Létrehozzuk az új válaszokat (Elfogad / Lead)
	for _, opt in ipairs(options) do
		local btn = Instance.new("TextButton", buttonContainer)
		btn.Size = UDim2.new(0, 150, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
		btn.BorderColor3 = Color3.fromRGB(180, 140, 50)
		btn.BorderSizePixel = 1
		btn.TextColor3 = Color3.fromRGB(255, 215, 0)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Text = opt.Text

		btn.MouseButton1Click:Connect(function()
			if opt.Action then opt.Action() end
			dialogFrame.Visible = false
		end)
	end
end

-- Megmutatja a középső Küldetés Listát
local function openDialogueList(npcName)
	title.Text = npcName
	dialogFrame.Visible = false

	-- JAVÍTÁS: Törlünk MINDENT (Frame-eket és Szövegeket is), kivéve a beállító Layout-ot!
	for _, c in pairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then 
			c:Destroy() 
		end
	end

	local pLevel = 1
	if player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("Level") then
		pLevel = player.PlayerStats.Level.Value
	end

	local activeQuests = player:FindFirstChild("Quests")
	local completedQuests = player:FindFirstChild("CompletedQuests")
	local hasAny = false

	for qName, qData in pairs(QuestDatabase) do
		local minLvl = qData.MinLevel or 1
		local maxLvl = minLvl + 10 

		local isCompleted = completedQuests and completedQuests:FindFirstChild(qName)
		local isActive = activeQuests and activeQuests:FindFirstChild(qName)

		if isCompleted then continue end 
		if not isActive and (pLevel < minLvl or pLevel > maxLvl) then continue end

		local showQuest = false
		local buttonText = ""
		local btnColor = Color3.fromRGB(120, 90, 30)
		local isCompleteAction = false
		local isAcceptAction = false
		local isClickable = true

		if qData.GiverNPC == npcName then
			if not isActive then
				showQuest = true
				isAcceptAction = true
				buttonText = "KÜLDETÉS FELVÉTELE"
				btnColor = Color3.fromRGB(120, 90, 30)
			else
				if qData.Type == "Talk" then
					showQuest = true
					isClickable = false
					buttonText = "FOLYAMATBAN (Irány: " .. qData.TargetNPC .. ")"
					btnColor = Color3.fromRGB(80, 80, 80)
				else
					showQuest = true
					isCompleteAction = true
					buttonText = "KÜLDETÉS LEADÁSA"
					btnColor = Color3.fromRGB(40, 120, 40)
				end
			end

		elseif qData.TargetNPC == npcName and isActive and qData.Type == "Talk" then
			showQuest = true
			isCompleteAction = true
			buttonText = "KÜLDETÉS TELJESÍTÉSE"
			btnColor = Color3.fromRGB(40, 120, 40)
		end

		if showQuest then
			hasAny = true

			local qFrame = Instance.new("Frame", scroll)
			qFrame.Size = UDim2.new(1, -10, 0, 110)
			qFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 15)
			qFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
			qFrame.BorderSizePixel = 1

			local qTitle = Instance.new("TextLabel", qFrame)
			qTitle.Size = UDim2.new(1, -10, 0, 20)
			qTitle.Position = UDim2.new(0, 5, 0, 5)
			qTitle.BackgroundTransparency = 1
			qTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
			qTitle.Font = Enum.Font.GothamBold
			qTitle.Text = qName .. " (Szint: " .. minLvl .. "-" .. maxLvl .. ")"
			qTitle.TextXAlignment = Enum.TextXAlignment.Left

			local qDesc = Instance.new("TextLabel", qFrame)
			qDesc.Size = UDim2.new(1, -10, 0, 40)
			qDesc.Position = UDim2.new(0, 5, 0, 30)
			qDesc.BackgroundTransparency = 1
			qDesc.TextColor3 = Color3.new(1, 1, 1)
			qDesc.Font = Enum.Font.Gotham
			qDesc.TextSize = 12
			qDesc.TextWrapped = true
			qDesc.TextXAlignment = Enum.TextXAlignment.Left
			qDesc.TextYAlignment = Enum.TextYAlignment.Top
			qDesc.Text = qData.Description

			local qBtn = Instance.new("TextButton", qFrame)
			qBtn.Size = UDim2.new(1, -10, 0, 30)
			qBtn.Position = UDim2.new(0, 5, 0, 75)
			qBtn.Font = Enum.Font.GothamBold
			qBtn.BackgroundColor3 = btnColor
			qBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
			qBtn.BorderSizePixel = 1
			qBtn.TextColor3 = Color3.new(1, 1, 1)
			qBtn.Text = buttonText
			qBtn.Active = isClickable

			if isClickable then
				qBtn.MouseButton1Click:Connect(function()
					-- HA FELVESZI: Alsó ablak megnyitása
					if isAcceptAction then
						local text = qData.AcceptText or qData.Description
						showConversation(npcName, text, {
							{Text = "Elfogadom", Action = function() AcceptQuest:FireServer(qName) end},
							{Text = "Mégse", Action = function() dialogFrame.Visible = false mainFrame.Visible = true end}
						})

						-- HA LEADJA: Alsó ablak megnyitása
					elseif isCompleteAction then
						local text = qData.CompleteText or "Köszönöm a segítséged! Itt a jutalmad."
						showConversation(npcName, text, {
							{Text = "Jutalom átvétele", Action = function() CompleteQuest:FireServer(qName) end}
						})
					end
				end)
			end
		end
	end

	if not hasAny then
		local msg = Instance.new("TextLabel", scroll)
		msg.Size = UDim2.new(1, 0, 0, 50)
		msg.BackgroundTransparency = 1
		msg.TextColor3 = Color3.new(1, 1, 1)
		msg.Font = Enum.Font.Gotham
		msg.Text = "Nincs számodra elérhető küldetés."
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	mainFrame.Visible = true

	local highest = 0
	for _, g in pairs(player.PlayerGui:GetChildren()) do
		-- Biztonsági kivételek bővítése!
		if g:IsA("ScreenGui") and g ~= gui and g.Name ~= "TooltipHUD" and g.Name ~= "SkillTooltipGUI" then
			if g.DisplayOrder > highest then highest = g.DisplayOrder end
		end
	end
	gui.DisplayOrder = highest + 1
end

-- Kattintás érzékelése a 3D világban
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			if model and protectedNPCs[model.Name] then
				local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if myRoot then
					local dist = (myRoot.Position - model:GetPivot().Position).Magnitude
					if dist <= 12 then
						currentInteractNPC = model
						openDialogueList(model.Name)
					end
				end
			end
		end
	end
end)

-- Ha elsétál az NPC-től, zárjon be minden ablakot!
RunService.Heartbeat:Connect(function()
	if (mainFrame.Visible or dialogFrame.Visible) and currentInteractNPC then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and currentInteractNPC:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - currentInteractNPC.HumanoidRootPart.Position).Magnitude
			if dist > 15 then
				mainFrame.Visible = false
				dialogFrame.Visible = false
				currentInteractNPC = nil
			end
		else
			mainFrame.Visible = false
			dialogFrame.Visible = false
			currentInteractNPC = nil
		end
	end
end)