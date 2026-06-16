local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Megvárjuk, amíg az adatok betöltenek
local stats = player:WaitForChild("PlayerStats")
local goldStat = stats:WaitForChild("Gold")

-- Eltároljuk, hogy mennyi pénze van most
local previousGold = goldStat.Value

-- FOLYAMATOS FIGYELÉS: Ha megváltozik a pénz mennyisége
goldStat.Changed:Connect(function(newGold)
	-- Kiszámoljuk a különbséget (Mennyit kapott?)
	local difference = newGold - previousGold
	previousGold = newGold -- Frissítjük a memóriát

	-- Ha NŐTT a pénze (és nem mondjuk a boltban költötte el)
	if difference > 0 then
		local character = player.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		-- Létrehozzuk a lebegő feliratot
		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 160, 0, 50)

		local offsetX = math.random(-3, 3)
		billboard.StudsOffset = Vector3.new(offsetX, 4, 0)
		billboard.AlwaysOnTop = true

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "+" .. tostring(difference) .. " Pénz"
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Arany szín
		textLabel.TextStrokeTransparency = 0
		textLabel.Font = Enum.Font.GothamBlack
		textLabel.TextScaled = true
		textLabel.Parent = billboard

		billboard.Parent = head

		-- ANIMÁCIÓK
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local moveGoal = {StudsOffset = Vector3.new(offsetX, 8, 0)} -- Magasabbra száll
		local moveTween = TweenService:Create(billboard, tweenInfo, moveGoal)

		local fadeGoal = {TextTransparency = 1, TextStrokeTransparency = 1} -- Elhalványul
		local fadeTween = TweenService:Create(textLabel, tweenInfo, fadeGoal)

		moveTween:Play()
		fadeTween:Play()

		Debris:AddItem(billboard, 1.5)
	end
end)