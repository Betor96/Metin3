-- Fájl helye: StarterPlayerScripts -> BankUIClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BankHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local CheckBankPwd = Events:WaitForChild("CheckBankPwd")
local ChangeBankPwd = Events:WaitForChild("ChangeBankPwd")
local CloseBank = Events:WaitForChild("CloseBank")

-- ==========================================
-- ÚJ: TOOLTIP MANAGER ÉS ITEM DATABASE BEHÍVÁSA
-- ==========================================
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local TooltipManager = require(ReplicatedStorage:WaitForChild("TooltipManager"))

-- ==========================================
-- AKCIÓ MENÜ (Raktárosra kattintva)
-- ==========================================
local actionMenu = Instance.new("Frame", screenGui)
actionMenu.Size = UDim2.new(0, 200, 0, 150)
actionMenu.Position = UDim2.new(0.5, -100, 0.5, -75)
actionMenu.BackgroundColor3 = Color3.fromRGB(15, 12, 10) -- Metines
actionMenu.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany
actionMenu.BorderSizePixel = 2
actionMenu.Visible = false

local title = Instance.new("TextLabel", actionMenu)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
title.BorderColor3 = Color3.fromRGB(180, 140, 50)
title.BorderSizePixel = 1
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Text = "RAKTÁROS"
title.Font = Enum.Font.GothamBold

local openBtn = Instance.new("TextButton", actionMenu)
openBtn.Size = UDim2.new(1, -20, 0, 30)
openBtn.Position = UDim2.new(0, 10, 0, 40)
openBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
openBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
openBtn.BorderSizePixel = 1
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Text = "Raktár megnyitása"
openBtn.Font = Enum.Font.GothamBold

local changePwdBtn = Instance.new("TextButton", actionMenu)
changePwdBtn.Size = UDim2.new(1, -20, 0, 30)
changePwdBtn.Position = UDim2.new(0, 10, 0, 75)
changePwdBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 30)
changePwdBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
changePwdBtn.BorderSizePixel = 1
changePwdBtn.TextColor3 = Color3.new(1,1,1)
changePwdBtn.Text = "Jelszó frissítése"
changePwdBtn.Font = Enum.Font.GothamBold

local closeActionBtn = Instance.new("TextButton", actionMenu)
closeActionBtn.Size = UDim2.new(1, -20, 0, 30)
closeActionBtn.Position = UDim2.new(0, 10, 0, 110)
closeActionBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
closeActionBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
closeActionBtn.BorderSizePixel = 1
closeActionBtn.TextColor3 = Color3.new(1,1,1)
closeActionBtn.Text = "Bezárás"
closeActionBtn.Font = Enum.Font.GothamBold

-- ==========================================
-- JELSZÓ KÉRŐ ABLAK
-- ==========================================
local pwdFrame = Instance.new("Frame", screenGui)
pwdFrame.Size = UDim2.new(0, 200, 0, 120)
pwdFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
pwdFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
pwdFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
pwdFrame.BorderSizePixel = 2
pwdFrame.Visible = false

local pwdTitle = Instance.new("TextLabel", pwdFrame)
pwdTitle.Size = UDim2.new(1, 0, 0, 30)
pwdTitle.BackgroundTransparency = 1
pwdTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
pwdTitle.Text = "Adja meg a jelszót!"
pwdTitle.Font = Enum.Font.GothamBold

local pwdInput = Instance.new("TextBox", pwdFrame)
pwdInput.Size = UDim2.new(1, -20, 0, 30)
pwdInput.Position = UDim2.new(0, 10, 0, 40)
pwdInput.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
pwdInput.BorderColor3 = Color3.fromRGB(180, 140, 50)
pwdInput.TextColor3 = Color3.new(1,1,1)
pwdInput.Text = ""
pwdInput.PlaceholderText = "6 számjegy"
pwdInput.Font = Enum.Font.Gotham
pwdInput.TextXAlignment = Enum.TextXAlignment.Center

local pwdSubmit = Instance.new("TextButton", pwdFrame)
pwdSubmit.Size = UDim2.new(0.5, -15, 0, 30)
pwdSubmit.Position = UDim2.new(0, 10, 0, 80)
pwdSubmit.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
pwdSubmit.BorderColor3 = Color3.fromRGB(180, 140, 50)
pwdSubmit.TextColor3 = Color3.new(1,1,1)
pwdSubmit.Text = "OK"

