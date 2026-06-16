local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ShowDamage = ReplicatedStorage.Events:WaitForChild("ShowDamage")

ShowDamage.OnClientEvent:Connect(function(amount, position, isCrit, isMiss)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position + Vector3.new(math.random(-1, 1), 2, math.random(-1, 1))
	part.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextStrokeTransparency = 0

	if isMiss then
		textLabel.Text = "Mellé!"
		textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		textLabel.TextSize = 20
	elseif isCrit then
		textLabel.Text = amount .. "!"
		textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Pirosas kritikus
		textLabel.TextSize = 35 -- Nagyobb betű
	else
		textLabel.Text = amount
		textLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		textLabel.TextSize = 25
	end

	textLabel.Parent = billboard

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(billboard, tweenInfo, {StudsOffset = Vector3.new(0, 4, 0)})
	local textTween = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})

	tween:Play()
	textTween:Play()

	game:GetService("Debris"):AddItem(part, 1)
end)