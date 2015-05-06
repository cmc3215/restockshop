--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
NS.addon = ...;
NS.title = GetAddOnMetadata( NS.addon, "Title" );
NS.stringVersion = GetAddOnMetadata( NS.addon, "Version" );
NS.version = tonumber( NS.stringVersion );
NS.loaded = false;
NS.wowClientBuild = select( 2, GetBuildInfo() );
NS.currentListKey = nil;
NS.AuctionTab = nil;
NS.tooltipAdded = false;
NS.items = {};
NS.editItemId = nil;
NS.scanning = false;
NS.scanType = nil;
NS.buyAll = false;
NS.canBid = false;
NS.ailu = "LISTEN";
NS.query = {
	queue = {},
	item = {},
	page = 0,
	totalPages = 0,
	attempts = 1,
	maxAttempts = 50,
	batchAttempts = 1,
	maxBatchAttempts = 3,
	batchAuctions = 0,
	totalAuctions = 0,
};
NS.auction = {
	data = {
		raw = {},
		groups = {
			visible = {},
			overpriced = {},
			overstock = {},
		},
		sortKey = nil,
		sortOrder = nil,
	},
	selected = {
		groupKey = nil,
		auction = nil,
		found = false,
	}
};
NS.options = {};
NS.colorCode = {
	low = ORANGE_FONT_COLOR_CODE,
	norm = YELLOW_FONT_COLOR_CODE,
	full = "|cff3fbf3f",
	maxFull = GRAY_FONT_COLOR_CODE,
};
NS.fontColor = {
	low = ORANGE_FONT_COLOR,
	norm = YELLOW_FONT_COLOR,
	full = { r=0.25, g=0.75, b=0.25 },
	maxFull = GRAY_FONT_COLOR,
};
--------------------------------------------------------------------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_Explode( sep, str )
	local t = {};
	for v in string.gmatch( str, "[^%" .. sep .. "]+" ) do
		table.insert( t, v );
	end
	return t;
end

--
function RestockShop_TimeDelayFunction( delaySeconds, delayFunction )
	local totalDelay = 0;
	local function CheckDelay( self, elapsed )
		totalDelay = totalDelay + elapsed;
		if totalDelay >= delaySeconds then
			self:SetScript( "OnUpdate", nil );
			self:SetParent( nil );
			delayFunction();
		end
	end
	local f = CreateFrame( "FRAME" );
	f:SetScript( "OnUpdate", CheckDelay );
end

--
function RestockShop_TruncatedText_OnEnter( self )
	local fs = _G[self:GetName() .. "Text"];
	if fs:IsTruncated() then
		GameTooltip:SetOwner( self, "ANCHOR_TOP" );
		GameTooltip:SetText( fs:GetText() );
	end
end

--
function RestockShop_Count( t )
	local count = 0;
	for _ in pairs( t ) do
		count = count + 1;
	end
	return count;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Optional Dependency Check - Need at least one loaded
--------------------------------------------------------------------------------------------------------------------------------------------
local addonLoaded = {};
local character = UnitName( "player" );
for i = 1, GetNumAddOns() do
	local name,_,_,loadable,_,_,_ = GetAddOnInfo( i );
	if loadable and GetAddOnEnableState( character, i ) > 0 then
		addonLoaded[name] = true;
	end
