local Players = game:GetService("Players")

local function updateWeapon(character, weaponName)
	-- Először is töröljük a régi fegyvert a kézből (ha van)
	local oldWeapon = character:FindFirstChild("EquippedWeaponModel")
	if oldWeapon then oldWeapon:Destroy() end

	-- Ha nincs fegyver, itt meg is állunk
	if weaponName == "" then return end

	-- Megkeressük a jobb kezet (R15 = RightHand, R6 = Right Arm)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand then return end

	-- Legeneráljuk a kardot
	if weaponName == "Kezdőkard" then
		local sword = Instance.new("Part")
		sword.Name = "EquippedWeaponModel"
		sword.Size = Vector3.new(0.2, 3, 0.5) -- Kard méret
		sword.Color = Color3.fromRGB(150, 150, 150)
		sword.CanCollide = false
		sword.Massless = true -- Hogy ne húzza le a karaktert a súlya

		-- Hozzárögzítjük a kézhez egy WeldConstraint-tel
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = sword
		weld.Parent = sword

		-- Beállítjuk a pozícióját, hogy a markolatát fogja
		sword.CFrame = hand.CFrame * CFrame.new(0, -1, 0)
		sword.Parent = character
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local equipment = player:WaitForChild("Equipment")
		local fegyverSlot = equipment:WaitForChild("Fegyver")

		-- Amikor átrakod a táskából a felszerelésbe (vagy vissza)
		fegyverSlot.Changed:Connect(function(newVal)
			updateWeapon(character, newVal)
		end)

		-- Belépéskor/Újraéledéskor ráadjuk, ha már fel van szerelve
		updateWeapon(character, fegyverSlot.Value)
	end)
end)