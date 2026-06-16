-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> CombatClient

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
local BASE_ATTACK_COOLDOWN = 0.8 
local lastAttackTime = 0
local isHoldingSpace = false 
local originalWalkSpeed = 16 -- Eltároljuk az eredeti sebességet

-- ==========================================
-- GOMB Lenyomása
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Ha LENYOMJUK a Space-t
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = true
		currentTarget = nil -- Töröljük a ráfókuszálást, mert kézzel ütünk

		-- Mozgás letiltása (Sebesség 0-ra állítása)
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.WalkSpeed > 0 then
				originalWalkSpeed = player.Character.Humanoid.WalkSpeed
			end
			player.Character.Humanoid.WalkSpeed = 0
		end
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

-- ==========================================
-- GOMB Elengedése
-- ==========================================
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	-- Ha ELENGEDJÜK a Space-t
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = false

		-- Mozgás visszaadása (Visszaállítjuk 16-ra)
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = originalWalkSpeed
		end
	end
end)

-- BIZTONSÁG: Ha lenyomva tartod a Space-t, de közben lekattintasz a játékról (Alt-Tab)
UserInputService.WindowFocusReleased:Connect(function()
	isHoldingSpace = false
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = originalWalkSpeed
	end
end)

-- ==========================================
-- A JÁTÉK FŐ CIKLUSA (60x fut le másodpercenként)
-- ==========================================
RunService.Heartbeat:Connect(function()
	-- ÚJ: Attack Speed beolvasása a statokból
	local atkSpeedBonus = 0
	if player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("AttackSpeed") then
		atkSpeedBonus = player.PlayerStats.AttackSpeed.Value
	end

	-- Az alap 0.8 másodpercet osztjuk a bónusszal (pl. +50% sebesség = 1.5 -> 0.53 mp cooldown)
	local currentCooldown = BASE_ATTACK_COOLDOWN / (1 + (atkSpeedBonus / 100))

	-- 1. KÉZI ÜTÉS (SPACE NYOMVA TARTÁSA)
	if isHoldingSpace then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")

			-- ==========================================
			-- ÚJ: METIN2 STÍLUSÚ FORGÁS (WASD alapján)
			-- ==========================================
			if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
				-- A MoveDirection megmondja merre akar menni a játékos a kamera szögéhez képest
				local targetPos = rootPart.Position + humanoid.MoveDirection
				local targetCFrame = CFrame.lookAt(rootPart.Position, targetPos)

				-- Simított forgás (lerp), hogy ne "kattanjon" azonnal oda, hanem szépen forduljon
				rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.25)
			end
		end

		-- Ütés leadása a szerver felé
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