end
local optAddons = { "Auc-Advanced", "Auctionator", "TradeSkillMaster_AuctionDB", "TradeSkillMaster_WoWuction" };
for k, v in ipairs( optAddons ) do
	if addonLoaded[v] then
		break -- Stop checking, we only needed one enabled
	elseif k == #optAddons then
		print( "RestockShop: " .. string.format( L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"], RED_FONT_COLOR_CODE, table.concat( optAddons, ", " ) ) );
		return -- Stop executing file
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Default SavedVariables/PerCharacter & Upgrade Function
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_DefaultSavedVariables()
	return {
		["version"] = NS.version,
		["wowClientBuild"] = NS.wowClientBuild,
		["flyoutPanelOpen"] = true,
		["hideOverpricedStacks"] = true,
		["hideOverstockStacks"] = false,
		["itemTooltipShoppingListSettings"] = true,
		["itemTooltipItemId"] = true,
		["showDeleteItemConfirmDialog"] = true,
		["rememberOptionsFramePosition"] = true,
		["optionsFramePosition"] = { "CENTER", 0, 0 },
		["shoppingLists"] = {
			[1] = {
				["name"] = L["Restock Shopping List"],
				["items"] = {},
				["itemValueSrc"] = ( addonLoaded["TradeSkillMaster_AuctionDB"] and "DBMarket" ) or ( addonLoaded["TradeSkillMaster_WoWuction"] and "wowuctionMarket" ) or ( addonLoaded["Auc-Advanced"] and "AucMarket" ) or ( addonLoaded["Auctionator"] and "AtrValue" ),
				["lowStockPct"] = 50,
				["qohAllCharacters"] = 1,
				["qohGuilds"] = true,
				["hideOverstockStacksPct"] = 20,
			},
		},
	};
end

--
function RestockShop_DefaultSavedVariablesPerCharacter()
	return {
		["version"] = NS.version,
		["currentListName"] = L["Restock Shopping List"],
	};
end

--
function RestockShop_Upgrade()
	local vars = RestockShop_DefaultSavedVariables();
	local version = NS.db["version"];
	-- 1.7
	if version < 1.7 then
		NS.db["showDeleteItemConfirmDialog"] = vars["showDeleteItemConfirmDialog"];
	end
	-- 1.9
	if version < 1.9 then
		NS.db["flyoutPanelOpen"] = vars["flyoutPanelOpen"];
	end
	-- 2.0
	if version < 2.0 then
		if string.sub( NS.db["itemValueSrc"], 1, 3 ) == "TUJ" then
			NS.db["itemValueSrc"] = vars["shoppingLists"][1]["itemValueSrc"];
		end
		--
		local listKey = 1;
		while listKey <= #NS.db["shoppingLists"] do
			if not NS.db["shoppingLists"][listKey]["name"] then
				table.remove( NS.db["shoppingLists"], listKey ); -- Remove empty tables from previously deleted lists
			else
				listKey = listKey + 1;
			end
		end
		--
		table.sort ( NS.db["shoppingLists"],
			function ( list1, list2 )
				return list1["name"] < list2["name"]; -- Sort lists by name A-Z
			end
		);
		--
		NS.db["wowClientBuild"] = 0; -- Forces the item data update that was added this version
	end
	-- 2.4
	if version < 2.4 then
		NS.db["hideOverstockStacks"] = vars["hideOverstockStacks"];
		NS.db["hideOverstockStacksPct"] = vars["shoppingLists"][1]["hideOverstockStacksPct"];
	end
	-- 2.5
	if version < 2.5 then
		if NS.db["itemValueSrc"] == "DBGlobalMarketMedian" or NS.db["itemValueSrc"] == "DBGlobalMinBuyoutMedian" then
			NS.db["itemValueSrc"] = vars["shoppingLists"][1]["itemValueSrc"];
		end
	end
	-- 2.8
	if version < 2.8 then
		NS.db["hideOverpricedStacks"] = vars["hideOverpricedStacks"];
	end
	-- 2.9
	if version < 2.9 then
		NS.db["rememberOptionsFramePosition"] = vars["rememberOptionsFramePosition"];
		NS.db["optionsFramePosition"] = vars["optionsFramePosition"];
		NS.db["qohAllCharacters"] = NS.db["qoh"]["allCharacters"];
		NS.db["qohGuilds"] = NS.db["qoh"]["guilds"];
		NS.db["itemTooltipShoppingListSettings"] = NS.db["itemTooltip"]["shoppingListSettings"];
		NS.db["itemTooltipItemId"] = NS.db["itemTooltip"]["itemId"];
		NS.db["qoh"] = nil;
		NS.db["itemTooltip"] = nil;
		for k = 1, #NS.db["shoppingLists"] do
			NS.db["shoppingLists"][k]["itemValueSrc"] = NS.db["itemValueSrc"];
			NS.db["shoppingLists"][k]["lowStockPct"] = NS.db["lowStockPct"];
			NS.db["shoppingLists"][k]["qohAllCharacters"] = NS.db["qohAllCharacters"];
			NS.db["shoppingLists"][k]["qohGuilds"] = NS.db["qohGuilds"];
			NS.db["shoppingLists"][k]["hideOverstockStacksPct"] = NS.db["hideOverstockStacksPct"];
		end
		NS.db["itemValueSrc"] = nil;
		NS.db["lowStockPct"] = nil;
		NS.db["qohAllCharacters"] = nil;
		NS.db["qohGuilds"] = nil;
		NS.db["hideOverstockStacksPct"] = nil;
	end
	-- 3.2
	if version < 3.2 then
		NS.db["optionsFramePosition"] = vars["optionsFramePosition"];
	end
	--
	print( "RestockShop: " .. string.format( L["Upgraded version %s to %s"], version, NS.version ) );
	NS.db["version"] = NS.version;
end

--
function RestockShop_UpgradePerCharacter()
	local varspercharacter = RestockShop_DefaultSavedVariablesPerCharacter();
	local version = NS.dbpc["version"];
	--
	-- Not currently used, but will be going forward, SVPC version was introduced in 2.0 requiring SVPC to be overwritten with defaults because version will be nil
	--
	NS.dbpc["version"] = NS.version;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_OnAddonLoaded() -- ADDON_LOADED
	if IsAddOnLoaded( "RestockShop" ) then
		if not NS.loaded then
			-- Set Default SavedVariables
			if not RESTOCKSHOP_SAVEDVARIABLES then
				RESTOCKSHOP_SAVEDVARIABLES = RestockShop_DefaultSavedVariables();
			end
			-- Set Default SavedVariablesPerCharacter
			if not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER or not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"] then
				RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER = RestockShop_DefaultSavedVariablesPerCharacter();
			end
			-- Localize SavedVariables
			NS.db = RESTOCKSHOP_SAVEDVARIABLES;
			NS.dbpc = RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER;
			-- Upgrade if old version
			if NS.db["version"] < NS.version then
				RestockShop_Upgrade();
			end
			-- Upgrade Per Character if old version
			if NS.dbpc["version"] < NS.version then
				RestockShop_UpgradePerCharacter();
			end
			-- WoW client build changed, requery all lists for possible item changes
			if NS.db["wowClientBuild"] ~= NS.wowClientBuild then
				RestockShop_WoWClientBuildChanged();
			end
			-- Make sure current list name exists, if not reset to first list
			for k, list in ipairs( NS.db["shoppingLists"] ) do
				if list["name"] == NS.dbpc["currentListName"] then
					NS.currentListKey = k;
					break;
				end
			end
			if not NS.currentListKey then
				NS.dbpc["currentListName"] = NS.db["shoppingLists"][1]["name"];
				NS.currentListKey = 1;
			end
			-- Hook Item Tooltip
			ItemRefTooltip:HookScript( "OnTooltipSetItem", RestockShop_AddTooltipData );
			GameTooltip:HookScript( "OnTooltipSetItem", RestockShop_AddTooltipData );
			ItemRefTooltip:HookScript( "OnTooltipCleared", Restockshop_ClearTooltipData );
			GameTooltip:HookScript( "OnTooltipCleared", Restockshop_ClearTooltipData );
			--
			NS.loaded = true;
		end
		if IsAddOnLoaded( "Blizzard_AuctionUI" ) then
			RestockShopEventsFrame:UnregisterEvent( "ADDON_LOADED" );
			-- Add "RestockShop" Tab to AuctionFrame
			local n = AuctionFrame.numTabs + 1;
			NS.AuctionTab = CreateFrame( "Button", "AuctionFrameTab" .. n, AuctionFrame, "AuctionTabTemplate" );
			NS.AuctionTab:SetID( n );
			NS.AuctionTab:SetText( "RestockShop" );
			NS.AuctionTab:SetNormalFontObject( GameFontNormalSmall );
			NS.AuctionTab:SetPoint( "LEFT", _G["AuctionFrameTab" .. n - 1], "RIGHT", -8, 0 );
			PanelTemplates_SetNumTabs( AuctionFrame, n );
			PanelTemplates_EnableTab( AuctionFrame, n );
			-- Place RestockShopFrame into AuctionFrame
			RestockShopFrame:SetParent( AuctionFrame );
			RestockShopFrame:SetPoint( "TOPLEFT" );
			-- Secure Hook function AuctionFrameTab_OnClick()
			hooksecurefunc( "AuctionFrameTab_OnClick", RestockShop_AuctionFrameTab_OnClick );
		end
	end
end

--
function RestockShop_OnPlayerLogin() -- PLAYER_LOGIN
	RestockShopEventsFrame:UnregisterEvent( "PLAYER_LOGIN" );
	RestockShopInterfaceOptionsPanel:Init();
	--
	if not NS.db["flyoutPanelOpen"] then
		RestockShopFrame_FlyoutPanelButton:Click();
	end
	--
	if NS.db["hideOverpricedStacks"] then
		RestockShopFrame_HideOverpricedStacksButton:LockHighlight();
	end
	--
	if NS.db["hideOverstockStacks"] then
		RestockShopFrame_HideOverstockStacksButton:LockHighlight();
	end
end

--
function RestockShop_OnAuctionItemListUpdate() -- AUCTION_ITEM_LIST_UPDATE
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	if NS.ailu == "AUCTION_WON" then RestockShop_AfterAuctionWon(); end
	if NS.ailu == "IGNORE" then NS.ailu = "LISTEN"; return end
	if not NS.scanning then return end
	NS.query.batchAuctions, NS.query.totalAuctions = GetNumAuctionItems( "list" );
	NS.query.totalPages = ceil( NS.query.totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE );
	RestockShop_ScanAuctionPage();
end

--
function RestockShop_OnChatMsgSystem( ... ) -- CHAT_MSG_SYSTEM
	local arg1 = select( 1, ... );
	if not arg1 then return end
	if arg1 == ERR_AUCTION_BID_PLACED then
		-- Bid Acccepted.
		NS.ailu = "IGNORE"; -- Ignore the list update after "Bid accepted."
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
	elseif arg1:match( string.gsub( ERR_AUCTION_WON_S, "%%s", "" ) ) and arg1 == string.format( ERR_AUCTION_WON_S, NS.auction.selected.auction["name"] ) then
		-- You won an auction for %s
		NS.ailu = "AUCTION_WON"; -- Helps decide to Ignore or Listen to the list update after "You won an auction for %s"
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	end
end

--
function RestockShop_OnUIErrorMessage( ... ) -- UI_ERROR_MESSAGE
	local arg1 = select( 1, ... );
	if not arg1 then return end
	--
	if arg1 == ERR_ITEM_NOT_FOUND or arg1 == ERR_AUCTION_HIGHER_BID or arg1 == ERR_AUCTION_BID_OWN then
		if arg1 == ERR_ITEM_NOT_FOUND or arg1 == ERR_AUCTION_HIGHER_BID then
			print( "RestockShop: " .. L["That auction was no longer available"] );
		elseif arg1 == ERR_AUCTION_BID_OWN then
			print( "RestockShop: " .. L["That auction belonged to you and couldn't be won"] );
		end
		--
		NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] = NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] - 1;
		--
		if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] == 0 then
			-- Group removed
			table.remove( NS.auction.data.groups.visible, NS.auction.selected.groupKey );
			RestockShopFrame_ScrollFrame_Auction_Deselect();
			if next( NS.auction.data.groups.visible ) then
				-- More auctions exist
				if NS.buyAll then
					RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
				else
					RestockShopFrame_ScrollFrame_Update();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
						RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
					end
					RestockShopFrame_BuyAllButton:Enable();
				end
			else
				-- No auctions exist
				RestockShopFrame_ScrollFrame_Update();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
				end
				RestockShopFrame_BuyAllButton_Reset();
			end
		else
			-- Single auction removed
			table.remove( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["auctions"] );
			RestockShopFrame_ScrollFrame_Entry_OnClick( NS.auction.selected.groupKey );
		end
	elseif arg1 == ERR_NOT_ENOUGH_MONEY then -- Not Enough Money
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["You don't have enough money to buy that auction"] );
		RestockShopFrame_BuyAllButton:Enable();
	elseif arg1 == ERR_ITEM_MAX_COUNT then -- Item Max Count
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["You can't carry anymore of that item"] );
		RestockShopFrame_BuyAllButton:Enable();
	else
		return; -- Stop function, ignore unrelated errors
	end
	--
	RestockShopFrame_ShopButton:Enable();
	RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Auction Frame Tab
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_AuctionFrameTab_OnClick( self, button, down, index ) -- AuctionFrameTab_OnClick
	if NS.AuctionTab:GetID() == self:GetID() then
		AuctionFrameTopLeft:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft" );
		AuctionFrameTop:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top" );
		AuctionFrameTopRight:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight" );
		AuctionFrameBotLeft:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft" );
		AuctionFrameBot:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot" );
		AuctionFrameBotRight:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight" );
		RestockShopFrame:Show();
	else
		RestockShopFrame:Hide();
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopFrame Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShopFrame_Reset( flyoutPanelEntryClick )
	RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	--
	RestockShopFrame_Title:SetText(
		NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ..
		"     /     " .. ( NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 1 and L["All Characters"] or L["Current Character"] ) .. " (" .. ( NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] == true and  L["including Guilds"] or L["not including Guilds"] ) .. ")" ..
		"     /     " .. NS.colorCode.low .. NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] .. "%|r" ..
		"     /     " .. NS.colorCode.full .. NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] .. "%|r"
	);
	--
	RestockShop_StopScanning();
	RestockShopFrame_ScrollFrame_Auction_Deselect();
	RestockShopFrame_DialogFrame_StatusFrame_Update( L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] );
	RestockShopFrame_ShoppingListsDropDownMenu_Load();
	RestockShopFrame_ShopButton_Reset();
	RestockShopFrame_BuyAllButton_Reset();
	--
	NS.items = {};
	NS.query.item = {};
	NS.query.queue = {};
	NS.auction.data.groups.visible = {};
	NS.auction.data.groups.overpriced = {};
	NS.auction.data.groups.overstock = {};
	--
	RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 );
	RestockShopFrame_HideSortButtonArrows();
	RestockShopFrame_NameSortButton:Click(); -- Also updates ScrollFrame
	--
	RestockShopFrame_ListStatusFrame_Text:SetText( string.format( "%s\n\n%s   =   %s%d|r", NS.db["shoppingLists"][NS.currentListKey]["name"], RestockShopFrame_ListSummary(), NORMAL_FONT_COLOR_CODE, #NS.db["shoppingLists"][NS.currentListKey]["items"] ) );
	RestockShopFrame_ListStatusFrame:Show();
	--
	RestockShopFrame_FlyoutPanel.TitleText:SetText( NS.db["shoppingLists"][NS.currentListKey]["name"] );
	if not flyoutPanelEntryClick then
		RestockShopFrame_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 ); -- Only reset vertical scroll when NOT clicking entry in FlyoutPanel
	end
	RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
	RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
	--
	StaticPopup_Hide( "RESTOCKSHOP_APPLY_TO_ALL_ITEMS" );
	StaticPopup_Hide( "RESTOCKSHOP_APPLY_TO_ALL_LISTS" );
	StaticPopup_Hide( "RESTOCKSHOP_SHOPPINGLISTITEM_DELETE" );
	StaticPopup_Hide( "RESTOCKSHOP_SHOPPINGLIST_CREATE" );
	StaticPopup_Hide( "RESTOCKSHOP_SHOPPINGLIST_COPY" );
	StaticPopup_Hide( "RESTOCKSHOP_SHOPPINGLIST_DELETE" );
	StaticPopup_Hide( "RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT" );
end

--
function RestockShopFrame_HideSortButtonArrows()
    _G["RestockShopFrame_RestockSortButtonArrow"]:Hide();
	_G["RestockShopFrame_NameSortButtonArrow"]:Hide();
	_G["RestockShopFrame_StackSizeSortButtonArrow"]:Hide();
	_G["RestockShopFrame_PctItemValueSortButtonArrow"]:Hide();
	_G["RestockShopFrame_ItemPriceSortButtonArrow"]:Hide();
	_G["RestockShopFrame_OnHandSortButtonArrow"]:Hide();
end

--
function RestockShopFrame_ListSummary()
	local low, norm, full, maxFull = 0, 0, 0, 0;
	for k, v in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
		local restockPct = RestockShop_RestockPct( RestockShop_QOH( v["tsmItemString"] ), v["fullStockQty"] );
		if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
			low = low + 1;
		elseif restockPct < 100 then
			norm = norm + 1;
		elseif v["maxPricePct"]["full"] > 0 then
			full = full + 1;
		else
			maxFull = maxFull + 1;
		end
	end
	return string.format( "|cffffffff%d|r %s(" .. L["Low"] .. ")|r  |cffffffff%d|r %s(" .. L["Norm"] .. ")|r  |cffffffff%d|r %s(" .. L["Full"] .. ")|r  |cffffffff%d|r %s(" .. L["Full"] .. ")|r", low, NS.colorCode.low, norm, NS.colorCode.norm, full, NS.colorCode.full, maxFull, NS.colorCode.maxFull );
end

--
function RestockShopFrame_ScrollFrame_UnlockHighlights()
	for numEntry = 1, 15 do
		_G["RestockShopFrame_ScrollFrame_Entry" .. numEntry]:UnlockHighlight();
	end
end

--
function RestockShopFrame_ScrollFrame_Update()
	local groups = NS.auction.data.groups.visible;
	local numItems, numToDisplay, valueStep = #groups, 15, 16;
	local dataOffset = FauxScrollFrame_GetOffset( RestockShopFrame_ScrollFrame );
	FauxScrollFrame_Update( RestockShopFrame_ScrollFrame, numItems, numToDisplay, valueStep );
	for numEntry = 1, numToDisplay do
		local EntryFrameName = "RestockShopFrame_ScrollFrame_Entry" .. numEntry;
		local EntryFrame = _G[EntryFrameName];
		local offsetKey = dataOffset + numEntry;
		EntryFrame:UnlockHighlight();
		if offsetKey <= numItems then
			local OnClick = function()
				RestockShopFrame_ScrollFrame_Entry_OnClick( offsetKey );
			end
			local IsHighlightLocked = function()
				if NS.auction.selected.groupKey and NS.auction.selected.groupKey == offsetKey then
					return true;
				else
					return false;
				end
			end
			--
			_G[EntryFrameName .. "_OnHand"]:SetText( groups[offsetKey]["onHandQty"] );
			local restockColor = RestockShop_RestockColor( "font", groups[offsetKey]["restockPct"] );
			_G[EntryFrameName .. "_Restock"]:SetText( math.floor( groups[offsetKey]["restockPct"] ) .. "%" );
			_G[EntryFrameName .. "_Restock"]:SetTextColor( restockColor["r"], restockColor["g"], restockColor["b"] );
			_G[EntryFrameName .. "_IconTexture"]:SetNormalTexture( groups[offsetKey]["texture"] );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( groups[offsetKey]["itemLink"] ); EntryFrame:LockHighlight(); end );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnLeave", function() GameTooltip_Hide(); if not IsHighlightLocked() then EntryFrame:UnlockHighlight(); end end );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnClick", OnClick );
			_G[EntryFrameName .. "_Name"]:SetText( groups[offsetKey]["name"] );
			_G[EntryFrameName .. "_Name"]:SetTextColor( GetItemQualityColor( groups[offsetKey]["quality"] ) );
			_G[EntryFrameName .. "_Stacks"]:SetText( string.format( L["%d stacks of %d"], groups[offsetKey]["numAuctions"], groups[offsetKey]["count"] ) );
			MoneyFrame_Update( EntryFrameName .. "_ItemPrice_SmallMoneyFrame", groups[offsetKey]["itemPrice"] );
			_G[EntryFrameName .. "_PctItemValue"]:SetText( math.floor( groups[offsetKey]["pctItemValue"] ) .. "%" );
			if groups[offsetKey]["pctMaxPrice"] > 100 then _G[EntryFrameName .. "_PctItemValue"]:SetText( RED_FONT_COLOR_CODE .. _G[EntryFrameName .. "_PctItemValue"]:GetText() .. "|r" ); end
			EntryFrame:SetScript( "OnClick", OnClick );
			EntryFrame:Show();
			if IsHighlightLocked() then EntryFrame:LockHighlight(); end
		else
			EntryFrame:Hide();
		end
	end
