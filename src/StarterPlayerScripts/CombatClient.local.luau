-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> CombatClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Events = ReplicatedStorage:WaitForChild("Events")
local MeleeAttack = Events:WaitForChild("MeleeAttack")

-- KÖZÖS CÉLPONT TÁROLÓ
local selectedTargetVal = player:FindFirstChild("SelectedTarget")
if not selectedTargetVal then
	selectedTargetVal = Instance.new("ObjectValue")
	selectedTargetVal.Name = "SelectedTarget"
	selectedTargetVal.Parent = player
end

local isAttacking = false
local walkToNPC = nil
local ATTACK_RANGE = 6

-- VIZUÁLIS KIJELÖLŐ GYŰRŰ
local selectionRing = Instance.new("Part")
selectionRing.Name = "SelectionRing"
selectionRing.Anchored = true
selectionRing.CanCollide = false
selectionRing.CastShadow = false
selectionRing.Massless = true
selectionRing.Size = Vector3.new(0.1, 5, 5) 
selectionRing.Shape = Enum.PartType.Cylinder
selectionRing.Material = Enum.Material.Neon
selectionRing.Transparency = 0.5
selectionRing.Parent = nil

local BASE_ATTACK_COOLDOWN = 0.8 
local lastAttackTime = 0
local isHoldingSpace = false 

local protectedNPCs = {
	["Fegyverkereskedo"] = true, ["Pancelkereskedo"] = true, ["Vegyesbolt"] = true, 
	["Kovacs"] = true, ["Faluose"] = true, ["Varosor"] = true, ["Raktaros"] = true
}

-- ==========================================
-- INPUT KEZELÉS (Egér és Space)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- SPACE GOMB: Támadás (Ha van kijelölt, elindul felé, ha nincs, helyben üt)
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = true
		if selectedTargetVal.Value and not protectedNPCs[selectedTargetVal.Value.Name] then
			isAttacking = true
		end
	end

	-- BAL KLIKK: Kijelölés ÉS Támadás / Sétálás
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local targetObj = mouse.Target
		local hitPos = mouse.Hit.Position

		if targetObj then
			local model = targetObj:FindFirstAncestorOfClass("Model")
			if model and model:FindFirstChild("Humanoid") and model ~= player.Character then
				if protectedNPCs[model.Name] then
					selectedTargetVal.Value = model
					isAttacking = false
					walkToNPC = model
				else
					selectedTargetVal.Value = model
					isAttacking = true
					walkToNPC = nil
				end
			else
				selectedTargetVal.Value = nil
				isAttacking = false
				walkToNPC = nil
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid:MoveTo(hitPos)
				end
			end
		end
	end

	-- JOBB KLIKK: CSAK KIJELÖLÉS (Lock-on, Kék kör)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local targetObj = mouse.Target
		if targetObj then
			local model = targetObj:FindFirstAncestorOfClass("Model")
			if model and model:FindFirstChild("Humanoid") and model ~= player.Character then
				selectedTargetVal.Value = model
				isAttacking = false 
				walkToNPC = nil
			end
		end
	end

	-- WASD megszakítja a CÉLPONTOS támadást (de ha a Space-t nyomod, attól még helyben üthetsz tovább!)
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
		isAttacking = false
		walkToNPC = nil
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space then
		isHoldingSpace = false
	end
end)

-- Dinamikus mozgási sebesség lekérő (A SZERVERRŐL kéri le a pontos, büntetett értéket!)
local function getCalculatedWalkSpeed()
	return player:GetAttribute("TrueWalkSpeed") or 16
end

-- ==========================================
-- A JÁTÉK FŐ CIKLUSA
-- ==========================================
RunService.Heartbeat:Connect(function()
	local targetModel = selectedTargetVal.Value

	if targetModel then
		local hum = targetModel:FindFirstChild("Humanoid")
		if not hum or hum.Health <= 0 then
			selectedTargetVal.Value = nil
			targetModel = nil
			isAttacking = false
			walkToNPC = nil
		end
	end

	-- GYŰRŰ RAJZOLÁSA ÉS SZÍNEZÉSE
	if targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
		selectionRing.Parent = workspace
		local rootPos = targetModel.HumanoidRootPart.Position

		if isAttacking then
			selectionRing.Color = Color3.fromRGB(255, 50, 50) -- PIROS
		else
			selectionRing.Color = Color3.fromRGB(50, 150, 255) -- KÉK
		end

		local isMetinStone = (targetModel.Parent and targetModel.Parent.Name == "MetinStones") or string.match(string.lower(targetModel.Name), "metin")
		local yOffset = isMetinStone and ((targetModel:GetExtentsSize().Y / 2) - 0.2) or 2.8 
		selectionRing.Size = isMetinStone and Vector3.new(0.1, 14, 14) or Vector3.new(0.1, 5, 5)

		selectionRing.CFrame = CFrame.new(rootPos.X, rootPos.Y - yOffset, rootPos.Z) * CFrame.Angles(0, tick() * 2, math.rad(90))
	else
		selectionRing.Parent = nil
	end

	-- JÁTÉKOS MOZGÁSÁNAK ÉS TÁMADÁSÁNAK KEZELÉSE (JAVÍTVA)
	local atkSpeedBonus = player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("AttackSpeed") and player.PlayerStats.AttackSpeed.Value or 0
	local currentCooldown = BASE_ATTACK_COOLDOWN / (1 + (atkSpeedBonus / 100))

	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if hum and root then
		if isHoldingSpace and not isAttacking then
			-- JAVÍTÁS: Álló helyzetben támadás, forgás WASD-vel (Nincs sétálás)
			hum.WalkSpeed = 0
			if hum.MoveDirection.Magnitude > 0 then
				local targetLook = root.Position + hum.MoveDirection
				root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, Vector3.new(targetLook.X, root.Position.Y, targetLook.Z)), 0.25)
			end

			if tick() - lastAttackTime >= currentCooldown then
				lastAttackTime = tick()
				MeleeAttack:FireServer()
			end

		elseif isAttacking and targetModel and targetModel:FindFirstChild("HumanoidRootPart") then
			-- Célpont üldözése / Auto-Attack
			local targetRoot = targetModel.HumanoidRootPart
			local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetRoot.Position.X, 0, targetRoot.Position.Z)).Magnitude

			if dist > ATTACK_RANGE then
				hum.WalkSpeed = getCalculatedWalkSpeed()
				hum:MoveTo(targetRoot.Position)
			else
				hum.WalkSpeed = 0 -- Megáll ütni, nem csúszkál
				hum:MoveTo(root.Position)
				local lookPos = Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
				root.CFrame = CFrame.lookAt(root.Position, lookPos)

				if tick() - lastAttackTime >= currentCooldown then
					lastAttackTime = tick()
					MeleeAttack:FireServer()
				end
			end

		elseif walkToNPC and walkToNPC.Parent then
			-- Boltos NPC-hez sétálás
			hum.WalkSpeed = getCalculatedWalkSpeed()
			local npcRoot = walkToNPC:FindFirstChild("HumanoidRootPart")
			if npcRoot then
				local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(npcRoot.Position.X, 0, npcRoot.Position.Z)).Magnitude
				if dist <= 6 then
					hum:MoveTo(root.Position)
					walkToNPC = nil
				else
					hum:MoveTo(npcRoot.Position)
				end
			end
		else
			-- Ha semmit nem csinálunk extrát, állítsuk vissza a sebességet a normálisra
			hum.WalkSpeed = getCalculatedWalkSpeed()
		end
	end
end)