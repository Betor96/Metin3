local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local stats = player:WaitForChild("PlayerStats", 99999)
local goldStat = stats:WaitForChild("Gold")

local previousGold = goldStat.Value

goldStat.Changed:Connect(function(newGold)
	local difference = newGold - previousGold
	previousGold = newGold 

	if difference > 0 then
		local character = player.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		-- ÚJ: Megnézzük, a Szerver rakott-e ránk "Dupla Pénz" jelzést!
		local isDouble = player:GetAttribute("DoubleGoldTriggered")
		if isDouble then
			player:SetAttribute("DoubleGoldTriggered", false) -- Egyből le is vesszük magunkról
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = head

		-- Nagyobb ablak, ha Dupla Pénz
		billboard.Size = isDouble and UDim2.new(0, 250, 0, 70) or UDim2.new(0, 160, 0, 50)

		local offsetX = math.random(-3, 3)
		billboard.StudsOffset = Vector3.new(offsetX, 4, 0)
		billboard.AlwaysOnTop = true

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1

		-- Különleges szöveg és szín a Dupla Pénzhez
		if isDouble then
			textLabel.Text = "+" .. tostring(difference) .. " Pénz (DUPLA!)"
			textLabel.TextColor3 = Color3.fromRGB(255, 150, 0) -- Extrém narancsos-arany
			textLabel.Font = Enum.Font.GothamBlack
		else
			textLabel.Text = "+" .. tostring(difference) .. " Pénz"
			textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Sima Arany szín
			textLabel.Font = Enum.Font.GothamBold
		end

		textLabel.TextStrokeTransparency = 0
		textLabel.TextScaled = true
		textLabel.Parent = billboard

		billboard.Parent = head

		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		-- Magasabbra száll, ha dupla!
		local moveGoal = {StudsOffset = Vector3.new(offsetX, isDouble and 10 or 8, 0)} 
		local moveTween = TweenService:Create(billboard, tweenInfo, moveGoal)

		local fadeGoal = {TextTransparency = 1, TextStrokeTransparency = 1} 
		local fadeTween = TweenService:Create(textLabel, tweenInfo, fadeGoal)

		moveTween:Play()
		fadeTween:Play()

		Debris:AddItem(billboard, 1.5)
	end
end)