end

--
function RestockShopFrame_ScrollFrame_Entry_OnClick( groupKey )
	if NS.scanning then
		print( "RestockShop: " .. L["Selection ignored, busy scanning"] );
		return; -- Stop function
	end
	--
	RestockShop_SetCanBid( false );
	--
	local auction = NS.auction.data.groups.visible[groupKey]["auctions"][#NS.auction.data.groups.visible[groupKey]["auctions"]];
	NS.query.page = auction["page"];
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = groupKey;
	NS.auction.selected.auction = auction; -- Cannot use index, ownerFullName, or buyoutPrice yet, these may change after scanning the page
	if NS.buyAll and groupKey == 1 then
		RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
	end
	RestockShopFrame_ScrollFrame_Update();
	--
	NS.query.queue = {};
	table.insert( NS.query.queue, NS.items[auction["itemId"]] );
	NS.scanType = "SELECT";
	RestockShop_ScanAuctionQueue();
end

--
function RestockShopFrame_ScrollFrame_Auction_Deselect()
	RestockShopFrame_ScrollFrame_UnlockHighlights();
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = nil;
	NS.auction.selected.auction = nil;
	RestockShop_SetCanBid( false );
end

--
function RestockShopFrame_FlyoutPanel_ScrollFrame_Update()
	local items = NS.db["shoppingLists"][NS.currentListKey]["items"];
	local numItems, numToDisplay, valueStep = #items, 17, 16;
	local dataOffset = FauxScrollFrame_GetOffset( RestockShopFrame_FlyoutPanel_ScrollFrame );
	FauxScrollFrame_Update( RestockShopFrame_FlyoutPanel_ScrollFrame, numItems, numToDisplay, valueStep );
	--
	local flyoutWidth = ( function() if numItems > 17 then return 254 else return 227 end end )();
	RestockShopFrame_FlyoutPanel:SetWidth( flyoutWidth );
	--
	if numItems > 17 and #NS.query.queue > 0 then
		local vScroll = ( numItems - #NS.query.queue - ( 17 - 1 ) ) * 16;
		if vScroll > 0 and vScroll > RestockShopFrame_FlyoutPanel_ScrollFrame:GetVerticalScroll() then
			RestockShopFrame_FlyoutPanel_ScrollFrame:SetVerticalScroll( vScroll );
		end
	end
	--
	for numEntry = 1, numToDisplay do
		local EntryFrameName = "RestockShopFrame_FlyoutPanel_ScrollFrame_Entry" .. numEntry;
		local EntryFrame = _G[EntryFrameName];
		local offsetKey = dataOffset + numEntry;
		EntryFrame:UnlockHighlight();
		if offsetKey <= numItems then
			local OnClick = function()
				RestockShopFrame_FlyoutPanel_ScrollFrame_Entry_OnClick( offsetKey );
			end
			local IsHighlightLocked = function()
				if ( NS.scanType == "SHOP" or RestockShop_Count( NS.items ) == 1 ) and NS.query.item["itemId"] == items[offsetKey]["itemId"] then
					return true;
				else
					return false;
				end
			end
			EntryFrame:SetScript( "OnClick", OnClick );
			_G[EntryFrameName .. "_IconTexture"]:SetNormalTexture( items[offsetKey]["texture"] );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[offsetKey]["link"] ); EntryFrame:LockHighlight(); end );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnLeave", function() GameTooltip_Hide(); if not IsHighlightLocked() then EntryFrame:UnlockHighlight(); end end );
			_G[EntryFrameName .. "_IconTexture"]:SetScript( "OnClick", OnClick );
			_G[EntryFrameName .. "_Name"]:SetText( items[offsetKey]["name"] );
			_G[EntryFrameName .. "_Name"]:SetTextColor( GetItemQualityColor( items[offsetKey]["quality"] ) );
			--
			local onHandQty = RestockShop_QOH( items[offsetKey]["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, items[offsetKey]["fullStockQty"] );
			local restockStatus;
			if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
				restockStatus = NS.colorCode.low .. L["Low"] .. "|r";
			elseif restockPct < 100 then
				restockStatus = NS.colorCode.norm .. L["Norm"] .. "|r";
			elseif items[offsetKey]["maxPricePct"]["full"] > 0 then
				restockStatus = NS.colorCode.full .. L["Full"] .. "|r";
			else
				restockStatus = NS.colorCode.maxFull .. L["Full"] .. "|r";
			end
			_G[EntryFrameName .. "_RestockStatus"]:SetText( restockStatus );
			--
			local scanTexture;
			if not NS.items[items[offsetKey]["itemId"]] then
				scanTexture = "Waiting";
			else
				scanTexture = NS.items[items[offsetKey]["itemId"]]["scanTexture"];
			end
			_G[EntryFrameName .. "_ScanTexture"]:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-" .. scanTexture );
			--
			EntryFrame:Show();
			if IsHighlightLocked() then EntryFrame:LockHighlight(); end
		else
			EntryFrame:Hide();
		end
	end
end

--
function RestockShopFrame_FlyoutPanel_ScrollFrame_Entry_OnClick( itemKey )
	RestockShopFrame_Reset( true );
	RestockShopFrame_ListStatusFrame:Hide();
	NS.auction.data.raw = {};
	--
	local item = CopyTable( NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey] );
	table.insert( NS.query.queue, item );
	NS.items[item["itemId"]] = item;
	NS.items[item["itemId"]]["scanTexture"] = "Waiting";
	NS.scanType = "SHOP";
	RestockShop_ScanAuctionQueue();
end

--
function RestockShopFrame_DialogFrame_StatusFrame_Update( text )
	RestockShopFrame_DialogFrame_StatusFrame_Text:SetText( text );
	RestockShopFrame_DialogFrame_StatusFrame_SetActive();
end

--
function RestockShopFrame_DialogFrame_StatusFrame_SetActive()
	RestockShopFrame_DialogFrame_BuyoutFrame:Hide();
	RestockShopFrame_DialogFrame_StatusFrame:Show();
end

--
function RestockShopFrame_DialogFrame_BuyoutFrame_SetActive()
	RestockShopFrame_DialogFrame_StatusFrame:Hide();
	RestockShopFrame_DialogFrame_BuyoutFrame:Show();
end

--
function RestockShopFrame_ShoppingListsDropDownMenu_Load()
	local panelName = "RestockShopFrame";
	-- Dropdown Button Click
	local function DropDownMenuButton_OnClick( info )
		UIDropDownMenu_SetSelectedValue( info.owner, info.value );
		if NS.currentListKey ~= info.value then
			NS.dbpc["currentListName"] = info.text;
			NS.currentListKey = info.value;
			RestockShopFrame_Reset();
		end
	end
	-- Dropdown Add Button
	local function DropDownMenu_AddButton( frame, text, value )
		local info = {};
		info.owner = frame;
		info.text = text;
		info.value = value;
		info.checked = nil;
		info.func = function () DropDownMenuButton_OnClick( info ) end;
		UIDropDownMenu_AddButton( info );
	end
	-- Dropdown Initialize
	local function DropDownMenu_Initialize( frame )
		local frameName = frame:GetName();
		if frameName == ( panelName .. "_ShoppingListsDropDownMenu" ) then
			for k, v in ipairs( NS.db["shoppingLists"] ) do
				DropDownMenu_AddButton( frame, v["name"], k );
			end
		end
	end
	-- Shopping Lists Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "_ShoppingListsDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "_ShoppingListsDropDownMenu"], NS.currentListKey );
	UIDropDownMenu_SetWidth( _G[panelName .. "_ShoppingListsDropDownMenu"], 195 );
end

--
function RestockShopFrame_ShopButton_Reset()
	RestockShopFrame_ShopButton:Enable();
	RestockShopFrame_ShopButton:SetText( L["Shop"] );
end

--
function RestockShopFrame_BuyAllButton_Reset()
	NS.buyAll = false;
	RestockShopFrame_BuyAllButton:Disable();
	RestockShopFrame_BuyAllButton:SetText( L["Buy All"] );
end

--
function RestockShopFrame_SortColumn_OnClick( button, itemInfoKey )
	-- Update Arrows
	local arrow = _G[button:GetName() .. "Arrow"];
	local l,_,_,_,r,t,_,b = arrow:GetTexCoord();
	local direction = ( function() if t == 0 and b == 1.0 then return "down" else return "up" end end )();
	local order;
	--
	if arrow:IsShown() and direction == "up" or not arrow:IsShown() then
		t = 0;
		b = 1.0;
		order = "ASC"; -- Arrow facing downward
	else
		t = 1.0;
		b = 0;
		order = "DESC"; -- Arrow facing upward
	end
	--
	RestockShopFrame_HideSortButtonArrows();
	arrow:SetTexCoord( 0, 0.5625, t, b );
	arrow:Show();
	-- Return sorted data to frame
	NS.auction.data.sortKey = itemInfoKey;
	NS.auction.data.sortOrder = order;
	RestockShop_AuctionDataGroups_Sort();
	if NS.buyAll then
		RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
	else
		RestockShopFrame_ScrollFrame_Update();
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Auction Data Groups Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_AuctionDataGroups_OnHandQtyChanged()
	-- Remove: If restockPct is 100+ and no maxPricePct["full"]
	-- Update: onHandQty, restockPct, pctMaxPrice
	-- This function should be run when an auction is won, uses the NS.auction.selected.auction
	-- ONLY Updates or Removes Groups for the ItemId that was won
	RestockShop_AuctionDataGroups_ShowOverpricedStacks();
	RestockShop_AuctionDataGroups_ShowOverstockStacks();
	--
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		if group["itemId"] == NS.auction.selected.auction["itemId"] then
			local onHandQty = RestockShop_QOH( group["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, group["fullStockQty"] );
			local pctMaxPrice = math.ceil( ( group["itemPrice"] * 100 ) / RestockShop_MaxPrice( group["itemValue"], restockPct, NS.items[group["itemId"]]["maxPricePct"] ) );
			--
			if restockPct >= 100 and NS.items[group["itemId"]]["maxPricePct"]["full"] == 0 then
				-- Remove
				table.remove( NS.auction.data.groups.visible, groupKey );
			else
				-- Update
				NS.auction.data.groups.visible[groupKey]["onHandQty"] = onHandQty;
				NS.auction.data.groups.visible[groupKey]["restockPct"] = restockPct;
				NS.auction.data.groups.visible[groupKey]["pctMaxPrice"] = pctMaxPrice;
				groupKey = groupKey + 1; -- INCREMENT ONLY IF NOT REMOVING. table.remove resequences the groupKeys, making the next actual group takeover the same groupKey you just deleted.
			end
		else
			groupKey = groupKey + 1; -- ItemId wasn't a match, increment to try the next group
		end
	end
	--
	if NS.db["hideOverpricedStacks"] then
		RestockShop_AuctionDataGroups_HideOverpricedStacks();
	end
	--
	if NS.db["hideOverstockStacks"] then
		RestockShop_AuctionDataGroups_HideOverstockStacks();
	end
end

--
function RestockShop_AuctionDataGroups_HideOverpricedStacks()
	-- Remove: If pctMaxPrice > 100
	-- Run this function when:
		-- a) Auction is won (RestockShop_AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside RestockShop_ScanAuctionQueue() just before RestockShop_ScanComplete()
		-- c) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		--
		if group["pctMaxPrice"] > 100 then
			-- Remove and insert
			table.insert( NS.auction.data.groups.overpriced, table.remove( NS.auction.data.groups.visible, groupKey ) );
		else
			-- Increment to try the next group
			groupKey = groupKey + 1;
		end
	end
end

--
function RestockShop_AuctionDataGroups_ShowOverpricedStacks()
	-- Run this function when:
		-- a) Auction is won (RestockShop_AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overpriced do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overpriced, groupKey ) );
	end
