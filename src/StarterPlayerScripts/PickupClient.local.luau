local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PickupItems = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PickupItems")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Ha a 'Q' gombot nyomod meg
	if input.KeyCode == Enum.KeyCode.Q then
		PickupItems:FireServer()
	end
end)