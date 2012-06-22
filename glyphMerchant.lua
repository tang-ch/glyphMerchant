--local scanOver, scanThisPageOver
local scanOver, scanThisPageOver = false, false
local itemName, minLevel, maxLevel, invTypeIndex, classIndex, subClassIndex, page, isUsable, minQuality, getAll = "", nil, nil, nil, nil, nil, nil, nil, nil, nil
local minItemLevel, maxItemLevel, minBidPrice, maxBidPrice, minBuyoutPrice, maxBuyoutPrice, sellerList = nil, nil, nil, nil, nil, nil, nil
local numBatchAuctions, totalAuctions = 0, 0
local myname = GetUnitName ("player")

glyphRecordSorted = {}

local f = CreateFrame ("frame")

scanButtonLable_zhCN = "Scan"
scanButtonLable = scanButtonLable_zhCN
--glyphRecord = glyphRecord
classIndex = 5

local function dealAuctionList ()
	f:UnregisterEvent ("AUCTION_ITEM_LIST_UPDATE")
	numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
	if numBatchAuctions == 0 then
		scanOver = true
		f:SetScript ("OnUpdate", nil)
		for id, v in pairs (glyphRecord) do
			table.insert (glyphRecordSorted, {id = id, minUnitPrice = v.minUnitPrice or 0, myPrice = v.myPrice})
		end
		table.sort (glyphRecordSorted, function (v1, v2) return v1.minUnitPrice > v2.minUnitPrice end)
		glyphMerchantButton:Enable ()
--		glyphMerchant_show ()
		glyphMerchant_report ()
		return
	end
	page = page + 1
	for i = 1, numBatchAuctions do
		local id = tonumber (string.match(GetAuctionItemLink ("list", i), ".*Hitem:(.-):.*"))
--		thisItem.name, thisItem.texture, thisItem.count, thisItem.quality, thisItem.canUse, thisItem.level, thisItem.minBid,
--			thisItem.minIncrement, thisItem.buyoutPrice, thisItem.bidAmount, thisItem.highestBidder, thisItem.owner = GetAuctionItemInfo("list", i)
--		thisItem.iLevel = select (4, GetItemInfo (itemLink))
		local _, _, count, _, _, _, _, _, buyoutPrice, _, _, owner = GetAuctionItemInfo("list", i)
		local unitPrice = math.floor (buyoutPrice / count) / 10000
		if unitPrice ~= 0 then
			glyphRecord[id] = glyphRecord[id] or {}
			glyphRecord[id].minUnitPrice = not glyphRecord[id].minUnitPrice and unitPrice or math.min (unitPrice, glyphRecord[id].minUnitPrice)
			if owner == myname then
				glyphRecord[id].myPrice = (not glyphRecord[id].myPrice and unitPrice or math.min (unitPrice, glyphRecord[id].myPrice))
			end
		end
	end
	scanThisPageOver = true
end

local function f_OnUpdate ()
	if not AuctionFrame:IsShown() then
		dealAuctionList ()
	end
	if scanThisPageOver and CanSendAuctionQuery () then
		scanThisPageOver = false
		QueryAuctionItems (itemName, minLevel, maxLevel, invTypeIndex, classIndex, subClassIndex, page, isUsable, minQuality, getAll)
--~ 		print (name, minLevel, maxLevel, invTypeIndex, classIndex, subClassIndex, page, isUsable, minQuality, getAll)
		f:RegisterEvent ("AUCTION_ITEM_LIST_UPDATE")
		f:SetScript ("OnEvent", dealAuctionList)
	end
end

function glyphMerchant_scan ()
	glyphMerchantPost:Hide ()
	glyphMerchantButton:Disable ()
	scanOver = false
	scanThisPageOver = true
	page = 0
	for i, v in pairs (glyphRecord) do
		glyphRecord[i] = {}
	end
	glyphRecordSorted = {}
	f:SetScript ("OnUpdate", f_OnUpdate)