end

--
function RestockShop_AuctionDataGroups_HideOverstockStacks()
	-- Remove: If ( ( onHandQty + count ) * 100 ) / fullStockQty > 100 + {overstockStacksPct}
	-- Run this function when:
		-- a) Auction is won (RestockShop_AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside RestockShop_ScanAuctionQueue() just before RestockShop_ScanComplete()
		-- c) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		local afterPurchaseRestockPct = RestockShop_RestockPct( group["onHandQty"] + group["count"], group["fullStockQty"] );
		--
		if afterPurchaseRestockPct > ( 100 + NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] ) then
			-- Remove and insert
			table.insert( NS.auction.data.groups.overstock, table.remove( NS.auction.data.groups.visible, groupKey ) );
		else
			-- Increment to try the next group
			groupKey = groupKey + 1;
		end
	end
end

--
function RestockShop_AuctionDataGroups_ShowOverstockStacks()
	-- Run this function when:
		-- a) Auction is won (RestockShop_AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overstock do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overstock, groupKey ) );
	end
end

--
function RestockShop_AuctionDataGroups_FindGroupKey( itemId, name, count, itemPrice )
	for k, v in ipairs( NS.auction.data.groups.visible ) do
		if v["itemId"] == itemId and v["name"] == name and v["count"] == count and v["itemPrice"] == itemPrice then
			return k;
		end
	end
	return nil;
end

--
function RestockShop_AuctionDataGroups_RemoveItemId( itemId )
	-- This function is run just before raw data from a RESCAN is used to form new data groups, out with the old before in with the new
	--
	-- Visible
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		if NS.auction.data.groups.visible[groupKey]["itemId"] == itemId then
			-- Match, remove group
			table.remove( NS.auction.data.groups.visible, groupKey );
		else
			-- Not a match, increment to try next group
			groupKey = groupKey + 1;
		end
	end
	-- Overpriced
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overpriced do
		if NS.auction.data.groups.overpriced[groupKey]["itemId"] == itemId then
			-- Match, remove group
			table.remove( NS.auction.data.groups.overpriced, groupKey );
		else
			-- Not a match, increment to try next group
			groupKey = groupKey + 1;
		end
	end
	-- Overstock
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overstock do
		if NS.auction.data.groups.overstock[groupKey]["itemId"] == itemId then
			-- Match, remove group
			table.remove( NS.auction.data.groups.overstock, groupKey );
		else
			-- Not a match, increment to try next group
			groupKey = groupKey + 1;
		end
	end
end

--
function RestockShop_AuctionDataGroups_Sort()
	if not next( NS.auction.data.groups.visible ) then return end
	table.sort ( NS.auction.data.groups.visible,
		function ( item1, item2 )
			if NS.auction.data.sortOrder == "ASC" then
				if NS.auction.data.sortKey ~= "pctItemValue" and item1[NS.auction.data.sortKey] == item2[NS.auction.data.sortKey] then
					return item1["pctItemValue"] < item2["pctItemValue"];
				else
					return item1[NS.auction.data.sortKey] < item2[NS.auction.data.sortKey];
				end
			elseif NS.auction.data.sortOrder == "DESC" then
				if NS.auction.data.sortKey ~= "pctItemValue" and item1[NS.auction.data.sortKey] == item2[NS.auction.data.sortKey] then
					return item1["pctItemValue"] < item2["pctItemValue"];
				else
					return item1[NS.auction.data.sortKey] > item2[NS.auction.data.sortKey];
				end
			end
		end
	);
	-- Have to find the groupKey again if you reorder them
	if NS.auction.selected.groupKey then
		NS.auction.selected.groupKey = RestockShop_AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Scan Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_StartScanning()
	NS.scanning = true;
	RestockShop_SetCanBid( false );
	RestockShopFrame_ShopButton:SetText( L["Abort"] );
	RestockShopFrame_BuyAllButton:Disable();
end

--
function RestockShop_StopScanning()
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	NS.scanning = false;
	NS.query.page = 0;
	NS.query.attempts = 1;
	NS.query.batchAttempts = 1;
	RestockShopFrame_ShopButton:Enable();
end

