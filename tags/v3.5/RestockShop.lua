--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
NS.addon = ...;
NS.title = GetAddOnMetadata( NS.addon, "Title" );
NS.stringVersion = GetAddOnMetadata( NS.addon, "Version" );
NS.version = tonumber( NS.stringVersion );
NS.initialized = false;
NS.wowClientBuild = select( 2, GetBuildInfo() );
NS.currentListKey = nil;
NS.AuctionFrameTab = nil;
NS.tooltipAdded = false;
NS.items = {};
NS.editItemId = nil;
NS.disableFlyoutChecks = false;
NS.scanning = false;
NS.scanType = nil;
NS.buyAll = false;
NS.canBid = false;
NS.buying = false;
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
NS.Print = function( msg )
	print( NS.colorCode.low .. "<|r" .. NORMAL_FONT_COLOR_CODE .. NS.addon .. "|r" .. NS.colorCode.low .. ">|r " .. msg );
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
		NS.Print( string.format( L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"], RED_FONT_COLOR_CODE, table.concat( optAddons, ", " ) ) );
		return -- Stop executing file
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Default SavedVariables/PerCharacter & Upgrade
--------------------------------------------------------------------------------------------------------------------------------------------
NS.DefaultSavedVariables = function()
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
NS.DefaultSavedVariablesPerCharacter = function()
	return {
		["version"] = NS.version,
		["currentListName"] = L["Restock Shopping List"],
	};
end

--
NS.Upgrade = function()
	local vars = NS.DefaultSavedVariables();
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
	-- 3.5
	if version < 3.5 then
		for listKey, list in ipairs( NS.db["shoppingLists"] ) do
			for itemKey, item in ipairs( NS.db["shoppingLists"][listKey]["items"] ) do
				NS.db["shoppingLists"][listKey]["items"][itemKey]["checked"] = true;
			end
		end
	end
	--
	NS.Print( string.format( L["Upgraded version %s to %s"], version, NS.version ) );
	NS.db["version"] = NS.version;
end

--
NS.UpgradePerCharacter = function()
	local varspercharacter = NS.DefaultSavedVariablesPerCharacter();
	local version = NS.dbpc["version"];
	--
	-- Not currently used, but will be going forward, SVPC version was introduced in 2.0 requiring SVPC to be overwritten with defaults because version will be nil
	--
	NS.dbpc["version"] = NS.version;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------------------------------------------------------------------
NS.OnAddonLoaded = function() -- ADDON_LOADED
	if IsAddOnLoaded( NS.addon ) then
		if not NS.initialized then
			-- Set Default SavedVariables
			if not RESTOCKSHOP_SAVEDVARIABLES then
				RESTOCKSHOP_SAVEDVARIABLES = NS.DefaultSavedVariables();
			end
			-- Set Default SavedVariablesPerCharacter
			if not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER or not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"] then
				RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER = NS.DefaultSavedVariablesPerCharacter();
			end
			-- Localize SavedVariables
			NS.db = RESTOCKSHOP_SAVEDVARIABLES;
			NS.dbpc = RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER;
			-- Upgrade if old version
			if NS.db["version"] < NS.version then
				NS.Upgrade();
			end
			-- Upgrade Per Character if old version
			if NS.dbpc["version"] < NS.version then
				NS.UpgradePerCharacter();
			end
			-- WoW client build changed, requery all lists for possible item changes
			if NS.db["wowClientBuild"] ~= NS.wowClientBuild then
				NS.WoWClientBuildChanged();
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
			ItemRefTooltip:HookScript( "OnTooltipSetItem", NS.AddTooltipData );
			GameTooltip:HookScript( "OnTooltipSetItem", NS.AddTooltipData );
			ItemRefTooltip:HookScript( "OnTooltipCleared", NS.ClearTooltipData );
			GameTooltip:HookScript( "OnTooltipCleared", NS.ClearTooltipData );
			--
			NS.initialized = true;
		elseif IsAddOnLoaded( "Blizzard_AuctionUI" ) then
			RestockShopEventsFrame:UnregisterEvent( "ADDON_LOADED" );
			NS.Blizzard_AuctionUI_OnLoad();
		end
	end
end

--
NS.OnPlayerLogin = function() -- PLAYER_LOGIN
	RestockShopEventsFrame:UnregisterEvent( "PLAYER_LOGIN" );
	InterfaceOptions_AddCategory( RestockShopInterfaceOptionsPanel );
end

--
NS.OnAuctionItemListUpdate = function() -- AUCTION_ITEM_LIST_UPDATE
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	if NS.ailu == "AUCTION_WON" then NS.AfterAuctionWon(); end
	if NS.ailu == "IGNORE" then NS.ailu = "LISTEN"; return end
	if not NS.scanning then return end
	NS.query.batchAuctions, NS.query.totalAuctions = GetNumAuctionItems( "list" );
	NS.query.totalPages = ceil( NS.query.totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE );
	NS.ScanAuctionPage();
end

--
NS.OnChatMsgSystem = function( ... ) -- CHAT_MSG_SYSTEM
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
NS.OnUIErrorMessage = function( ... ) -- UI_ERROR_MESSAGE
	local arg1 = select( 1, ... );
	if not arg1 or (
	arg1 ~= ERR_ITEM_NOT_FOUND and
	arg1 ~= ERR_AUCTION_HIGHER_BID and
	arg1 ~= ERR_AUCTION_BID_OWN and
	arg1 ~= ERR_NOT_ENOUGH_MONEY and
	arg1 ~= ERR_ITEM_MAX_COUNT
	) then
		return;
	end
	--
	RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
	--
	if arg1 == ERR_ITEM_NOT_FOUND or arg1 == ERR_AUCTION_HIGHER_BID or arg1 == ERR_AUCTION_BID_OWN then
		if arg1 == ERR_ITEM_NOT_FOUND or arg1 == ERR_AUCTION_HIGHER_BID then
			NS.Print( RED_FONT_COLOR_CODE .. L["That auction is no longer available"] .. "|r" );
		elseif arg1 == ERR_AUCTION_BID_OWN then
			NS.Print( RED_FONT_COLOR_CODE .. L["That auction belongs to a character on your account"] .. "|r" );
		end
		--
		NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] = NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] - 1;
		--
		if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] == 0 then
			-- Group removed
			table.remove( NS.auction.data.groups.visible, NS.auction.selected.groupKey );
			NS.Auction_Deselect();
			if next( NS.auction.data.groups.visible ) then
				-- More auctions exist
				if NS.buyAll then
					NS.AuctionGroup_OnClick( 1 );
				else
					AuctionFrameRestockShop_ScrollFrame:Update();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
						NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
					end
					AuctionFrameRestockShop_BuyAllButton:Enable();
				end
			else
				-- No auctions exist
				AuctionFrameRestockShop_ScrollFrame:Update();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				end
				NS.BuyAllButton_Reset();
			end
		else
			-- Single auction removed
			table.remove( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["auctions"] );
			NS.AuctionGroup_OnClick( NS.auction.selected.groupKey );
		end
	elseif arg1 == ERR_NOT_ENOUGH_MONEY then -- Not Enough Money
		NS.StatusFrame_Message( L["You don't have enough money to buy that auction"] );
		AuctionFrameRestockShop_BuyAllButton:Enable();
	elseif arg1 == ERR_ITEM_MAX_COUNT then -- Item Max Count
		NS.StatusFrame_Message( L["You can't carry anymore of that item"] );
		AuctionFrameRestockShop_BuyAllButton:Enable();
	end
	--
	NS.buying = false;
	AuctionFrameRestockShop_ShopButton:Enable();
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- AuctionFrame Tab
--------------------------------------------------------------------------------------------------------------------------------------------
NS.AuctionFrameTab_OnClick = function( self, button, down, index ) -- AuctionFrameTab_OnClick
	if NS.AuctionFrameTab:GetID() == self:GetID() then
		AuctionFrameTopLeft:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft" );
		AuctionFrameTop:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top" );
		AuctionFrameTopRight:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight" );
		AuctionFrameBotLeft:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft" );
		AuctionFrameBot:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot" );
		AuctionFrameBotRight:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight" );
		AuctionFrameRestockShop:Show();
	else
		AuctionFrameRestockShop:Hide();
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- AuctionFrameRestockShop
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Reset = function( flyoutPanelItem_Clicked )
	RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
	local dm, rsfn = nil, AuctionFrameRestockShop:GetName();
	--
	AuctionFrameRestockShop_TitleText:SetText(
		NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ..
		"     /     " .. ( NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 1 and L["All Characters"] or L["Current Character"] ) .. " (" .. ( NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] == true and  L["including Guilds"] or L["not including Guilds"] ) .. ")" ..
		"     /     " .. NS.colorCode.low .. NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] .. "%|r" ..
		"     /     " .. NS.colorCode.full .. NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] .. "%|r"
	);
	--
	if NS.db["hideOverpricedStacks"] then
		AuctionFrameRestockShop_HideOverpricedStacksButton:LockHighlight();
	end
	if NS.db["hideOverstockStacks"] then
		AuctionFrameRestockShop_HideOverstockStacksButton:LockHighlight();
	end
	--
	NS.ScanStop();
	NS.buying = false;
	NS.Auction_Deselect();
	NS.StatusFrame_Message( L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] );
	--
	dm = _G[rsfn .. "_ShoppingListsDropDownMenu"];
	UIDropDownMenu_Initialize( dm, NS.DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( dm, NS.currentListKey );
	--
	NS.ShopButton_Reset();
	NS.BuyAllButton_Reset();
	--
	NS.items = {};
	NS.query.item = {};
	NS.query.queue = {};
	NS.auction.data.groups.visible = {};
	NS.auction.data.groups.overpriced = {};
	NS.auction.data.groups.overstock = {};
	--
	AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 );
	NS.HideAuctionSortButtonArrows();
	AuctionFrameRestockShop_NameSortButton:Click(); -- Also updates ScrollFrame
	--
	AuctionFrameRestockShop_ListStatusFrameText:SetText( string.format( "%s\n\n%s   =   %s%d|r", NS.db["shoppingLists"][NS.currentListKey]["name"], NS.ListSummary(), NORMAL_FONT_COLOR_CODE, #NS.db["shoppingLists"][NS.currentListKey]["items"] ) );
	AuctionFrameRestockShop_ListStatusFrame:Show();
	--
	AuctionFrameRestockShop_FlyoutPanel.TitleText:SetText( NS.db["shoppingLists"][NS.currentListKey]["name"] );
	if not flyoutPanelItem_Clicked then
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 ); -- Only reset vertical scroll when NOT clicking entry in FlyoutPanel
	end
	NS.disableFlyoutChecks = false;
	AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
	AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( NS.ListSummary() );
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
NS.HideAuctionSortButtonArrows = function()
    _G["AuctionFrameRestockShop_RestockSortButtonArrow"]:Hide();
	_G["AuctionFrameRestockShop_NameSortButtonArrow"]:Hide();
	_G["AuctionFrameRestockShop_StackSizeSortButtonArrow"]:Hide();
	_G["AuctionFrameRestockShop_PctItemValueSortButtonArrow"]:Hide();
	_G["AuctionFrameRestockShop_ItemPriceSortButtonArrow"]:Hide();
	_G["AuctionFrameRestockShop_OnHandSortButtonArrow"]:Hide();
end

--
NS.ListSummary = function()
	local low, norm, full, maxFull = 0, 0, 0, 0;
	for k, v in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
		local restockPct = NS.RestockPct( NS.QOH( v["tsmItemString"] ), v["fullStockQty"] );
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
NS.Auction_Deselect = function()
	NS.SetCanBid( false );
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = nil;
	NS.auction.selected.auction = nil;
	AuctionFrameRestockShop_ScrollFrame:Update();
end

--
NS.StatusFrame_Message = function( text )
	AuctionFrameRestockShop_DialogFrame_StatusFrameText:SetText( text );
	NS.StatusFrame_Activate();
end

--
NS.StatusFrame_Activate = function()
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame:Hide();
	AuctionFrameRestockShop_DialogFrame_StatusFrame:Show();
end

--
NS.BuyoutFrame_Activate = function()
	AuctionFrameRestockShop_DialogFrame_StatusFrame:Hide();
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame:Show();
end

--
NS.ShopButton_Reset = function()
	AuctionFrameRestockShop_ShopButton:Enable();
	AuctionFrameRestockShop_ShopButton:SetText( L["Shop"] );
end

--
NS.BuyAllButton_Reset = function()
	NS.buyAll = false;
	AuctionFrameRestockShop_BuyAllButton:Disable();
	AuctionFrameRestockShop_BuyAllButton:SetText( L["Buy All"] );
end

--
NS.AuctionSortButton_OnClick = function( button, itemInfoKey )
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
	NS.HideAuctionSortButtonArrows();
	arrow:SetTexCoord( 0, 0.5625, t, b );
	arrow:Show();
	-- Return sorted data to frame
	NS.auction.data.sortKey = itemInfoKey;
	NS.auction.data.sortOrder = order;
	NS.AuctionDataGroups_Sort();
	if NS.buyAll then
		NS.AuctionGroup_OnClick( 1 );
	else
		AuctionFrameRestockShop_ScrollFrame:Update();
	end
end
--
NS.AuctionGroup_OnClick = function( groupKey )
	if NS.scanning or NS.buying then
		NS.Print( L["Busy scanning or buying, selection ignored."] );
		return; -- Stop function
	end
	--
	NS.SetCanBid( false );
	--
	local auction = NS.auction.data.groups.visible[groupKey]["auctions"][#NS.auction.data.groups.visible[groupKey]["auctions"]];
	NS.query.page = auction["page"];
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = groupKey;
	NS.auction.selected.auction = auction; -- Cannot use index, ownerFullName, or buyoutPrice yet, these may change after scanning the page
	if NS.buyAll and groupKey == 1 then
		AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
	end
	AuctionFrameRestockShop_ScrollFrame:Update();
	--
	NS.query.queue = {};
	table.insert( NS.query.queue, NS.items[auction["itemId"]] );
	NS.scanType = "SELECT";
	NS.ScanAuctionQueue();
end

--
NS.FlyoutPanelItem_OnClick = function( itemKey )
	NS.Reset( true );
	AuctionFrameRestockShop_ListStatusFrame:Hide();
	NS.auction.data.raw = {};
	--
	local item = CopyTable( NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey] );
	table.insert( NS.query.queue, item );
	NS.items[item["itemId"]] = item;
	NS.items[item["itemId"]]["scanTexture"] = "Waiting";
	NS.scanType = "SHOP";
	NS.ScanAuctionQueue();
end
--
NS.FlyoutPanelSetChecks = function( checked )
	for itemKey,_ in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
		NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey]["checked"] = checked;
	end
	AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Auction Data Groups