end

function glyphMerchant_show ()
	for i, v in ipairs (glyphRecordSorted) do
		if v.minUnitPrice < 20 then
			break
		end
		print (select (2, GetItemInfo (v.id)), v.minUnitPrice, v.myPrice)
	end
end

function glyphMerchant_report ()
	local n = table.getn (glyphRecordSorted)
	glyphMerchantPostList:SetHeight (16 * n)
	glyphMerchantPostList:SetWidth (244)
	for i = 1, n do
		if not getglobal ("glyphMerchantPostList" .. i) then
			_G["glyphMerchantPostList" .. i] = CreateFrame ("frame", "glyphMerchantPostList" .. i, glyphMerchantPostList, "glyphMerchantPostVirtualBar1")
			if i == 1 then
				getglobal ("glyphMerchantPostList" .. i):SetPoint ("TOP")
			else
				getglobal ("glyphMerchantPostList" .. i):SetPoint ("TOP", "glyphMerchantPostList" .. i - 1, "BOTTOM")
			end
		end
		getglobal ("glyphMerchantPostList" .. i .. "Button1" .. "Text"):SetText (select (2, GetItemInfo(glyphRecordSorted[i].id)))
		if glyphRecordSorted[i].minUnitPrice ~= 0 then
			getglobal ("glyphMerchantPostList" .. i .. "Button2" .. "Text"):SetText (string.format("%.4f", glyphRecordSorted[i].minUnitPrice))
		else
			getglobal ("glyphMerchantPostList" .. i .. "Button2" .. "Text"):SetText ("")
		end
		if glyphRecordSorted[i].myPrice then
			if glyphRecordSorted[i].myPrice > glyphRecordSorted[i].minUnitPrice then
				getglobal ("glyphMerchantPostList" .. i .. "Button3" .. "Text"):SetTextColor (1,0,0)
			else
				getglobal ("glyphMerchantPostList" .. i .. "Button3" .. "Text"):SetTextColor (1,1,1)
			end
			getglobal ("glyphMerchantPostList" .. i .. "Button3" .. "Text"):SetText (string.format("%.4f", glyphRecordSorted[i].myPrice))
		else
			getglobal ("glyphMerchantPostList" .. i .. "Button3" .. "Text"):SetText ("")
		end
		getglobal ("glyphMerchantPostList" .. i .. "Button1"):SetScript ("OnEnter", function ()
																						GameTooltip:SetOwner (ChatFrame1, "ANCHOR_TOPRIGHT")
																						GameTooltip:SetHyperlink (select (2, GetItemInfo(glyphRecordSorted[i].id)))
																						GameTooltip:Show ()
																					end)
		getglobal ("glyphMerchantPostList" .. i .. "Button1"):SetScript ("OnClick", function ()
																						local itemname = select (1, GetItemInfo(glyphRecordSorted[i].id))
																						QueryAuctionItems (itemname, nil, nil, nil, classIndex, subClassIndex, nil, nil, nil, nil)
																					end)

	end
	glyphMerchantPost:Show ();
end

function glyphMerchant_cancelAuction ()
	local n = GetNumAuctionItems("owner")
	local canceled = 0
	for i = n, 1, -1 do
		local count = select (3, GetAuctionItemInfo("owner", i))
		if count == 0 then
			break
		end
		local buyoutPrice, bidAmount = select(9,GetAuctionItemInfo("owner", i))
		local id = tonumber (string.match (GetAuctionItemLink("owner", i), ".*Hitem:(.-):.*"))
		if glyphRecord[id] then
			if bidAmount == 0 and glyphRecord[id].minUnitPrice and glyphRecord[id].minUnitPrice < math.floor (buyoutPrice / count) /10000 then
				CancelAuction(i)
				canceled = canceled + 1
			end
		end
	end
--	print (string.format(glyphMerchantCancelOver, canceled))
end
