local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")

-- Brutálisan sok HP beállítása, hogy sose haljon meg egy ütéstől
humanoid.MaxHealth = 999999999
humanoid.Health = humanoid.MaxHealth

-- Rögzítjük a földhöz, hogy a skillek ne lökjék el
local rootPart = npc:WaitForChild("HumanoidRootPart")
rootPart.Anchored = true

-- Ha megütik, 2 másodperc múlva automatikusan visszatölti magát maxra!
humanoid.HealthChanged:Connect(function(currentHealth)
	if currentHealth < humanoid.MaxHealth then
		task.wait(2)
		-- Ellenőrizzük, hogy létezik-e még, mielőtt gyógyítjuk
		if humanoid and humanoid.Parent then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end)