--
function RestockShop_ScanAuctionQueue()
	if NS.scanning then return end
	if NS.scanType == "SHOP" then
		local footerText = ( function()
			if #NS.query.queue == 0 then
				return RestockShopFrame_ListSummary();
			else
				return string.format( L["%d items remaining"], #NS.query.queue );
			end
		end )();
		RestockShopFrame_FlyoutPanel_Footer:SetText( footerText );
	end
	if not next( NS.query.queue ) then
		-- Auction scan complete, queue empty
		if NS.scanType ~= "SELECT" then
			-- Assemble into sortable groups (itemid has x stacks of y for z copper)
			if NS.scanType == "RESCAN" then
				-- Remove groups for rescanned item, new groups will be created from raw data
				RestockShop_AuctionDataGroups_RemoveItemId( NS.query.item["itemId"] );
			end
			--
			for itemId, pages in pairs( NS.auction.data.raw ) do -- [ItemId] => [Page] => [Index] => ItemInfo
				for page, indexes in pairs( pages ) do
					for index, itemInfo in pairs( indexes ) do
						local groupKey = RestockShop_AuctionDataGroups_FindGroupKey( itemInfo["itemId"], itemInfo["name"], itemInfo["count"], itemInfo["itemPrice"] );
						if groupKey then
							table.insert( NS.auction.data.groups.visible[groupKey]["auctions"], itemInfo );
							NS.auction.data.groups.visible[groupKey]["numAuctions"] = NS.auction.data.groups.visible[groupKey]["numAuctions"] + 1;
						else
							table.insert( NS.auction.data.groups.visible, {
								["restockPct"] = itemInfo["restockPct"],
								["name"] = itemInfo["name"],
								["texture"] = itemInfo["texture"],
								["count"] = itemInfo["count"],
								["quality"] = itemInfo["quality"],
								["itemId"] = itemInfo["itemId"],
								["itemLink"] = itemInfo["itemLink"],
								["itemValue"] = itemInfo["itemValue"],
								["tsmItemString"] = itemInfo["tsmItemString"],
								["itemPrice"] = itemInfo["itemPrice"],
								["pctItemValue"] = itemInfo["pctItemValue"],
								["pctMaxPrice"] = itemInfo["pctMaxPrice"],
								["onHandQty"] = itemInfo["onHandQty"],
								["fullStockQty"] = itemInfo["fullStockQty"],
								["numAuctions"] = 1,
								["auctions"] = { itemInfo }
							} );
						end
					end
				end
			end
			--
			if NS.db["hideOverpricedStacks"] then
				RestockShop_AuctionDataGroups_HideOverpricedStacks();
			end
			--
			if NS.db["hideOverstockStacks"] then
				RestockShop_AuctionDataGroups_HideOverstockStacks();
			end
			--
			RestockShop_AuctionDataGroups_Sort();
			RestockShopFrame_ScrollFrame_Update();
		end
		RestockShop_ScanComplete();
		return; -- Stop function, queue is empty, scan completed
	end
	-- Remove and query last item in the queue
	NS.query.item = table.remove( NS.query.queue );
	RestockShopFrame_FlyoutPanel_ScrollFrame_Update(); -- Update scanTexture and Highlight query item, also moves vertical scroll
	--
	RestockShop_StartScanning();
	--
	if NS.scanType ~= "SELECT" then
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Scanning"] .. " " .. NS.query.item["name"] .. "..." );
	end
	--
	local itemValue = TSMAPI:GetItemValue( NS.query.item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) or 0;
	--
	if itemValue == 0 then
		-- Skipping: No Item Value
		print( "RestockShop: " .. string.format( L["Skipping %s: %sRequires %s data|r"], NS.query.item["link"], RED_FONT_COLOR_CODE,NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) );
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "NotReady";
		RestockShop_StopScanning();
		RestockShop_ScanAuctionQueue();
	elseif NS.query.item["maxPricePct"]["full"] == 0 and RestockShop_QOH( NS.query.item["tsmItemString"] ) >= NS.query.item["fullStockQty"] then
		-- Skipping: Full Stock reached and no Full price set
		--print( "RestockShop: " .. string.format( L["Skipping %s: %sFull Stock|r reached and no %sFull|r price set"], NS.query.item["link"], NORMAL_FONT_COLOR_CODE, NS.colorCode.full ) );
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "NotReady";
		RestockShop_StopScanning();
		RestockShop_ScanAuctionQueue();
	else
		-- OK: SendAuctionQuery()
		if NS.scanType ~= "SELECT" then
			NS.auction.data.raw[NS.query.item["itemId"]] = {}; -- Select scan only reads, it won't be rewriting the raw data
		end
		RestockShop_SendAuctionQuery();
	end
end

--
function RestockShop_SendAuctionQuery()
	if not NS.scanning then return end
	if CanSendAuctionQuery() and NS.ailu ~= "IGNORE" then
		NS.query.attempts = 1; -- Set to default on successful attempt
		local name = NS.query.item["name"];
		local page = NS.query.page or nil;
		local minLevel,maxLevel,invTypeIndex,classIndex,subClassIndex,isUsable,qualityIndex,getAll;
		SortAuctionClearSort( "list" );
		SortAuctionSetSort( "list", "buyout" );
		SortAuctionSetSort( "list", "quantity" );
		SortAuctionSetSort( "list", "name" ); -- Very unlikely items will be the same "level", "quality" and "name", this will group them together for the least chance of fail on max price exceeded checks
		SortAuctionSetSort( "list", "level" ); -- ^
		SortAuctionSetSort( "list", "quality" ); -- ^
		SortAuctionApplySort( "list" );
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		QueryAuctionItems( name, minLevel, maxLevel, invTypeIndex, classIndex, subClassIndex, page, isUsable, qualityIndex, getAll );
	elseif NS.query.attempts < NS.query.maxAttempts then
		-- Increment attempts, delay and reattempt
		NS.query.attempts = NS.query.attempts + 1;
		RestockShop_TimeDelayFunction( 0.10, RestockShop_SendAuctionQuery );
	else
		-- Aborting scan of this item, return to queue if NOT SELECT
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Could not query Auction House after several attempts, please try again in a few moments"] );
		RestockShop_StopScanning();
		if NS.scanType == "SELECT" then
			RestockShopFrame_ScrollFrame_Auction_Deselect(); -- Select failed, deselect auction and allow user to manually click again
			return; -- Stop function, a failed Select should never be allowed to complete, just deselect or rescan
		end
		RestockShop_ScanAuctionQueue();
	end
end

--
function RestockShop_ScanAuctionPage()
	if not NS.scanning then return end
	if NS.scanType ~= "SELECT" then
		NS.auction.data.raw[NS.query.item["itemId"]][NS.query.page] = {};
		RestockShopFrame_DialogFrame_StatusFrame_Update( string.format( L["Scanning %s: Page %d of %d"], NS.query.item["name"], ( NS.query.page + 1 ), NS.query.totalPages ) );
	end
	local incompleteData = false;
	for i = 1, NS.query.batchAuctions do
		-- name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo
		local name,texture,count,quality,_,_,_,_,_,buyoutPrice,_,_,_,_,ownerFullName,_,itemId,_ = GetAuctionItemInfo( "list", i );
		ownerFullName = ownerFullName or owner or "Unknown"; -- Note: Auction may not have an owner(FullName), the character could have been deleted
		if itemId == NS.query.item["itemId"] and buyoutPrice > 0 then
			local onHandQty = RestockShop_QOH( NS.query.item["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, NS.query.item["fullStockQty"] );
			local itemValue = TSMAPI:GetItemValue( NS.query.item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] );
			local itemPrice = math.ceil( buyoutPrice / count );
			local maxPrice = RestockShop_MaxPrice( itemValue, restockPct, NS.query.item["maxPricePct"] );
			local pctItemValue = ( itemPrice * 100 ) / itemValue;
			local pctMaxPrice = ( itemPrice * 100 ) / maxPrice;
			if ownerFullName ~= GetUnitName( "player" ) then
				-- Matching Auction, record info
				if NS.scanType == "SELECT" then
					-- SELECT match found?
					if not NS.auction.selected.found and NS.auction.selected.auction["name"] == name and NS.auction.selected.auction["count"] == count and NS.auction.selected.auction["itemPrice"] == itemPrice then
						NS.auction.selected.found = true;
						NS.auction.selected.auction["index"] = i;
						NS.auction.selected.auction["buyoutPrice"] = buyoutPrice;
						NS.auction.selected.auction["ownerFullName"] = ownerFullName;
						break; -- Not recording any additional data, just stop loop and continue on below to page scan completion checks
					end
				else
					-- Record raw data if not a SELECT scan
					NS.auction.data.raw[itemId][NS.query.page][i] = {
						["restockPct"] = restockPct,
						["name"] = name,
						["texture"] = texture,
						["count"] = count,
						["quality"] = quality,
						["itemPrice"] = itemPrice,
						["buyoutPrice"] = buyoutPrice,
						["pctItemValue"] = pctItemValue,
						["pctMaxPrice"] = pctMaxPrice,
						["ownerFullName"] = ownerFullName,
						["itemId"] = itemId,
						["itemLink"] = NS.query.item["link"],
						["itemValue"] = itemValue,
						["tsmItemString"] = NS.query.item["tsmItemString"],
						["onHandQty"] = onHandQty,
						["fullStockQty"] = NS.query.item["fullStockQty"],
						["page"] = NS.query.page,
						["index"] = i,
					};
				end
			end
		end
	end
	-- Page scan data incomplete, requery page
	if incompleteData and NS.query.batchAttempts < NS.query.maxBatchAttempts then
		NS.query.batchAttempts = NS.query.batchAttempts + 1;
		RestockShop_TimeDelayFunction( 0.25, RestockShop_SendAuctionQuery ); -- Delay for missing data to be provided
		return; -- Stop function, requery in progress
	end
	-- Page scan complete, query next page unless doing SELECT scan
	if NS.scanType ~= "SELECT" and NS.query.page < ( NS.query.totalPages - 1 ) then -- Subtract 1 because the first page is 0
		NS.query.page = NS.query.page + 1; -- Increment to next page
		NS.query.batchAttempts = 1; -- Reset to default
		RestockShop_SendAuctionQuery(); -- Send query for next page to scan
	else
	-- Item scan completed
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "Ready";
		RestockShop_StopScanning();
		if NS.scanType == "SELECT" and not NS.auction.selected.found then
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item not found, rescanning item"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			RestockShop_RescanItem();
			return; -- Stop function, starting rescan
		end
		RestockShop_ScanAuctionQueue(); -- Return to queue
	end
end

--
function RestockShop_ScanComplete()
	if NS.scanType == "SHOP" then
		-- Shop
		if RestockShop_Count( NS.items ) > 1 then
			NS.query.item = {}; -- Reset to unlock highlight when scanning more than one item
		end
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update(); -- Update scanTexture and Highlight
		--
		if next( NS.auction.data.groups.visible ) then
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
			else
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
			end
			RestockShopFrame_BuyAllButton:Enable();
		else
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["No auctions were found that matched your settings"] );
			end
		end
	elseif NS.scanType == "SELECT" then
		-- Select, this scan type only completes if it found what it was looking for, always. Otherwise it would generate a rescan.
		local auction = NS.auction.selected.auction;
		local _,_,_,hexColor = GetItemQualityColor( auction["quality"] );
		local BuyoutFrameName = "RestockShopFrame_DialogFrame_BuyoutFrame";
		_G[BuyoutFrameName .. "_TextureFrame_Texture"]:SetTexture( auction["texture"] );
		_G[BuyoutFrameName .. "_TextureFrame"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( auction["itemLink"] ); end );
		_G[BuyoutFrameName .. "_TextureFrame"]:SetScript( "OnLeave", GameTooltip_Hide );
		_G[BuyoutFrameName .. "_DescriptionFrame_Text"]:SetText( "|c" .. hexColor .. auction["name"] .. "|r x " .. auction["count"] );
		MoneyFrame_Update( BuyoutFrameName .. "_SmallMoneyFrame", auction["buyoutPrice"] );
		RestockShop_SetCanBid( true );
		RestockShopFrame_DialogFrame_BuyoutFrame_SetActive();
		RestockShopFrame_BuyAllButton:Enable();
	elseif NS.scanType == "RESCAN" then
		-- Rescanned the specific item from the selected group. If the group exists after a rescan, then reselect it.
		NS.auction.selected.groupKey = RestockShop_AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
		if not NS.auction.selected.groupKey then
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item not found after rescan"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			if next( NS.auction.data.groups.visible ) then
				if NS.buyAll then
					RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
				else
					RestockShopFrame_ScrollFrame_Auction_Deselect();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
						RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
					end
					RestockShopFrame_BuyAllButton:Enable();
				end
			else
				RestockShopFrame_ScrollFrame_Auction_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
				end
				RestockShopFrame_BuyAllButton_Reset();
			end
		else
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item was found after rescan"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			RestockShopFrame_ScrollFrame_Entry_OnClick( NS.auction.selected.groupKey );
		end
	end
	--
	RestockShopFrame_ShopButton_Reset();
end

--
function RestockShop_RescanItem()
	NS.auction.data.raw = {};
	NS.query.queue = {};
	table.insert( NS.query.queue, NS.items[NS.query.item["itemId"]] );
	NS.scanType = "RESCAN";
	RestockShop_ScanAuctionQueue();
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_AfterAuctionWon()
	NS.ailu = "IGNORE"; -- Ignore by default, change below where needed.
	-- NextAuction()
	local function NextAuction( groupKey )
		local auction = NS.auction.data.groups.visible[groupKey]["auctions"][#NS.auction.data.groups.visible[groupKey]["auctions"]];
		if NS.auction.selected.auction["itemId"] == auction["itemId"] and NS.auction.selected.auction["page"] == auction["page"] then
			NS.query.page = auction["page"];
			NS.auction.selected.found = false;
			NS.auction.selected.groupKey = groupKey;
			NS.auction.selected.auction = auction; -- Cannot use index, ownerFullName, or buyoutPrice yet, these may change after scanning the page
			if NS.buyAll and groupKey == 1 then
				RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
			end
			RestockShopFrame_ScrollFrame_Update(); -- Highlight the selected group
			RestockShop_StartScanning();
			NS.ailu = "LISTEN";
		else
			RestockShopFrame_ScrollFrame_Entry_OnClick( groupKey ); -- Item wasn't the same or wasn't on the same page, this will send a new QueryAuctionItems()
		end
	end
	-- NoGroupKey()
	local function NoGroupKey()
		if next( NS.auction.data.groups.visible ) then
			-- More auction exist
			if NS.buyAll then
				NextAuction( 1 );
			else
				RestockShopFrame_ScrollFrame_Auction_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
				end
				RestockShopFrame_BuyAllButton:Enable();
			end
		else
			-- No auctions exist
			RestockShopFrame_ScrollFrame_Auction_Deselect();
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
			end
			RestockShopFrame_BuyAllButton_Reset();
		end
	end
	-- Full Stock notice
	if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["onHandQty"] < NS.auction.selected.auction["fullStockQty"] and ( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["onHandQty"] + NS.auction.selected.auction["count"] ) >= NS.auction.selected.auction["fullStockQty"] then
		print( "RestockShop: " .. string.format( L["You reached the %sFull Stock|r of %s%d|r on %s"], NORMAL_FONT_COLOR_CODE, NS.colorCode.full, NS.auction.selected.auction["fullStockQty"], NS.auction.selected.auction["itemLink"] ) );
	end
	--
	RestockShopFrame_ShopButton:Enable();
	--
	NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] = NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] - 1;
	--
	if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] == 0 then
		-- Group removed
		table.remove( NS.auction.data.groups.visible, NS.auction.selected.groupKey );
		RestockShop_AuctionDataGroups_OnHandQtyChanged();
		NS.auction.selected.groupKey = nil;
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
		NoGroupKey();
	else
		-- Single auction removed
		table.remove( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["auctions"] );
		RestockShop_AuctionDataGroups_OnHandQtyChanged();
		NS.auction.selected.groupKey = RestockShop_AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
		if not NS.auction.selected.groupKey then
			NoGroupKey();
		else
			NextAuction( NS.auction.selected.groupKey );
		end
	end
end

