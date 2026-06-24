-- Fájl helye: ServerScriptService -> NPCAnchorServer

local workspace = game:GetService("Workspace")

local function lockNPC(npc)
	-- Várunk egy pillanatot, hogy a modell minden része (ruhák, fegyverek) betöltsön
	task.wait(0.5)

	if npc:IsA("Model") then
		local hum = npc:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end

		-- Végigmegyünk az NPC minden egyes apró alkatrészén
		for _, part in pairs(npc:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true -- Teljesen lefagyasztjuk (nem lehet eltolni)
				part.CanCollide = false -- Kikapcsoljuk az ütközést (nem lehet rájuk mászni, átmész rajtuk)
			end
		end
	end
end

local function setupNPCs()
	local npcFolder = workspace:FindFirstChild("NPCs")

	-- 1. Végigmegyünk a dedikált NPCs mappán
	if npcFolder then
		for _, npc in pairs(npcFolder:GetChildren()) do
			lockNPC(npc)
		end

		-- 2. Figyeljük a mappába menet közben érkező új NPC-ket is
		npcFolder.ChildAdded:Connect(lockNPC)
	end

	-- 3. Tartalék biztonsági háló: ha véletlenül a Workspace-be raktál egy NPC-t
	for _, obj in pairs(workspace:GetChildren()) do
		-- Olyan modelleket keresünk, amiknek van Humanoidja és rájuk is lehet kattintani
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChildOfClass("ClickDetector", true) then
			lockNPC(obj)
		end
	end
end

setupNPCs()