--------------------------------------------------------------------------------------------------------------------------------------------
NS.AuctionDataGroups_OnHandQtyChanged = function()
	-- Remove: If restockPct is 100+ and no maxPricePct["full"]
	-- Update: onHandQty, restockPct, pctMaxPrice
	-- This function should be run when an auction is won, uses the NS.auction.selected.auction
	-- ONLY Updates or Removes Groups for the ItemId that was won
	NS.AuctionDataGroups_ShowOverpricedStacks();
	NS.AuctionDataGroups_ShowOverstockStacks();
	--
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		if group["itemId"] == NS.auction.selected.auction["itemId"] then
			local onHandQty = NS.QOH( group["tsmItemString"] );
			local restockPct = NS.RestockPct( onHandQty, group["fullStockQty"] );
			local pctMaxPrice = math.ceil( ( group["itemPrice"] * 100 ) / NS.MaxPrice( group["itemValue"], restockPct, NS.items[group["itemId"]]["maxPricePct"] ) );
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
		NS.AuctionDataGroups_HideOverpricedStacks();
	end
	--
	if NS.db["hideOverstockStacks"] then
		NS.AuctionDataGroups_HideOverstockStacks();
	end
end

--
NS.AuctionDataGroups_HideOverpricedStacks = function()
	-- Remove: If pctMaxPrice > 100
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside NS.ScanAuctionQueue() just before NS.ScanComplete()
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
NS.AuctionDataGroups_ShowOverpricedStacks = function()
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overpriced do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overpriced, groupKey ) );
	end
