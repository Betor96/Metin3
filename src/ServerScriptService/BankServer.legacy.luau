-- Fájl helye: ServerScriptService -> BankServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Events = ReplicatedStorage:WaitForChild("Events")

-- ==========================================
-- BIZTONSÁGI ADAT-ELLENŐRZŐ (ÖNGYÓGYÍTÓ)
-- ==========================================
local function ensureBankDataExists(stats)
	local pwdObj = stats:FindFirstChild("BankPassword")
	if not pwdObj then
		pwdObj = Instance.new("StringValue", stats)
		pwdObj.Name = "BankPassword"
		pwdObj.Value = "000000"
	end

	-- Ha valamiért számként mentette el a 0-t, javítjuk 6 karakteresre
	if pwdObj.Value == "" or pwdObj.Value == "0" or pwdObj.Value == "nil" then
		pwdObj.Value = "000000"
	end

	local pagesObj = stats:FindFirstChild("BankUnlockedPages")
	if not pagesObj then
		pagesObj = Instance.new("IntValue", stats)
		pagesObj.Name = "BankUnlockedPages"
		pagesObj.Value = 1
	end

	return pwdObj, pagesObj
end


-- ==========================================
-- JELSZÓ ELLENŐRZÉSE
-- ==========================================
local CheckBankPwd = Events:FindFirstChild("CheckBankPwd") or Instance.new("RemoteFunction", Events)
CheckBankPwd.Name = "CheckBankPwd"

local CloseBank = Events:FindFirstChild("CloseBank") or Instance.new("RemoteEvent", Events)
CloseBank.Name = "CloseBank"

CloseBank.OnServerEvent:Connect(function(player)
	player:SetAttribute("BankUnlocked", false)
	player:SetAttribute("BankUnlockTime", nil)
end)

CheckBankPwd.OnServerInvoke = function(player, pwdAttempt)
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return false end

	local pwdObj, _ = ensureBankDataExists(stats)
	local realPwd = tostring(pwdObj.Value)
	local attempt = tostring(pwdAttempt)

	-- JAVÍTÁS: Csak akkor kapja meg az engedélyt, ha a jelszó jó!
	if realPwd == attempt then
		player:SetAttribute("BankUnlocked", true)
		player:SetAttribute("BankUnlockTime", os.time())
		return true
	else
		player:SetAttribute("BankUnlocked", false)
		player:SetAttribute("BankUnlockTime", nil)
		return false
	end
end

-- ==========================================
-- JELSZÓ MEGVÁLTOZTATÁSA
-- ==========================================
local ChangeBankPwd = Events:FindFirstChild("ChangeBankPwd") or Instance.new("RemoteFunction", Events)
ChangeBankPwd.Name = "ChangeBankPwd"

ChangeBankPwd.OnServerInvoke = function(player, oldPwd, newPwd)
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return false, "Hiba az adatokkal." end

	local pwdObj, _ = ensureBankDataExists(stats)
	local realPwd = tostring(pwdObj.Value)

	if realPwd == tostring(oldPwd) then
		if string.match(tostring(newPwd), "^%d%d%d%d%d%d$") then
			pwdObj.Value = tostring(newPwd)
			return true, "Sikeres jelszóváltoztatás!"
		else
			return false, "Az új jelszó nem 6 számjegyű!"
		end
	else
		return false, "A régi jelszó helytelen!"
	end
end

-- ==========================================
-- BANK OLDAL FELOLDÁSA (ARANY)
-- ==========================================
local UnlockBankPageGold = Events:FindFirstChild("UnlockBankPageGold") or Instance.new("RemoteEvent", Events)
UnlockBankPageGold.Name = "UnlockBankPageGold"

UnlockBankPageGold.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return end
	local gold = stats:FindFirstChild("Gold")
	local _, bankPages = ensureBankDataExists(stats)

	if gold and bankPages and bankPages.Value < 4 then
		local cost = bankPages.Value * 50000 
		if gold.Value >= cost then
			gold.Value -= cost
			bankPages.Value += 1
		end
	end
end)

-- ==========================================
-- BANK OLDAL FELOLDÁSA (ROBUX)
-- ==========================================
local BANK_PAGE_PRODUCT_ID = 3605410365 -- Raktár Robux ID
local PromptBankRobuxUnlock = Events:FindFirstChild("PromptBankRobuxUnlock") or Instance.new("RemoteEvent", Events)
PromptBankRobuxUnlock.Name = "PromptBankRobuxUnlock"

PromptBankRobuxUnlock.OnServerEvent:Connect(function(player)
	MarketplaceService:PromptProductPurchase(player, BANK_PAGE_PRODUCT_ID)
end)

local INVENTORY_PAGE_PRODUCT_ID = 3604998372 -- Táska Robux ID

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- Ha a játékos pont kilépett, majd később újra megpróbáljuk
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local stats = player:FindFirstChild("PlayerStats")
	if stats then
		-- 1. BANK VÁSÁRLÁS
		if receiptInfo.ProductId == BANK_PAGE_PRODUCT_ID then
			local _, bankPages = ensureBankDataExists(stats)
			if bankPages.Value < 4 then
				bankPages.Value += 1
			end
			-- 2. TÁSKA VÁSÁRLÁS
		elseif receiptInfo.ProductId == INVENTORY_PAGE_PRODUCT_ID then
			local unlockedPages = stats:FindFirstChild("UnlockedPages")
			if unlockedPages and unlockedPages.Value < 4 then
				unlockedPages.Value += 1
			end
		end

		-- JAVÍTÁS 5: Csak sikeres Stats betöltés után jelezzük a Robloxnak, hogy kész!
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		-- JAVÍTÁS 5: VÉDELEM! Ha a szerver még nem töltötte be az adatokat, NEM vonhatjuk le a Robuxot!
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end