local pwdCancel = Instance.new("TextButton", pwdFrame)
pwdCancel.Size = UDim2.new(0.5, -15, 0, 30)
pwdCancel.Position = UDim2.new(0.5, 5, 0, 80)
pwdCancel.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
pwdCancel.BorderColor3 = Color3.fromRGB(180, 140, 50)
pwdCancel.TextColor3 = Color3.new(1,1,1)
pwdCancel.Text = "Mégse"

-- ==========================================
-- JELSZÓ MÓDOSÍTÁS ABLAK
-- ==========================================
local changeFrame = Instance.new("Frame", screenGui)
changeFrame.Size = UDim2.new(0, 200, 0, 200)
changeFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
changeFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
changeFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
changeFrame.BorderSizePixel = 2
changeFrame.Visible = false

local chgTitle = Instance.new("TextLabel", changeFrame)
chgTitle.Size = UDim2.new(1, 0, 0, 30)
chgTitle.BackgroundTransparency = 1
chgTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
chgTitle.Text = "Jelszó Módosítása"
chgTitle.Font = Enum.Font.GothamBold

local oldPwdInput = Instance.new("TextBox", changeFrame)
oldPwdInput.Size = UDim2.new(1, -20, 0, 30)
oldPwdInput.Position = UDim2.new(0, 10, 0, 40)
oldPwdInput.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
oldPwdInput.BorderColor3 = Color3.fromRGB(180, 140, 50)
oldPwdInput.TextColor3 = Color3.new(1,1,1)
oldPwdInput.PlaceholderText = "Régi Jelszó"
oldPwdInput.Text = ""

local newPwdInput = Instance.new("TextBox", changeFrame)
newPwdInput.Size = UDim2.new(1, -20, 0, 30)
newPwdInput.Position = UDim2.new(0, 10, 0, 80)
newPwdInput.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
newPwdInput.BorderColor3 = Color3.fromRGB(180, 140, 50)
newPwdInput.TextColor3 = Color3.new(1,1,1)
newPwdInput.PlaceholderText = "Új Jelszó"
newPwdInput.Text = ""

local newPwdInput2 = Instance.new("TextBox", changeFrame)
newPwdInput2.Size = UDim2.new(1, -20, 0, 30)
newPwdInput2.Position = UDim2.new(0, 10, 0, 120)
newPwdInput2.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
newPwdInput2.BorderColor3 = Color3.fromRGB(180, 140, 50)
newPwdInput2.TextColor3 = Color3.new(1,1,1)
newPwdInput2.PlaceholderText = "Új Jelszó újra"
newPwdInput2.Text = ""

local chgSubmit = Instance.new("TextButton", changeFrame)
chgSubmit.Size = UDim2.new(0.5, -15, 0, 30)
chgSubmit.Position = UDim2.new(0, 10, 0, 160)
chgSubmit.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
chgSubmit.BorderColor3 = Color3.fromRGB(180, 140, 50)
chgSubmit.TextColor3 = Color3.new(1,1,1)
chgSubmit.Text = "Mentés"

local chgCancel = Instance.new("TextButton", changeFrame)
chgCancel.Size = UDim2.new(0.5, -15, 0, 30)
chgCancel.Position = UDim2.new(0.5, 5, 0, 160)
chgCancel.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
chgCancel.BorderColor3 = Color3.fromRGB(180, 140, 50)
chgCancel.TextColor3 = Color3.new(1,1,1)
chgCancel.Text = "Mégse"

local function restrictTo6Digits(box)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local filtered = box.Text:gsub("%D", "") 
		if #filtered > 6 then
			filtered = filtered:sub(1, 6)
		end
		if box.Text ~= filtered then
			box.Text = filtered
		end
	end)
end

restrictTo6Digits(pwdInput)
restrictTo6Digits(oldPwdInput)
restrictTo6Digits(newPwdInput)
restrictTo6Digits(newPwdInput2)

-- ==========================================
-- BANK (RAKTÁR) UI FELÜLET
-- ==========================================
local bankMainFrame = Instance.new("Frame", screenGui)
bankMainFrame.Name = "BankMainFrame"
bankMainFrame.Size = UDim2.new(0, 220, 0, 520)
bankMainFrame.Position = UDim2.new(0.75, -240, 0.5, -260)
bankMainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
bankMainFrame.BorderColor3 = Color3.fromRGB(180, 140, 50)
bankMainFrame.BorderSizePixel = 3
bankMainFrame.Active = true
bankMainFrame.Visible = false

local bankFrameTitle = Instance.new("TextLabel", bankMainFrame)
bankFrameTitle.Size = UDim2.new(1, 0, 0, 30)
bankFrameTitle.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
bankFrameTitle.BorderColor3 = Color3.fromRGB(180, 140, 50)
bankFrameTitle.BorderSizePixel = 1
bankFrameTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
bankFrameTitle.Text = "RAKTÁR"
bankFrameTitle.Font = Enum.Font.GothamBold
bankFrameTitle.Active = true

