-- Fájl helye: ServerScriptService -> InventoryServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local MoveItem = Events:WaitForChild("MoveItem")
local DropItem = Events:WaitForChild("DropItem")

-- Melyik tárgy hova való?
local itemTypes = {
	["Kezdőkard"] = "Fegyver",
	["Vadfarkas Páncél"] = "Pancel",
	["Vas Páncél"] = "Pancel",
	["Hosszúkard"] = "Fegyver"
}

MoveItem.OnServerEvent:Connect(function(player, fromFolderStr, fromSlotName, toFolderStr, toSlotName)
	local inv = player:FindFirstChild("Inventory")
	local eq = player:FindFirstChild("Equipment")
	if not inv or not eq then return end

	local fromFolder = (fromFolderStr == "Inventory") and inv or eq
	local toFolder = (toFolderStr == "Inventory") and inv or eq

	local fromSlot = fromFolder:FindFirstChild(fromSlotName)
	local toSlot = toFolder:FindFirstChild(toSlotName)

	if fromSlot and toSlot and fromSlot.Value ~= "" then
		local itemName = fromSlot.Value
		if toFolderStr == "Equipment" then
			local requiredType = itemTypes[itemName]
			if requiredType ~= toSlotName then return end
		end
		local temp = toSlot.Value
		toSlot.Value = fromSlot.Value
		fromSlot.Value = temp
	end
end)

DropItem.OnServerEvent:Connect(function(player, folderStr, slotName)
	local folder = (folderStr == "Inventory") and player:FindFirstChild("Inventory") or player:FindFirstChild("Equipment")
	if folder then
		local slot = folder:FindFirstChild(slotName)
		if slot and slot.Value ~= "" then
			local itemName = slot.Value
			slot.Value = ""

			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPart = character.HumanoidRootPart
				local droppedFolder = workspace:FindFirstChild("DroppedItems")
				if not droppedFolder then
					droppedFolder = Instance.new("Folder")
					droppedFolder.Name = "DroppedItems"
					droppedFolder.Parent = workspace
				end

				local droppedItem = Instance.new("Part")
				droppedItem.Name = "LootPart"
				droppedItem.Size = Vector3.new(0.5, 0.2, 3) 
				droppedItem.Position = rootPart.Position + (rootPart.CFrame.LookVector * 5) + Vector3.new(0, 3, 0)
				droppedItem.Color = (itemName == "Kezdőkard") and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(130, 80, 50)

				local itemTag = Instance.new("StringValue")
				itemTag.Name = "ItemName"
				itemTag.Value = itemName
				itemTag.Parent = droppedItem

				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.new(0, 150, 0, 25)
				billboard.StudsOffset = Vector3.new(0, 1.5, 0)
				billboard.AlwaysOnTop = true
				billboard.Adornee = droppedItem

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, 0, 1, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = itemName
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.TextStrokeTransparency = 0 

				if itemName == "Kezdőkard" then nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
				elseif itemName == "Vadfarkas Páncél" then nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				else nameLabel.TextColor3 = Color3.new(1, 1, 1) end

				nameLabel.Parent = billboard
				billboard.Parent = droppedItem
				droppedItem.Parent = droppedFolder
			end
		end
	end
end)