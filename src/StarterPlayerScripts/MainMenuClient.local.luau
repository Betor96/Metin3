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

-- Törlés event (Ha még nem létezik a szerveren, létrehozzuk, hogy ne fagyjon ki)
local DeleteCharacter = Events:FindFirstChild("DeleteCharacter")
if not DeleteCharacter then
	DeleteCharacter = Instance.new("RemoteEvent")
	DeleteCharacter.Name = "DeleteCharacter"
	DeleteCharacter.Parent = Events
end

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
		Role = "<b>Szerep:</b> Tank / Bruiser\n<b>Erősség:</b> Hatalmas túlélés, Tömegkontroll (CC)\n<b>Hátrány:</b> Lassú mozgás, Alacsony burst sebzés",
		Passive = "<font color='rgb(255,215,0)'><b>[ PASSZÍV ] Iron Will:</b></font>\nAhogy csökken a HP-d, úgy leszel egyre keményebb. 50% HP alatt +10%, 30% alatt +20%, 15% HP alatt +30% bónusz Páncélzatot (Defense) kapsz valós időben.",
		Actives = "<font color='rgb(255,100,50)'><b>[ AKTÍV KÉPESSÉGEK ]</b></font>\n<b>1. Shield Charge:</b> Előrerohan, fellöki és sebzi az útjába esőket.\n<b>2. Earthbreaker:</b> Területi (AOE) földcsapás, 3 másodpercre 50%-kal lassít.\n<b>3. Blade Spirit (Aura):</b> Kiosztott sebzésből (Life Steal) HP-t tölt vissza.\n<b>4. Iron Skin (Aura):</b> 6 másodpercig 50%-kal kevesebb sebzést kapsz.",
		Stats = "<b>[ FEJLŐDÉS ]</b> Fő statok: VIT (Élet) és STR (Erő).\n<font color='rgb(255,50,50)'><b>[ BÜNTETÉS ] Ha túl sok az INT (Mágia), a páncélzatod csökken!</b></font>"
	},
	{
		Name = "SHADOWBLADE",
		Role = "<b>Szerep:</b> Burst DPS / Assassin\n<b>Erősség:</b> Extrém mobilitás, Brutális egycélpontos sebzés\n<b>Hátrány:</b> Üvegágyú, Gyenge védelem",
		Passive = "<font color='rgb(255,215,0)'><b>[ PASSZÍV ] Shadow Mastery:</b></font>\nPozicionálás és kivégzés. Ha a célpontod mögül támadsz (180 fok), +10% sebzést kapsz. Ha a célpont HP-ja 30% alatt van, további +10% sebzést kapsz (A kettő halmozódik!).",
		Actives = "<font color='rgb(255,100,50)'><b>[ AKTÍV KÉPESSÉGEK ]</b></font>\n<b>1. Shadow Strike:</b> A célpont mögé teleportál és hatalmasat sebez.\n<b>2. Whirling Blades:</b> 3 ütésből álló, pörgő területi (AOE) vágás.\n<b>3. Bloodlust (Aura):</b> Megnöveli a Támadási- és Mozgási sebességedet.\n<b>4. Death Mark:</b> Megjelöli a célt, majd a következő ütés bónuszt sebez.",
		Stats = "<b>[ FEJLŐDÉS ]</b> Fő statok: DEX (Ügyesség) és STR (Erő).\n<font color='rgb(255,50,50)'><b>[ BÜNTETÉS ] A nehéz vértezet (sok Páncél) drasztikusan lelassít!</b></font>"
	},
	{
		Name = "SOULWEAVER",
		Role = "<b>Szerep:</b> AOE DPS / Mage\n<b>Erősség:</b> Pusztító területi mágiák, Távolsági harc\n<b>Hátrány:</b> Nagyon kevés életerő, Közelharcban sebezhető",
		Passive = "<font color='rgb(255,215,0)'><b>[ PASSZÍV ] Soul Echo:</b></font>\nMinden elsütött sebző varázslatodnak 15% esélye van, hogy egy lila energiarobbanással az eredeti sebzés 35%-át bevigye még egyszer a célpontnak.",
		Actives = "<font color='rgb(255,100,50)'><b>[ AKTÍV KÉPESSÉGEK ]</b></font>\n<b>1. Soul Orb:</b> Célkövető lila energiagömböt lő az ellenségre.\n<b>2. Spirit Chain:</b> Villámsugár, ami célpontról célpontra ugrik (Max 5).\n<b>3. Spirit Blessing (Aura):</b> Megnöveli az alap sebzésedet és a gyorsaságod.\n<b>4. Soul Explosion:</b> Késleltetett, hatalmas és pusztító AOE robbanás.",
		Stats = "<b>[ FEJLŐDÉS ]</b> Fő statok: INT (Mágia) és DEX (Ügyesség).\n<font color='rgb(255,50,50)'><b>[ BÜNTETÉS ] Ha túl sok a VIT (Életerő), a varázslataid gyengülnek!</b></font>"
	},
	{
		Name = "SEALER",
		Role = "<b>Szerep:</b> Support / Control\n<b>Erősség:</b> Csapat erősítése, Láncreakciós tömegkontroll\n<b>Hátrány:</b> Alacsony alap sebzés, Csapattársak nélkül gyengébb",
		Passive = "<font color='rgb(255,215,0)'><b>[ PASSZÍV ] Seal Mastery:</b></font>\nAktivált képességenként kapsz egy töltetet (Max 5). Minden töltet +2% Sebzést és +2% Buff erőt ad. Ha 10 másodpercig nem használsz skillt, a töltetek elvesznek.",
		Actives = "<font color='rgb(255,100,50)'><b>[ AKTÍV KÉPESSÉGEK ]</b></font>\n<b>1. Seal of Power (Buff):</b> Megnöveli a saját vagy társad támadóerejét.\n<b>2. Seal of Protection (Buff):</b> Extra Páncélt és Max HP-t ad a célpontnak.\n<b>3. Explosive Seal:</b> Időzített bombát tesz a célpontra (AOE sebzés).\n<b>4. Dragon Shackles:</b> Lekötözi (Root) a célt, majd ugrálva terjed tovább.",
		Stats = "<b>[ FEJLŐDÉS ]</b> Fő statok: INT (Mágia) és STR (Erő).\n<font color='rgb(255,50,50)'><b>[ BÜNTETÉS ] A kapkodás (magas DEX) rontja a buffjaid erejét!</b></font>"
	}
}