-- ABLAK MOZGATÁSA (DRAG) A CÍMSORON KERESZTÜL
local draggingBank, dragInputBank, mousePosBank, framePosBank
bankFrameTitle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingBank = true
		mousePosBank = input.Position
		framePosBank = bankMainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then draggingBank = false end
		end)
	end
end)

bankFrameTitle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInputBank = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInputBank and draggingBank then
		local delta = input.Position - mousePosBank
		bankMainFrame.Position = UDim2.new(
			framePosBank.X.Scale, framePosBank.X.Offset + delta.X, 
			framePosBank.Y.Scale, framePosBank.Y.Offset + delta.Y
		)
	end
end)

local bankCloseBtn = Instance.new("TextButton", bankMainFrame)
bankCloseBtn.Size = UDim2.new(0, 30, 0, 30)
bankCloseBtn.Position = UDim2.new(1, -5, 0, 5)
bankCloseBtn.AnchorPoint = Vector2.new(1, 0)
bankCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
bankCloseBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
bankCloseBtn.BorderSizePixel = 2
bankCloseBtn.TextColor3 = Color3.new(1,1,1)
bankCloseBtn.Text = "X"
bankCloseBtn.Font = Enum.Font.GothamBold

local slotContainer = Instance.new("Frame", bankMainFrame)
slotContainer.Size = UDim2.new(0, 205, 0, 405) -- Kicsit megnövelve, hogy ne lógjon ki!
slotContainer.Position = UDim2.new(0.5, -102.5, 0, 40)
slotContainer.BackgroundTransparency = 1

local grid = Instance.new("UIGridLayout", slotContainer)
grid.CellSize = UDim2.new(0, 45, 0, 45)
grid.CellPadding = UDim2.new(0, 5, 0, 5)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center

for i = 1, 32 do
	local uiSlot = Instance.new("Frame", slotContainer)
	uiSlot.Name = "BankSlotUI_" .. i
	uiSlot.BackgroundColor3 = Color3.fromRGB(20, 18, 15)
	uiSlot.BorderColor3 = Color3.fromRGB(180, 140, 50)
	uiSlot.BorderSizePixel = 1
	uiSlot.LayoutOrder = i 
end

local pageNav = Instance.new("Frame", bankMainFrame)
pageNav.Size = UDim2.new(1, -20, 0, 30)
pageNav.Position = UDim2.new(0, 10, 0, 450)
pageNav.BackgroundTransparency = 1

local prevBtn = Instance.new("TextButton", pageNav)
prevBtn.Size = UDim2.new(0, 30, 1, 0)
prevBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
prevBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
prevBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
prevBtn.Text = "<"
prevBtn.Font = Enum.Font.GothamBold

local nextBtn = Instance.new("TextButton", pageNav)
nextBtn.Size = UDim2.new(0, 30, 1, 0)
nextBtn.Position = UDim2.new(1, -30, 0, 0)
nextBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
nextBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
nextBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
nextBtn.Text = ">"
nextBtn.Font = Enum.Font.GothamBold

local pageLabel = Instance.new("TextLabel", pageNav)
pageLabel.Size = UDim2.new(1, -70, 1, 0)
pageLabel.Position = UDim2.new(0, 35, 0, 0)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
pageLabel.Text = "Oldal: 1 / 4"
pageLabel.Font = Enum.Font.GothamBold

local lockOverlay = Instance.new("Frame", bankMainFrame)
lockOverlay.Size = UDim2.new(1, -10, 0, 405)
lockOverlay.Position = UDim2.new(0, 5, 0, 40)
lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lockOverlay.BackgroundTransparency = 0.15
lockOverlay.ZIndex = 20
lockOverlay.Visible = false

local lockText = Instance.new("TextLabel", lockOverlay)
lockText.Size = UDim2.new(1, 0, 0, 40)
lockText.Position = UDim2.new(0, 0, 0, 100)
lockText.BackgroundTransparency = 1
lockText.TextColor3 = Color3.fromRGB(255, 100, 100)
lockText.Text = "EZ AZ OLDAL LE VAN ZÁRVA"
lockText.Font = Enum.Font.GothamBlack
lockText.ZIndex = 21

local buyGoldBtn = Instance.new("TextButton", lockOverlay)
buyGoldBtn.Size = UDim2.new(0.8, 0, 0, 40)
buyGoldBtn.Position = UDim2.new(0.1, 0, 0, 160)
buyGoldBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
buyGoldBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
buyGoldBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
buyGoldBtn.Font = Enum.Font.GothamBold
buyGoldBtn.ZIndex = 21

