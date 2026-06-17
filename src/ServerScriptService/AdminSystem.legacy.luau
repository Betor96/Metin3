-- Fájl helye: ServerScriptService -> AdminSystem

local Players = game:GetService("Players")

-- IDE ÍRD BE A SAJÁT USER ID-DAT (hogy csak te tudd használni!)
local ADMIN_ID = 4484119590 

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.UserId ~= ADMIN_ID then return end -- Csak te használhatod

		local args = string.split(message, " ")
		local cmd = args[1]:lower()

		-- 1. SZINT ADÁS / ELVÉTEL: /level 50
		if cmd == "/level" then
			local amount = tonumber(args[2])
			if amount then player.PlayerStats.Level.Value = amount end

			-- 2. ARANY ADÁS / ELVÉTEL: /gold 10000
		elseif cmd == "/gold" then
			local amount = tonumber(args[2])
			if amount then player.PlayerStats.Gold.Value += amount end

			-- 3. ITEM ADÁS: /give "Farkas Kard" 1
		elseif cmd == "/give" then
			local itemName = args[2] -- Ha több szavas, ezt még finomítani kell
			local amount = tonumber(args[3]) or 1
			local inv = player.Inventory
			for i = 1, 128 do
				local slot = inv:FindFirstChild("Slot_" .. i)
				if slot and slot.Value == "" then
					slot.Value = itemName
					slot.Amount.Value = amount
					break
				end
			end

			-- 4. KILL ALL (MINDEN SZÖRNY HALÁLA): /killall
		elseif cmd == "/killall" then
			local monsters = workspace:FindFirstChild("Monsters")
			if monsters then
				for _, m in pairs(monsters:GetChildren()) do
					if m:FindFirstChild("Humanoid") then m.Humanoid.Health = 0 end
				end
			end

			-- 5. SPAWN METIN: /spawnmetin "Fekete Metin Kő"
		elseif cmd == "/spawnmetin" then
			local mName = args[2]
			local mTemplate = game.ReplicatedStorage:FindFirstChild(mName)
			if mTemplate then
				local clone = mTemplate:Clone()
				clone.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
				clone.Parent = workspace:FindFirstChild("MetinStones")
			end
		end
	end)
end)