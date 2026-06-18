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

CheckBankPwd.OnServerInvoke = function(player, pwdAttempt)
	local stats = player:FindFirstChild("PlayerStats")
	if not stats then return false end

	local pwdObj, _ = ensureBankDataExists(stats)
	local realPwd = tostring(pwdObj.Value)
	local attempt = tostring(pwdAttempt)

	return realPwd == attempt
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
local BANK_PAGE_PRODUCT_ID = 444555666 -- IDE ÍRD MAJD A ROBUX PRODUCT ID-DAT A BANKHOZ!
local PromptBankRobuxUnlock = Events:FindFirstChild("PromptBankRobuxUnlock") or Instance.new("RemoteEvent", Events)
PromptBankRobuxUnlock.Name = "PromptBankRobuxUnlock"

PromptBankRobuxUnlock.OnServerEvent:Connect(function(player)
	MarketplaceService:PromptProductPurchase(player, BANK_PAGE_PRODUCT_ID)
end)

local INVENTORY_PAGE_PRODUCT_ID = 3604998372 -- A normál táska Robux ID-ja

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player then
		local stats = player:FindFirstChild("PlayerStats")
		if stats then
			-- 1. BANK OLDAL VÁSÁRLÁS
			if receiptInfo.ProductId == BANK_PAGE_PRODUCT_ID then
				local _, bankPages = ensureBankDataExists(stats)
				if bankPages.Value < 4 then
					bankPages.Value += 1
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
				-- 2. TÁSKA OLDAL VÁSÁRLÁS (EZ HIÁNYZOTT!)
			elseif receiptInfo.ProductId == INVENTORY_PAGE_PRODUCT_ID then
				local unlockedPages = stats:FindFirstChild("UnlockedPages")
				if unlockedPages and unlockedPages.Value < 4 then
					unlockedPages.Value += 1
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end