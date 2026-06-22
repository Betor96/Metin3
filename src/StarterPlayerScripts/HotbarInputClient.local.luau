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
			isCooldown = true -- Gomb lezárása a spamelés ellen

			local itemName = slotVal.Value
			local target = mouse.Target

			-- Pozíció biztosítása, ha az égre mutatna az egér (ne fagyjon ki!)
			local mousePos = Vector3.zero
			if mouse.Hit then
				mousePos = mouse.Hit.Position
			elseif player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				mousePos = player.Character.HumanoidRootPart.Position + (player.Character.HumanoidRootPart.CFrame.LookVector * 10)
			end

			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			-- Ha már sétáltunk egy előző parancs miatt, azt megszakítjuk
			if currentWalkConnection then
				currentWalkConnection:Disconnect()
				currentWalkConnection = nil
			end

			local maxRange = SkillDatabase.Ranges[itemName]
			local isDistantTarget = false

			-- ==========================================
			-- AUTO-APPROACH (Célpont megközelítése)
			-- ==========================================
			if maxRange and maxRange > 0 and target and target.Parent:FindFirstChild("Humanoid") then
				local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart")

				if root and targetRoot and hum then
					local dist = (root.Position - targetRoot.Position).Magnitude

					-- Ha az ellenfél messzebb van, mint a hatótáv, elindulunk felé!
					if dist > maxRange then
						isDistantTarget = true
						hum:MoveTo(targetRoot.Position)

						-- Külön szálon (task.spawn) futtatjuk, hogy a gombok NE ragadjanak be!
						task.spawn(function()
							local connection
							connection = RunService.Heartbeat:Connect(function()
								if not root or not targetRoot or not hum or hum.Health <= 0 then 
									connection:Disconnect()
									return 
								end

								local currentDist = (root.Position - targetRoot.Position).Magnitude

								-- Beértünk a hatótávba! Megállítjuk a karaktert és elsütjük.
								if currentDist <= maxRange then
									hum:MoveTo(root.Position) 
									UseItem:FireServer(itemName, targetRoot.Position, target)
									connection:Disconnect()
								end

								-- Ha a játékos közben megnyom egy WASD gombot, megszakítjuk az automata menést
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
			-- AZONNALI ELSÜTÉS (Ha közel vagyunk, vagy poti/buff)
			-- ==========================================
			if not isDistantTarget then
				UseItem:FireServer(itemName, mousePos, target) 
			end

			-- Várakozás, majd gomb feloldása minden körülmények között!
			task.wait(0.2)
			isCooldown = false
		end
	end
end)