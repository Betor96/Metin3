-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> DamageIndicatorClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Events = ReplicatedStorage:WaitForChild("Events")
local ShowDamage = Events:WaitForChild("ShowDamage")

-- Véletlenszerű eltolás, hogy a sok sebzés ne fedje el teljesen egymást
local rng = Random.new()

ShowDamage.OnClientEvent:Connect(function(amount, position, isCrit, isHeal)
	-- 1. Hordozó "Part" létrehozása a megadott pozícióban
	local part = Instance.new("Part")
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Size = Vector3.new(1, 1, 1)

	-- Kicsit eltoljuk a pozíciót, hogy a számok "szétnyíljanak" (ne pont egymáson legyenek)
	local offsetX = rng:NextNumber(-1.5, 1.5)
	local offsetZ = rng:NextNumber(-1.5, 1.5)
	part.Position = position + Vector3.new(offsetX, 1, offsetZ)
	part.Parent = workspace

	-- 2. BillboardGui létrehozása (Ez mindig a kamera felé néz)
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.StudsOffset = Vector3.new(0, 2, 0) -- Egy picit a karakter/szörny feje fölött indul
	gui.Parent = part

	-- 3. Maga a Szöveg
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tostring(math.floor(amount))
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true 
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextStrokeTransparency = 0 -- Erős fekete körvonal, hogy mindenhol olvasható legyen!
	textLabel.Parent = gui

	-- 4. Színek és Méretek beállítása (Sima vs. Kritikus/Death Mark proc vs. Heal)
	if isHeal then
		textLabel.TextColor3 = Color3.fromRGB(50, 255, 50) -- Zöld szín gyógyulásnál
		gui.Size = UDim2.new(0, 100, 0, 40)
		textLabel.Text = "+" .. textLabel.Text

	elseif isCrit then
		-- EZ A KRITIKUS ÉS A DEATH MARK PROCKOLÁS!
		textLabel.TextColor3 = Color3.fromRGB(255, 40, 40) -- Brutális piros szín
		gui.Size = UDim2.new(0, 200, 0, 75) -- Jóval nagyobb méret
		textLabel.Text = textLabel.Text .. "!"
		gui.StudsOffset = Vector3.new(0, 3.5, 0) -- Hogy az alap sebzés fölött jelenjen meg

	else
		-- SIMA SEBZÉS
		textLabel.TextColor3 = Color3.fromRGB(255, 220, 120) -- Sárgás/Fehér szín
		gui.Size = UDim2.new(0, 120, 0, 45) -- Normál méret
	end

	-- 5. ANIMÁCIÓ (Felugrás és lassan elhalványulás)
	local targetPos = part.Position + Vector3.new(0, 3.5, 0) -- 3.5 studot úszik felfelé

	local moveTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local moveTween = TweenService:Create(part, moveTweenInfo, {Position = targetPos})
	moveTween:Play()

	-- Egy kis várakozás után elkezd elhalványulni a szöveg
	task.delay(0.5, function()
		if textLabel then
			local fadeTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local fadeText = TweenService:Create(textLabel, fadeTweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
			fadeText:Play()
		end
	end)

	-- 6. Automatikus takarítás 1.5 másodperc múlva, nehogy belaggoljon a szerver!
	Debris:AddItem(part, 1.5)
end)