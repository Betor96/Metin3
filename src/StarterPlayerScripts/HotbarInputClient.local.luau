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
local currentWalkConnection = nil -- Ezzel állítjuk le a sétálást, ha menet közben meggondolod magad

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
			local target = mouse.Target

			-- BIZTONSÁGI JAVÍTÁS: Ha az égre mutat az egér, ne fagyjon ki a script!
			local mousePos = Vector3.zero
			if mouse.Hit then
				mousePos = mouse.Hit.Position
			elseif player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Ha az égbe mutat, maga elé céloz
				mousePos = player.Character.HumanoidRootPart.Position + (player.Character.HumanoidRootPart.CFrame.LookVector * 10)
			end

			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			-- Ha már automatikusan sétáltunk valahova egy előző skill miatt, azt most megszakítjuk
			if currentWalkConnection then
				currentWalkConnection:Disconnect()
				currentWalkConnection = nil
			end

			-- ==========================================
			-- AUTO-APPROACH LOGIKA (Sétálás a célponthoz, ha messze van)
			-- ==========================================
			local maxRange = SkillDatabase.Ranges[itemName]
			if maxRange and maxRange > 0 and target and target.Parent:FindFirstChild("Humanoid") then
				local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart")

				if root and targetRoot and hum then
					local dist = (root.Position - targetRoot.Position).Magnitude

					-- Ha az ellenfél messzebb van, mint a skill hatótávja, elindulunk felé!
					if dist > maxRange then
						hum:MoveTo(targetRoot.Position)

						currentWalkConnection = RunService.Heartbeat:Connect(function()
							-- Biztonsági ellenőrzések (ha meghalunk vagy a célpont eltűnik)
							if not root or not targetRoot or not hum or hum.Health <= 0 then 
								if currentWalkConnection then currentWalkConnection:Disconnect() end
								return 
							end

							local currentDist = (root.Position - targetRoot.Position).Magnitude

							-- Beértünk a hatótávba! Megállunk és elsütjük a varázslatot.
							if currentDist <= maxRange then
								hum:MoveTo(root.Position) -- Megállítás
								UseItem:FireServer(itemName, targetRoot.Position, target)
								if currentWalkConnection then currentWalkConnection:Disconnect() end
							end

							-- Ha a játékos maga elkezd mozogni (megnyomja a WASD-t), megszakítjuk az auto-sétálást
							if hum.MoveDirection.Magnitude > 0 and (hum.WalkToPoint - targetRoot.Position).Magnitude > 2 then
								if currentWalkConnection then currentWalkConnection:Disconnect() end
							end
						end)

						task.wait(0.2)
						isCooldown = false
						return
					end
				end
			end

			-- ==========================================
			-- AZONNALI ELSÜTÉS (Ha közel vagyunk, vagy buffot / potit nyomtunk)
			-- ==========================================
			UseItem:FireServer(itemName, mousePos, target) 

			-- Kis várakozás, ne lehessen 1 másodperc alatt százszor elküldeni
			task.wait(0.2)
			isCooldown = false
		end
	end
end)