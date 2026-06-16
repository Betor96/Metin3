-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> MainHUDClient

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MetinHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.Parent = playerGui

-- ==========================================
-- BAL ALSÓ SÁV (HP, MP, EXP)
-- ==========================================
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 300, 0, 80)
statusContainer.AnchorPoint = Vector2.new(0, 1) -- FIX: Bal alsó sarok horgony
statusContainer.Position = UDim2.new(0, 20, 1, -20) -- FIX: Fixen 20 pixelre a bal alsó saroktól
statusContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
statusContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
statusContainer.BorderSizePixel = 2
statusContainer.Parent = screenGui

local hpBg = Instance.new("Frame", statusContainer)
hpBg.Size = UDim2.new(1, -20, 0, 20)
hpBg.Position = UDim2.new(0, 10, 0, 10)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
hpBg.BorderSizePixel = 1
hpBg.BorderColor3 = Color3.fromRGB(80, 80, 80)

local hpBar = Instance.new("Frame", hpBg)
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
hpBar.BorderSizePixel = 0

local hpText = Instance.new("TextLabel", hpBg)
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.TextColor3 = Color3.new(1,1,1)
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 12
hpText.Text = "0 / 0"

local mpBg = Instance.new("Frame", statusContainer)
mpBg.Size = UDim2.new(1, -20, 0, 20)
mpBg.Position = UDim2.new(0, 10, 0, 35)
mpBg.BackgroundColor3 = Color3.fromRGB(10, 10, 40)
mpBg.BorderSizePixel = 1
mpBg.BorderColor3 = Color3.fromRGB(80, 80, 80)

local mpBar = Instance.new("Frame", mpBg)
mpBar.Size = UDim2.new(1, 0, 1, 0)
mpBar.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
mpBar.BorderSizePixel = 0

local mpText = Instance.new("TextLabel", mpBg)
mpText.Size = UDim2.new(1, 0, 1, 0)
mpText.BackgroundTransparency = 1
mpText.TextColor3 = Color3.new(1,1,1)
mpText.Font = Enum.Font.GothamBold
mpText.TextSize = 12
mpText.Text = "0 / 0"

local expBg = Instance.new("Frame", statusContainer)
expBg.Size = UDim2.new(1, -20, 0, 10)
expBg.Position = UDim2.new(0, 10, 0, 60)
expBg.BackgroundColor3 = Color3.fromRGB(30, 30, 15)
expBg.BorderSizePixel = 0

local expBar = Instance.new("Frame", expBg)
expBar.Size = UDim2.new(0.5, 0, 1, 0)
expBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
expBar.BorderSizePixel = 0

local function updateHP()
	local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	hpBar.Size = UDim2.new(percent, 0, 1, 0)
	hpText.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
end

humanoid.HealthChanged:Connect(updateHP)
updateHP()

local function updateMPXP()
	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		local mana = stats:FindFirstChild("Mana")
		local maxMana = stats:FindFirstChild("MaxMana")
		if mana and maxMana and maxMana.Value > 0 then
			local mPerc = math.clamp(mana.Value / maxMana.Value, 0, 1)
			mpBar.Size = UDim2.new(mPerc, 0, 1, 0)
			mpText.Text = mana.Value .. " / " .. maxMana.Value
		end

		local exp = stats:FindFirstChild("Experience")
		local maxExp = stats:FindFirstChild("MaxExperience")
		if exp and maxExp and maxExp.Value > 0 then
			local ePerc = math.clamp(exp.Value / maxExp.Value, 0, 1)
			expBar.Size = UDim2.new(ePerc, 0, 1, 0)
		end
	end
end

task.spawn(function()
	task.wait(0.5)
	updateMPXP()
	while task.wait(0.5) do updateMPXP() end
end)

-- ==========================================
-- KÖZÉPSŐ GYORSGOMBOK (HOTBAR 1-8)
-- ==========================================
local hotbarContainer = Instance.new("Frame")
hotbarContainer.Size = UDim2.new(0, 440, 0, 60)
hotbarContainer.AnchorPoint = Vector2.new(0.5, 1) 
hotbarContainer.Position = UDim2.new(0.5, 0, 1, -20) 
hotbarContainer.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
hotbarContainer.BorderColor3 = Color3.fromRGB(100, 20, 20)
hotbarContainer.BorderSizePixel = 2
hotbarContainer.Active = true -- <----- EZ A SOR FOGJA FEL A KATTINTÁSOKAT!
hotbarContainer.Parent = screenGui

local uiList = Instance.new("UIListLayout", hotbarContainer)
uiList.FillDirection = Enum.FillDirection.Horizontal
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 5)