end

--
NS.AuctionDataGroups_HideOverstockStacks = function()
	-- Remove: If ( ( onHandQty + count ) * 100 ) / fullStockQty > 100 + {overstockStacksPct}
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside NS.ScanAuctionQueue() just before NS.ScanComplete()
		-- c) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		local afterPurchaseRestockPct = NS.RestockPct( group["onHandQty"] + group["count"], group["fullStockQty"] );
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
NS.AuctionDataGroups_ShowOverstockStacks = function()
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.overstock do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overstock, groupKey ) );
	end
end

--
NS.AuctionDataGroups_FindGroupKey = function( itemId, name, count, itemPrice )
	for k, v in ipairs( NS.auction.data.groups.visible ) do
		if v["itemId"] == itemId and v["name"] == name and v["count"] == count and v["itemPrice"] == itemPrice then
			return k;
		end
	end
	return nil;
end

--
NS.AuctionDataGroups_RemoveItemId = function( itemId )
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
NS.AuctionDataGroups_Sort = function()
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
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Scan
--------------------------------------------------------------------------------------------------------------------------------------------
NS.ScanStart = function()
	NS.scanning = true;
	NS.SetCanBid( false );
	AuctionFrameRestockShop_ShopButton:SetText( L["Abort"] );
	AuctionFrameRestockShop_BuyAllButton:Disable();
end

--
NS.ScanStop = function()
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	NS.scanning = false;
	NS.query.page = 0;
	NS.query.attempts = 1;
	NS.query.batchAttempts = 1;
	AuctionFrameRestockShop_ShopButton:Enable();
end

