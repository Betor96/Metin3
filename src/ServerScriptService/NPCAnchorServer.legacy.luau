-- Fájl helye: ServerScriptService -> NPCAnchorServer

local function secureNPC(npc)
	-- Várunk egy picit, hogy a modell minden része betöltődjön
	task.wait(0.5)

	-- Megkeressük a gyökér-alkatrészt (ez a fő fizikai test)
	local rootPart = npc:FindFirstChild("HumanoidRootPart")

	if rootPart then
		-- 1. Odaszögezzük a földhöz! Ezentúl senki sem tudja eltolni.
		rootPart.Anchored = true

		-- (Opcionális) Ha azt akarod, hogy egyáltalán ne remegjenek vagy csússzanak meg
		-- beállíthatjuk a többi testrészüket is extrán nehézre:
		for _, part in pairs(npc:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) -- 100-as sűrűség (nagyon nehéz)
			end
		end

		-- 2. Kikapcsoljuk az NPC saját mozgását
		local humanoid = npc:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
end

-- ==========================================
-- 1. RÖGZÍTI A MÁR BENT LÉVŐ NPC-KET
-- ==========================================
for _, obj in pairs(workspace:GetChildren()) do
	-- Ha ez egy modell, van benne Humanoid (karakter) ÉS van benne ClickDetector (interakció)
	-- Akkor ez biztosan egy Bolt/Kovács/Küldetés NPC! (A szörnyekben nincs ClickDetector)
	if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChildOfClass("ClickDetector") then
		task.spawn(function()
			secureNPC(obj)
		end)
	end
end

-- ==========================================
-- 2. RÖGZÍTI AZOKAT, AKIK KÉSŐBB KERÜLNEK BE (pl. eventekkor)
-- ==========================================
workspace.ChildAdded:Connect(function(obj)
	-- Megvárjuk, amíg teljesen bekerül a játékba
	task.wait(1) 
	if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChildOfClass("ClickDetector") then
		secureNPC(obj)
	end
end)