for i = 1, 8 do
	if i == 5 then
		local gap = Instance.new("Frame")
		gap.Name = "HotbarGap"
		gap.Size = UDim2.new(0, 20, 0, 45) 
		gap.BackgroundTransparency = 1
		gap.Parent = hotbarContainer
	end

	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "HotbarSlotUI_" .. i
	slotFrame.Size = UDim2.new(0, 45, 0, 45)
	slotFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
	slotFrame.BorderColor3 = Color3.fromRGB(80, 60, 40)
	slotFrame.BorderSizePixel = 1
	slotFrame.Active = true -- <----- ÉS EZ IS SEGÍT BLOKKOLNI A MOZGÁST!
	slotFrame.Parent = hotbarContainer

	local numLabel = Instance.new("TextLabel", slotFrame)
	numLabel.Size = UDim2.new(0, 15, 0, 15)
	numLabel.Position = UDim2.new(0, 2, 0, 2)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = tostring(i)
	numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	numLabel.Font = Enum.Font.GothamBold
	numLabel.TextSize = 10
	numLabel.TextXAlignment = Enum.TextXAlignment.Left
	numLabel.TextYAlignment = Enum.TextYAlignment.Top
	numLabel.ZIndex = 3

	local itemIcon = Instance.new("TextLabel", slotFrame)
	itemIcon.Name = "ItemIcon"
	itemIcon.Size = UDim2.new(1, -4, 1, -4)
	itemIcon.Position = UDim2.new(0, 2, 0, 2)
	itemIcon.BackgroundTransparency = 1
	itemIcon.TextColor3 = Color3.new(1,1,1)
	itemIcon.Text = ""
	itemIcon.TextScaled = true
	itemIcon.Font = Enum.Font.GothamBold
	itemIcon.ZIndex = 2
end

-- Fájl helye: StarterPlayerScripts -> MainHUDClient (részlet!)
local function renderHotbar()
	local hotbarFolder = player:FindFirstChild("Hotbar")
	local invFolder = player:FindFirstChild("Inventory")
	if not hotbarFolder or not invFolder then return end

	for i = 1, 8 do
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. i)
		local uiSlot = hotbarContainer:FindFirstChild("HotbarSlotUI_" .. i)

		if slotVal and uiSlot then
			local icon = uiSlot:FindFirstChild("ItemIcon")
			if icon then
				for _, c in pairs(icon:GetChildren()) do c:Destroy() end -- Töröljük a régi számot

				if slotVal.Value ~= "" then
					icon.Text = slotVal.Value

					-- Megkeressük, mennyi van a táskában összesen ebből a tárgyból!
					local totalAmount = 0
					for j = 1, 8 do
						local invSlot = invFolder:FindFirstChild("Slot_" .. j)
						if invSlot and invSlot.Value == slotVal.Value then
							local amt = invSlot:FindFirstChild("Amount")
							totalAmount = totalAmount + (amt and amt.Value or 1)
						end
					end

					if totalAmount > 0 then
						-- VAN BELŐLE: Piros és aktív
						icon.BackgroundTransparency = 0
						icon.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
						icon.TextTransparency = 0

						-- Szám csak akkor, ha > 1
						if totalAmount > 1 then
							local amtLabel = Instance.new("TextLabel")
							amtLabel.Size = UDim2.new(0, 15, 0, 15)
							amtLabel.Position = UDim2.new(1, -15, 1, -15)
							amtLabel.BackgroundTransparency = 1
							amtLabel.TextColor3 = Color3.new(1,1,1)
							amtLabel.TextStrokeTransparency = 0
							amtLabel.Text = tostring(totalAmount)
							amtLabel.Font = Enum.Font.GothamBold
							amtLabel.TextSize = 12
							amtLabel.Parent = icon
						end
					else
						-- ELFOGYOTT: Szürke, lebegő, szám nélküli
						icon.BackgroundTransparency = 0
						icon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
						icon.TextTransparency = 0.6 
					end
				else
					icon.Text = ""
					icon.BackgroundTransparency = 1
				end
			end
		end
	end
end

player:WaitForChild("Hotbar").ChildAdded:Connect(renderHotbar)
for _, child in pairs(player:WaitForChild("Hotbar"):GetChildren()) do child.Changed:Connect(renderHotbar) end

-- ÚJ: A táska változását is figyelnie kell a hotbarnak!
task.spawn(function()
	local inv = player:WaitForChild("Inventory")
	for _, slot in pairs(inv:GetChildren()) do
		slot.Changed:Connect(renderHotbar)
		local amt = slot:WaitForChild("Amount", 2)
		if amt then amt.Changed:Connect(renderHotbar) end
	end
end)

player:WaitForChild("Hotbar").ChildAdded:Connect(renderHotbar)
for _, child in pairs(player:WaitForChild("Hotbar"):GetChildren()) do
	child.Changed:Connect(renderHotbar)
end
renderHotbar()