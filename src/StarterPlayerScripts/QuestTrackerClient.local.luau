-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> QuestTrackerClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))

local player = Players.LocalPlayer

-- UI Létrehozása bal felülre
local gui = Instance.new("ScreenGui")
gui.Name = "QuestTrackerHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame", gui)
container.BackgroundTransparency = 1
container.Size = UDim2.new(0, 250, 0, 400)
container.Position = UDim2.new(0, 20, 0, 20) -- BAL FELSŐ SAROK
container.Active = false

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- UI Frissítő függvény
local function updateTracker()
	-- Letöröljük a régi szövegeket
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local questsFolder = player:FindFirstChild("Quests")
	if not questsFolder then return end

	-- Végigmegyünk az aktív küldetéseken
	for _, qVal in pairs(questsFolder:GetChildren()) do
		local qData = QuestDatabase[qVal.Name]
		if qData then
			local qFrame = Instance.new("Frame", container)
			qFrame.BackgroundTransparency = 0.4
			qFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
			qFrame.BorderSizePixel = 2
			qFrame.BorderColor3 = Color3.fromRGB(60, 40, 20)
			qFrame.Size = UDim2.new(1, 0, 0, 45)

			local title = Instance.new("TextLabel", qFrame)
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, -10, 0, 20)
			title.Position = UDim2.new(0, 5, 0, 2)
			title.TextColor3 = Color3.fromRGB(255, 215, 0)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 14
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Text = qVal.Name

			local progress = Instance.new("TextLabel", qFrame)
			progress.BackgroundTransparency = 1
			progress.Size = UDim2.new(1, -10, 0, 20)
			progress.Position = UDim2.new(0, 5, 0, 22)
			progress.TextColor3 = Color3.new(1, 1, 1)
			progress.Font = Enum.Font.Gotham
			progress.TextSize = 12
			progress.TextXAlignment = Enum.TextXAlignment.Left

			-- Szöveg beállítása típus szerint
			if qData.Type == "Kill" then
				local color = (qVal.Value >= qData.Count) and "<font color='rgb(100,255,100)'>" or "<font color='rgb(200,200,200)'>"
				progress.RichText = true
				progress.Text = color .. "Ölj meg: " .. qData.Target .. " (" .. qVal.Value .. "/" .. qData.Count .. ")</font>"
			elseif qData.Type == "Gather" then
				progress.Text = "Gyűjts össze " .. qData.Count .. "db " .. qData.TargetItem .. "-t"
			elseif qData.Type == "Talk" then
				progress.Text = "Beszélj vele: " .. qData.TargetNPC
			end
		end
	end
end

-- Folyamatos megfigyelő
local function setupFolder()
	local questsFolder = player:WaitForChild("Quests", 10)
	if questsFolder then
		-- Ha új küldetést veszünk fel, vagy adunk le
		questsFolder.ChildAdded:Connect(function(child)
			if child:IsA("IntValue") then
				child.Changed:Connect(updateTracker)
			end
			updateTracker()
		end)
		questsFolder.ChildRemoved:Connect(updateTracker)

		-- Ha öltünk egy szörnyet és változik az érték
		for _, child in pairs(questsFolder:GetChildren()) do
			if child:IsA("IntValue") then
				child.Changed:Connect(updateTracker)
			end
		end
	end
	updateTracker()
end

-- Várjuk meg amíg betölt a karakter és a mappák
task.spawn(function()
	while not player:FindFirstChild("Quests") do
		task.wait(0.5)
	end
	setupFolder()
end)