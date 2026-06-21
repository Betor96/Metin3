-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> DeathUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")
local RespawnPlayer = Events:WaitForChild("RespawnPlayer")

local sg = Instance.new("ScreenGui")
sg.Name = "DeathHUD"
sg.ResetOnSpawn = false
sg.DisplayOrder = 1000
sg.IgnoreGuiInset = true -- JAVÍTÁS: A képernyő legtetejét is lefedi!
sg.Parent = player:WaitForChild("PlayerGui")

-- ==========================================
-- SÖTÉTÍTŐ HÁTTÉR (Kattintás blokkoló)
-- ==========================================
local darkBg = Instance.new("Frame", sg)
darkBg.Size = UDim2.new(1, 0, 1, 0)
darkBg.BackgroundColor3 = Color3.new(0, 0, 0)
darkBg.BackgroundTransparency = 0.6
darkBg.Visible = false
darkBg.Active = true -- JAVÍTÁS: Megakadályozza, hogy a háttérben bármire is rákattints!

-- ==========================================
-- METIN2 STÍLUSÚ ABLAK LÉTREHOZÁSA
-- ==========================================
local deathWindow = Instance.new("Frame", darkBg)
deathWindow.Size = UDim2.new(0, 320, 0, 180)
deathWindow.Position = UDim2.new(0.5, -160, 0.5, -90) -- Pontosan középre zárva
deathWindow.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Sötét szürkés/kő szín
deathWindow.BorderColor3 = Color3.fromRGB(150, 110, 50) -- Arany/Barna keret
deathWindow.BorderSizePixel = 3

-- Belső díszítő keret
local innerBorder = Instance.new("Frame", deathWindow)
innerBorder.Size = UDim2.new(1, -8, 1, -8)
innerBorder.Position = UDim2.new(0, 4, 0, 4)
innerBorder.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
innerBorder.BorderColor3 = Color3.fromRGB(80, 60, 30)
innerBorder.BorderSizePixel = 1

local deathText = Instance.new("TextLabel", innerBorder)
deathText.Size = UDim2.new(1, 0, 0, 50)
deathText.Position = UDim2.new(0, 0, 0, 10)
deathText.BackgroundTransparency = 1
deathText.Text = "MEGHALTÁL"
deathText.TextColor3 = Color3.fromRGB(220, 40, 40)
deathText.Font = Enum.Font.GothamBlack
deathText.TextSize = 26
deathText.TextStrokeTransparency = 0

local btnHere = Instance.new("TextButton", innerBorder)
btnHere.Size = UDim2.new(0, 240, 0, 35)
btnHere.Position = UDim2.new(0.5, -120, 0, 70)
btnHere.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
btnHere.BorderColor3 = Color3.fromRGB(150, 110, 50)
btnHere.BorderSizePixel = 1
btnHere.TextColor3 = Color3.fromRGB(150, 150, 150)
btnHere.Font = Enum.Font.GothamBold
btnHere.TextSize = 14

local btnTown = Instance.new("TextButton", innerBorder)
btnTown.Size = UDim2.new(0, 240, 0, 35)
btnTown.Position = UDim2.new(0.5, -120, 0, 115)
btnTown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
btnTown.BorderColor3 = Color3.fromRGB(150, 110, 50)
btnTown.BorderSizePixel = 1
btnTown.TextColor3 = Color3.fromRGB(220, 200, 180)
btnTown.Text = "Újraéledés a városban"
btnTown.Font = Enum.Font.GothamBold
btnTown.TextSize = 14

-- ==========================================
-- EGYÉB UI-K ELREJTÉSE / MEGJELENÍTÉSE
-- ==========================================
local function toggleOtherUIs(isVisible)
	if player and player:FindFirstChild("PlayerGui") then
		for _, gui in pairs(player.PlayerGui:GetChildren()) do
			-- Minden felületet kikapcsol, kivéve magát a halál ablakot
			if gui:IsA("ScreenGui") and gui.Name ~= "DeathHUD" then
				gui.Enabled = isVisible
			end
		end
	end
end

local function showDeathScreen()
	toggleOtherUIs(false) -- JAVÍTÁS: Minden más ablak (Táska, Hotbar) eltűnik és inaktív lesz!

	darkBg.Visible = true
	btnHere.AutoButtonColor = false
	btnHere.TextColor3 = Color3.fromRGB(120, 120, 120)

	task.spawn(function()
		for i = 10, 1, -1 do
			if not darkBg.Visible then return end 
			btnHere.Text = "Újraéledés itt (" .. i .. ")"
			task.wait(1)
		end

		if darkBg.Visible then
			btnHere.Text = "Újraéledés itt"
			btnHere.TextColor3 = Color3.fromRGB(220, 200, 180)
			btnHere.AutoButtonColor = true
		end
	end)
end

btnHere.MouseButton1Click:Connect(function()
	if btnHere.Text == "Újraéledés itt" then
		darkBg.Visible = false
		toggleOtherUIs(true) -- JAVÍTÁS: UI-k visszakapcsolása éledéskor
		RespawnPlayer:FireServer("Here")
	end
end)

btnTown.MouseButton1Click:Connect(function()
	darkBg.Visible = false
	toggleOtherUIs(true) -- JAVÍTÁS: UI-k visszakapcsolása éledéskor
	RespawnPlayer:FireServer("Town")
end)

local function setupCharacter(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.Died:Connect(showDeathScreen)
	end
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end