-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> MainMenuClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")
local GetCharacterList = Events:WaitForChild("GetCharacterList")
local CreateCharacter = Events:WaitForChild("CreateCharacter")
local SelectCharacter = Events:WaitForChild("SelectCharacter")

local camera = workspace.CurrentCamera

local inMenu = true 

-- HUD ÉS ROBLOX MENÜK ERŐSZAKOS ELREJTÉSE
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

local hudHiderConnection
hudHiderConnection = RunService.RenderStepped:Connect(function()
	if inMenu then
		if player and player:FindFirstChild("PlayerGui") then
			for _, gui in pairs(player.PlayerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Name ~= "MainMenuGUI" then
					gui.Enabled = false
				end
			end
		end
	else
		if player and player:FindFirstChild("PlayerGui") then
			for _, gui in pairs(player.PlayerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Name ~= "MainMenuGUI" then
					gui.Enabled = true
				end
			end
		end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
		hudHiderConnection:Disconnect()
	end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "MainMenuGUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame", sg)
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BackgroundTransparency = 0.2
background.Active = true

local title = Instance.new("TextLabel", background)
title.Size = UDim2.new(1, 0, 0, 80)
title.Position = UDim2.new(0, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "METIN 3 - KARAKTERVÁLASZTÓ"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 36

local slotContainer = Instance.new("Frame", background)
slotContainer.Size = UDim2.new(0, 400, 0, 400)
slotContainer.Position = UDim2.new(0.5, -200, 0.5, -150)
slotContainer.BackgroundTransparency = 1

local classes = {
	{
		Name = "GUARDIAN",
		Role = "Szerep: Tank / Bruiser\nStílus: Lassú, tankos, frontline harcos",
		Desc = "1. Shield Charge: Előrerohan és lök (CC)\n2. Earthbreaker: Erős AOE földcsapás\n3. Blade Spirit: +25% Sebzés, +10% Véd. (Buff)\n4. Iron Skin: 50% Sebzéscsökkentés (6 mp)",
		Stats = "FONTOS: A HP és Sebzés húzása javasolt.\nNEGATÍVUM: Ha sok az INT, a páncélod csökken!"
	},
	{
		Name = "SHADOWBLADE",
		Role = "Szerep: Burst DPS / Assassin\nStílus: Gyors, mobil, magas sebzés",
		Desc = "1. Shadow Strike: Teleport és Burst sebzés\n2. Whirling Blades: Körkörös AOE támadás\n3. Bloodlust: +30% ATK SPD, +15% Mozgás\n4. Death Mark: Megjelöli a célt extra sebzésre",
		Stats = "FONTOS: Ügyesség (DEX) és Sebzés (STR) a fő.\nNEGATÍVUM: Túl sok páncél esetén lelassulsz!"
	},
	{
		Name = "SOULWEAVER",
		Role = "Szerep: AOE DPS / Mage\nStílus: Távolsági, területi sebzés",
		Desc = "1. Soul Orb: Távolsági varázslövedék\n2. Spirit Chain: Célpontok közt ugró sebzés\n3. Spirit Blessing: +25% Sebzés, +10% Mana regen\n4. Soul Explosion: Hatalmas AOE robbanás",
		Stats = "FONTOS: Intelligencia (INT) és Ügyesség (DEX).\nNEGATÍVUM: A túl sok HP csökkenti a sebzésed!"
	},
	{
		Name = "SEALER",
		Role = "Szerep: Support / Control\nStílus: Csapatbuff + boss kontroll",
		Desc = "1. Seal of Power: +20% Sebzés mindenkinek\n2. Seal of Protection: +20% DEF, +15% HP\n3. Explosive Seal: Késleltetett erős robbanás\n4. Dragon Shackles: Célpont lefogása (Root)",
		Stats = "FONTOS: Főleg Intelligencia (INT) és Sebzés.\nNEGATÍVUM: A magas DEX rontja a képességeid!"
	}
}

local currentClassIndex = 1
local activeSlot = 1

local creatorContainer = Instance.new("Frame", background)
creatorContainer.Size = UDim2.new(1, 0, 1, 0)
creatorContainer.BackgroundTransparency = 1
creatorContainer.Visible = false

local classInfoPanel = Instance.new("Frame", creatorContainer)
classInfoPanel.Size = UDim2.new(0, 350, 1, -100)
classInfoPanel.Position = UDim2.new(0, 50, 0, 50)
classInfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
classInfoPanel.BackgroundTransparency = 0.4
classInfoPanel.BorderSizePixel = 2
classInfoPanel.BorderColor3 = Color3.fromRGB(150, 110, 50)

local lblName = Instance.new("TextLabel", classInfoPanel)
lblName.Size = UDim2.new(1, -20, 0, 50)
lblName.Position = UDim2.new(0, 10, 0, 10)
lblName.Font = Enum.Font.GothamBlack
lblName.TextSize = 28
lblName.TextColor3 = Color3.fromRGB(255, 255, 255)
lblName.BackgroundTransparency = 1
lblName.TextXAlignment = Enum.TextXAlignment.Left

local lblRole = Instance.new("TextLabel", classInfoPanel)
lblRole.Size = UDim2.new(1, -20, 0, 40)
lblRole.Position = UDim2.new(0, 10, 0, 60)
lblRole.Font = Enum.Font.GothamBold
lblRole.TextSize = 14
lblRole.TextColor3 = Color3.fromRGB(150, 200, 255)
lblRole.BackgroundTransparency = 1
lblRole.TextXAlignment = Enum.TextXAlignment.Left

local lblDesc = Instance.new("TextLabel", classInfoPanel)
lblDesc.Size = UDim2.new(1, -20, 0, 150)
lblDesc.Position = UDim2.new(0, 10, 0, 110)
lblDesc.Font = Enum.Font.Gotham
lblDesc.TextSize = 14
lblDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
lblDesc.BackgroundTransparency = 1
lblDesc.TextXAlignment = Enum.TextXAlignment.Left
lblDesc.TextYAlignment = Enum.TextYAlignment.Top
lblDesc.TextWrapped = true

local lblStats = Instance.new("TextLabel", classInfoPanel)
lblStats.Size = UDim2.new(1, -20, 0, 100)
lblStats.Position = UDim2.new(0, 10, 0, 270)
lblStats.Font = Enum.Font.GothamBold
lblStats.TextSize = 14
lblStats.TextColor3 = Color3.fromRGB(255, 100, 100)
lblStats.BackgroundTransparency = 1
lblStats.TextXAlignment = Enum.TextXAlignment.Left
lblStats.TextYAlignment = Enum.TextYAlignment.Top
lblStats.TextWrapped = true

local btnCreate = Instance.new("TextButton", classInfoPanel)
btnCreate.Size = UDim2.new(1, -40, 0, 50)
btnCreate.Position = UDim2.new(0, 20, 1, -70)
btnCreate.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
btnCreate.TextColor3 = Color3.new(1,1,1)
btnCreate.Font = Enum.Font.GothamBlack
btnCreate.TextSize = 20
btnCreate.Text = "KARAKTER LÉTREHOZÁSA"

local btnBack = Instance.new("TextButton", creatorContainer)
btnBack.Size = UDim2.new(0, 100, 0, 40)
btnBack.Position = UDim2.new(1, -150, 0, 50)
btnBack.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
btnBack.TextColor3 = Color3.new(1,1,1)
btnBack.Font = Enum.Font.GothamBold
btnBack.Text = "VISSZA"

local btnLeft = Instance.new("TextButton", creatorContainer)
btnLeft.Size = UDim2.new(0, 60, 0, 60)
btnLeft.Position = UDim2.new(0.5, -200, 0.8, 0)
btnLeft.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnLeft.TextColor3 = Color3.new(1,1,1)
btnLeft.Font = Enum.Font.GothamBlack
btnLeft.TextSize = 30
btnLeft.Text = "<"

local btnRight = Instance.new("TextButton", creatorContainer)
btnRight.Size = UDim2.new(0, 60, 0, 60)
btnRight.Position = UDim2.new(0.5, 140, 0.8, 0)
btnRight.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnRight.TextColor3 = Color3.new(1,1,1)
btnRight.Font = Enum.Font.GothamBlack
btnRight.TextSize = 30
btnRight.Text = ">"

-- ==========================================
-- JAVÍTOTT KAMERA: Bárhol megtalálja a bábut!
-- ==========================================
local function focusCameraOnClass(index, instant)
	local className = classes[index].Name
	lblName.Text = classes[index].Name
	lblRole.Text = classes[index].Role
	lblDesc.Text = classes[index].Desc
	lblStats.Text = classes[index].Stats

	-- Megkeressük a bábut bárhol a Workspace-ben
	local targetDummy = nil
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and string.upper(obj.Name) == className then
			targetDummy = obj
			break
		end
	end

	if not targetDummy then
		warn("HIBA: Nem találom a pályán ezt a bábut: " .. className)
		return
	end

	-- Pontosan a bábu testéhez viszonyítjuk a kamerát
	local root = targetDummy:FindFirstChild("HumanoidRootPart") or targetDummy:FindFirstChild("Torso") or targetDummy.PrimaryPart
	if not root then
		warn("HIBA: A(z) " .. className .. " bábunak nincs HumanoidRootPart-ja vagy Torso-ja!")
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Kiszámoljuk a pozíciót: 10 studdal a bábu előtt, 2 studdal feljebb
	local camPos = root.Position + (root.CFrame.LookVector * 10) + Vector3.new(0, 2, 0)
	local targetCamCFrame = CFrame.lookAt(camPos, root.Position + Vector3.new(0, 1, 0))

	if instant then
		camera.CFrame = targetCamCFrame
	else
		TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCamCFrame}):Play()
	end
end

local function loadMenu()
	inMenu = true

	camera.CameraType = Enum.CameraType.Scriptable

	local charList = GetCharacterList:InvokeServer()
	slotContainer:ClearAllChildren()

	for i = 1, 3 do
		local data = charList[i]
		local slotBtn = Instance.new("TextButton", slotContainer)
		slotBtn.Size = UDim2.new(1, 0, 0, 100)
		slotBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 120)
		slotBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		slotBtn.BorderColor3 = Color3.fromRGB(150, 110, 50)
		slotBtn.BorderSizePixel = 2
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.Font = Enum.Font.GothamBold
		slotBtn.TextSize = 18

		if data.Exists then
			slotBtn.Text = "SLOT " .. i .. "\nKaszt: " .. data.Class .. "\nSzint: " .. data.Level
			local playBtn = Instance.new("TextButton", slotBtn)
			playBtn.Size = UDim2.new(0, 120, 0, 40)
			playBtn.Position = UDim2.new(1, -130, 0.5, -20)
			playBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
			playBtn.TextColor3 = Color3.new(1, 1, 1)
			playBtn.Font = Enum.Font.GothamBold
			playBtn.Text = "FOLYTATÁS"

			playBtn.MouseButton1Click:Connect(function()
				inMenu = false 
				sg:Destroy() 
				camera.CameraType = Enum.CameraType.Custom 
				SelectCharacter:FireServer(i) 
			end)
		else
			slotBtn.Text = "SLOT " .. i .. "\n[ ÜRES ]"
			local createBtn = Instance.new("TextButton", slotBtn)
			createBtn.Size = UDim2.new(0, 120, 0, 40)
			createBtn.Position = UDim2.new(1, -130, 0.5, -20)
			createBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
			createBtn.TextColor3 = Color3.new(1, 1, 1)
			createBtn.Font = Enum.Font.GothamBold
			createBtn.Text = "+ ÚJ KARAKTER"

			createBtn.MouseButton1Click:Connect(function()
				activeSlot = i
				slotContainer.Visible = false
				title.Visible = false
				background.BackgroundTransparency = 1 
				creatorContainer.Visible = true

				-- Azonnal rápillant az első kasztra
				focusCameraOnClass(currentClassIndex, true)
			end)
		end
	end
end

btnRight.MouseButton1Click:Connect(function()
	currentClassIndex = currentClassIndex + 1
	if currentClassIndex > #classes then currentClassIndex = 1 end
	focusCameraOnClass(currentClassIndex, false)
end)

btnLeft.MouseButton1Click:Connect(function()
	currentClassIndex = currentClassIndex - 1
	if currentClassIndex < 1 then currentClassIndex = #classes end
	focusCameraOnClass(currentClassIndex, false)
end)

btnBack.MouseButton1Click:Connect(function()
	creatorContainer.Visible = false
	slotContainer.Visible = true
	title.Visible = true
	background.BackgroundTransparency = 0.2
end)

btnCreate.MouseButton1Click:Connect(function()
	local selectedClass = classes[currentClassIndex].Name
	btnCreate.Text = "LÉTREHOZÁS..."
	btnCreate.Active = false

	inMenu = false 
	sg:Destroy()
	camera.CameraType = Enum.CameraType.Custom
	CreateCharacter:FireServer(activeSlot, selectedClass)
end)

loadMenu()