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
sg.Parent = player:WaitForChild("PlayerGui")

local darkBg = Instance.new("Frame", sg)
darkBg.Size = UDim2.new(1, 0, 1, 0)
darkBg.BackgroundColor3 = Color3.new(0, 0, 0)
darkBg.BackgroundTransparency = 0.3
darkBg.Visible = false
darkBg.Active = true

local deathText = Instance.new("TextLabel", darkBg)
deathText.Size = UDim2.new(1, 0, 0, 100)
deathText.Position = UDim2.new(0, 0, 0.2, 0)
deathText.BackgroundTransparency = 1
deathText.Text = "MEGHALTÁL"
deathText.TextColor3 = Color3.fromRGB(200, 30, 30)
deathText.Font = Enum.Font.GothamBlack
deathText.TextScaled = true

local btnHere = Instance.new("TextButton", darkBg)
btnHere.Size = UDim2.new(0, 250, 0, 50)
btnHere.Position = UDim2.new(0.5, -260, 0.6, 0)
btnHere.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnHere.TextColor3 = Color3.new(1, 1, 1)
btnHere.Font = Enum.Font.GothamBold
btnHere.TextSize = 18

local btnTown = Instance.new("TextButton", darkBg)
btnTown.Size = UDim2.new(0, 250, 0, 50)
btnTown.Position = UDim2.new(0.5, 10, 0.6, 0)
btnTown.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
btnTown.TextColor3 = Color3.new(1, 1, 1)
btnTown.Text = "Újraéledés a városban"
btnTown.Font = Enum.Font.GothamBold
btnTown.TextSize = 18

local function showDeathScreen()
	darkBg.Visible = true
	btnHere.AutoButtonColor = false
	btnHere.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

	task.spawn(function()
		-- Golyóálló ciklus a visszaszámláláshoz
		for i = 10, 1, -1 do
			if not darkBg.Visible then return end -- Ha közben eltűnt az ablak, leáll!
			btnHere.Text = "Újraéledés itt (" .. i .. ")"
			task.wait(1)
		end

		if darkBg.Visible then
			btnHere.Text = "Újraéledés itt"
			btnHere.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
			btnHere.AutoButtonColor = true
		end
	end)
end

btnHere.MouseButton1Click:Connect(function()
	if btnHere.Text == "Újraéledés itt" then
		darkBg.Visible = false
		RespawnPlayer:FireServer("Here")
	end
end)

btnTown.MouseButton1Click:Connect(function()
	darkBg.Visible = false
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