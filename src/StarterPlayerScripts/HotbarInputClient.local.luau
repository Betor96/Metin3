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

UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping or isCooldown then return end

	local slotNum = keyMap[input.KeyCode]
	if slotNum then
		local hotbarFolder = player:WaitForChild("Hotbar")
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. slotNum)

		if slotVal and slotVal.Value ~= "" then
			isCooldown = true
			
			local skillName = slotVal.Value
			local target = mouse.Target
			local mousePos = mouse.Hit.Position
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			-- ÚJ: AUTO-APPROACH (Célra sétálás, ha túl messze van)
			local maxRange = SkillDatabase.Ranges[skillName]
			if maxRange and maxRange > 0 and target and target.Parent:FindFirstChild("Humanoid") then
				local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart")
				if root and targetRoot and hum then
					local dist = (root.Position - targetRoot.Position).Magnitude
					if dist > maxRange then
						-- Odasétálunk az ellenfélhez!
						hum:MoveTo(targetRoot.Position)
						
						-- Várunk, amíg beérünk a hatótávba
						local connection
						connection = RunService.Heartbeat:Connect(function()
							if not root or not targetRoot then connection:Disconnect() return end
							if (root.Position - targetRoot.Position).Magnitude <= maxRange then
								-- Beértünk! Megállunk és elsütjük.
								hum:MoveTo(root.Position)
								UseItem:FireServer(skillName, targetRoot.Position, target)
								connection:Disconnect()
							end
							-- Ha a játékos maga elkezd mozogni (WASD), megszakítjuk az automata menést
							if hum.MoveDirection.Magnitude > 0 and hum.WalkToPoint ~= targetRoot.Position then
								connection:Disconnect()
							end
						end)
						task.wait(0.2)
						isCooldown = false
						return
					end
				end
			end
			
			-- Ha eleve közel van, vagy ez egy sima Poti / Buff, azonnal elsütjük:
			UseItem:FireServer(skillName, mousePos, target) 

			task.wait(0.2)
			isCooldown = false
		end
	end
end)