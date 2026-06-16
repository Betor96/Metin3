local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Events = ReplicatedStorage:WaitForChild("Events")
local MeleeAttack = Events:WaitForChild("MeleeAttack")

local currentTarget = nil
local ATTACK_RANGE = 6

-- ==========================================
-- TÁMADÁSI SEBESSÉG VÁLTOZÓK
-- ==========================================
local BASE_ATTACK_COOLDOWN = 0.8 -- Alapértelmezett ütési sebesség
local lastAttackTime = 0
local isHoldingSpace = false -- Ezt kapcsolgatjuk a gomb nyomásakor

-- AMIKOR LENYOMOD A GOMBOT
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Ha LENYOMJUK a Space-t
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = true
		currentTarget = nil -- Töröljük a ráfókuszálást, mert kézzel ütünk
	end

	-- BAL KLIKK: Célzás és Mozgás az NPC védelemmel
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local targetObj = mouse.Target
		local hitPos = mouse.Hit.Position

		if targetObj then
			local model = targetObj:FindFirstAncestorOfClass("Model")

			local protectedNPCs = {
				["Fegyverkereskedo"] = true, 
				["Pancelkereskedo"] = true, 
				["Vegyesbolt"] = true, 
				["Kovacs"] = true, 
				["Faluose"] = true,
				["Varosor"] = true
			}

			if model and model:FindFirstChild("Humanoid") and model ~= player.Character then
				if protectedNPCs[model.Name] then
					currentTarget = nil
					player.Character.Humanoid:MoveTo(hitPos)
				else
					currentTarget = model
				end
			else
				currentTarget = nil
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid:MoveTo(hitPos)
				end
			end
		end
	end
end)

-- AMIKOR ELENGEDED A GOMBOT
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	-- Ha ELENGEDJÜK a Space-t
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = false
	end
end)

-- ==========================================
-- A JÁTÉK FŐ CIKLUSA (60x fut le másodpercenként)
-- ==========================================
RunService.Heartbeat:Connect(function()

	-- IDE KERÜL MAJD A JÖVŐBEN AZ ITEMEK BÓNUSZA!
	-- Pl: Ha van rajta Zöld Ital, akkor a currentCooldown legyen 0.5!
	local currentCooldown = BASE_ATTACK_COOLDOWN 

	-- 1. KÉZI ÜTÉS (SPACE NYOMVA TARTÁSA)
	if isHoldingSpace then
		if tick() - lastAttackTime >= currentCooldown then
			lastAttackTime = tick()
			MeleeAttack:FireServer()
		end
	end

	-- 2. AUTOMATA ÜTÉS (Ha rákattintottunk valakire egerrel)
	if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local myRoot = character.HumanoidRootPart
			local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")

			if targetRoot then
				local dist = (myRoot.Position - targetRoot.Position).Magnitude

				if dist > ATTACK_RANGE then
					character.Humanoid:MoveTo(targetRoot.Position)
				else
					character.Humanoid:MoveTo(myRoot.Position)

					if tick() - lastAttackTime >= currentCooldown then
						lastAttackTime = tick()
						MeleeAttack:FireServer()
					end
				end
			end
		end
	else
		-- Ha a célpont meghalt, ne akarja tovább ütni
		if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health <= 0 then
			currentTarget = nil
		end
	end
end)