local currentClassIndex = 1
local activeSlot = 1

local creatorContainer = Instance.new("Frame", background)
creatorContainer.Size = UDim2.new(1, 0, 1, 0)
creatorContainer.BackgroundTransparency = 1
creatorContainer.Visible = false

local classInfoPanel = Instance.new("Frame", creatorContainer)
classInfoPanel.Size = UDim2.new(0, 480, 1, -120) -- Szélesebb panel
classInfoPanel.Position = UDim2.new(0, 40, 0, 60)
classInfoPanel.BackgroundColor3 = Color3.fromRGB(15, 12, 10) -- Sötétebb, elegánsabb háttér
classInfoPanel.BackgroundTransparency = 0.15
classInfoPanel.BorderSizePixel = 2
classInfoPanel.BorderColor3 = Color3.fromRGB(180, 140, 50) -- Arany keret

-- Automatikus elrendezés (nem lóg egymásba a szöveg)
local listLayout = Instance.new("UIListLayout", classInfoPanel)
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local padding = Instance.new("UIPadding", classInfoPanel)
padding.PaddingTop = UDim.new(0, 15)
padding.PaddingBottom = UDim.new(0, 15)
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)

local lblName = Instance.new("TextLabel", classInfoPanel)
lblName.Size = UDim2.new(1, 0, 0, 40)
lblName.Font = Enum.Font.GothamBlack
lblName.TextSize = 34
lblName.TextColor3 = Color3.fromRGB(255, 215, 0)
lblName.BackgroundTransparency = 1
lblName.LayoutOrder = 1

local lblRole = Instance.new("TextLabel", classInfoPanel)
lblRole.Size = UDim2.new(1, 0, 0, 60)
lblRole.Font = Enum.Font.Gotham
lblRole.TextSize = 14
lblRole.TextColor3 = Color3.fromRGB(220, 220, 220)
lblRole.BackgroundTransparency = 1
lblRole.TextXAlignment = Enum.TextXAlignment.Left
lblRole.TextYAlignment = Enum.TextYAlignment.Top
lblRole.RichText = true
lblRole.LayoutOrder = 2