local buyRobuxBtn = Instance.new("TextButton", lockOverlay)
buyRobuxBtn.Size = UDim2.new(0.8, 0, 0, 40)
buyRobuxBtn.Position = UDim2.new(0.1, 0, 0, 210)
buyRobuxBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
buyRobuxBtn.BorderColor3 = Color3.fromRGB(180, 140, 50)
buyRobuxBtn.TextColor3 = Color3.new(1, 1, 1)
buyRobuxBtn.Text = "Feloldás: 100 Robux"
buyRobuxBtn.Font = Enum.Font.GothamBold
buyRobuxBtn.ZIndex = 21

local bankCurrentPage = 1

-- ==========================================
-- ÚJ: TOOLTIP ADAT GENERÁTOR RAKTÁRHOZ
-- ==========================================
local function getTooltipDataForItem(itemName)
	local data = ItemDatabase[itemName]
	if not data then return nil end

	local toolData = {
		Name = itemName,
		Icon = "rbxassetid://0",
	}

	if data.Type == "Fegyver" then
		toolData.Active = "Szintkövetelmény: " .. (data.Level or 1)
		toolData.Passive = string.format("Sebzés: <font color='rgb(255,100,50)'>%d - %d</font>", data.MinDmg or 0, data.MaxDmg or 0)
	elseif data.Type == "Páncél" then
		toolData.Active = "Szintkövetelmény: " .. (data.Level or 1)
		toolData.Passive = string.format("Védelem: <font color='rgb(50,150,255)'>+%d Páncél</font>", data.Defense or 0)
	elseif data.Type == "Fogyóeszköz" then
		toolData.Active = "Nyomd meg a gombot vagy kattints duplán a használathoz."
	end

	if data.Description then
		toolData.Passive = (toolData.Passive and (toolData.Passive .. "\n\n") or "") .. "<i>" .. data.Description .. "</i>"
	end

	toolData.BottomStats = {{"Állapot", "Raktárban"}}

	return toolData
end

local function renderBankItems()
	local bankFolder = player:WaitForChild("Bank")
	local stats = player:WaitForChild("PlayerStats",99999)
	local unlockedPages = stats:WaitForChild("BankUnlockedPages")

	pageLabel.Text = "Oldal: " .. bankCurrentPage .. " / 4"

	if bankCurrentPage > unlockedPages.Value then
		lockOverlay.Visible = true
		buyGoldBtn.Text = "Feloldás: " .. (unlockedPages.Value * 50000) .. " Arany"
	else
		lockOverlay.Visible = false
	end

	local uiSlots = {}
	for _, child in pairs(slotContainer:GetChildren()) do
		if child:IsA("Frame") then
			uiSlots[child.LayoutOrder] = child
		end
	end

	for i = 1, 32 do
		local serverSlotNum = ((bankCurrentPage - 1) * 32) + i
		local uiSlot = uiSlots[i]
		local slotVal = bankFolder:FindFirstChild("Slot_" .. serverSlotNum)

		if uiSlot then
			uiSlot.Name = "BankSlot_" .. serverSlotNum 
			uiSlot:ClearAllChildren()
			if slotVal and slotVal.Value ~= "" then
				local itemIcon = Instance.new("TextLabel", uiSlot)
				itemIcon.Size = UDim2.new(1, -4, 1, -4)
				itemIcon.Position = UDim2.new(0, 2, 0, 2)
				itemIcon.BackgroundColor3 = Color3.fromRGB(40, 30, 20) -- Metines
				itemIcon.TextColor3 = Color3.new(1, 1, 1)
				itemIcon.Text = slotVal.Value
				itemIcon.TextScaled = true
				itemIcon.Font = Enum.Font.GothamBold

				local amtVal = slotVal:FindFirstChild("Amount")
				if amtVal and amtVal.Value > 1 then
					local amtLabel = Instance.new("TextLabel", itemIcon)
					amtLabel.Size = UDim2.new(0, 15, 0, 15)
					amtLabel.Position = UDim2.new(1, -15, 1, -15) 
					amtLabel.BackgroundTransparency = 1
					amtLabel.TextColor3 = Color3.new(1, 1, 1)
					amtLabel.TextStrokeTransparency = 0 
					amtLabel.Text = tostring(amtVal.Value)
					amtLabel.Font = Enum.Font.GothamBold
					amtLabel.TextSize = 12
				end

				-- HOVER TOOLTIP AZ RAKTÁRBAN
				itemIcon.MouseEnter:Connect(function()
					local tData = getTooltipDataForItem(slotVal.Value)
					if tData then TooltipManager.show(tData) end
				end)
				itemIcon.MouseLeave:Connect(function() TooltipManager.hide() end)
			end
		end
	end
