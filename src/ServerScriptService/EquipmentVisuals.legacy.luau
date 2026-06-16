-- Fájl helye: ServerScriptService -> EquipmentVisuals

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local function updateWeapon(character, weaponName)
	-- Először is töröljük a régi fegyvert a kézből (ha van)
	local oldWeapon = character:FindFirstChild("EquippedWeaponModel")
	if oldWeapon then oldWeapon:Destroy() end

	-- Ha levette, meg is állunk
	if weaponName == "" then return end

	-- Megkeressük az adatbázisban
	local itemData = ItemDatabase[weaponName]
	if not itemData or itemData.Type ~= "Fegyver" then return end

	-- Megkeressük a jobb kezet (R15 = RightHand, R6 = Right Arm)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand then return end

	-- Legeneráljuk a kardot (Most már minden fegyverre működik!)
	local sword = Instance.new("Part")
	sword.Name = "EquippedWeaponModel"
	sword.Size = Vector3.new(0.2, 3, 0.5) 

	-- Pici vizuális bónusz: Ha +-os a kard, legyen fémesebb és fényesebb!
	if string.match(weaponName, "%+") then
		sword.Color = Color3.fromRGB(200, 200, 200)
		sword.Material = Enum.Material.Metal
	else
		sword.Color = Color3.fromRGB(150, 150, 150)
	end

	sword.CanCollide = false
	sword.Massless = true 

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = sword
	weld.Parent = sword

	sword.CFrame = hand.CFrame * CFrame.new(0, -1, 0)
	sword.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local equipment = player:WaitForChild("Equipment")
		local fegyverSlot = equipment:WaitForChild("Fegyver")

		fegyverSlot.Changed:Connect(function(newVal)
			updateWeapon(character, newVal)
		end)

		updateWeapon(character, fegyverSlot.Value)
	end)
end)