--
function RestockShop_AddTooltipData( self, ... )
	if ( not NS.db["itemTooltipShoppingListSettings"] and not NS.db["itemTooltipItemId"] ) or NS.tooltipAdded then return end
	-- Get Item Id
	local itemName, itemLink = self:GetItem();
	local itemId = itemLink and tonumber( string.match( itemLink, "item:(%d+):" ) ) or nil;
	if not itemId then return end
	-- Shopping List Settings
	if NS.db["itemTooltipShoppingListSettings"] then
		local itemKey = RestockShop_FindItemKey( itemId );
		if itemKey then
			-- Item found in current shopping list
			if strtrim( _G[self:GetName() .. "TextLeft" .. self:NumLines()]:GetText() ) ~= "" then
				self:AddLine( " " ); -- Blank line at top
			end
			-- Prepare and format data
			local item = NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey];
			local itemValue = TSMAPI:GetItemValue( item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) or 0;
			local onHandQty = RestockShop_QOH( item["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, item["fullStockQty"] );
			local maxPrice, restock = RestockShop_MaxPrice( itemValue, restockPct, item["maxPricePct"], "returnRestock" );
			maxPrice = ( maxPrice > 0 ) and ( TSMAPI:FormatTextMoney( maxPrice, "|cffffffff", true ) .. " " ) or ""; -- If full stock and no full price then leave it blank
			local restockColor = RestockShop_RestockColor( "code", restockPct, item["maxPricePct"] );
			restockPct = restockColor .. math.floor( restockPct ) .. "%|r";
			restock = restockColor .. L[restock] .. "|r";
			if itemValue ~= 0 then
				itemValue = TSMAPI:FormatTextMoney( itemValue, "|cffffffff", true );
			else
				itemValue, maxPrice = nil, nil;
			end
			local TOOLTIP_COLOR_CODE = TSMAPI.Design:GetInlineColor( "tooltip" ) or "|cff7674d9";
			-- Add lines to tooltip
			self:AddLine( "|cffffff00RestockShop:" );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["List"] .. ":|r |cffffffff" .. NS.db["shoppingLists"][NS.currentListKey]["name"] );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["On Hand"] .. ":|r |cffffffff" .. onHandQty .. "|r " .. TOOLTIP_COLOR_CODE .. "(|r" .. restockPct .. TOOLTIP_COLOR_CODE .. ")|r" );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Full Stock"] .. ":|r |cffffffff" .. item["fullStockQty"] );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Low"] .. ":|r |cffffffff" .. item["maxPricePct"]["low"] .. "%" );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Norm"] .. ":|r |cffffffff" .. item["maxPricePct"]["normal"] .. "%" );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Full"] .. ":|r |cffffffff" .. ( ( item["maxPricePct"]["full"] > 0 ) and ( item["maxPricePct"]["full"] .. "%" ) or "-" ) );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Item Value"] .. ":|r |cffffffff" .. ( itemValue and ( itemValue .. " " .. TOOLTIP_COLOR_CODE .. "(" .. NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] .. ")|r" ) or ( "|cffff2020" .. string.format( L["Requires %s Data"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) .. "|r" ) ) );
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Max Price"] .. ":|r " .. ( maxPrice and ( maxPrice .. TOOLTIP_COLOR_CODE .. "(|r" .. restock .. TOOLTIP_COLOR_CODE .. ")|r"  ) or "|cffff2020" .. L["Requires Item Value"] .. "|r" ) );
			self:AddLine( " " ); -- Blank line at bottom
		end
	end
	-- Item Id
	if NS.db["itemTooltipItemId"] then
		self:AddLine( L["Item ID"] .. " " .. itemId  );
	end
	-- Makes added lines show immediately
	self:Show();
	-- Completed
	NS.tooltipAdded = true;
end

--
function Restockshop_ClearTooltipData()
	NS.tooltipAdded = false;
end

--
function RestockShop_WoWClientBuildChanged()
	-- Forward Declarations
	local listKey, queueList;
	-- Function: updateItem()
	local function updateItem( listKey, itemKey, name, link, quality, maxStack, texture )
		NS.db["shoppingLists"][listKey]["items"][itemKey]["name"] = name or NS.db["shoppingLists"][listKey]["items"][itemKey]["name"];
		NS.db["shoppingLists"][listKey]["items"][itemKey]["link"] = link or NS.db["shoppingLists"][listKey]["items"][itemKey]["link"];
		NS.db["shoppingLists"][listKey]["items"][itemKey]["quality"] = quality or 0;
		NS.db["shoppingLists"][listKey]["items"][itemKey]["maxStack"] = maxStack or NS.db["shoppingLists"][listKey]["items"][itemKey]["maxStack"];
		NS.db["shoppingLists"][listKey]["items"][itemKey]["texture"] = texture or "Interface\\ICONS\\INV_Misc_QuestionMark";
	end
	-- Function: updateList()
	local function updateList()
		for itemKey, item in ipairs( NS.db["shoppingLists"][listKey]["items"] ) do
			local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( item["itemId"] );
			updateItem( listKey, itemKey, name, link, quality, maxStack, texture );
		end
		--
		table.sort ( NS.db["shoppingLists"][listKey]["items"],
			function ( item1, item2 )
				return item1["name"] < item2["name"]; -- Sort by name A-Z
			end
		);
		--
		listKey = listKey + 1;
		RestockShop_TimeDelayFunction( 1, queueList );
	end
	-- Function: queryList()
	local function queryList()
		for itemKey, item in ipairs( NS.db["shoppingLists"][listKey]["items"] ) do
			local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( item["itemId"] );
		end
		--
		local _,_,_,latencyWorld = GetNetStats();
		local delay = math.ceil( #NS.db["shoppingLists"][listKey]["items"] * ( ( latencyWorld > 0 and latencyWorld or 300 ) * 0.10 * 0.001 ) );
		delay = delay > 0 and delay or 1;
		RestockShop_TimeDelayFunction( delay, updateList );
	end
	-- Forward Declared Function: queueList()
	queueList = function()
		if listKey <= #NS.db["shoppingLists"] then
			if NS.db["shoppingLists"][listKey]["name"] then
				queryList();
			else
				listKey = listKey + 1;
				queueList();
			end
		else
			-- Update complete, save new build
			NS.db["wowClientBuild"] = NS.wowClientBuild;
		end
	end
	--
	listKey = 1;
	RestockShop_TimeDelayFunction( 30, queueList ); -- Delay allows time for WoW client to establish latency
end

--
function RestockShop_FindItemKey( itemId, shoppingList )
	shoppingList = shoppingList or NS.currentListKey;
	for k, v in ipairs( NS.db["shoppingLists"][shoppingList]["items"] ) do
		if v["itemId"] == itemId then
			return k;
		end
	end
	return nil;
end

--
function RestockShop_SetCanBid( enable )
	if enable then
		RestockShopFrame_DialogFrame_BuyoutFrame_AcceptButton:Enable();
		RestockShopFrame_DialogFrame_BuyoutFrame_CancelButton:Enable();
	else
		RestockShopFrame_DialogFrame_BuyoutFrame_AcceptButton:Disable();
		RestockShopFrame_DialogFrame_BuyoutFrame_CancelButton:Disable();
	end
	NS.canBid = enable;
end

--
function RestockShop_TSMItemString( itemLink )
	local itemString = string.match( itemLink, "item[%-?%d:]+" );
	local s1,s2,s3,s4,s5,s6,s7,s8 = strsplit( ":", itemString );
	return s1 .. ":" .. s2 .. ":" .. s3 .. ":" .. s4 .. ":" .. s5 .. ":" .. s6 .. ":" .. s7 .. ":" .. s8;
end

--
function RestockShop_QOH( tsmItemString )
	local qoh = 0;
	local currentPlayerTotal, otherPlayersTotal = TSMAPI:ModuleAPI( "ItemTracker", "playertotal", tsmItemString ); -- Bags, Bank, and Mail
	if NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 1 then
		-- All Characters
		qoh = qoh + currentPlayerTotal + otherPlayersTotal;
		local auctionsTotal = TSMAPI:ModuleAPI( "ItemTracker", "auctionstotal", tsmItemString ); -- Auction Listings
		qoh = qoh + ( auctionsTotal or 0 );
		if NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] then
			local guildTotal = TSMAPI:ModuleAPI( "ItemTracker", "guildtotal", tsmItemString ); -- Guild Bank
			qoh = qoh + ( guildTotal or 0 );
		end
	elseif NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 2 then
		-- Current Character
		qoh = qoh + currentPlayerTotal;
		local playerAuctions = TSMAPI:ModuleAPI( "ItemTracker", "playerauctions", GetUnitName( "player" ) ); -- Auction Listings
		qoh = qoh + ( playerAuctions[tsmItemString] or 0 );
		if NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] then
			local guild,_,_ = GetGuildInfo( "player" );
			local guildBank = ( guild and TSMAPI:ModuleAPI( "ItemTracker", "guildbank", guild ) ) or nil; -- Guild Bank
			qoh = qoh + ( ( guildBank and guildBank[tsmItemString] ) or 0 );
		end
	end
	return qoh;
end

--
function RestockShop_RestockPct( onHandQty, fullStockQty )
	return ( onHandQty * 100 ) / fullStockQty;
end

--
function RestockShop_MaxPrice( itemValue, restockPct, maxPricePct, returnRestock )
	local maxPrice = nil;
	if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
		maxPrice = math.ceil( ( itemValue * maxPricePct["low"] ) / 100 );
		restock = "Low"; -- Do not translate here
	elseif restockPct < 100 then
		maxPrice = math.ceil( ( itemValue * maxPricePct["normal"] ) / 100 );
		restock = "Norm"; -- Do not translate here
	else
		maxPrice = math.ceil( ( itemValue * maxPricePct["full"] ) / 100 );
		restock = "Full"; -- Do not translate here
	end
	--
	if returnRestock then
		return unpack( { maxPrice, restock } );
	else
		return maxPrice;
	end
end

--
function RestockShop_RestockColor( colorType, restockPct, maxPricePct )
	if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
		return colorType == "code" and NS.colorCode.low or NS.fontColor.low; -- Orange
	elseif restockPct < 100 then
		return colorType == "code" and NS.colorCode.norm or NS.fontColor.norm; -- Yellow
	elseif restockPct >= 100 and ( not maxPricePct or maxPricePct["full"] ~= 0 ) then
		return colorType == "code" and NS.colorCode.full or NS.fontColor.full; -- Green
	else
		return colorType == "code" and NS.colorCode.maxFull or NS.fontColor.maxFull; -- Gray
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_SlashCmdHandler( msg )
	if msg == "acceptbuttonclick" then
		if not NS.canBid then return end
		RestockShopFrame_DialogFrame_BuyoutFrame_AcceptButton:Click();
		return;
	end
	--
	if RestockShopFrame:IsShown() then
		AuctionFrameTab1:Click();
	end
	--
	if msg == "" or msg == "sl" or msg == "shoppinglists" then
		NS.options.MainFrame:ShowTab( 1 );
	elseif msg == "moreoptions" then
		NS.options.MainFrame:ShowTab( 2 );
	elseif msg == "help" then
		NS.options.MainFrame:ShowTab( 3 );
	else
		NS.options.MainFrame:ShowTab( 3 );
		print( "RestockShop: " .. L["Unknown command, opening Help"] );
	end
