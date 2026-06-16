-- Fájl helye: StarterPlayer -> StarterPlayerScripts -> HotbarInputClient

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local UseItem = Events:WaitForChild("UseItem") -- ÚJ: Bekötjük a kommunikációs csatornát

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

local isCooldown = false -- Védelem a Potion-spam ellen

UserInputService.InputBegan:Connect(function(input, isTyping)
	-- Ha épp chatel a játékos, vagy várakozási időn van, nem sülnek el a gombok
	if isTyping or isCooldown then return end

	local slotNum = keyMap[input.KeyCode]
	if slotNum then
		local hotbarFolder = player:WaitForChild("Hotbar")
		local slotVal = hotbarFolder:FindFirstChild("Hotbar_" .. slotNum)

		if slotVal and slotVal.Value ~= "" then
			-- Elküldjük a Szervernek, hogy mit akarunk használni!
			isCooldown = true
			UseItem:FireServer(slotVal.Value)

			-- 0.2 másodperc múlva ihat ismét (MMO alapértelmezés)
			task.wait(0.2)
			isCooldown = false
		end
	end
end)