local lblPassives = Instance.new("TextLabel", classInfoPanel)
lblPassives.Size = UDim2.new(1, 0, 0, 70)
lblPassives.Font = Enum.Font.Gotham
lblPassives.TextSize = 13
lblPassives.TextColor3 = Color3.fromRGB(200, 255, 200)
lblPassives.BackgroundTransparency = 1
lblPassives.TextXAlignment = Enum.TextXAlignment.Left
lblPassives.TextYAlignment = Enum.TextYAlignment.Top
lblPassives.TextWrapped = true
lblPassives.RichText = true
lblPassives.LayoutOrder = 3

local lblActives = Instance.new("TextLabel", classInfoPanel)
lblActives.Size = UDim2.new(1, 0, 0, 110)
lblActives.Font = Enum.Font.Gotham
lblActives.TextSize = 13
lblActives.TextColor3 = Color3.fromRGB(230, 230, 230)
lblActives.BackgroundTransparency = 1
lblActives.TextXAlignment = Enum.TextXAlignment.Left
lblActives.TextYAlignment = Enum.TextYAlignment.Top
lblActives.TextWrapped = true
lblActives.RichText = true
lblActives.LayoutOrder = 4

local lblStats = Instance.new("TextLabel", classInfoPanel)
lblStats.Size = UDim2.new(1, 0, 0, 60)
lblStats.Font = Enum.Font.Gotham
lblStats.TextSize = 13
lblStats.TextColor3 = Color3.fromRGB(255, 255, 255)
lblStats.BackgroundTransparency = 1
lblStats.TextXAlignment = Enum.TextXAlignment.Left
lblStats.TextYAlignment = Enum.TextYAlignment.Top
lblStats.TextWrapped = true
lblStats.RichText = true
lblStats.LayoutOrder = 5

local btnCreate = Instance.new("TextButton", classInfoPanel)
btnCreate.Size = UDim2.new(1, 0, 0, 45)
btnCreate.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
btnCreate.TextColor3 = Color3.new(1,1,1)
btnCreate.Font = Enum.Font.GothamBlack
btnCreate.TextSize = 20
btnCreate.Text = "KARAKTER LÉTREHOZÁSA"
btnCreate.LayoutOrder = 6

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
-- KARAKTER TÖRLÉSE UI ELEMEK
-- ==========================================
local deleteMode = false
local deleteButtons = {}
local targetDeleteSlot = nil

local btnToggleDelete = Instance.new("TextButton", background)
btnToggleDelete.Size = UDim2.new(0, 200, 0, 40)
btnToggleDelete.Position = UDim2.new(1, -220, 1, -60)
btnToggleDelete.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
btnToggleDelete.TextColor3 = Color3.new(1, 1, 1)
btnToggleDelete.Font = Enum.Font.GothamBold
btnToggleDelete.Text = "Karakterek Törlése"

local confirmPopup = Instance.new("Frame", sg)
confirmPopup.Size = UDim2.new(1, 0, 1, 0)
confirmPopup.BackgroundTransparency = 1 -- JAVÍTVA: Nincs sötétítés, teljesen átlátszó a háttér
confirmPopup.Visible = false
confirmPopup.ZIndex = 10

local popupBox = Instance.new("Frame", confirmPopup)
popupBox.Size = UDim2.new(0, 400, 0, 200)
popupBox.Position = UDim2.new(0.5, -200, 0.5, -100)
popupBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
popupBox.BorderColor3 = Color3.fromRGB(200, 50, 50)
popupBox.BorderSizePixel = 2

local popupTitle = Instance.new("TextLabel", popupBox)
popupTitle.Size = UDim2.new(1, 0, 0, 40)
popupTitle.Text = "BIZTOSAN TÖRÖLNI AKAROD?"
popupTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
popupTitle.BackgroundTransparency = 1
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextSize = 18

local popupDesc = Instance.new("TextLabel", popupBox)
popupDesc.Size = UDim2.new(1, -20, 0, 40)
popupDesc.Position = UDim2.new(0, 10, 0, 40)
popupDesc.Text = "Írd be a pontos neved a megerősítéshez:\n" .. player.Name
popupDesc.TextColor3 = Color3.new(1, 1, 1)
popupDesc.BackgroundTransparency = 1
popupDesc.Font = Enum.Font.Gotham

local inputName = Instance.new("TextBox", popupBox)
inputName.Size = UDim2.new(0.8, 0, 0, 40)
inputName.Position = UDim2.new(0.1, 0, 0, 90)
inputName.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputName.TextColor3 = Color3.new(1, 1, 1)
inputName.Font = Enum.Font.Gotham
inputName.Text = ""
inputName.PlaceholderText = player.Name

