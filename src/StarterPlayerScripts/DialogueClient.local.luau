-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> DialogueClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService") -- ÚJ: Folyamatos távolságméréshez
local Events = ReplicatedStorage:WaitForChild("Events")
local AcceptQuest = Events:WaitForChild("AcceptQuest")
local TurnInQuest = Events:WaitForChild("TurnInQuest")

local QuestDatabase = require(ReplicatedStorage:WaitForChild("QuestDatabase"))
local NPCDatabase = require(ReplicatedStorage:WaitForChild("NPCDatabase"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogueHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local dialogFrame = Instance.new("Frame")
dialogFrame.Size = UDim2.new(0, 600, 0, 150)
dialogFrame.AnchorPoint = Vector2.new(0.5, 1) 
dialogFrame.Position = UDim2.new(0.5, 0, 1, -100) 
dialogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
dialogFrame.BackgroundTransparency = 0.1
dialogFrame.BorderColor3 = Color3.fromRGB(180, 150, 80)
dialogFrame.BorderSizePixel = 3
dialogFrame.Visible = false
dialogFrame.Parent = screenGui

local npcNameText = Instance.new("TextLabel")
npcNameText.Size = UDim2.new(1, -20, 0, 30)
npcNameText.Position = UDim2.new(0, 10, 0, 5)
npcNameText.BackgroundTransparency = 1
npcNameText.TextColor3 = Color3.fromRGB(255, 215, 0)
npcNameText.Font = Enum.Font.GothamBlack
npcNameText.TextSize = 18
npcNameText.TextXAlignment = Enum.TextXAlignment.Left
npcNameText.Parent = dialogFrame

local dialogText = Instance.new("TextLabel")
dialogText.Size = UDim2.new(1, -40, 1, -80)
dialogText.Position = UDim2.new(0, 20, 0, 40)
dialogText.BackgroundTransparency = 1
dialogText.TextColor3 = Color3.new(1, 1, 1)
dialogText.Font = Enum.Font.Gotham
dialogText.TextSize = 16
dialogText.TextWrapped = true
dialogText.TextXAlignment = Enum.TextXAlignment.Left
dialogText.TextYAlignment = Enum.TextYAlignment.Top
dialogText.Parent = dialogFrame

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, -20, 0, 40)
buttonContainer.Position = UDim2.new(0, 10, 1, -45)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = dialogFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
uiListLayout.Padding = UDim.new(0, 10)
uiListLayout.Parent = buttonContainer

local questTracker = Instance.new("Frame")
questTracker.Size = UDim2.new(0, 250, 0, 80)
questTracker.AnchorPoint = Vector2.new(0, 0) 
questTracker.Position = UDim2.new(0, 20, 0, 20) 
questTracker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
questTracker.BackgroundTransparency = 0.3
questTracker.BorderColor3 = Color3.fromRGB(100, 80, 40)
questTracker.BorderSizePixel = 2
questTracker.Visible = false
questTracker.Parent = screenGui

local trackerTitle = Instance.new("TextLabel")
trackerTitle.Size = UDim2.new(1, 0, 0, 25)
trackerTitle.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
trackerTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
trackerTitle.Text = " Küldetés"
trackerTitle.Font = Enum.Font.GothamBold
trackerTitle.TextSize = 14
trackerTitle.TextXAlignment = Enum.TextXAlignment.Left
trackerTitle.Parent = questTracker

local trackerInfo = Instance.new("TextLabel")
trackerInfo.Size = UDim2.new(1, -10, 1, -30)
trackerInfo.Position = UDim2.new(0, 5, 0, 30)
trackerInfo.BackgroundTransparency = 1
trackerInfo.TextColor3 = Color3.new(1, 1, 1)
trackerInfo.Font = Enum.Font.Gotham
trackerInfo.TextSize = 13
trackerInfo.TextWrapped = true
trackerInfo.TextXAlignment = Enum.TextXAlignment.Left
trackerInfo.TextYAlignment = Enum.TextYAlignment.Top
trackerInfo.Parent = questTracker

-- ==========================================
-- ÚJ: TÁVOLSÁGMÉRÉS VÁLTOZÓI
-- ==========================================
local currentInteractNPC = nil
local MAX_INTERACT_DISTANCE = 15

local function updateQuestTracker()
	local quests = player:WaitForChild("Quests")
	local activeQuestFound = false

	for _, qVal in pairs(quests:GetChildren()) do
		local qData = QuestDatabase[qVal.Name]
		if qData and qVal.Value >= 0 and qVal.Value <= qData.Count then
			activeQuestFound = true
			questTracker.Visible = true

			if qVal.Value < qData.Count then
				trackerInfo.Text = qData.Title .. "\nÖlj meg " .. qData.Count .. " " .. qData.Target .. "-t!\nÁllapot: " .. qVal.Value .. " / " .. qData.Count
				trackerInfo.TextColor3 = Color3.new(1, 1, 1)
			else
				trackerInfo.Text = qData.Title .. "\nÁllapot: KÉSZ!\nBeszélj az NPC-vel."
				trackerInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
			break
		end
	end

	if not activeQuestFound then questTracker.Visible = false end
end

local function showDialogue(name, text, options)
	npcNameText.Text = name
	dialogText.Text = text

	for _, child in pairs(buttonContainer:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, opt in ipairs(options) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 120, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Text = opt.Text
		btn.Parent = buttonContainer

		btn.MouseButton1Click:Connect(function()
			if opt.Action then opt.Action() end
			dialogFrame.Visible = false
			currentInteractNPC = nil -- Töröljük a fókuszt
		end)
	end
	dialogFrame.Visible = true
end

local function setupNPCs()
	for npcPartName, npcData in pairs(NPCDatabase) do
		local npc = workspace:FindFirstChild(npcPartName)
		if npc and npc:FindFirstChildOfClass("ClickDetector") then

			npc.ClickDetector.MouseClick:Connect(function()
				-- ÚJ: Csak akkor nyitja meg, ha elég közel vagyunk!
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("HumanoidRootPart") then
					local dist = (char.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
					if dist > MAX_INTERACT_DISTANCE then return end -- Túl messze van!
				end

				currentInteractNPC = npc -- Eltároljuk, kivel beszélünk épp

				if npcData.Type == "Regular" then
					local lines = npcData.Dialogues
					local randomLine = lines[math.random(1, #lines)] 
					showDialogue(npcData.Name, randomLine, {{Text = "Bezár", Action = function() end}})

				elseif npcData.Type == "QuestGiver" then
					local questName = npcData.QuestName
					local qVal = player.Quests:FindFirstChild(questName)
					local qData = QuestDatabase[questName]

					if qVal and qData then
						if qVal.Value == -1 then
							local rewardText = string.format("\n\nJutalom: %d EXP, %d Pénz", qData.Rewards.Exp, qData.Rewards.Gold)
							if qData.Rewards.Item then rewardText = rewardText .. ", " .. qData.Rewards.Item end

							showDialogue(npcData.Name, npcData.Dialogues.NotStarted .. rewardText, {
								{Text = "Elfogadom", Action = function() AcceptQuest:FireServer(questName) task.wait(0.2) updateQuestTracker() end},
								{Text = "Mégse", Action = function() end}
							})
						elseif qVal.Value >= 0 and qVal.Value < qData.Count then
							showDialogue(npcData.Name, npcData.Dialogues.InProgress, {{Text = "Rendben", Action = function() end}})
						elseif qVal.Value == qData.Count then
							showDialogue(npcData.Name, npcData.Dialogues.ReadyToTurnIn, {
								{Text = "Jutalom átvétele", Action = function() TurnInQuest:FireServer(questName) task.wait(0.2) updateQuestTracker() end}
							})
						elseif qVal.Value == 9999 then
							showDialogue(npcData.Name, npcData.Dialogues.Completed, {{Text = "Viszlát", Action = function() end}})
						end
					end
				end
			end)
		end
	end
end

-- ==========================================
-- ÚJ: FOLYAMATOS TÁVOLSÁG ELLENŐRZÉS (Párbeszéd bezárása)
-- ==========================================
RunService.Heartbeat:Connect(function()
	if dialogFrame.Visible and currentInteractNPC then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and currentInteractNPC:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - currentInteractNPC.HumanoidRootPart.Position).Magnitude
			if dist > MAX_INTERACT_DISTANCE then
				dialogFrame.Visible = false -- Ha túl messze mész, rácsapja az ablakot!
				currentInteractNPC = nil
			end
		else
			dialogFrame.Visible = false
			currentInteractNPC = nil
		end
	end
end)

player:WaitForChild("Quests")
for _, qVal in pairs(player.Quests:GetChildren()) do qVal.Changed:Connect(updateQuestTracker) end
updateQuestTracker()

workspace.ChildAdded:Connect(function(child)
	if NPCDatabase[child.Name] then task.wait(0.5) setupNPCs() end
end)
setupNPCs()