--
NS.ScanAuctionQueue = function()
	if NS.scanning then return end
	if NS.scanType == "SHOP" then
		NS.disableFlyoutChecks = true;
		local footerText = ( function()
			if #NS.query.queue == 0 then
				return NS.ListSummary();
			else
				return string.format( L["%d items remaining"], #NS.query.queue );
			end
		end )();
		AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( footerText );
	end
	if not next( NS.query.queue ) then
		-- Auction scan complete, queue empty
		if NS.scanType ~= "SELECT" then
			-- Assemble into sortable groups (itemid has x stacks of y for z copper)
			if NS.scanType == "RESCAN" then
				-- Remove groups for rescanned item, new groups will be created from raw data
				NS.AuctionDataGroups_RemoveItemId( NS.query.item["itemId"] );
			end
			--
			for itemId, pages in pairs( NS.auction.data.raw ) do -- [ItemId] => [Page] => [Index] => ItemInfo
				for page, indexes in pairs( pages ) do
					for index, itemInfo in pairs( indexes ) do
						local groupKey = NS.AuctionDataGroups_FindGroupKey( itemInfo["itemId"], itemInfo["name"], itemInfo["count"], itemInfo["itemPrice"] );
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
				NS.AuctionDataGroups_HideOverpricedStacks();
			end
			--
			if NS.db["hideOverstockStacks"] then
				NS.AuctionDataGroups_HideOverstockStacks();
			end
			--
			NS.AuctionDataGroups_Sort();
			AuctionFrameRestockShop_ScrollFrame:Update();
		end
		NS.ScanComplete();
		return; -- Stop function, queue is empty, scan completed
	end
	-- Remove and query last item in the queue
	NS.query.item = table.remove( NS.query.queue );
	NS.ScanStart();
	--
	AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update(); -- Update scanTexture and Highlight query item, also moves vertical scroll
	--
	if NS.scanType ~= "SELECT" then
		NS.StatusFrame_Message( L["Scanning"] .. " " .. NS.query.item["name"] .. "..." );
	end
	--
	local itemValue = TSMAPI:GetItemValue( NS.query.item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) or 0;
	--
	if itemValue == 0 then
		-- Skipping: No Item Value
		NS.Print( string.format( L["Skipping %s: %sRequires %s data|r"], NS.query.item["link"], RED_FONT_COLOR_CODE,NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) );
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "NotReady";
		NS.ScanStop();
		NS.ScanAuctionQueue();
	elseif NS.query.item["checked"] == false or NS.query.item["maxPricePct"]["full"] == 0 and NS.QOH( NS.query.item["tsmItemString"] ) >= NS.query.item["fullStockQty"] then
		-- Skipping: Full Stock reached and no Full price set or unchecked
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "NotReady";
		NS.ScanStop();
		NS.ScanAuctionQueue();
	else
		-- OK: SendAuctionQuery()
		if NS.scanType ~= "SELECT" then
			NS.auction.data.raw[NS.query.item["itemId"]] = {}; -- Select scan only reads, it won't be rewriting the raw data
		end
		NS.SendAuctionQuery();
	end
end

--
NS.SendAuctionQuery = function()
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
		NS.TimeDelayFunction( 0.10, NS.SendAuctionQuery );
	else
		-- Aborting scan of this item, return to queue if NOT SELECT
		NS.StatusFrame_Message( L["Could not query Auction House after several attempts, please try again in a few moments"] );
		NS.ScanStop();
		if NS.scanType == "SELECT" then
			NS.Auction_Deselect(); -- Select failed, deselect auction and allow user to manually click again
			return; -- Stop function, a failed Select should never be allowed to complete, just deselect or rescan
		end
		NS.ScanAuctionQueue();
	end
end

--
NS.ScanAuctionPage = function()
	if not NS.scanning then return end
	if NS.scanType ~= "SELECT" then
		NS.auction.data.raw[NS.query.item["itemId"]][NS.query.page] = {};
		NS.StatusFrame_Message( string.format( L["Scanning %s: Page %d of %d"], NS.query.item["name"], ( NS.query.page + 1 ), NS.query.totalPages ) );
	end
	local incompleteData = false;
	for i = 1, NS.query.batchAuctions do
		-- name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo
		local name,texture,count,quality,_,_,_,_,_,buyoutPrice,_,_,_,_,ownerFullName,_,itemId,_ = GetAuctionItemInfo( "list", i );
		ownerFullName = ownerFullName or owner or "Unknown"; -- Note: Auction may not have an owner(FullName), the character could have been deleted
		if itemId == NS.query.item["itemId"] and buyoutPrice > 0 then
			local onHandQty = NS.QOH( NS.query.item["tsmItemString"] );
			local restockPct = NS.RestockPct( onHandQty, NS.query.item["fullStockQty"] );
			local itemValue = TSMAPI:GetItemValue( NS.query.item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] );
			local itemPrice = math.ceil( buyoutPrice / count );
			local maxPrice = NS.MaxPrice( itemValue, restockPct, NS.query.item["maxPricePct"] );
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
		NS.TimeDelayFunction( 0.25, NS.SendAuctionQuery ); -- Delay for missing data to be provided
		return; -- Stop function, requery in progress
	end
	-- Page scan complete, query next page unless doing SELECT scan
	if NS.scanType ~= "SELECT" and NS.query.page < ( NS.query.totalPages - 1 ) then -- Subtract 1 because the first page is 0
		NS.query.page = NS.query.page + 1; -- Increment to next page
		NS.query.batchAttempts = 1; -- Reset to default
		NS.SendAuctionQuery(); -- Send query for next page to scan
	else
	-- Item scan completed
		NS.items[NS.query.item["itemId"]]["scanTexture"] = "Ready";
		NS.ScanStop();
		if NS.scanType == "SELECT" and not NS.auction.selected.found then
			NS.Print( string.format( L["%s%sx%d|r for %s per item not found, rescanning item"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			NS.RescanItem();
			return; -- Stop function, starting rescan
		end
		NS.ScanAuctionQueue(); -- Return to queue
	end
end

--
NS.ScanComplete = function()
	if NS.scanType == "SHOP" then
		-- Shop
		if NS.Count( NS.items ) > 1 then
			NS.query.item = {}; -- Reset to unlock highlight when scanning more than one item
		end
		NS.disableFlyoutChecks = false;
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update(); -- Update scanTexture, Checks and Highlight
		--
		if next( NS.auction.data.groups.visible ) then
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
			else
				NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
			end
			AuctionFrameRestockShop_BuyAllButton:Enable();
		else
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				NS.StatusFrame_Message( L["No auctions were found that matched your settings"] );
			end
		end
	elseif NS.scanType == "SELECT" then
		-- Select, this scan type only completes if it found what it was looking for, always. Otherwise it would generate a rescan.
		local auction = NS.auction.selected.auction;
		local _,_,_,hexColor = GetItemQualityColor( auction["quality"] );
		local BuyoutFrameName = "AuctionFrameRestockShop_DialogFrame_BuyoutFrame";
		_G[BuyoutFrameName .. "_ItemIcon"]:SetNormalTexture( auction["texture"] );
		_G[BuyoutFrameName .. "_DescriptionFrameText"]:SetText( "|c" .. hexColor .. auction["name"] .. "|r x " .. auction["count"] );
		MoneyFrame_Update( BuyoutFrameName .. "_SmallMoneyFrame", auction["buyoutPrice"] );
		NS.SetCanBid( true );
		NS.BuyoutFrame_Activate();
		AuctionFrameRestockShop_BuyAllButton:Enable();
	elseif NS.scanType == "RESCAN" then
		-- Rescanned the specific item from the selected group. If the group exists after a rescan, then reselect it.
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
		if not NS.auction.selected.groupKey then
			NS.Print( string.format( L["%s%sx%d|r for %s per item not found after rescan"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			if next( NS.auction.data.groups.visible ) then
				if NS.buyAll then
					NS.AuctionGroup_OnClick( 1 );
				else
					NS.Auction_Deselect();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
						NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
					end
					AuctionFrameRestockShop_BuyAllButton:Enable();
				end
			else
				NS.Auction_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				end
				NS.BuyAllButton_Reset();
			end
		else
			NS.Print( string.format( L["%s%sx%d|r for %s per item was found after rescan"], NS.auction.selected.auction["itemLink"], YELLOW_FONT_COLOR_CODE, NS.auction.selected.auction["count"], TSMAPI:FormatTextMoney( NS.auction.selected.auction["itemPrice"], "|cffffffff", true ) ) );
			NS.AuctionGroup_OnClick( NS.auction.selected.groupKey );
		end
	end
	--
	NS.ShopButton_Reset();
end

--
NS.RescanItem = function()
	NS.auction.data.raw = {};
	NS.query.queue = {};
	table.insert( NS.query.queue, NS.items[NS.query.item["itemId"]] );
	NS.scanType = "RESCAN";
	NS.ScanAuctionQueue();
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------------------------------------------------------------------
NS.AfterAuctionWon = function()
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
				AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
			end
			AuctionFrameRestockShop_ScrollFrame:Update(); -- Highlight the selected group
			NS.ScanStart();
			NS.ailu = "LISTEN";
		else
			NS.AuctionGroup_OnClick( groupKey ); -- Item wasn't the same or wasn't on the same page, this will send a new QueryAuctionItems()
		end
	end
	-- NoGroupKey()
	local function NoGroupKey()
		if next( NS.auction.data.groups.visible ) then
			-- More auction exist
			if NS.buyAll then
				NextAuction( 1 );
			else
				NS.Auction_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
				end
				AuctionFrameRestockShop_BuyAllButton:Enable();
			end
		else
			-- No auctions exist
			NS.Auction_Deselect();
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
			end
			NS.BuyAllButton_Reset();
		end
	end
	-- Full Stock notice
	if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["onHandQty"] < NS.auction.selected.auction["fullStockQty"] and ( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["onHandQty"] + NS.auction.selected.auction["count"] ) >= NS.auction.selected.auction["fullStockQty"] then
		NS.Print( string.format( L["You reached the %sFull Stock|r of %s%d|r on %s"], NORMAL_FONT_COLOR_CODE, NS.colorCode.full, NS.auction.selected.auction["fullStockQty"], NS.auction.selected.auction["itemLink"] ) );
	end
	--
	NS.buying = false;
	AuctionFrameRestockShop_ShopButton:Enable();
	--
	NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] = NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] - 1;
	--
	if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] == 0 then
		-- Group removed
		table.remove( NS.auction.data.groups.visible, NS.auction.selected.groupKey );
		NS.AuctionDataGroups_OnHandQtyChanged();
		NS.auction.selected.groupKey = nil;
		AuctionFrameRestockShop_ScrollFrame:Update();
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
		AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( NS.ListSummary() );
		NoGroupKey();
	else
		-- Single auction removed
		table.remove( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["auctions"] );
		NS.AuctionDataGroups_OnHandQtyChanged();
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemId"], NS.auction.selected.auction["name"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
		AuctionFrameRestockShop_ScrollFrame:Update();
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
		AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( NS.ListSummary() );
		if not NS.auction.selected.groupKey then
			NoGroupKey();
		else
			NextAuction( NS.auction.selected.groupKey );
		end
	end
end

--
NS.AddTooltipData = function( self, ... )
	if ( not NS.db["itemTooltipShoppingListSettings"] and not NS.db["itemTooltipItemId"] ) or NS.tooltipAdded then return end
	-- Get Item Id
	local itemName, itemLink = self:GetItem();
	local itemId = itemLink and tonumber( string.match( itemLink, "item:(%d+):" ) ) or nil;
	if not itemId then return end
	-- Shopping List Settings
	if NS.db["itemTooltipShoppingListSettings"] then
		local itemKey = NS.FindItemKey( itemId );
		if itemKey then
			-- Item found in current shopping list
			if strtrim( _G[self:GetName() .. "TextLeft" .. self:NumLines()]:GetText() ) ~= "" then
				self:AddLine( " " ); -- Blank line at top
			end
			-- Prepare and format data
			local item = NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey];
			local itemValue = TSMAPI:GetItemValue( item["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) or 0;
			local onHandQty = NS.QOH( item["tsmItemString"] );
			local restockPct = NS.RestockPct( onHandQty, item["fullStockQty"] );
			local maxPrice, status = NS.MaxPrice( itemValue, restockPct, item["maxPricePct"], "returnStatus" );
			maxPrice = ( maxPrice > 0 ) and ( TSMAPI:FormatTextMoney( maxPrice, "|cffffffff", true ) .. " " ) or ""; -- If full stock and no full price then leave it blank
			local restockColor = NS.RestockColor( "code", restockPct, item["maxPricePct"] );
			restockPct = restockColor .. math.floor( restockPct ) .. "%|r";
			status = restockColor .. L[status] .. "|r";
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
			self:AddLine( "  " .. TOOLTIP_COLOR_CODE .. L["Max Price"] .. ":|r " .. ( maxPrice and ( maxPrice .. TOOLTIP_COLOR_CODE .. "(|r" .. status .. TOOLTIP_COLOR_CODE .. ")|r"  ) or "|cffff2020" .. L["Requires Item Value"] .. "|r" ) );
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
NS.ClearTooltipData = function()
	NS.tooltipAdded = false;
end

--
NS.WoWClientBuildChanged = function()
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
		NS.TimeDelayFunction( 1, queueList );
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
		NS.TimeDelayFunction( delay, updateList );
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
	NS.TimeDelayFunction( 30, queueList ); -- Delay allows time for WoW client to establish latency
end

--
NS.FindItemKey = function( itemId, shoppingList )
	shoppingList = shoppingList or NS.currentListKey;
	for k, v in ipairs( NS.db["shoppingLists"][shoppingList]["items"] ) do
		if v["itemId"] == itemId then
			return k;
		end
	end
	return nil;
end

--
NS.SetCanBid = function( enable )
	if enable then
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Enable();
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Enable();
	else
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Disable();
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Disable();
	end
	NS.canBid = enable;
end

--
NS.TSMItemString = function( itemLink )
	local itemString = string.match( itemLink, "item[%-?%d:]+" );
	local s1,s2,s3,s4,s5,s6,s7,s8 = strsplit( ":", itemString );
	return s1 .. ":" .. s2 .. ":" .. s3 .. ":" .. s4 .. ":" .. s5 .. ":" .. s6 .. ":" .. s7 .. ":" .. s8;
end

--
NS.QOH = function( tsmItemString )
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
NS.RestockPct = function( onHandQty, fullStockQty )
	return ( onHandQty * 100 ) / fullStockQty;
end

--
NS.MaxPrice = function( itemValue, restockPct, maxPricePct, returnStatus )
	local maxPrice = nil;
	if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
		maxPrice = math.ceil( ( itemValue * maxPricePct["low"] ) / 100 );
		status = "Low"; -- Do not translate here
	elseif restockPct < 100 then
		maxPrice = math.ceil( ( itemValue * maxPricePct["normal"] ) / 100 );
		status = "Norm"; -- Do not translate here
	else
		maxPrice = math.ceil( ( itemValue * maxPricePct["full"] ) / 100 );
		status = "Full"; -- Do not translate here
	end
	--
	if returnStatus then
		return unpack( { maxPrice, status } );
	else
		return maxPrice;
	end
end

--
NS.RestockColor = function( colorType, restockPct, maxPricePct )
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
NS.SlashCmdHandler = function( msg )
	if msg == "acceptbuttonclick" then
		if NS.canBid then
			AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Click();
		end
		return;
	end
	-- Switch to "Browse" AuctionFrame tab
	if AuctionFrameRestockShop and AuctionFrameRestockShop:IsShown() then
		AuctionFrameTab1:Click();
	end
	-- Open an options frame tab
	if msg == "" or msg == "sl" or msg == "shoppinglists" then
		NS.options.MainFrame:ShowTab( 1 );
	elseif msg == "moreoptions" then
		NS.options.MainFrame:ShowTab( 2 );
	elseif msg == "help" then
		NS.options.MainFrame:ShowTab( 3 );
	else
		NS.options.MainFrame:ShowTab( 3 );
		NS.Print( L["Unknown command, opening Help"] );
	end
end
--
SLASH_RESTOCKSHOP1 = "/restockshop";
SLASH_RESTOCKSHOP2 = "/rs";
SlashCmdList["RESTOCKSHOP"] = function( msg ) NS.SlashCmdHandler( msg ) end;
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopInterfaceOptionsPanel : Interface > Addons > RestockShop
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Frame( "RestockShopInterfaceOptionsPanel", UIParent, {
	topLevel = true,
	hidden = true,
	setPoint = { "TOPLEFT" },
	OnLoad = function( self )
		self.name = NS.title;
	end,
} );
NS.TextFrame( "Text", RestockShopInterfaceOptionsPanel, L["Options for RestockShop can be opened from the Auction House on the RestockShop tab.\n\nYou can also use either slash command /rs or /restockshop"], {
	setAllPoints = true,
	setPoint = { "TOPLEFT", 16, -16 },
	justifyV = "TOP",
} );
--------------------------------------------------------------------------------------------------------------------------------------------
-- "RestockShop" AuctionFrame Tab (AuctionFrameRestockShop)
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Blizzard_AuctionUI_OnLoad = function()
	NS.Frame( "AuctionFrameRestockShop", UIParent, {
		topLevel = true,
		hidden = true,
		size = { 824, 447 }, --f:SetSize( 758, 447 ); 66 x removed from close button
		OnShow = function( self )
			NS.options.MainFrame:Hide();
			NS.Reset();
		end,
		OnHide = NS.Reset,
	} );
	NS.TextFrame( "_Title", AuctionFrameRestockShop, "", {
		setPoint = {
			{ "TOPLEFT", 25, -24 },
			{ "RIGHT", 0 },
		},
		justifyH = "CENTER",
	} );
	NS.Button( "_OnHandSortButton", AuctionFrameRestockShop, L["On Hand"], {
		template = "AuctionSortButtonTemplate",
		size = { 82, 19 },
		setPoint = { "TOPLEFT", 65, -52 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "onHandQty" );
		end,
	} );
	NS.Button( "_RestockSortButton", AuctionFrameRestockShop, L["Restock %"], {
		template = "AuctionSortButtonTemplate",
		size = { 82, 19 },
		setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "restockPct" );
		end,
	} );
	NS.Button( "_NameSortButton", AuctionFrameRestockShop, NAME, {
		template = "AuctionSortButtonTemplate",
		size = { 220, 19 },
		setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "name" );
		end,
	} );
	NS.Button( "_StackSizeSortButton", AuctionFrameRestockShop, L["Stack Size"], {
		template = "AuctionSortButtonTemplate",
		size = { 110, 19 },
		setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "count" );
		end,
	} );
	NS.Button( "_ItemPriceSortButton", AuctionFrameRestockShop, L["Item Price"], {
		template = "AuctionSortButtonTemplate",
		size = { 150, 19 },
		setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "itemPrice" );
		end,
	} );
	NS.Button( "_PctItemValueSortButton", AuctionFrameRestockShop, L["% Item Value"], {
		template = "AuctionSortButtonTemplate",
		size = { 101, 19 },
		setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
		OnClick = function( self )
			NS.AuctionSortButton_OnClick( self, "pctItemValue" );
		end,
	} );
	NS.ScrollFrame( "_ScrollFrame", AuctionFrameRestockShop, {
		size = { 733, ( 20 * 14 - 5 ) },
		setPoint = { "TOPLEFT", "$parent_OnHandSortButton", "BOTTOMLEFT", 1, -5 },
		buttonTemplate = "AuctionFrameRestockShop_ScrollFrameButtonTemplate",
		udpate = {
			numToDisplay = 14,
			buttonHeight = 20,
			UpdateFunction = function( sf )
				local items = NS.auction.data.groups.visible;
				local numItems = #items;
				FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight );
				for num = 1, sf.numToDisplay do
					local bn = sf.buttonName .. num; -- button name
					local b = _G[bn]; -- button
					local k = FauxScrollFrame_GetOffset( sf ) + num; -- key
					b:UnlockHighlight();
					if k <= numItems then
						local OnClick = function()
							NS.AuctionGroup_OnClick( k );
						end
						local IsHighlightLocked = function()
							if NS.auction.selected.groupKey and NS.auction.selected.groupKey == k then
								return true;
							else
								return false;
							end
						end
						b:SetScript( "OnClick", OnClick );
						_G[bn .. "_OnHand"]:SetText( items[k]["onHandQty"] );
						local restockColor = NS.RestockColor( "font", items[k]["restockPct"] );
						_G[bn .. "_Restock"]:SetText( math.floor( items[k]["restockPct"] ) .. "%" );
						_G[bn .. "_Restock"]:SetTextColor( restockColor["r"], restockColor["g"], restockColor["b"] );
						_G[bn .. "_IconTexture"]:SetNormalTexture( items[k]["texture"] );
						_G[bn .. "_IconTexture"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[k]["itemLink"] ); b:LockHighlight(); end );
						_G[bn .. "_IconTexture"]:SetScript( "OnLeave", function() GameTooltip_Hide(); if not IsHighlightLocked() then b:UnlockHighlight(); end end );
						_G[bn .. "_IconTexture"]:SetScript( "OnClick", OnClick );
						_G[bn .. "_Name"]:SetText( items[k]["name"] );
						_G[bn .. "_Name"]:SetTextColor( GetItemQualityColor( items[k]["quality"] ) );
						_G[bn .. "_Stacks"]:SetText( string.format( L["%d stacks of %d"], items[k]["numAuctions"], items[k]["count"] ) );
						MoneyFrame_Update( bn .. "_ItemPrice_SmallMoneyFrame", items[k]["itemPrice"] );
						_G[bn .. "_PctItemValue"]:SetText( math.floor( items[k]["pctItemValue"] ) .. "%" );
						if items[k]["pctMaxPrice"] > 100 then _G[bn .. "_PctItemValue"]:SetText( RED_FONT_COLOR_CODE .. _G[bn .. "_PctItemValue"]:GetText() .. "|r" ); end
						b:Show();
						if IsHighlightLocked() then b:LockHighlight(); end
					else
						b:Hide();
					end
				end
			end
		},
	} );
	NS.TextFrame( "_ListStatusFrame", AuctionFrameRestockShop, "", {
		hidden = true,
		size = { 733, ( 334 - 22 ) },
		setPoint = { "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT" },
		fontObject = "GameFontHighlightLarge",
		justifyH = "CENTER",
	} );
	NS.Frame( "_DialogFrame", AuctionFrameRestockShop, {
		size = { 733, 54 },
		setPoint = { "TOP", "$parent_ScrollFrameButton14", "BOTTOM" },
	} );
	NS.Frame( "_BuyoutFrame", AuctionFrameRestockShop_DialogFrame, {
		hidden = true,
		setAllPoints = true,
	} );
	NS.Button( "_CancelButton", AuctionFrameRestockShop_DialogFrame_BuyoutFrame, CANCEL, {
		size = { 120, 30 },
		setPoint = { "RIGHT" },
		OnClick = function()
			if NS.buyAll then
				AuctionFrameRestockShop_BuyAllButton:Click();
			else
				NS.Auction_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
				end
			end
		end,
	} );
	NS.Button( "_AcceptButton", AuctionFrameRestockShop_DialogFrame_BuyoutFrame, ACCEPT, {
		size = { 120, 30 },
		setPoint = { "RIGHT", "#sibling", "LEFT", -10, 0 },
		OnClick = function( self )
			if NS.canBid then
				NS.SetCanBid( false );
				NS.buying = true;
				AuctionFrameRestockShop_ShopButton:Disable();
				AuctionFrameRestockShop_BuyAllButton:Disable();
				RestockShopEventsFrame:RegisterEvent( "CHAT_MSG_SYSTEM" );
				RestockShopEventsFrame:RegisterEvent( "UI_ERROR_MESSAGE" );
				PlaceAuctionBid( "list", NS.auction.selected.auction["index"], NS.auction.selected.auction["buyoutPrice"] );
			end
		end,
	} );

	NS.Frame( "_SmallMoneyFrame", AuctionFrameRestockShop_DialogFrame_BuyoutFrame, {
		template = "SmallMoneyFrameTemplate",
		size = { 137, 16 },
		setPoint = { "RIGHT", "#sibling", "LEFT" },
		OnLoad = function( self )
			SmallMoneyFrame_OnLoad( self );
			MoneyFrame_SetType( self, "AUCTION" );
		end,
	} );
	NS.Button( "_ItemIcon", AuctionFrameRestockShop_DialogFrame_BuyoutFrame, nil, {
		template = false,
		size = { 30, 30 },
		setPoint = { "LEFT" },
		tooltip = function()
			GameTooltip:SetHyperlink( NS.auction.selected.auction["itemLink"] );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_RIGHT" };
		end,
	} );

	NS.TextFrame( "_DescriptionFrame", AuctionFrameRestockShop_DialogFrame_BuyoutFrame, "", {
		size = { 200, 30 },
		setPoint = { "LEFT", "$parent_ItemIcon", "RIGHT", 10, 0 },
	} );
	NS.TextFrame( "_StatusFrame", AuctionFrameRestockShop_DialogFrame, "", {
		setAllPoints = true,
		justifyH = "CENTER",
	} );
	NS.Button( "_CloseButton", AuctionFrameRestockShop, CLOSE, {
		size = { 80, 22 },
		setPoint = { "BOTTOMRIGHT", 0, 14 },
		OnClick = function() AuctionFrame_Hide() end,
	} );
	NS.Button( "_BuyAllButton", AuctionFrameRestockShop, L["Buy All"], {
		size = { 80, 22 },
		setPoint = { "RIGHT", "#sibling", "LEFT" },
		OnClick = function( self )
			if NS.buyAll then
				NS.buyAll = false;
				self:SetText( L["Buy All"] );
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
				end
				NS.Auction_Deselect();
			else
				NS.buyAll = true;
				self:SetText( L["Stop"] );
				NS.StatusFrame_Message( L["Scanning"] .. "..." );
				NS.AuctionGroup_OnClick( 1 );
			end
		end,
	} );
	NS.Button( "_ShopButton", AuctionFrameRestockShop, L["Shop"], {
		size = { 80, 22 },
		setPoint = { "RIGHT", "#sibling", "LEFT" },
		OnClick = function ( self )
			if NS.scanning then
				NS.Reset();
			else
				NS.items = {};
				NS.query.queue= {};
				NS.auction.data.raw = {};
				NS.auction.data.groups.visible = {};
				NS.auction.data.groups.overstock = {};
				NS.Auction_Deselect();
				AuctionFrameRestockShop_ScrollFrame:Update();
				AuctionFrameRestockShop_ListStatusFrame:Hide();
				NS.BuyAllButton_Reset();
				AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 );
				for k, v in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
					table.insert( NS.query.queue, v );
					NS.items[v["itemId"]] = v;
					NS.items[v["itemId"]]["scanTexture"] = "Waiting";
				end
				table.sort ( NS.query.queue, function ( item1, item2 )
					return item1["name"] > item2["name"]; -- Sort by name Z-A because items are pulled from the end of the queue which will become A-Z
				end	);
				NS.scanType = "SHOP";
				NS.ScanAuctionQueue();
			end
		end,
	} );
	NS.DropDownMenu( "_ShoppingListsDropDownMenu", AuctionFrameRestockShop, {
		setPoint = { "RIGHT", "#sibling", "LEFT", 15, -2 },
		buttons = function()
			local t = {};
			for k, v in ipairs( NS.db["shoppingLists"] ) do
				tinsert( t, { v["name"], k } );
			end
			return t;
		end,
		OnClick = function( info )
			if NS.currentListKey ~= info.value then
				NS.dbpc["currentListName"] = info.text;
				NS.currentListKey = info.value;
				NS.Reset();
			end
		end,
		width = 195,
	} );
	NS.Button( "_ShoppingListsButton", AuctionFrameRestockShop, L["Shopping Lists"], {
		size = { 192, 22 },
		setPoint = { "RIGHT", "$parent_ShopButton", "LEFT", -212, 0 },
		OnClick = function()
			NS.SlashCmdHandler( "shoppinglists" );
		end,
	} );
	NS.Frame( "_FlyoutPanel", AuctionFrameRestockShop, {
		template = "BasicFrameTemplate",
		size = { 247, 423 }, -- 274 with scrollbar, 247 without scrollbar
		setPoint = { "LEFT", "$parent", "RIGHT", 8, -1 },
		bg = { "Interface\\FrameGeneral\\UI-Background-Marble", true },
		OnLoad = function( self )
			self.TitleText:SetWordWrap( false );
			self.TitleText:SetPoint( "LEFT", 4, 0 );
			self.TitleText:SetPoint( "RIGHT", -28, 0 );
			self.CloseButton:SetScript( "OnClick", function( self )
				_G[self:GetParent():GetParent():GetName() .. "_FlyoutPanelButton"]:Click();
			end );
		end,
	} );
	NS.ScrollFrame( "_ScrollFrame", AuctionFrameRestockShop_FlyoutPanel, {
		size = { 242, ( 20 * 17 - 5 ) },
		setPoint = { "TOPLEFT", 1, -27 },
		buttonTemplate = "AuctionFrameRestockShop_FlyoutPanel_ScrollFrameButtonTemplate",
		udpate = {
			numToDisplay = 17,
			buttonHeight = 20,
			UpdateFunction = function( sf )
				local items = NS.db["shoppingLists"][NS.currentListKey]["items"];
				local numItems = #items;
				FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight );
				-- Adjust FlyoutPanel width for scrollbar
				local flyoutWidth = ( function() if numItems > sf.numToDisplay then return 274 else return 247 end end )();
				AuctionFrameRestockShop_FlyoutPanel:SetWidth( flyoutWidth );
				-- Adjust vertical scroll if doing ShopButton scan
				if NS.scanning and NS.scanType == "SHOP" and NS.Count( NS.items ) > 1 then
					local vScroll = ( numItems - #NS.query.queue - sf.numToDisplay ) * sf.buttonHeight;
					if vScroll > 0 and vScroll > sf:GetVerticalScroll() then
						sf:SetVerticalScroll( vScroll );
					end
				end
				--
				for num = 1, sf.numToDisplay do
					local bn = sf.buttonName .. num; -- button name
					local b = _G[bn]; -- button
					local k = FauxScrollFrame_GetOffset( sf ) + num; -- key
					b:UnlockHighlight();
					if k <= numItems then
						local OnClick = function()
							NS.FlyoutPanelItem_OnClick( k );
						end
						local IsHighlightLocked = function()
							if ( NS.scanType == "SHOP" or NS.Count( NS.items ) == 1 ) and NS.query.item["itemId"] == items[k]["itemId"] then
								return true;
							else
								return false;
							end
						end
						b:SetScript( "OnClick", OnClick );
						_G[bn .. "_IconTexture"]:SetNormalTexture( items[k]["texture"] );
						_G[bn .. "_IconTexture"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[k]["link"] ); b:LockHighlight(); end );
						_G[bn .. "_IconTexture"]:SetScript( "OnLeave", function() GameTooltip_Hide(); if not IsHighlightLocked() then b:UnlockHighlight(); end end );
						_G[bn .. "_IconTexture"]:SetScript( "OnClick", OnClick );
						_G[bn .. "_Name"]:SetText( items[k]["name"] );
						_G[bn .. "_Name"]:SetTextColor( GetItemQualityColor( items[k]["quality"] ) );
						-- Status - Low, Norm, Full
						local onHandQty = NS.QOH( items[k]["tsmItemString"] );
						local restockPct = NS.RestockPct( onHandQty, items[k]["fullStockQty"] );
						local restockStatus;
						if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
							restockStatus = NS.colorCode.low .. L["Low"] .. "|r";
						elseif restockPct < 100 then
							restockStatus = NS.colorCode.norm .. L["Norm"] .. "|r";
						elseif items[k]["maxPricePct"]["full"] > 0 then
							restockStatus = NS.colorCode.full .. L["Full"] .. "|r";
						else
							restockStatus = NS.colorCode.maxFull .. L["Full"] .. "|r";
						end
						_G[bn .. "_RestockStatus"]:SetText( restockStatus );
						--
						local scanTexture;
						if not NS.items[items[k]["itemId"]] then
							scanTexture = "Waiting";
						else
							scanTexture = NS.items[items[k]["itemId"]]["scanTexture"];
						end
						_G[bn .. "_ScanTexture"]:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-" .. scanTexture );
						--
						_G[bn .. "_Checked"]:SetChecked( items[k]["checked"] );
						_G[bn .. "_Checked"]:SetScript( "OnEnter", function() b:LockHighlight(); end );
						_G[bn .. "_Checked"]:SetScript( "OnLeave", function() if not IsHighlightLocked() then b:UnlockHighlight(); end end );
						_G[bn .. "_Checked"]:SetScript( "OnClick", function( self ) NS.db["shoppingLists"][NS.currentListKey]["items"][k]["checked"] = self:GetChecked(); end );
						if NS.disableFlyoutChecks then
							_G[bn .. "_Checked"]:Disable();
							AuctionFrameRestockShop_FlyoutPanel_UncheckAll:Disable();
							AuctionFrameRestockShop_FlyoutPanel_CheckAll:Disable();
						else
							_G[bn .. "_Checked"]:Enable();
							AuctionFrameRestockShop_FlyoutPanel_UncheckAll:Enable();
							AuctionFrameRestockShop_FlyoutPanel_CheckAll:Enable();
						end
						--
						b:Show();
						if IsHighlightLocked() then b:LockHighlight(); end
					else
						b:Hide();
					end
				end
			end
		},
	} );
	NS.Button( "_UncheckAll", AuctionFrameRestockShop_FlyoutPanel, L["Uncheck All"], {
		size = { 96, 20 },
		setPoint = { "BOTTOMRIGHT", "$parent", "BOTTOM", -5, 30 },
		fontObject = "GameFontNormalSmall",
		OnClick = function()
			NS.FlyoutPanelSetChecks( false );
		end,
	} );
	NS.Button( "_CheckAll", AuctionFrameRestockShop_FlyoutPanel, L["Check All"], {
		size = { 96, 20 },
		setPoint = { "BOTTOMLEFT", "$parent", "BOTTOM", 5, 30 },
		fontObject = "GameFontNormalSmall",
		OnClick = function()
			NS.FlyoutPanelSetChecks( true );
		end,
	} );
	NS.TextFrame( "_Footer", AuctionFrameRestockShop_FlyoutPanel, "", {
		setPoint = {
			{ "BOTTOMLEFT", 0, 15 },
			{ "RIGHT", 0 },
		},
		justifyH = "CENTER",
	} );
	NS.Button( "_FlyoutPanelButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 28, 28 },
		setPoint = { "TOPRIGHT", "$parent", "TOPRIGHT", 5, -34 },
		normalTexture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		pushedTexture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down",
		highlightTexture = "Interface\\Buttons\\UI-Common-MouseHilight",
		OnClick = function ( self )
			local FlyoutPanel = _G[self:GetParent():GetName() .. "_FlyoutPanel"];
			if FlyoutPanel:IsShown() then
				FlyoutPanel:Hide();
				NS.db["flyoutPanelOpen"] = false;
				self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" );
				self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down" );
			else
				FlyoutPanel:Show();
				NS.db["flyoutPanelOpen"] = true;
				self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
				self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
			end
		end,
		OnLoad = function( self )
			if not NS.db["flyoutPanelOpen"] then
				self:Click();
			end
		end,
	} );
	NS.Button( "_HideOverpricedStacksButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 32, 32 },
		setPoint = { "TOPRIGHT", "$parent_OnHandSortButton", "BOTTOMLEFT", -6, -7 },
		normalTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Up",
		pushedTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Down",
		highlightTexture = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
		tooltip = function()
			local tooltip = string.format( L["%sHide Overpriced Stacks|r\n\nHides auctions whose %% Item Value exceeds\nthe current max price: %sLow|r, %sNorm|r, or %sFull|r %%"], RED_FONT_COLOR_CODE, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full );
			local numAuctions = 0;
			if #NS.auction.data.groups.overpriced > 0 then
				for _,group in ipairs( NS.auction.data.groups.overpriced ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
			end
			if not NS.db["hideOverpricedStacks"] or NS.scanning or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			else
				return tooltip .. "\n\n" .. RED_FONT_COLOR_CODE .. string.format( L["%s Auctions Hidden"], numAuctions ) .. "|r";
			end
		end,
		OnClick = function ( self )
			if NS.scanning then
				NS.Print( L["Selection ignored, busy scanning"] );
				return; -- Stop function
			end
			--
			AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Click();
			--
			NS.AuctionDataGroups_ShowOverpricedStacks();
			NS.AuctionDataGroups_ShowOverstockStacks();
			--
			if NS.db["hideOverpricedStacks"] then
				-- Show
				NS.AuctionDataGroups_Sort();
				NS.db["hideOverpricedStacks"] = false;
				self:UnlockHighlight();
			else
				-- Hide
				NS.AuctionDataGroups_HideOverpricedStacks();
				NS.db["hideOverpricedStacks"] = true;
				self:LockHighlight();
			end
			--
			if NS.db["hideOverstockStacks"] then
				NS.AuctionDataGroups_HideOverstockStacks();
			end
			--
			GameTooltip:SetText( self.tooltip() );
			--
			if next( NS.auction.data.groups.visible ) then
				-- Auctions shown
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
				end
				AuctionFrameRestockShop_BuyAllButton:Enable();
			elseif next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) then
				-- Auctions hidden
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				AuctionFrameRestockShop_BuyAllButton:Disable();
			elseif next( NS.items ) then
				-- Auctions scanned, but none available
				NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				AuctionFrameRestockShop_BuyAllButton:Disable();
			end
			AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 );
			AuctionFrameRestockShop_ScrollFrame:Update();
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
		end,
	} );
	NS.Button( "_HideOverstockStacksButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 32, 32 },
		setPoint = { "TOP", "#sibling", "BOTTOM", 0, -3 },
		normalTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Up",
		pushedTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Down",
		highlightTexture = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
		tooltip = function()
			local tooltip =  string.format( L["%sHide Overstock Stacks|r\n\nHides auctions that when purchased would cause you\nto exceed your \"Full Stock\" by more than %s%s%%|r"], NS.colorCode.full, NS.colorCode.full, NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] );
			local numAuctions = 0;
			if #NS.auction.data.groups.overstock > 0 then
				for _,group in ipairs( NS.auction.data.groups.overstock ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
			end
			if not NS.db["hideOverstockStacks"] or NS.scanning or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			else
				return tooltip .. "\n\n" .. NS.colorCode.full .. string.format( L["%s Auctions Hidden"], numAuctions ) .. "|r";
			end
		end,
		OnClick = function ( self )
			if NS.scanning then
				NS.Print( L["Selection ignored, busy scanning"] );
				return; -- Stop function
			end
			--
			AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Click();
			--
			NS.AuctionDataGroups_ShowOverpricedStacks();
			NS.AuctionDataGroups_ShowOverstockStacks();
			--
			if NS.db["hideOverstockStacks"] then
				-- Show
				NS.AuctionDataGroups_Sort();
				NS.db["hideOverstockStacks"] = false;
				self:UnlockHighlight();
			else
				-- Hide
				NS.AuctionDataGroups_HideOverstockStacks();
				NS.db["hideOverstockStacks"] = true;
				self:LockHighlight();
			end
			--
			if NS.db["hideOverpricedStacks"] then
				NS.AuctionDataGroups_HideOverpricedStacks();
			end
			--
			GameTooltip:SetText( self.tooltip() );
			--
			if next( NS.auction.data.groups.visible ) then
				-- Auctions shown
				if next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.overpriced ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
				end
				AuctionFrameRestockShop_BuyAllButton:Enable();
			elseif next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.overpriced ) then
				-- Auctions hidden
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				AuctionFrameRestockShop_BuyAllButton:Disable();
			elseif next( NS.items ) then
				-- Auctions scanned, but none available
				NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				AuctionFrameRestockShop_BuyAllButton:Disable();
			end
			AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 );
			AuctionFrameRestockShop_ScrollFrame:Update();
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
		end,
	} );
	-- Add "RestockShop" tab to AuctionFrame
	local numTab = AuctionFrame.numTabs + 1;
	NS.AuctionFrameTab = CreateFrame( "Button", "AuctionFrameTab" .. numTab, AuctionFrame, "AuctionTabTemplate" );
	NS.AuctionFrameTab:SetID( numTab );
	NS.AuctionFrameTab:SetText( NS.title );
	NS.AuctionFrameTab:SetPoint( "LEFT", _G["AuctionFrameTab" .. numTab - 1], "RIGHT", -8, 0 );
	PanelTemplates_SetNumTabs( AuctionFrame, numTab );
	PanelTemplates_EnableTab( AuctionFrame, numTab );
	-- Set AuctionFrameRestockShop inside AuctionFrame
	AuctionFrameRestockShop:SetParent( AuctionFrame );
	AuctionFrameRestockShop:SetPoint( "TOPLEFT" );
	-- Hook tab click
	hooksecurefunc( "AuctionFrameTab_OnClick", NS.AuctionFrameTab_OnClick );
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopEventsFrame
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Frame( "RestockShopEventsFrame", UIParent, {
	topLevel = true,
	hidden = true,
	OnEvent = function ( self, event, ... )
		if			event == "ADDON_LOADED"				then	NS.OnAddonLoaded();
			elseif	event == "PLAYER_LOGIN"				then	NS.OnPlayerLogin();
			elseif	event == "AUCTION_ITEM_LIST_UPDATE"	then	NS.OnAuctionItemListUpdate();
			elseif	event == "CHAT_MSG_SYSTEM"			then	NS.OnChatMsgSystem( ... );
			elseif	event == "UI_ERROR_MESSAGE"			then	NS.OnUIErrorMessage( ... );
		end
	end,
	OnLoad = function( self )
		self:RegisterEvent( "ADDON_LOADED" );
		self:RegisterEvent( "PLAYER_LOGIN" );
	end,
} );