local btnConfirmDelete = Instance.new("TextButton", popupBox)
btnConfirmDelete.Size = UDim2.new(0, 120, 0, 40)
btnConfirmDelete.Position = UDim2.new(0.5, 20, 0, 140)
btnConfirmDelete.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
btnConfirmDelete.TextColor3 = Color3.new(1, 1, 1)
btnConfirmDelete.Font = Enum.Font.GothamBold
btnConfirmDelete.Text = "TÖRLÉS"

local btnCancelDelete = Instance.new("TextButton", popupBox)
btnCancelDelete.Size = UDim2.new(0, 120, 0, 40)
btnCancelDelete.Position = UDim2.new(0.5, -140, 0, 140)
btnCancelDelete.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnCancelDelete.TextColor3 = Color3.new(1, 1, 1)
btnCancelDelete.Font = Enum.Font.GothamBold
btnCancelDelete.Text = "MÉGSE"

btnToggleDelete.MouseButton1Click:Connect(function()
	deleteMode = not deleteMode
	if deleteMode then
		btnToggleDelete.BackgroundColor3 = Color3.fromRGB(200, 100, 40)
		btnToggleDelete.Text = "Törlés Kikapcsolása"
	else
		btnToggleDelete.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
		btnToggleDelete.Text = "Karakterek Törlése"
	end

	for _, btn in pairs(deleteButtons) do
		btn.Visible = deleteMode
	end
end)

btnCancelDelete.MouseButton1Click:Connect(function()
	confirmPopup.Visible = false
	targetDeleteSlot = nil
end)


local function focusCameraOnClass(index, instant)
	local className = classes[index].Name

	-- Az új RichText elemek betöltése
	lblName.Text = classes[index].Name
	lblRole.Text = classes[index].Role
	lblPassives.Text = classes[index].Passive
	lblActives.Text = classes[index].Actives
	lblStats.Text = classes[index].Stats

	local targetDummy = nil
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and string.upper(obj.Name) == className then
			targetDummy = obj
			break
		end
	end

	if not targetDummy then return end

	local root = targetDummy:FindFirstChild("HumanoidRootPart") or targetDummy:FindFirstChild("Torso") or targetDummy.PrimaryPart
	if not root then return end

	camera.CameraType = Enum.CameraType.Scriptable

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
	deleteButtons = {} 

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
				if deleteMode then return end 
				inMenu = false 
				sg:Destroy() 
				camera.CameraType = Enum.CameraType.Custom 
				SelectCharacter:FireServer(i) 
			end)

			local delBtn = Instance.new("TextButton", slotBtn)
			delBtn.Size = UDim2.new(0, 40, 0, 40)
			delBtn.Position = UDim2.new(1, -180, 0.5, -20)
			delBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
			delBtn.TextColor3 = Color3.new(1, 1, 1)
			delBtn.Font = Enum.Font.GothamBlack
			delBtn.Text = "X"
			delBtn.Visible = deleteMode
			table.insert(deleteButtons, delBtn)

			delBtn.MouseButton1Click:Connect(function()
				targetDeleteSlot = i
				inputName.Text = ""
				confirmPopup.Visible = true
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
				if deleteMode then return end 
				activeSlot = i
				slotContainer.Visible = false
				title.Visible = false
				btnToggleDelete.Visible = false 
				background.BackgroundTransparency = 1 
				creatorContainer.Visible = true

				focusCameraOnClass(currentClassIndex, true)
			end)
		end
	end
end

-- Tényleges Törlés Elküldése a Szervernek
btnConfirmDelete.MouseButton1Click:Connect(function()
	if inputName.Text == player.Name and targetDeleteSlot then
		btnConfirmDelete.Text = "TÖRLÉS..."
		DeleteCharacter:FireServer(targetDeleteSlot)

		task.wait(0.5)
		confirmPopup.Visible = false
		btnConfirmDelete.Text = "TÖRLÉS"
		targetDeleteSlot = nil
		loadMenu() -- Újratöltjük a listát, ami most már üres lesz
	else
		inputName.Text = "HIBÁS NÉV!"
		task.wait(1)
		inputName.Text = ""
	end
end)

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
	btnToggleDelete.Visible = true
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