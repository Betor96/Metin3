-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> EffectUIClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ApplyEffect = Events:WaitForChild("ApplyEffect")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Megkeressük, vagy létrehozzuk a Buff tároló HUD-ot
local effectGui = playerGui:FindFirstChild("EffectHUD")
if not effectGui then
	effectGui = Instance.new("ScreenGui")
	effectGui.Name = "EffectHUD"
	effectGui.ResetOnSpawn = false
	effectGui.DisplayOrder = 0
	effectGui.Parent = playerGui
end

local container = effectGui:FindFirstChild("Container")
if not container then
	container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 300, 0, 35)
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 1, -120) 
	container.BackgroundTransparency = 1
	container.Parent = effectGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 5)
	layout.Parent = container
end

local activeEffects = {}

-- Segédfüggvény: Idő átalakítása szebb formátumba (pl. 2:00:00 vagy 1m 30s)
local function formatTime(seconds)
	if seconds >= 90000 then return "∞" end -- Végtelen (Toggle) skillek jelzése
	if seconds >= 3600 then
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		local s = seconds % 60
		return string.format("%d:%02d:%02d", h, m, s)
	elseif seconds >= 60 then
		local m = math.floor(seconds / 60)
		local s = seconds % 60
		return string.format("%dm %ds", m, s)
	else
		return seconds .. "s"
	end
end

ApplyEffect.OnClientEvent:Connect(function(itemName, effectType, value, duration)

	-- JAVÍTÁS: Ha az idő 0 vagy kevesebb (Kikapcsolás), azonnal töröljük az ikont!
	if duration <= 0 then
		if activeEffects[effectType] then
			activeEffects[effectType].TimeLeft = 0
		end
		return
	end

	-- Ha már van ilyen buff a képernyőn, csak frissítjük az idejét
	if activeEffects[effectType] then
		activeEffects[effectType].TimeLeft = duration
		return
	end

	-- Új UI Ikon létrehozása
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 30, 0, 30)

	-- Debuff vs Buff vizuális megkülönböztetés
	if effectType == "Lassítás" or effectType == "Debuff" or effectType == "Időzített Bomba" or effectType == "Lefogva" then
		box.BackgroundColor3 = Color3.fromRGB(150, 20, 20) -- Piros hátterű debuff
		box.BorderColor3 = Color3.fromRGB(255, 100, 100)
	else
		box.BackgroundColor3 = Color3.fromRGB(20, 50, 100) -- Kék hátterű buff
		box.BorderColor3 = Color3.fromRGB(100, 200, 255)
	end

	box.BorderSizePixel = 1
	box.Parent = container

	local shortName = string.sub(effectType, 1, 3)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	titleLabel.Text = shortName
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 9
	titleLabel.Parent = box

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, 0, 1, -12)
	timeLabel.Position = UDim2.new(0, 0, 0, 12)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.new(1, 1, 1)
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextSize = 10
	timeLabel.TextStrokeTransparency = 0
	timeLabel.Parent = box

	-- Dinamikus Tooltip (Ha a value 0, ne írja ki a "+0"-t)
	local tooltipText = itemName
	if value and value ~= 0 then
		tooltipText = tooltipText .. "\n+" .. tostring(value) .. " " .. effectType
	else
		tooltipText = tooltipText .. "\n" .. effectType
	end

	local tooltip = Instance.new("TextLabel")
	tooltip.Size = UDim2.new(0, 140, 0, 35)
	tooltip.Position = UDim2.new(0.5, -70, 0, -40) 
	tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tooltip.TextColor3 = Color3.new(1, 1, 1)
	tooltip.BorderColor3 = Color3.fromRGB(100, 80, 50)
	tooltip.BorderSizePixel = 2
	tooltip.Text = tooltipText
	tooltip.Font = Enum.Font.Gotham
	tooltip.TextSize = 11
	tooltip.ZIndex = 10
	tooltip.Visible = false
	tooltip.Parent = box

	box.MouseEnter:Connect(function() tooltip.Visible = true end)
	box.MouseLeave:Connect(function() tooltip.Visible = false end)

	activeEffects[effectType] = {TimeLeft = duration, UI = box}

	-- Időzítő szál indítása
	task.spawn(function()
		while activeEffects[effectType] and activeEffects[effectType].TimeLeft > 0 do
			timeLabel.Text = formatTime(activeEffects[effectType].TimeLeft)
			task.wait(1)

			-- Biztosíték: hátha közben felülírták
			if activeEffects[effectType] then
				activeEffects[effectType].TimeLeft -= 1
			end
		end

		-- Ha letelt az idő (vagy 0-ra állították kikapcsoláskor)
		if activeEffects[effectType] then
			activeEffects[effectType].UI:Destroy()
			activeEffects[effectType] = nil
		end
	end)
end)