end

nextBtn.MouseButton1Click:Connect(function()
	if bankCurrentPage < 4 then bankCurrentPage += 1 renderBankItems() end
end)
prevBtn.MouseButton1Click:Connect(function()
	if bankCurrentPage > 1 then bankCurrentPage -= 1 renderBankItems() end
end)

buyGoldBtn.MouseButton1Click:Connect(function() 
	local stats = player:FindFirstChild("PlayerStats")
	local gold = stats and stats:FindFirstChild("Gold")
	local pages = stats and stats:FindFirstChild("BankUnlockedPages")

	if gold and pages then
		local cost = pages.Value * 50000
		if gold.Value >= cost then
			Events:WaitForChild("UnlockBankPageGold"):FireServer()
		else
			local originalText = buyGoldBtn.Text
			buyGoldBtn.Text = "Nincs elég Arany!"
			task.wait(1.5)
			buyGoldBtn.Text = originalText
		end
	end
end)

-- Biztonságos, szimpla Robux hívás
buyRobuxBtn.MouseButton1Click:Connect(function() 
	Events:WaitForChild("PromptBankRobuxUnlock"):FireServer() 
end)

bankCloseBtn.MouseButton1Click:Connect(function() 
	bankMainFrame.Visible = false
	CloseBank:FireServer()
	TooltipManager.hide()
end)

task.spawn(function()
	local bankFolder = player:WaitForChild("Bank")
	for _, slot in pairs(bankFolder:GetChildren()) do
		slot.Changed:Connect(renderBankItems)
		local amt = slot:WaitForChild("Amount", 2)
		if amt then
			amt.Changed:Connect(renderBankItems)
		end
	end
	bankFolder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ValueBase") then descendant.Changed:Connect(renderBankItems) end
		renderBankItems()
	end)
	bankFolder.DescendantRemoving:Connect(renderBankItems)
	local stats = player:WaitForChild("PlayerStats")
	if stats:WaitForChild("BankUnlockedPages") then
		stats.BankUnlockedPages.Changed:Connect(renderBankItems)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = player:GetMouse().Target
		if target and target:FindFirstAncestor("Raktaros") then
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local npcRoot = target:FindFirstAncestor("Raktaros"):FindFirstChild("HumanoidRootPart") or target:FindFirstAncestor("Raktaros"):GetPivot()
			if myRoot and npcRoot then
				if (myRoot.Position - npcRoot.Position).Magnitude <= 12 then
					actionMenu.Visible = true
				end
			end
		end
	end
end)

closeActionBtn.MouseButton1Click:Connect(function() actionMenu.Visible = false end)
openBtn.MouseButton1Click:Connect(function()
	actionMenu.Visible = false
	pwdInput.Text = ""
	pwdFrame.Visible = true
end)
changePwdBtn.MouseButton1Click:Connect(function()
	actionMenu.Visible = false
	oldPwdInput.Text = ""
	newPwdInput.Text = ""
	newPwdInput2.Text = ""
	changeFrame.Visible = true
end)
pwdCancel.MouseButton1Click:Connect(function()
	pwdFrame.Visible = false
	CloseBank:FireServer()
end)
chgCancel.MouseButton1Click:Connect(function() changeFrame.Visible = false end)

pwdSubmit.MouseButton1Click:Connect(function()
	local success = CheckBankPwd:InvokeServer(pwdInput.Text)
	if success then
		pwdFrame.Visible = false
		bankMainFrame.Visible = true
		renderBankItems()
		local invHud = player.PlayerGui:FindFirstChild("InventoryHUD")
		if invHud and invHud:FindFirstChild("MainFrame") then invHud.MainFrame.Visible = true end
	else
		pwdInput.Text = ""
		pwdInput.PlaceholderText = "Hibás jelszó!"
	end
end)

chgSubmit.MouseButton1Click:Connect(function()
	if newPwdInput.Text ~= newPwdInput2.Text then
		newPwdInput.Text = ""
		newPwdInput2.Text = ""
		newPwdInput.PlaceholderText = "Nem egyezik!"
		return
	end
	local success, msg = ChangeBankPwd:InvokeServer(oldPwdInput.Text, newPwdInput.Text)
	if success then
		changeFrame.Visible = false
		actionMenu.Visible = true
	else
		oldPwdInput.Text = ""
		oldPwdInput.PlaceholderText = msg
	end
end)