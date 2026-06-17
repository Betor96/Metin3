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
local walkToNPC = nil
local selectedTarget = nil 
local ATTACK_RANGE = 6

-- ==========================================
-- VIZUÁLIS KIJELÖLŐ (GYŰRŰ) LÉTREHOZÁSA
-- ==========================================
local selectionRing = Instance.new("Part")
selectionRing.Name = "SelectionRing"
selectionRing.Anchored = true
selectionRing.CanCollide = false
selectionRing.CastShadow = false
selectionRing.Massless = true
selectionRing.Size = Vector3.new(0.1, 5, 5) 
selectionRing.Shape = Enum.PartType.Cylinder
selectionRing.Color = Color3.fromRGB(255, 255, 0) 
selectionRing.Material = Enum.Material.Neon
selectionRing.Transparency = 0.5
selectionRing.Parent = nil

-- ==========================================
-- TÁMADÁSI SEBESSÉG VÁLTOZÓK
-- ==========================================
local BASE_ATTACK_COOLDOWN = 0.8 
local lastAttackTime = 0
local isHoldingSpace = false 
local originalWalkSpeed = 16 

-- ==========================================
-- GOMB Lenyomása
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = true
		currentTarget = nil 
		selectedTarget = nil 

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if player.Character.Humanoid.WalkSpeed > 0 then
				originalWalkSpeed = player.Character.Humanoid.WalkSpeed
			end
			player.Character.Humanoid.WalkSpeed = 0
		end
	end

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
				["Varosor"] = true,
				["Raktaros"] = true
			}

			if model and model:FindFirstChild("Humanoid") and model ~= player.Character then
				if protectedNPCs[model.Name] then
					currentTarget = nil
					selectedTarget = model 

					local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
					local npcRoot = model:FindFirstChild("HumanoidRootPart")

					if myRoot and npcRoot then
						local dist = (Vector3.new(myRoot.Position.X, 0, myRoot.Position.Z) - Vector3.new(npcRoot.Position.X, 0, npcRoot.Position.Z)).Magnitude

						if dist > 6 then
							walkToNPC = model
							player.Character.Humanoid:MoveTo(npcRoot.Position)
						else
							walkToNPC = nil
							player.Character.Humanoid:MoveTo(myRoot.Position)
						end
					end
				else
					currentTarget = model
					walkToNPC = nil
					selectedTarget = model 
				end
			else
				currentTarget = nil
				walkToNPC = nil
				selectedTarget = nil 
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid:MoveTo(hitPos)
				end
			end
		end
	end
end)

-- ==========================================
-- GOMB Elengedése és Alt-Tab javítás
-- ==========================================
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = false
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local msBonus = player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("MovementSpeed") and player.PlayerStats.MovementSpeed.Value or 0
			player.Character.Humanoid.WalkSpeed = 16 * (1 + (msBonus / 100))
		end
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	isHoldingSpace = false
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local msBonus = player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("MovementSpeed") and player.PlayerStats.MovementSpeed.Value or 0
		player.Character.Humanoid.WalkSpeed = 16 * (1 + (msBonus / 100))
	end
end)

-- ==========================================
-- A JÁTÉK FŐ CIKLUSA (60x fut le másodpercenként)
-- ==========================================
RunService.Heartbeat:Connect(function()

	-- ==========================================
	-- VIZUÁLIS KIJELÖLÉS (GYŰRŰ) FRISSÍTÉSE ÉS ANIMÁLÁSA
	-- ==========================================
	if selectedTarget then
		local hum = selectedTarget:FindFirstChild("Humanoid")
		if not hum or hum.Health <= 0 then
			selectedTarget = nil
			if currentTarget == selectedTarget then currentTarget = nil end
			if walkToNPC == selectedTarget then walkToNPC = nil end
		end
	end

	if selectedTarget and selectedTarget:FindFirstChild("HumanoidRootPart") then
		selectionRing.Parent = workspace
		local rootPos = selectedTarget.HumanoidRootPart.Position

		-- ==========================================
		-- ÚJ JAVÍTÁS: DINAMIKUS MAGASSÁG A METINKÖVEKHEZ!
		-- ==========================================
		local isMetinStone = false
		if selectedTarget.Parent and selectedTarget.Parent.Name == "MetinStones" then
			isMetinStone = true
		elseif string.match(string.lower(selectedTarget.Name), "metin") then
			isMetinStone = true
		end

		local yOffset = 2.8 -- Alap levonás normál emberi/szörny magassághoz

		if isMetinStone then
			selectionRing.Size = Vector3.new(0.1, 14, 14)
			-- Ha Metinkő, kiszámoljuk a modell PONTOS magasságát, elosztjuk 2-vel,
			-- és levonunk belőle 0.2-t, hogy ne olvadjon bele a talaj textúrájába!
			yOffset = (selectedTarget:GetExtentsSize().Y / 2) - 0.2
		else
			selectionRing.Size = Vector3.new(0.1, 5, 5)
			yOffset = 2.8
		end

		local spinAngle = tick() * 2 

		selectionRing.CFrame = CFrame.new(rootPos.X, rootPos.Y - yOffset, rootPos.Z) * CFrame.Angles(0, spinAngle, math.rad(90))
	else
		selectionRing.Parent = nil
	end

	-- ==========================================
	-- NPC-HEZ SÉTÁLÁS MEGÁLLÍTÁSA
	-- ==========================================
	if walkToNPC and walkToNPC.Parent then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local myRoot = character.HumanoidRootPart
			local npcRoot = walkToNPC:FindFirstChild("HumanoidRootPart")

			if npcRoot then
				local dist = (Vector3.new(myRoot.Position.X, 0, myRoot.Position.Z) - Vector3.new(npcRoot.Position.X, 0, npcRoot.Position.Z)).Magnitude

				if dist <= 6 then
					character.Humanoid:MoveTo(myRoot.Position)
					walkToNPC = nil
				end
			end
		end
	end

	local atkSpeedBonus = 0
	if player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("AttackSpeed") then
		atkSpeedBonus = player.PlayerStats.AttackSpeed.Value
	end

	local currentCooldown = BASE_ATTACK_COOLDOWN / (1 + (atkSpeedBonus / 100))

	-- 1. KÉZI ÜTÉS (SPACE NYOMVA TARTÁSA)
	if isHoldingSpace then
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")

			if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
				local targetPos = rootPart.Position + humanoid.MoveDirection
				local targetCFrame = CFrame.lookAt(rootPart.Position, targetPos)
				rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.25)
			end
		end

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

					local lookPos = Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z)
					myRoot.CFrame = CFrame.lookAt(myRoot.Position, lookPos)

					if tick() - lastAttackTime >= currentCooldown then
						lastAttackTime = tick()
						MeleeAttack:FireServer()
					end
				end
			end
		end
	else
		if currentTarget and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health <= 0 then
			currentTarget = nil
		end
	end
end)