-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> HotbarInputClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- A billentyűzetek (1-től 8-ig) hozzárendelése a számokhoz
local keyMap = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8
}

UserInputService.InputBegan:Connect(function(input, isTyping)
	-- Ha épp chatel a játékos, nem sülnek el a gombok
	if isTyping then return end

	local slotNum = keyMap[input.KeyCode]
	if slotNum then
		local hotbarFolder = player:WaitForChild("Hotbar")
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. slotNum)

		if slotVal and slotVal.Value ~= "" then
			-- KÉSŐBB IDE JÖN A GYÓGYITAL MEGIVÁSA!
			print("Megnyomtad a(z) " .. slotNum .. ". gombot, amin ez van: " .. slotVal.Value)
		end
	end
end)