end
--
SLASH_RESTOCKSHOP1 = "/restockshop";
SLASH_RESTOCKSHOP2 = "/rs";
SlashCmdList["RESTOCKSHOP"] = RestockShop_SlashCmdHandler;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Create Frames
--------------------------------------------------------------------------------------------------------------------------------------------
local f, fs, tx, overlay = nil, nil, nil, nil;
local backdrop1 = { ["bgFile"] = "Interface\\DialogFrame\\UI-DialogBox-Background", ["tile"] = true, ["tileSize"] = 64, ["insets"] = { ["left"] = 5, ["right"] = 5, ["top"] = 5, ["bottom"] = 5 } };
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopInterfaceOptionsPanel
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopInterfaceOptionsPanel", UIParent );
f:Hide();
function f:Init()
	self.name = NS.title;
	self.okay = function() end;
	self.cancel = function() end;
	InterfaceOptions_AddCategory( self );
end
-- RestockShopInterfaceOptionsPanel > Title
fs = f:CreateFontString( "$parentTitle", "ARTWORK", "GameFontNormal" );
fs:SetText( L["Options for RestockShop can be opened from the Auction House on the RestockShop tab.\n\nYou can also use either slash command /rs or /restockshop"] );
fs:SetJustifyH( "LEFT" );
fs:SetJustifyV( "TOP" );
fs:SetPoint( "TOPLEFT", 16, -16 );
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopFrame
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopFrame", UIParent );
f:Hide();
--f:SetSize( 758, 447 ); 66 x removed from close button
f:SetSize( 824, 447 );
f:SetScript( "OnShow", function ( self )
	NS.options.MainFrame:Hide();
	FauxScrollFrame_SetOffset( RestockShopFrame_ScrollFrame, 0 );
	RestockShopFrame_Reset();
end );
f:SetScript( "OnHide", RestockShopFrame_Reset );
-- RestockShopFrame > Title
fs = f:CreateFontString( "$parent_Title", "BACKGROUND", "GameFontNormal" );
fs:SetText( "" );
fs:SetPoint( "TOP", 25, -18 );
-- RestockShopFrame > OnHandSortButton
f = CreateFrame( "Button", "$parent_OnHandSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["On Hand"] );
f:SetSize( 82, 19 );
f:SetPoint( "TOPLEFT", 65, -52 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "onHandQty" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 82 - 28 ), 19 );
-- RestockShopFrame > RestockSortButton
f = CreateFrame( "Button", "$parent_RestockSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["Restock %"] );
f:SetSize( 82, 19 );
f:SetPoint( "LEFT", "$parent_OnHandSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "restockPct" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 82 - 28 ), 19 );
-- RestockShopFrame > NameSortButton
f = CreateFrame( "Button", "$parent_NameSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( NAME );
f:SetSize( 220, 19 );
f:SetPoint( "LEFT", "$parent_RestockSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "name" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 220 - 28 ), 19 );
-- RestockShopFrame > StackSizeSortButton
f = CreateFrame( "Button", "$parent_StackSizeSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["Stack Size"] );
f:SetSize( 110, 19 );
f:SetPoint( "LEFT", "$parent_NameSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "count" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 110 - 28 ), 19 );
-- RestockShopFrame > ItemPriceSortButton
f = CreateFrame( "Button", "$parent_ItemPriceSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["Item Price"] );
f:SetSize( 150, 19 );
f:SetPoint( "LEFT", "$parent_StackSizeSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "itemPrice" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 150 - 28 ), 19 );
-- RestockShopFrame > pctItemValueSortButton
f = CreateFrame( "Button", "$parent_PctItemValueSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["% Item Value"] );
f:SetSize( 101, 19 );
f:SetPoint( "LEFT", "$parent_ItemPriceSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "pctItemValue" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 101 - 28 ), 19 );
-- RestockShopFrame > ScrollFrame
f = CreateFrame( "ScrollFrame", "$parent_ScrollFrame", RestockShopFrame, "FauxScrollFrameTemplate" );
f:SetSize( 733, 276 );
f:SetPoint( "TOPLEFT", "$parent_OnHandSortButton", "BOTTOMLEFT", 0, -6 );
f:SetScript( "OnVerticalScroll", function ( self, offset )
	FauxScrollFrame_OnVerticalScroll( self, offset, 16, RestockShopFrame_ScrollFrame_Update );
end );
f:SetScript( "OnShow", RestockShopFrame_ScrollFrame_Update );
tx = f:CreateTexture( nil, "ARTWORK" );
tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
tx:SetSize( 31, 250 );
tx:SetPoint( "TOPLEFT", "$parent", "TOPRIGHT", -2, 5 );
tx:SetTexCoord( 0, 0.484375, 0, 1.0 );
tx = f:CreateTexture( nil, "ARTWORK" );
tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
tx:SetSize( 31, 100 );
tx:SetPoint( "BOTTOMLEFT", "$parent", "BOTTOMRIGHT", -2, -2 );
tx:SetTexCoord( 0.515625, 1.0, 0, 0.4140625 );
-- RestockShopFrame > ScrollFrame_Entry(i) x 15
f = CreateFrame( "Button", "$parent_ScrollFrame_Entry1", RestockShopFrame, "RestockShopFrame_ScrollFrame_EntryTemplate" );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT", 1, 3 );
for i = 2, 15 do
	f = CreateFrame( "Button", ( "$parent_ScrollFrame_Entry" .. i ), RestockShopFrame, "RestockShopFrame_ScrollFrame_EntryTemplate" );
	f:SetPoint( "TOPLEFT", ( "$parent_ScrollFrame_Entry" .. ( i - 1 ) ), "BOTTOMLEFT", 0, -3 );
end
-- RestockShopFrame > ListStatusFrame
f = CreateFrame( "Frame", "$parent_ListStatusFrame", RestockShopFrame );
f:SetSize( 733, ( 334 - 22 ) );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT", 0, 0 );
f:Hide();
fs = f:CreateFontString( "$parent_Text", "BACKGROUND", "GameFontHighlightLarge" );
fs:SetText( "" );
fs:SetPoint( "CENTER" );
-- RestockShopFrame > DialogFrame
f = CreateFrame( "Frame", "$parent_DialogFrame", RestockShopFrame );
f:SetSize( 733, 58 );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "BOTTOMLEFT", 0, 0 );
-- RestockShopFrame > DialogFrame > BuyoutFrame
f = CreateFrame( "Frame", "$parent_BuyoutFrame", RestockShopFrame_DialogFrame );
f:Hide();
f:SetAllPoints();
-- RestockShopFrame > DialogFrame > BuyoutFrame > CancelButton
f = CreateFrame( "Button", "$parent_CancelButton", RestockShopFrame_DialogFrame_BuyoutFrame, "UIPanelButtonTemplate" );
f:SetText( CANCEL );
f:SetSize( 120, 30 );
f:SetPoint( "RIGHT" );
f:SetScript( "OnClick", function ( self )
	if NS.buyAll then
		RestockShopFrame_BuyAllButton:Click();
	else
		RestockShopFrame_ScrollFrame_Auction_Deselect();
		if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
		else
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
		end
	end
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 120 - 16 ), 30 );
-- RestockShopFrame > DialogFrame > BuyoutFrame > AcceptButton
f = CreateFrame( "Button", "$parent_AcceptButton", RestockShopFrame_DialogFrame_BuyoutFrame, "UIPanelButtonTemplate" );
f:SetText( ACCEPT );
f:SetSize( 120, 30 );
f:SetPoint( "RIGHT", "$parent_CancelButton", "LEFT", -10, 0 );
f:SetScript( "OnClick", function ( self )
	if NS.canBid then
		RestockShop_SetCanBid( false );
		RestockShopFrame_ShopButton:Disable();
		RestockShopFrame_BuyAllButton:Disable();
		RestockShopEventsFrame:RegisterEvent( "CHAT_MSG_SYSTEM" );
		RestockShopEventsFrame:RegisterEvent( "UI_ERROR_MESSAGE" );
		PlaceAuctionBid( "list", NS.auction.selected.auction["index"], NS.auction.selected.auction["buyoutPrice"] );
	end
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 120 - 16 ), 30 );
-- RestockShopFrame > DialogFrame > BuyoutFrame > SmallMoneyFrame
f = CreateFrame( "Frame", "$parent_SmallMoneyFrame", RestockShopFrame_DialogFrame_BuyoutFrame, "SmallMoneyFrameTemplate" );
f:SetSize( 137, 16 );
f:SetPoint( "RIGHT", "$parent_AcceptButton", "LEFT" );
SmallMoneyFrame_OnLoad( f );
MoneyFrame_SetType( f, "AUCTION" );
-- RestockShopFrame > DialogFrame > BuyoutFrame > TextureFrame
f = CreateFrame( "Frame", "$parent_TextureFrame", RestockShopFrame_DialogFrame_BuyoutFrame );
f:SetSize( 30, 30 );
f:SetPoint( "LEFT" );
tx = f:CreateTexture( "$parent_Texture", "ARTWORK" );
tx:SetAllPoints();
-- RestockShopFrame > DialogFrame > BuyoutFrame > DescriptionFrame
f = CreateFrame( "Frame", "$parent_DescriptionFrame", RestockShopFrame_DialogFrame_BuyoutFrame );
f:SetSize( 200, 30 );
f:SetPoint( "LEFT", "$parent_TextureFrame", "RIGHT", 10, 0 );
fs = f:CreateFontString( "$parent_Text", "BACKGROUND", "GameFontNormal" );
fs:SetText( "" );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
fs:SetPoint( "LEFT" );
-- RestockShopFrame > DialogFrame > StatusFrame
f = CreateFrame( "Frame", "$parent_StatusFrame", RestockShopFrame_DialogFrame );
f:SetAllPoints();
fs = f:CreateFontString( "$parent_Text", "BACKGROUND", "GameFontNormal" );
fs:SetText( "" );
fs:SetPoint( "CENTER" );
-- RestockShopFrame > CloseButton
f = CreateFrame( "Button", "$parent_CloseButton", RestockShopFrame, "UIPanelButtonTemplate" );
f:SetText( CLOSE );
f:SetSize( 80, 22 );
f:SetPoint( "BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", 0, 14 );
f:SetScript( "OnClick", function() AuctionFrame_Hide() end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 80 - 16 ), 22 );
-- RestockShopFrame > BuyAllButton
f = CreateFrame( "Button", "$parent_BuyAllButton", RestockShopFrame, "UIPanelButtonTemplate" );
f:SetText( L["Buy All"] );
f:SetSize( 80, 22 );
f:SetPoint( "RIGHT", "$parent_CloseButton", "LEFT", 0, 0 );
f:SetScript( "OnClick", function ( self )
	if NS.buyAll then
		NS.buyAll = false;
		self:SetText( L["Buy All"] );
		if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
		else
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
		end
		RestockShopFrame_ScrollFrame_Auction_Deselect();
	else
		NS.buyAll = true;
		self:SetText( L["Stop"] );
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Scanning"] .. "..." );
		RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
	end
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 80 - 16 ), 22 );
-- RestockShopFrame > ShopButton
f = CreateFrame( "Button", "$parent_ShopButton", RestockShopFrame, "UIPanelButtonTemplate" );
f:SetText( L["Shop"] );
f:SetSize( 80, 22 );
f:SetPoint( "RIGHT", "$parent_BuyAllButton", "LEFT", 0, 0 );
f:SetScript( "OnClick", function ( self )
	if NS.scanning then
		RestockShopFrame_Reset();
	else
		NS.items = {};
		NS.query.queue= {};
		NS.auction.data.raw = {};
		NS.auction.data.groups.visible = {};
		NS.auction.data.groups.overstock = {};
		RestockShopFrame_ScrollFrame_Auction_Deselect();
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_ListStatusFrame:Hide();
		RestockShopFrame_BuyAllButton_Reset();
		RestockShopFrame_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 );
		for k, v in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
			table.insert( NS.query.queue, v );
			NS.items[v["itemId"]] = v;
			NS.items[v["itemId"]]["scanTexture"] = "Waiting";
		end
		table.sort ( NS.query.queue, function ( item1, item2 )
			return item1["name"] > item2["name"]; -- Sort by name Z-A because items are pulled from the end of the queue which will become A-Z
		end	);
		NS.scanType = "SHOP";
		RestockShop_ScanAuctionQueue();
	end
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 80 - 16 ), 22 );
-- RestockShopFrame > ShoppingListsDropDownMenu
f = CreateFrame( "Frame", "$parent_ShoppingListsDropDownMenu", RestockShopFrame, "UIDropDownMenuTemplate" );
f:SetPoint( "RIGHT", "$parent_ShopButton", "LEFT", 15, -2 );
-- RestockShopFrame > ShoppingListsButton
f = CreateFrame( "Button", "$parent_ShoppingListsButton", RestockShopFrame, "UIPanelButtonTemplate" );
f:SetText( L["Shopping Lists"] );
f:SetSize( 192, 22 );
f:SetPoint( "RIGHT", "$parent_ShopButton", "LEFT", -212, 0 );
f:SetScript( "OnClick", function ( self )
	if RestockShopFrame:IsShown() then
		AuctionFrameTab1:Click();
	end
	NS.options.MainFrame:ShowTab( 1 );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 135 - 16 ), 22 );
-- RestockShopFrame > FlyoutPanel
f = CreateFrame( "Frame", "$parent_FlyoutPanel", RestockShopFrame, "BasicFrameTemplate" );
f:SetSize( 227, 376 ); -- 255 with scrollbar, 227 without scrollbar
f:SetPoint( "LEFT", "$parent", "RIGHT", 8, 0 );
f.Bg:SetTexture( "Interface\\FrameGeneral\\UI-Background-Marble", true );
f.TitleText:SetPoint( "LEFT", 4, 0 );
f.TitleText:SetPoint( "RIGHT", -28, 0 );
f.CloseButton:SetScript( "OnClick", function( self )
	_G[self:GetParent():GetParent():GetName() .. "_FlyoutPanelButton"]:Click();
end );
-- RestockShopFrame_FlyoutPanel > Footer
fs = f:CreateFontString( "$parent_Footer", "BACKGROUND", "GameFontNormal" );
fs:SetText( "" );
fs:SetPoint( "BOTTOM", 0, 8 );
-- RestockShopFrame > FlyoutPanelButton
f = CreateFrame( "Button", "$parent_FlyoutPanelButton", RestockShopFrame );
f:SetSize( 28, 28 );
f:SetPoint( "TOPRIGHT", "$parent_FlyoutPanel", "TOPLEFT", -4, 2 );
f:SetScript( "OnClick", function ( self )
	local flyoutPanel = _G[self:GetParent():GetName() .. "_FlyoutPanel"];
	if flyoutPanel:IsShown() then
		flyoutPanel:Hide();
		NS.db["flyoutPanelOpen"] = false;
		self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" );
		self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down" );
	else
		flyoutPanel:Show();
		NS.db["flyoutPanelOpen"] = true;
		self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
		self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
	end
end );
f:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
f:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
f:SetHighlightTexture( "Interface\\Buttons\\UI-Common-MouseHilight", "ADD" );
-- RestockShopFrame_FlyoutPanel > ScrollFrame
f = CreateFrame( "ScrollFrame", "$parent_ScrollFrame", RestockShopFrame_FlyoutPanel, "FauxScrollFrameTemplate" );
f:SetSize( 220, 315 );
f:SetPoint( "TOPLEFT", "$parent", "TOPLEFT", 2, -30 );
f:SetScript( "OnVerticalScroll", function ( self, offset )
	FauxScrollFrame_OnVerticalScroll( self, offset, 16, RestockShopFrame_FlyoutPanel_ScrollFrame_Update );
end );
f:SetScript( "OnShow", RestockShopFrame_FlyoutPanel_ScrollFrame_Update );
tx = f:CreateTexture( nil, "ARTWORK" );
tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
tx:SetSize( 31, 250 );
tx:SetPoint( "TOPLEFT", "$parent", "TOPRIGHT", -2, 5 );
tx:SetTexCoord( 0, 0.484375, 0, 1.0 );
tx = f:CreateTexture( nil, "ARTWORK" );
tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
tx:SetSize( 31, 100 );
tx:SetPoint( "BOTTOMLEFT", "$parent", "BOTTOMRIGHT", -2, -2 );
tx:SetTexCoord( 0.515625, 1.0, 0, 0.4140625 );
-- RestockShopFrame_FlyoutPanel > ScrollFrame_Entry(i) x 17
f = CreateFrame( "Button", "$parent_ScrollFrame_Entry1", RestockShopFrame_FlyoutPanel, "RestockShopFrame_FlyoutPanel_ScrollFrame_EntryTemplate" );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT", 1, 3 );
for i = 2, 17 do
	f = CreateFrame( "Button", ( "$parent_ScrollFrame_Entry" .. i ), RestockShopFrame_FlyoutPanel, "RestockShopFrame_FlyoutPanel_ScrollFrame_EntryTemplate" );
	f:SetPoint( "TOPLEFT", ( "$parent_ScrollFrame_Entry" .. ( i - 1 ) ), "BOTTOMLEFT", 0, -3 );
end
-- RestockShopFrame > HideOverpricedStacksButton
f = CreateFrame( "Button", "$parent_HideOverpricedStacksButton", RestockShopFrame );
f:SetSize( 32, 32 );
f:SetPoint( "TOPRIGHT", "$parent_OnHandSortButton", "BOTTOMLEFT", -6, -7 );
f:SetNormalTexture( "Interface\\FriendsFrame\\UI-FriendsList-Large-Up" );
f:SetPushedTexture( "Interface\\FriendsFrame\\UI-FriendsList-Large-Down" );
f:SetHighlightTexture( "Interface\\FriendsFrame\\UI-FriendsList-Highlight", "ADD" );
f:SetScript( "OnClick", function ( self )
	if NS.scanning then
		print( "RestockShop: " .. L["Selection ignored, busy scanning"] );
		return; -- Stop function
	end
	--
	RestockShopFrame_DialogFrame_BuyoutFrame_CancelButton:Click();
	--
	RestockShop_AuctionDataGroups_ShowOverpricedStacks();
	RestockShop_AuctionDataGroups_ShowOverstockStacks();
	--
	if NS.db["hideOverpricedStacks"] then
		-- Show
		RestockShop_AuctionDataGroups_Sort();
		NS.db["hideOverpricedStacks"] = false;
		self:UnlockHighlight();
	else
		-- Hide
		RestockShop_AuctionDataGroups_HideOverpricedStacks();
		NS.db["hideOverpricedStacks"] = true;
		self:LockHighlight();
	end
	--
	if NS.db["hideOverstockStacks"] then
		RestockShop_AuctionDataGroups_HideOverstockStacks();
	end
	--
	if next( NS.auction.data.groups.visible ) then
		-- Auctions shown
		if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
		else
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
		end
		RestockShopFrame_BuyAllButton:Enable();
	elseif next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
		-- Auctions hidden
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
		RestockShopFrame_BuyAllButton:Disable();
	elseif next( NS.items ) then
		-- Auctions scanned, but none available
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
		RestockShopFrame_BuyAllButton:Disable();
	end
	RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 );
	RestockShopFrame_ScrollFrame_Update();
end );
f:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_BOTTOMRIGHT" );
	GameTooltip:SetText( string.format( L["%sHide Overpriced Stacks|r\n\nHides auctions whose %% Item Value exceeds\nthe current max price: %sLow|r, %sNorm|r, or %sFull|r %%"], RED_FONT_COLOR_CODE, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full ) );
end );
f:SetScript( "OnLeave", GameTooltip_Hide );
-- RestockShopFrame > HideOverstockStacksButton
f = CreateFrame( "Button", "$parent_HideOverstockStacksButton", RestockShopFrame );
f:SetSize( 32, 32 );
f:SetPoint( "TOP", "$parent_HideOverpricedStacksButton", "BOTTOM", 0, -3 );
f:SetNormalTexture( "Interface\\FriendsFrame\\UI-FriendsList-Large-Up" );
f:SetPushedTexture( "Interface\\FriendsFrame\\UI-FriendsList-Large-Down" );
f:SetHighlightTexture( "Interface\\FriendsFrame\\UI-FriendsList-Highlight", "ADD" );
f:SetScript( "OnClick", function ( self )
	if NS.scanning then
		print( "RestockShop: " .. L["Selection ignored, busy scanning"] );
		return; -- Stop function
	end
	--
	RestockShopFrame_DialogFrame_BuyoutFrame_CancelButton:Click();
	--
	RestockShop_AuctionDataGroups_ShowOverpricedStacks();
	RestockShop_AuctionDataGroups_ShowOverstockStacks();
	--
	if NS.db["hideOverstockStacks"] then
		-- Show
		RestockShop_AuctionDataGroups_Sort();
		NS.db["hideOverstockStacks"] = false;
		self:UnlockHighlight();
	else
		-- Hide
		RestockShop_AuctionDataGroups_HideOverstockStacks();
		NS.db["hideOverstockStacks"] = true;
		self:LockHighlight();
	end
	--
	if NS.db["hideOverpricedStacks"] then
		RestockShop_AuctionDataGroups_HideOverpricedStacks();
	end
	--
	if next( NS.auction.data.groups.visible ) then
		-- Auctions shown
		if next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.overpriced ) then
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
		else
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
		end
		RestockShopFrame_BuyAllButton:Enable();
	elseif next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.overpriced ) then
		-- Auctions hidden
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
		RestockShopFrame_BuyAllButton:Disable();
	elseif next( NS.items ) then
		-- Auctions scanned, but none available
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
		RestockShopFrame_BuyAllButton:Disable();
	end
	RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 );
	RestockShopFrame_ScrollFrame_Update();
end );
f:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_BOTTOMRIGHT" );
	GameTooltip:SetText( string.format( L["%sHide Overstock Stacks|r\n\nHides auctions that when purchased would cause you\nto exceed your \"Full Stock\" by more than %s%s%%|r"], NS.colorCode.full, NS.colorCode.full, NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] ) );
end );
f:SetScript( "OnLeave", GameTooltip_Hide );
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopEventsFrame
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopEventsFrame", UIParent );
f:Hide();
f:SetScript( "OnEvent", function ( self, event, ... )
	if			event == "ADDON_LOADED"				then	RestockShop_OnAddonLoaded();
		elseif	event == "PLAYER_LOGIN"				then	RestockShop_OnPlayerLogin();
		elseif	event == "AUCTION_ITEM_LIST_UPDATE"	then	RestockShop_OnAuctionItemListUpdate();
		elseif	event == "CHAT_MSG_SYSTEM"			then	RestockShop_OnChatMsgSystem( ... );
		elseif	event == "UI_ERROR_MESSAGE"			then	RestockShop_OnUIErrorMessage( ... );
	end
end );
f:RegisterEvent( "ADDON_LOADED" );
f:RegisterEvent( "PLAYER_LOGIN" );
