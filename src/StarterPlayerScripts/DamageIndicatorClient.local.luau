local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Az animációkért felelős szolgáltatás
local Debris = game:GetService("Debris") -- Az elemek automatikus törléséért felelős

local Events = ReplicatedStorage:WaitForChild("Events")
local ShowDamage = Events:WaitForChild("ShowDamage")

ShowDamage.OnClientEvent:Connect(function(targetPart, damageAmount)
	if not targetPart then return end

	-- Létrehozunk egy 2D-s táblát a 3D-s térben (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = targetPart
	billboard.Size = UDim2.new(0, 60, 0, 40)
	billboard.AlwaysOnTop = true -- Falakon keresztül is látszik egy kicsit

	-- Véletlenszerű eltolás, hogy ha sokat ütsz, ne fedjék el egymást teljesen a számok
	local offsetX = math.random(-2, 2)
	local offsetY = math.random(2, 4)
	billboard.StudsOffset = Vector3.new(offsetX, offsetY, 0)

	-- Maga a szöveg (Piros szám)
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tostring(math.floor(damageAmount))
	textLabel.TextColor3 = Color3.fromRGB(255, 40, 40) -- Metin2 stílusú élénk piros
	textLabel.TextStrokeTransparency = 0 -- Fekete körvonal, hogy jól olvasható legyen
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	-- Betesszük a pályára
	billboard.Parent = targetPart

	-- ANIMÁCIÓ: Felfelé szállás
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local moveGoal = {StudsOffset = Vector3.new(offsetX, offsetY + 3, 0)}
	local moveTween = TweenService:Create(billboard, tweenInfo, moveGoal)

	-- ANIMÁCIÓ: Elhalványulás
	local fadeGoal = {TextTransparency = 1, TextStrokeTransparency = 1}
	local fadeTween = TweenService:Create(textLabel, tweenInfo, fadeGoal)

	-- Animációk elindítása
	moveTween:Play()
	fadeTween:Play()

	-- 0.8 másodperc múlva automatikusan letörli a memóriából a feliratot
	Debris:AddItem(billboard, 0.8)
end)