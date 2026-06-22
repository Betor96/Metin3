-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> HotbarInputClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Events = ReplicatedStorage:WaitForChild("Events")
local UseItem = Events:WaitForChild("UseItem")
local SkillDatabase = require(ReplicatedStorage:WaitForChild("SkillDatabase"))

local keyMap = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8
}

local isCooldown = false 
local currentWalkConnection = nil 

UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping or isCooldown then return end

	local slotNum = keyMap[input.KeyCode]
	if slotNum then
		local hotbarFolder = player:FindFirstChild("Hotbar")
		if not hotbarFolder then return end

		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. slotNum)

		if slotVal and slotVal.Value ~= "" then
			isCooldown = true 

			local itemName = slotVal.Value
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			-- ==========================================
			-- 1. CÉLPONT MEGHATÁROZÁSA (Okos Kijelölés)
			-- ==========================================
			local finalTargetPart = mouse.Target
			local finalTargetModel = finalTargetPart and finalTargetPart:FindFirstAncestorOfClass("Model")
			local mousePos = Vector3.zero

			-- Ha van fix KÉK kijelölt célpontunk (ezt a CombatClient fogja adni), az felülír mindent!
			local selectedTargetVal = player:FindFirstChild("SelectedTarget")
			if selectedTargetVal and selectedTargetVal.Value then
				finalTargetModel = selectedTargetVal.Value
				finalTargetPart = finalTargetModel:FindFirstChild("HumanoidRootPart") or finalTargetModel.PrimaryPart
			end

			-- Pozíció beállítása (Nem számít, hova néz az egér, a kijelölt célpont helyét veszi!)
			if finalTargetPart then
				mousePos = finalTargetPart.Position
			elseif mouse.Hit then
				mousePos = mouse.Hit.Position
			elseif root then
				mousePos = root.Position + (root.CFrame.LookVector * 10)
			end

			if currentWalkConnection then
				currentWalkConnection:Disconnect()
				currentWalkConnection = nil
			end

			local maxRange = SkillDatabase.Ranges[itemName]
			local isDistantTarget = false

			-- ==========================================
			-- 2. AUTO-APPROACH (Sétálás a rádiuszba)
			-- ==========================================
			if maxRange and maxRange > 0 and finalTargetModel and finalTargetModel:FindFirstChild("Humanoid") then
				local targetRoot = finalTargetModel:FindFirstChild("HumanoidRootPart")

				if root and targetRoot and hum then
					-- Csak X és Z tengelyen mérünk távolságot, hogy a hegyek/ugrás ne zavarjanak be
					local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetRoot.Position.X, 0, targetRoot.Position.Z)).Magnitude

					if dist > maxRange then
						isDistantTarget = true
						hum:MoveTo(targetRoot.Position)

						task.spawn(function()
							local connection
							connection = RunService.Heartbeat:Connect(function()
								if not root or not targetRoot or not hum or hum.Health <= 0 then 
									connection:Disconnect()
									return 
								end

								local currentDist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetRoot.Position.X, 0, targetRoot.Position.Z)).Magnitude

								-- BEÉRTÜNK A HATÓTÁVBA! (Megállunk és lőjük a varázslatot a célpontra)
								if currentDist <= maxRange then
									hum:MoveTo(root.Position)
									-- Itt is átadjuk a finalTargetPart-ot, ami a fixen kijelölt ellenfél!
									UseItem:FireServer(itemName, targetRoot.Position, finalTargetPart)
									connection:Disconnect()
								end

								-- Megszakítás mozgáskor (WASD)
								if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
									connection:Disconnect()
								end
							end)
							currentWalkConnection = connection
						end)
					end
				end
			end

			-- ==========================================
			-- 3. AZONNALI ELSÜTÉS (Ha már rádiuszban vagyunk)
			-- ==========================================
			if not isDistantTarget then
				UseItem:FireServer(itemName, mousePos, finalTargetPart) 
			end

			task.wait(0.2)
			isCooldown = false
		end
	end
end)