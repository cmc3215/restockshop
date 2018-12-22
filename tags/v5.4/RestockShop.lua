--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
NS.releasePatch = "8.1";
NS.versionString = "5.4";
NS.version = tonumber( NS.versionString );
--
NS.options = {};
--
NS.initialized = false;
NS.currentListKey = nil;
NS.playerLoginMsg = {};
NS.AuctionFrameTab = nil;
NS.tooltipAdded = false;
NS.editItemId = nil;
--
NS.scan = {};
NS.auction = {
	data = {
		raw = {},
		groups = {
			visible = {},
			overpriced = {},
			overstock = {},
			uneven = {},
			one = {},
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
NS.numAuctionsWon = 0;
NS.copperAuctionsWon = 0;
NS.tsmPriceSources = nil;
NS.disableFlyoutChecks = false;
NS.buyAll = false;
--
NS.colorCode = {
	low = ORANGE_FONT_COLOR_CODE,
	norm = YELLOW_FONT_COLOR_CODE,
	full = "|cff3fbf3f",
	maxFull = GRAY_FONT_COLOR_CODE,
	tooltip = not TSMAPI_FOUR and TSMAPI.Design:GetInlineColor( "tooltip" ) or "|cff8282fa", -- TradeSkillMaster\Core\Service\Tooltip\Core.lua:115 --- r, g, b = 130, 130, 250
	quality = {
		[0] = "|c" .. select( 4, GetItemQualityColor( 0 ) ),
		[1] = "|c" .. select( 4, GetItemQualityColor( 1 ) ),
		[2] = "|c" .. select( 4, GetItemQualityColor( 2 ) ),
		[3] = "|c" .. select( 4, GetItemQualityColor( 3 ) ),
		[4] = "|c" .. select( 4, GetItemQualityColor( 4 ) ),
		[5] = "|c" .. select( 4, GetItemQualityColor( 5 ) ),
		[6] = "|c" .. select( 4, GetItemQualityColor( 6 ) ),
		[7] = "|c" .. select( 4, GetItemQualityColor( 7 ) ),
	},
};
NS.fontColor = {
	low = ORANGE_FONT_COLOR,
	norm = YELLOW_FONT_COLOR,
	full = { r=0.25, g=0.75, b=0.25 },
	maxFull = GRAY_FONT_COLOR,
	quality = {
		[0] = GetItemQualityColor( 0 ),
		[1] = GetItemQualityColor( 1 ),
		[2] = GetItemQualityColor( 2 ),
		[3] = GetItemQualityColor( 3 ),
		[4] = GetItemQualityColor( 4 ),
		[5] = GetItemQualityColor( 5 ),
		[6] = GetItemQualityColor( 6 ),
		[7] = GetItemQualityColor( 7 ),
	},
};
if not ITEM_QUALITY_COLORS[-1] then
	ITEM_QUALITY_COLORS[-1] = { hex="|cff9d9d9d", r=0, g=0, b=0 };
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Optional Dependency Check - Need at least one loaded
--------------------------------------------------------------------------------------------------------------------------------------------
local addonLoaded = {};
local character = UnitName( "player" );
for i = 1, GetNumAddOns() do
	local name,_,_,loadable = GetAddOnInfo( i );
	if loadable and GetAddOnEnableState( character, i ) > 0 then
		addonLoaded[name] = true;
	end
end
local optAddons = { "Auc-Advanced", "Auctionator", "TradeSkillMaster_AuctionDB" };
for i = 1, #optAddons do
	if TSMAPI_FOUR or addonLoaded[optAddons[i]] then
		break -- Stop checking, we only needed TSM 4 or one enabled
	elseif i == #optAddons then
		table.insert( NS.playerLoginMsg, string.format( L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"], RED_FONT_COLOR_CODE, table.concat( optAddons, ", " ) ) );
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Default SavedVariables/PerCharacter & Upgrade
--------------------------------------------------------------------------------------------------------------------------------------------
NS.DefaultSavedVariables = function()
	return {
		["version"] = NS.version,
		["flyoutPanelOpen"] = true,
		["hideOverpricedStacks"] = true,
		["hideOverstockStacks"] = false,
		["hideUnevenStacks"] = false,
		["hideOneStacks"] = false,
		["itemTooltipShoppingListSettings"] = true,
		["itemTooltipItemId"] = true,
		["showDeleteItemConfirmDialog"] = true,
		["rememberOptionsFramePosition"] = true,
		["optionsFramePosition"] = { "CENTER", 0, 0 },
		["shoppingLists"] = {
			[1] = {
				["name"] = L["Restock Shopping List"],
				["items"] = {},
				["itemValueSrc"] = ( ( TSMAPI_FOUR or addonLoaded["TradeSkillMaster_AuctionDB"] ) and "DBMarket" ) or ( addonLoaded["Auc-Advanced"] and "AucMarket" ) or ( addonLoaded["Auctionator"] and "AtrValue" ) or "DBMarket",
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
				table.remove( NS.db["shoppingLists"], listKey );
			else
				listKey = listKey + 1;
			end
		end
		--
		NS.Sort( NS.db["shoppingLists"], "name", "ASC" );
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
		NS.db["optionsFramePosition"] = vars["optionsFramePosition"]; -- Overwrite possible corrupt position info
	end
	-- 3.5
	if version < 3.5 then
		for listKey, list in ipairs( NS.db["shoppingLists"] ) do
			for itemKey, item in ipairs( NS.db["shoppingLists"][listKey]["items"] ) do
				NS.db["shoppingLists"][listKey]["items"][itemKey]["checked"] = true;
			end
		end
	end
	-- 4.0
	if version < 4.0 then
		for k = 1, #NS.db["shoppingLists"] do
			if NS.db["shoppingLists"][k]["itemValueSrc"] == "wowuctionMarket" then
				NS.db["shoppingLists"][k]["itemValueSrc"] = "DBMarket";
			elseif NS.db["shoppingLists"][k]["itemValueSrc"] == "wowuctionMedian" then
				NS.db["shoppingLists"][k]["itemValueSrc"] = "DBHistorical";
			elseif NS.db["shoppingLists"][k]["itemValueSrc"] == "wowuctionRegionMarket" then
				NS.db["shoppingLists"][k]["itemValueSrc"] = "DBRegionMarketAvg";
			elseif NS.db["shoppingLists"][k]["itemValueSrc"] == "wowuctionRegionMedian" then
				NS.db["shoppingLists"][k]["itemValueSrc"] = "DBRegionHistorical";
			end
		end
	end
	-- 4.7
	if version < 4.7 then
		NS.db["hideUnevenStacks"] = vars["hideUnevenStacks"];
		NS.db["hideOneStacks"] = vars["hideOneStacks"];
	end
	-- 5.3
	if version < 5.3 then
		for i = 1, #NS.db["shoppingLists"] do
			if type( NS.db["shoppingLists"][i]["itemValueSrc"] ) == "table" then
				NS.db["shoppingLists"][i]["itemValueSrc"] = vars["shoppingLists"][1]["itemValueSrc"];
			end
		end
	end
	--
	table.insert( NS.playerLoginMsg, string.format( L["Upgraded version %s to %s"], version, NS.version ) );
	NS.db["version"] = NS.version;
end
--
NS.UpgradePerCharacter = function()
	local vars = NS.DefaultSavedVariablesPerCharacter();
	local version = NS.dbpc["version"];
	--
	-- SVPC version was added in 2.0 which required SVPC to be overwritten with defaults if version was nil
	--
	-- X.x
	--if version < X.x then
		-- Do upgrade
	--end
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
			-- Make sure current list name exists, if not reset to first list
			NS.currentListKey = NS.FindKeyByField( NS.db["shoppingLists"], "name", NS.dbpc["currentListName"] );
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
	NS.tsmPriceSources = ( TSMAPI_FOUR and NS.TSMAPI_FOUR_GetPriceSources() ) or ( not TSMAPI_FOUR and TSMAPI:GetPriceSources() ); -- TSM Price Sources: Load here to avoid missing sources from modules outside of core
	if #NS.playerLoginMsg > 0 then
		for _,msg in ipairs( NS.playerLoginMsg ) do
			NS.Print( msg );
		end
	end
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
		AuctionFrameMoneyFrame:Show();
		AuctionFrameRestockShop:Show();
		--
		RestockShopEventsFrame:RegisterEvent( "UI_ERROR_MESSAGE" );
	elseif AuctionFrameRestockShop:IsShown() then
		AuctionFrameRestockShop:Hide();
	end
end
--
NS.IsTabShown = function()
	if AuctionFrameRestockShop and AuctionFrame:IsShown() and PanelTemplates_GetSelectedTab( AuctionFrame ) == NS.AuctionFrameTab:GetID() then
		return true;
	else
		return false;
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- AuctionFrameRestockShop
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Reset = function( flyoutPanelItem_OnClick )
	RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	NS.scan:Reset(); -- Also Unregisters AUCTION_ITEM_LIST_UPDATE
	wipe( NS.auction.data.raw );
	wipe( NS.auction.data.groups.visible );
	wipe( NS.auction.data.groups.overpriced );
	wipe( NS.auction.data.groups.overstock );
	wipe( NS.auction.data.groups.uneven );
	wipe( NS.auction.data.groups.one );
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = nil;
	NS.auction.selected.auction = nil;
	NS.disableFlyoutChecks = false;
	NS.buyAll = false;
	--
	if AuctionFrame and not NS.IsTabShown() then -- Stop monitoring UI errors, when tab is changed or Auction House closed
		RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
		NS.numAuctionsWon = 0;
		NS.copperAuctionsWon = 0;
	end
	--
	NS.HideAuctionSortButtonArrows();
	AuctionFrameRestockShop_NameSortButton:Click();
	AuctionFrameRestockShop_HideOverpricedStacksButton:Reset();
	AuctionFrameRestockShop_HideOverstockStacksButton:Reset();
	AuctionFrameRestockShop_HideUnevenStacksButton:Reset();
	AuctionFrameRestockShop_HideOneStacksButton:Reset();
	AuctionFrameRestockShop_PauseResumeButton:Reset();
	AuctionFrameRestockShop_ListStatusFrame:Reset();
	AuctionFrameRestockShop_ScrollFrame:Reset(); -- Includes: UpdateTitleText()
	NS.StatusFrame_Message( L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] );
	AuctionFrameRestockShop_ShoppingListsDropDownMenu:Reset( NS.currentListKey );
	AuctionFrameRestockShop_ShopButton:Reset();
	AuctionFrameRestockShop_BuyAllButton:Reset();
	AuctionFrameRestockShop_FlyoutPanel:Reset( flyoutPanelItem_OnClick );
	-- Hide Static Popups
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
	for _,item in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
		local restockPct = NS.RestockPct( NS.QOH( item["link"] ), item["fullStockQty"] );
		if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
			low = low + 1;
		elseif restockPct < 100 then
			norm = norm + 1;
		elseif item["maxPricePct"]["full"] > 0 then
			full = full + 1;
		else
			maxFull = maxFull + 1;
		end
	end
	return string.format( HIGHLIGHT_FONT_COLOR_CODE .. "%d|r " .. NS.colorCode.low .. "(" .. L["Low"] .. ")|r  " .. HIGHLIGHT_FONT_COLOR_CODE .. "%d|r " .. NS.colorCode.norm .. "(" .. L["Norm"] .. ")|r  " .. HIGHLIGHT_FONT_COLOR_CODE .. "%d|r " .. NS.colorCode.full .. "(" .. L["Full"] .. ")|r  " .. HIGHLIGHT_FONT_COLOR_CODE .. "%d|r " .. NS.colorCode.maxFull .. "(" .. L["Full"] .. ")|r", low, norm, full, maxFull );
end
--
NS.StatusFrame_Message = function( text )
	AuctionFrameRestockShop_DialogFrame_StatusFrameText:SetText( text );
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame:Hide();
	AuctionFrameRestockShop_DialogFrame_StatusFrame:Show();
end
--
NS.BuyoutFrame_Activate = function()
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Enable();
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Enable();
	AuctionFrameRestockShop_DialogFrame_StatusFrame:Hide();
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame:Show();
end
--
NS.UpdateTitleText = function()
	local text = {};
	if #NS.auction.data.groups.visible > 0 then
		text[#text + 1] = NS.FormatNum( #NS.auction.data.groups.visible ) .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. L["Results"] .. FONT_COLOR_CODE_CLOSE;
	end
	if NS.numAuctionsWon > 0 then
		text[#text + 1] = NS.numAuctionsWon .. " " .. GREEN_FONT_COLOR_CODE .. ( NS.numAuctionsWon == 1 and L["Buyout"] or L["Buyouts"] ) .. FONT_COLOR_CODE_CLOSE .. " (" .. NS.MoneyToString( NS.copperAuctionsWon, HIGHLIGHT_FONT_COLOR_CODE ) .. ")";
	end
	AuctionFrameRestockShop_TitleText:SetText( table.concat( text, HIGHLIGHT_FONT_COLOR_CODE .. "   " .. FONT_COLOR_CODE_CLOSE ) );
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
NS.HideStacksButton_OnClick = function( button, hide )
	if NS.scan.status == "scanning" or NS.scan.status == "buying" then
		NS.Print( L["Selection ignored, busy scanning or buying"] );
		return; -- Stop function
	end
	--
	if NS.scan.status == "selected" then
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Click();
	end
	-- Show
	NS.AuctionDataGroups_ShowOverpricedStacks();
	NS.AuctionDataGroups_ShowOverstockStacks();
	NS.AuctionDataGroups_ShowUnevenStacks();
	NS.AuctionDataGroups_ShowOneStacks();
	NS.AuctionDataGroups_Sort();
	-- Overpriced
	if hide == "overpriced" then
		if NS.db["hideOverpricedStacks"] then
			NS.db["hideOverpricedStacks"] = false;
			button:UnlockHighlight();
		else
			NS.db["hideOverpricedStacks"] = true;
			button:LockHighlight();
		end
	-- Overstock
	elseif hide == "overstock" then
		if NS.db["hideOverstockStacks"] then
			NS.db["hideOverstockStacks"] = false;
			button:UnlockHighlight();
		else
			NS.db["hideOverstockStacks"] = true;
			button:LockHighlight();
		end
	-- Uneven
	elseif hide == "uneven" then
		if NS.db["hideUnevenStacks"] then
			NS.db["hideUnevenStacks"] = false;
			button:UnlockHighlight();
		else
			NS.db["hideUnevenStacks"] = true;
			button:LockHighlight();
		end
	-- One
	elseif hide == "one" then
		if NS.db["hideOneStacks"] then
			NS.db["hideOneStacks"] = false;
			button:UnlockHighlight();
		else
			NS.db["hideOneStacks"] = true;
			button:LockHighlight();
		end
	end
	-- Hide
	if NS.db["hideOverpricedStacks"] then
		NS.AuctionDataGroups_HideOverpricedStacks();
	end
	--
	if NS.db["hideOverstockStacks"] then
		NS.AuctionDataGroups_HideOverstockStacks();
	end
	--
	if NS.db["hideUnevenStacks"] then
		NS.AuctionDataGroups_HideUnevenStacks();
	end
	--
	if NS.db["hideOneStacks"] then
		NS.AuctionDataGroups_HideOneStacks();
	end
	--
	GameTooltip:SetText( button.tooltip() );
	--
	if next( NS.auction.data.groups.visible ) then
		-- Auctions shown
		if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
			NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
		else
			NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
		end
		AuctionFrameRestockShop_BuyAllButton:Enable();
	elseif next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
		-- Auctions hidden
		NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
		AuctionFrameRestockShop_BuyAllButton:Disable();
	elseif next( NS.scan.items ) then
		-- Auctions scanned, but none available
		NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
		AuctionFrameRestockShop_BuyAllButton:Disable();
	end
	AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 );
	AuctionFrameRestockShop_ScrollFrame:Update();
end
--
NS.AuctionGroup_OnClick = function( groupKey )
	if NS.scan.status == "ready" or NS.scan.status == "selected" or ( not NS.scan.paused and NS.scan.status == "scanning" and NS.scan.type == "SHOP" ) then
		if NS.scan.status == "ready" or NS.scan.status == "selected" then
			-- SELECT
			local auction = CopyTable( NS.auction.data.groups.visible[groupKey]["auctions"][#NS.auction.data.groups.visible[groupKey]["auctions"]] );
			NS.scan.query.page = auction["page"];
			NS.auction.selected.found = false;
			NS.auction.selected.groupKey = groupKey;
			NS.auction.selected.auction = auction;
			if NS.buyAll and groupKey == 1 then
				AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
			end
			AuctionFrameRestockShop_ScrollFrame:Update();
			NS.scan:QueueAddItem( NS.scan.items[NS.auction.data.groups.visible[groupKey]["itemId"]], nil, "SELECT" );
			NS.scan:Start( "SELECT" );
		else
			-- Pause
			AuctionFrameRestockShop_PauseResumeButton:Click();
		end
	elseif NS.scan.status == "buying" then
		NS.Print( L["Selection ignored, buying"] );
	else
		NS.Print( L["Selection ignored, scanning"] );
	end
end
--
NS.AuctionGroup_Deselect = function()
	NS.scan.status = "ready";
	NS.auction.selected.found = false;
	NS.auction.selected.groupKey = nil;
	NS.auction.selected.auction = nil;
	AuctionFrameRestockShop_ScrollFrame:Update();
end
--
NS.FlyoutPanelItem_OnClick = function( itemKey )
	NS.Reset( true );
	local item = CopyTable( NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey] );
	NS.scan:QueueAddItem( item );
	NS.scan:Start( "SHOP" );
end
--
NS.FlyoutPanelSetChecks = function( checked )
	for k = 1, #NS.db["shoppingLists"][NS.currentListKey]["items"] do
		NS.db["shoppingLists"][NS.currentListKey]["items"][k]["checked"] = checked;
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
	NS.AuctionDataGroups_ShowUnevenStacks();
	NS.AuctionDataGroups_ShowOneStacks();
	--
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		if group["itemId"] == NS.auction.selected.auction["itemId"] then
			-- Reindex
			for i = 1, #group["auctions"] do
				local auction = group["auctions"][i];
				-- Greater page
				if auction["page"] > NS.auction.selected.auction["page"] then
					-- Move index only
					if auction["index"] > 1 then
						auction["index"] = auction["index"] - 1;
					-- Move index and page
					else
						auction["index"] = NUM_AUCTION_ITEMS_PER_PAGE;
						auction["page"] = auction["page"] - 1;
					end
				-- Greater index
				elseif auction["page"] == NS.auction.selected.auction["page"] and auction["index"] > NS.auction.selected.auction["index"] then
					auction["index"] = auction["index"] - 1;
				end
			end
			--
			local onHandQty = NS.QOH( group["itemLinkGeneric"] );
			local restockPct = NS.RestockPct( onHandQty, group["fullStockQty"] );
			local pctMaxPrice = math.ceil( ( group["itemPrice"] * 100 ) / NS.MaxPrice( group["itemValue"], restockPct, NS.scan.items[group["itemId"]]["maxPricePct"] ) );
			--
			if restockPct >= 100 and NS.scan.items[group["itemId"]]["maxPricePct"]["full"] == 0 then
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
	--
	if NS.db["hideUnevenStacks"] then
		NS.AuctionDataGroups_HideUnevenStacks();
	end
	--
	if NS.db["hideOneStacks"] then
		NS.AuctionDataGroups_HideOneStacks();
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
	while #NS.auction.data.groups.overpriced > 0 do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overpriced ) );
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
	while #NS.auction.data.groups.overstock > 0 do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.overstock ) );
	end
end
--
NS.AuctionDataGroups_HideUnevenStacks = function()
	-- Remove: If count (i.e. stack size) is not evenly divisible by 5
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside NS.ScanAuctionQueue() just before NS.ScanComplete()
		-- c) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		--
		if group["count"] % 5 > 0 then
			-- Remove and insert
			table.insert( NS.auction.data.groups.uneven, table.remove( NS.auction.data.groups.visible, groupKey ) );
		else
			-- Increment to try the next group
			groupKey = groupKey + 1;
		end
	end
end
--
NS.AuctionDataGroups_ShowUnevenStacks = function()
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	while #NS.auction.data.groups.uneven > 0 do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.uneven ) );
	end
end
--
NS.AuctionDataGroups_HideOneStacks = function()
	-- Remove: If count (i.e. stack size) is 1
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) Inside NS.ScanAuctionQueue() just before NS.ScanComplete()
		-- c) User toggles either Hide button
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.visible do
		local group = NS.auction.data.groups.visible[groupKey];
		--
		if group["count"] == 1 then
			-- Remove and insert
			table.insert( NS.auction.data.groups.one, table.remove( NS.auction.data.groups.visible, groupKey ) );
		else
			-- Increment to try the next group
			groupKey = groupKey + 1;
		end
	end
end
--
NS.AuctionDataGroups_ShowOneStacks = function()
	-- Run this function when:
		-- a) Auction is won (NS.AuctionDataGroups_OnHandQtyChanged)
		-- b) User toggles either Hide button
	while #NS.auction.data.groups.one > 0 do
		-- Remove and insert
		table.insert( NS.auction.data.groups.visible, table.remove( NS.auction.data.groups.one ) );
	end
end
--
NS.AuctionDataGroups_FindGroupKey = function( itemLink, count, itemPrice )
	local groups = NS.auction.data.groups.visible;
	for k = 1, #groups do
		if groups[k]["itemLink"] == itemLink and groups[k]["count"] == count and groups[k]["itemPrice"] == itemPrice then
			return k;
		end
	end
	return nil;
end
--
NS.AuctionDataGroups_RemoveItemId = function( itemId )
	-- This function is run just before raw data from a RESCAN is used to form new data groups, out with the old before in with the new
	-- Also used on Resume from Pause to rescan the item that was Paused
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
	-- One
	local groupKey = 1;
	while groupKey <= #NS.auction.data.groups.one do
		if NS.auction.data.groups.one[groupKey]["itemId"] == itemId then
			-- Match, remove group
			table.remove( NS.auction.data.groups.one, groupKey );
		else
			-- Not a match, increment to try next group
			groupKey = groupKey + 1;
		end
	end
end
--
NS.AuctionDataGroups_ImportRawData = function()
	for itemId, pages in pairs( NS.auction.data.raw ) do -- [ItemId] => [Page] => [Index] => ItemInfo
		for page, indexes in pairs( pages ) do
			for index, itemInfo in pairs( indexes ) do
				local groupKey = NS.AuctionDataGroups_FindGroupKey( itemInfo["itemLink"], itemInfo["count"], itemInfo["itemPrice"] );
				if groupKey then
					-- Add auction to existing group
					table.insert( NS.auction.data.groups.visible[groupKey]["auctions"], itemInfo );
					NS.auction.data.groups.visible[groupKey]["numAuctions"] = NS.auction.data.groups.visible[groupKey]["numAuctions"] + 1;
				else
					-- Add auction to new group
					local onHandQty = NS.QOH( NS.scan.query.item["link"] ); -- Use generic itemLink
					local restockPct = NS.RestockPct( onHandQty, NS.scan.query.item["fullStockQty"] );
					local itemValue = NS.GetItemValue( itemInfo["itemLink"] ); -- use Auction House itemLink
					local maxPrice = NS.MaxPrice( itemValue, restockPct, NS.scan.query.item["maxPricePct"] );
					local pctItemValue = ( itemInfo["itemPrice"] * 100 ) / itemValue;
					local pctMaxPrice = ( itemInfo["itemPrice"] * 100 ) / maxPrice;
					table.insert( NS.auction.data.groups.visible, {
						["restockPct"] = restockPct,
						["name"] = itemInfo["name"],
						["texture"] = itemInfo["texture"],
						["count"] = itemInfo["count"],
						["quality"] = itemInfo["quality"],
						["itemId"] = itemInfo["itemId"],
						["itemLinkGeneric"] = NS.scan.query.item["link"],
						["itemLink"] = itemInfo["itemLink"],
						["itemValue"] = itemValue,
						["itemPrice"] = itemInfo["itemPrice"],
						["pctItemValue"] = pctItemValue,
						["pctMaxPrice"] = pctMaxPrice,
						["onHandQty"] = onHandQty,
						["fullStockQty"] = NS.scan.query.item["fullStockQty"],
						["numAuctions"] = 1,
						["auctions"] = { itemInfo },
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
	if NS.db["hideUnevenStacks"] then
		NS.AuctionDataGroups_HideUnevenStacks();
	end
	--
	if NS.db["hideOneStacks"] then
		NS.AuctionDataGroups_HideOneStacks();
	end
	--
	NS.AuctionDataGroups_Sort();
	-- Cleans page of raw data that was just imported
	wipe( NS.auction.data.raw[NS.scan.query.item["itemId"]] );
end
--
NS.AuctionDataGroups_Sort = function()
	if not next( NS.auction.data.groups.visible ) then return end
	table.sort ( NS.auction.data.groups.visible,
		function ( g1, g2 )
			if g1[NS.auction.data.sortKey] == g2[NS.auction.data.sortKey] then
				if g1["pctItemValue"] ~= g2["pctItemValue"] then
					return g1["pctItemValue"] < g2["pctItemValue"];
				else
					return g1["count"] < g2["count"];
				end
			end
			if NS.auction.data.sortOrder == "ASC" then
				return g1[NS.auction.data.sortKey] < g2[NS.auction.data.sortKey];
			elseif NS.auction.data.sortOrder == "DESC" then
				return g1[NS.auction.data.sortKey] > g2[NS.auction.data.sortKey];
			end
		end
	);
	-- Have to find the groupKey again if you reorder them
	if NS.auction.selected.groupKey then
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemLink"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Scan
--------------------------------------------------------------------------------------------------------------------------------------------
function NS.scan:Reset()
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	self.items = {};
	self.queue = {};
	self.query = {
		item = {},
		page = 0,
		totalPages = 0,
		attempts = 1,
		maxAttempts = 50,
	};
	self.pauseQueue = {};
	self.paused = false;
	self.type = nil;
	self.status = "ready"; -- ready, scanning, selected, buying
	self.ailu = "LISTEN";
end
--
function NS.scan:QueueAddList( queue )
	for _,item in ipairs( NS.db["shoppingLists"][NS.currentListKey]["items"] ) do
		table.insert( queue or self.queue, item );
		self.items[item["itemId"]] = item;
		self.items[item["itemId"]]["scanTexture"] = "Waiting";
	end
	NS.Sort( self.queue, "name", "DESC" ); -- Sort by name Z-A because items are pulled from the end of the queue which will become A-Z
end
--
function NS.scan:QueueAddItem( item, queue, scanType )
	table.insert( queue or self.queue, item );
	local scanTexture;
	if scanType == "SELECT" then
		scanTexture = self.items[item["itemId"]]["scanTexture"];
	else
		scanTexture = "Waiting";
	end
	self.items[item["itemId"]] = item;
	self.items[item["itemId"]]["scanTexture"] = scanTexture;
end
--
function NS.scan:QueueRemoveItem( item, queue )
	local queueKey;
	for i = 1, #queue do
		if queue[i]["itemId"] == item["itemId"] then
			queueKey = i;
			break; -- Stop loop
		end
	end
	if queueKey then
		table.remove( queue, queueKey );
	end
end
--
function NS.scan:Start( type )
	if self.status ~= "ready" and self.status ~= "selected" then return end
	--
	self.status = "scanning";
	self.type = ( function() if type == "SELECT_UPDATE" then return "SELECT"; else return type; end end )();
	AuctionFrameRestockShop_ListStatusFrame:Hide();
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Disable();
	AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Disable();
	AuctionFrameRestockShop_ShopButton:SetText( L["Abort"] );
	AuctionFrameRestockShop_BuyAllButton:Disable();
	if self.type == "SHOP" or self.paused then
		AuctionFrameRestockShop_PauseResumeButton:Enable();
	else
		AuctionFrameRestockShop_PauseResumeButton:Disable();
	end
	--
	if type ~= "SELECT_UPDATE" then
		self:QueueRun(); --QueueRun() not used with SELECT_UPDATE, after buying an auction it's faster to use the AUCTION_ITEM_LIST_UPDATE for our SELECT scan
	end
end
--
function NS.scan:QueueRun()
	if self.status ~= "scanning" then return end
	-- Update FlyoutPanel checks and footer
	if self.type == "SHOP" then
		NS.disableFlyoutChecks = true;
		local footerText = ( function()
			if #self.queue == 0 then
				return NS.ListSummary();
			else
				return string.format( L["%d items remaining"], #self.queue );
			end
		end )();
		AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( footerText );
	end
	-- Scan complete, queue empty
	if #self.queue == 0 then
		self:Complete();
		return; -- Stop function, queue is empty, scan complete
	end
	-- Remove and query last item in the queue
	self.query.item = table.remove( self.queue );
	-- Update scanTexture, Highlight query item, vertical scroll if needed
	AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
	--
	if NS.GetItemValue( self.query.item["link"] ) == 0 then
		-- Skipping: No Item Value
		NS.Print( string.format( L["Skipping %s: %sRequires %s data|r"], self.query.item["link"], RED_FONT_COLOR_CODE, NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) );
		self.items[self.query.item["itemId"]]["scanTexture"] = "NotReady";
		self:QueueRun();
	elseif not self.query.item["checked"] or ( self.query.item["maxPricePct"]["full"] == 0 and NS.QOH( self.query.item["link"] ) >= self.query.item["fullStockQty"] ) then
		-- Skipping: Full Stock reached and no Full price set or unchecked
		self.items[self.query.item["itemId"]]["scanTexture"] = "NotReady";
		self:QueueRun();
	else
		-- OK: QueryPageSend()
		if self.type ~= "SELECT" then
			NS.auction.data.raw[self.query.item["itemId"]] = {}; -- Select scan only reads, but all others need an itemId table to write raw data
			NS.StatusFrame_Message( L["Scanning"] .. " " .. NS.colorCode.quality[self.query.item["quality"]] .. self.query.item["name"] .. FONT_COLOR_CODE_CLOSE );
		end
		self:QueryPageSend();
	end
end
--
function NS.scan:QueryPageSend()
	if self.status ~= "scanning" then return end
	if CanSendAuctionQuery( "list" ) and self.ailu ~= "IGNORE" then
		self.query.attempts = 1; -- Set to default on successful attempt
		local name = self.query.item["name"]; -- self.query.name;
		local page = self.query.page;
		local usable = false;
		local rarity = nil; -- self.query.rarity;
		local getAll = false;
		local exactMatch = false; -- self.query.exactMatch;
		local filterData = nil; -- self.query.filterData;
		local minLevel,maxLevel;
		SortAuctionClearSort( "list" );
		SortAuctionSetSort( "list", "buyout" );
		SortAuctionApplySort( "list" );
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		QueryAuctionItems( name, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData );
	elseif self.query.attempts < self.query.maxAttempts then
		-- Increment attempts, delay and reattempt
		self.query.attempts = self.query.attempts + 1;
		C_Timer.After( 0.10, function() self:QueryPageSend() end );
	else
		-- Aborting scan
		NS.Print( L["Could not query Auction House after several attempts. Please try again later."] );
		NS.Reset();
	end
end
--
function NS.scan:OnAuctionItemListUpdate() -- AUCTION_ITEM_LIST_UPDATE
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	if self.ailu == "AUCTION_WON" then self:AfterAuctionWon(); end
	if self.ailu == "IGNORE" then self.ailu = "LISTEN"; return end
	if self.status ~= "scanning" then return end
	self:QueryPageRetrieve();
end
--
function NS.scan:GetAuctionItemInfo( index )
	local name,texture,count,quality,_,_,_,_,_,buyoutPrice,_,_,_,_,ownerFullName,_,itemId = GetAuctionItemInfo( "list", index );
	local itemLink;
	if itemId == self.query.item["itemId"] and buyoutPrice > 0 and ( not ownerFullName or ownerFullName ~= GetUnitName( "player" ) ) then
		if quality ~= -1 then
			itemLink = GetAuctionItemLink( "list", index ); -- Ignore missing quality (-1) to force retry
		end
		if not itemLink then
			return "retry";
		else
			local itemPrice = math.ceil( buyoutPrice / count );
			itemLink = NS.NormalizeItemLink( itemLink );
			if self.type == "SELECT" then
				if NS.auction.selected.auction["itemLink"] == itemLink and
					NS.auction.selected.auction["count"] == count and
					NS.auction.selected.auction["itemPrice"] == itemPrice
				then
					-- SELECT MATCH FOUND!
					NS.auction.selected.found = true;
					NS.auction.selected.auction["buyoutIndex"] = index; -- Set index for buying
					NS.auction.selected.auction["buyoutPrice"] = buyoutPrice; -- Set again to make sure minor variations in buyoutPrice don't prevent buying the itemPrice selected
					return "found";
				end
			else
				NS.auction.data.raw[itemId][self.query.page][index] = {
					["itemId"] = itemId,
					["name"] = name,
					["texture"] = texture,
					["count"] = count,
					["quality"] = quality,
					["itemPrice"] = itemPrice,
					["buyoutPrice"] = buyoutPrice,
					["itemLink"] = itemLink,
					["page"] = self.query.page,
					["index"] = index,
				};
			end
		end
	end
end
--
function NS.scan:QueryPageRetrieve()
	if self.status ~= "scanning" then return end
	--
	local batchAuctions, totalAuctions = GetNumAuctionItems( "list" );
	self.query.totalPages = ceil( totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE );
	local auctionBatchNum,auctionBatchRetry,NextAuction,PageComplete;
	--
	if self.type ~= "SELECT" then
		NS.auction.data.raw[self.query.item["itemId"]][self.query.page] = {}; -- Create table to store this page of auctions
		NS.StatusFrame_Message( string.format( L["Scanning %s: Page %d of %d"], NS.colorCode.quality[self.query.item["quality"]] .. self.query.item["name"] .. FONT_COLOR_CODE_CLOSE, ( self.query.page + 1 ), self.query.totalPages ) );
	end
	--
	NextAuction = function()
		if self.status ~= "scanning" then return end -- Scan interrupted
		--
		if not auctionBatchRetry.inProgress or ( auctionBatchRetry.inProgress and auctionBatchRetry.auctionBatchNum[auctionBatchNum] ) then -- Not currently retrying or retrying and match
			local get = self:GetAuctionItemInfo( auctionBatchNum );
			if get == "retry" then
				-- Retry required
				if not auctionBatchRetry.inProgress then
					auctionBatchRetry.count = auctionBatchRetry.count + 1;
					auctionBatchRetry.auctionBatchNum[auctionBatchNum] = true;
				end
			else
				if get == "found" then
					--
					-- SELECT MATCH FOUND!!!
					--
					return PageComplete();
				elseif auctionBatchRetry.inProgress then
					-- Retry successful
					auctionBatchRetry.count = auctionBatchRetry.count - 1;
					auctionBatchRetry.auctionBatchNum[auctionBatchNum] = nil;
				end
			end
		end
		-- Batch Complete
		if auctionBatchNum == batchAuctions then
			if auctionBatchRetry.count > 0 and ( not auctionBatchRetry.inProgress or ( auctionBatchRetry.inProgress and auctionBatchRetry.attempts < auctionBatchRetry.attemptsMax ) ) then
				-- Start Batch Retry
				auctionBatchRetry.inProgress = true;
				auctionBatchRetry.attempts = auctionBatchRetry.attempts + 1;
				auctionBatchNum = 1;
				local after = auctionBatchRetry.attempts * 0.01;
				return C_Timer.After( after, NextAuction );
			else
				-- No Batch Retry
				return PageComplete();
			end
		else
			-- Auction Complete
			auctionBatchNum = auctionBatchNum + 1;
			return NextAuction();
		end
	end
	--
	PageComplete = function()
		-- Update auction results
		if self.type ~= "SELECT" then
			NS.AuctionDataGroups_ImportRawData();
			AuctionFrameRestockShop_ScrollFrame:Update();
		end
		-- Paused?
		if self.type == "SHOP" and self.paused then
			NS.StatusFrame_Message( BATTLENET_FONT_COLOR_CODE .. L["Scan paused. You can purchase auctions and resume scanning afterwards"] .. FONT_COLOR_CODE_CLOSE );
			self.type = nil;
			self.status = "ready";
			return; -- Stop function
		end
		-- Page scan complete, query next page unless doing SELECT scan
		if self.type ~= "SELECT" and self.query.page < ( self.query.totalPages - 1 ) then -- Subtract 1 because the first page is 0
			self.query.page = self.query.page + 1; -- Increment to next page
			return self:QueryPageSend(); -- Send query for next page to scan
		else
		-- Item scan completed
			if self.type ~= "SELECT" then
				self.query.page = 0; -- Reset to default
				self.items[self.query.item["itemId"]]["scanTexture"] = "Ready"; -- Green checkmark!
			end
			return self:QueueRun(); -- Return to queue
		end
	end
	--
	if batchAuctions == 0 then
		PageComplete();
	else
		auctionBatchNum = 1;
		auctionBatchRetry = { inProgress = false, count = 0, attempts = 0, attemptsMax = 50, auctionBatchNum = {} };
		NextAuction();
	end
end
--
function NS.scan:Complete()
	self.status = "ready"; -- Set to default status, successful SELECT scans become "selected" below
	--
	if self.type == "SHOP" then
		-- SHOP: Clicked the "Shop" button or clicked on an item in the FlyoutPanel
		if NS.Count( self.items ) > 1 then
			self.query.item = {}; -- Reset to unlock highlight when scanning more than one item
		end
		NS.disableFlyoutChecks = false;
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update(); -- Update scanTexture, Checks and Highlight
		--
		if next( NS.auction.data.groups.visible ) then
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
			else
				NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
			end
			AuctionFrameRestockShop_BuyAllButton:Enable();
		else
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				NS.StatusFrame_Message( L["No auctions were found that matched your settings"] );
			end
		end
	elseif self.type == "SELECT" then
		-- SELECT: If it hasn't found what it was looking for, rescan item. Otherwise, set status to "Selected" and activate buyout frame
		local auction = NS.auction.selected.auction;
		--
		if not NS.auction.selected.found then
			NS.Print( string.format( L["%s%sx%d|r for %s is no longer on page %s"], auction["itemLink"], YELLOW_FONT_COLOR_CODE, auction["count"], NS.MoneyToString( auction["buyoutPrice"], HIGHLIGHT_FONT_COLOR_CODE ), ( auction["page"] + 1 ) ) );
			NS.Print( string.format( L["Rescanning %s"], auction["itemLink"] ) );
			self:RescanItem();
			return; -- Stop function, starting rescan
		end
		--
		self.status = "selected";
		local bfn = "AuctionFrameRestockShop_DialogFrame_BuyoutFrame";
		_G[bfn .. "_ItemIcon"]:SetNormalTexture( auction["texture"] );
		_G[bfn .. "_DescriptionFrameText"]:SetText( NS.colorCode.quality[auction["quality"]] .. auction["name"] .. "|r x " .. auction["count"] );
		MoneyFrame_Update( bfn .. "_SmallMoneyFrame", auction["buyoutPrice"] );
		NS.BuyoutFrame_Activate();
		AuctionFrameRestockShop_BuyAllButton:Enable();
		AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update(); -- Update scanTexture
	elseif self.type == "RESCAN" then
		-- RESCAN: Rescanned the specific item from the selected group. If the group exists after a rescan, then reselect it.
		local auction = NS.auction.selected.auction;
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( auction["itemLink"], auction["count"], auction["itemPrice"] );
		if not NS.auction.selected.groupKey then
			NS.Print( string.format( L["%s%sx%d|r for %s is no longer available"], auction["itemLink"], YELLOW_FONT_COLOR_CODE, auction["count"], NS.MoneyToString( auction["buyoutPrice"], HIGHLIGHT_FONT_COLOR_CODE ) ) );
			AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update(); -- Update scanTexture
			if next( NS.auction.data.groups.visible ) then
				if NS.buyAll then
					NS.AuctionGroup_OnClick( 1 );
				else
					NS.AuctionGroup_Deselect();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
						NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
					end
					AuctionFrameRestockShop_BuyAllButton:Enable();
				end
			else
				NS.AuctionGroup_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				end
				AuctionFrameRestockShop_BuyAllButton:Reset();
			end
		else
			NS.Print( string.format( L["%s%sx%d|r for %s was found!"], auction["itemLink"], YELLOW_FONT_COLOR_CODE, auction["count"], NS.MoneyToString( auction["buyoutPrice"], HIGHLIGHT_FONT_COLOR_CODE ) ) );
			NS.AuctionGroup_OnClick( NS.auction.selected.groupKey );
		end
	end
	--
	if not self.paused then
		AuctionFrameRestockShop_PauseResumeButton:Reset();
		AuctionFrameRestockShop_ShopButton:Reset();
	end
end
--
function NS.scan:RescanItem()
	-- Remove item from pause queue
	if self.paused then
		self:QueueRemoveItem( self.query.item, self.pauseQueue ); -- Try to remove this item from the pause queue, we don't need to scan it again on resume
	end
	-- Remove old result data and rescan item
	NS.AuctionDataGroups_RemoveItemId( self.query.item["itemId"] );
	self.query.page = 0;
	self:QueueAddItem( self.query.item );
	self:Start( "RESCAN" );
end
--
function NS.scan:Pause()
	if #self.queue > 0 or self.query.page < self.query.totalPages then
		self.pauseQueue = CopyTable( self.queue );
		self:QueueAddItem( self.query.item, self.pauseQueue );
		NS.Sort( self.pauseQueue, "name", "DESC" ); -- Sort by name Z-A because items are pulled from the end of the queue which will become A-Z
		self.paused = true;
		--
		wipe( self.queue ); -- Clear queue
	end
end
--
function NS.scan:Resume()
	self.queue = CopyTable( self.pauseQueue ); -- Restore queue
	self.query.page = 0; -- Reset page to default
	--
	-- Remove partial results from the next (last before Pause) item in queue, we're about to rescan it for new data and don't want overlap
	-- Even if the item removed was never scanned at all, because a RescanItem() removed the original, it won't hurt anything to try
	NS.AuctionDataGroups_RemoveItemId( self.queue[#self.queue]["itemId"] ); -- Only removing the AuctionDataGroups, the item is next in queue to be scanned
	--
	wipe( self.pauseQueue ); -- Clear pause queue
	self.paused = false; -- Unpause
	--
	NS.AuctionGroup_Deselect(); -- Deselect any SELECT scans during Pause
	--
	NS.scan:Start( "SHOP" ); -- Resume SHOP scan
end
--
function NS.scan:OnChatMsgSystem( ... ) -- CHAT_MSG_SYSTEM
	local arg1 = select( 1, ... );
	if not arg1 then return end
	if arg1 == ERR_AUCTION_BID_PLACED then
		-- Bid Acccepted.
		self.ailu = "IGNORE"; -- Ignore the list update after "Bid accepted."
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	elseif arg1 == string.format( ERR_AUCTION_WON_S, NS.auction.selected.auction["name"] ) then
		-- You won an auction for %s
		self.ailu = "AUCTION_WON"; -- Helps decide to Ignore or Listen to the list update after "You won an auction for %s"
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	end
end
--
function NS.scan:OnUIErrorMessage( ... ) -- UI_ERROR_MESSAGE
	local arg2 = select( 2, ... );
	if not arg2 then return end
	if self.status ~= "buying" then
		-- Not Buying
		if arg2 == ERR_AUCTION_DATABASE_ERROR then
			NS.Print( RED_FONT_COLOR_CODE .. arg2 .. FONT_COLOR_CODE_CLOSE );
			return NS.Reset(); -- Reset on Internal Auction Error
		else
			return -- Ignore errors unexpected when not buying an auction
		end
	elseif (
		-- Buying
		arg2 ~= ERR_AUCTION_DATABASE_ERROR and
		arg2 ~= ERR_ITEM_NOT_FOUND and
		arg2 ~= ERR_AUCTION_HIGHER_BID and
		arg2 ~= ERR_AUCTION_BID_OWN and
		arg2 ~= ERR_NOT_ENOUGH_MONEY and
		arg2 ~= ERR_RESTRICTED_ACCOUNT and	-- Starter Edition account
		arg2 ~= ERR_ITEM_MAX_COUNT ) then
		return -- Ignore errors unexpected during buying an auction
	end
	--
	-- Handle error expected when buying an auction
	--
	RestockShopEventsFrame:UnregisterEvent( "CHAT_MSG_SYSTEM" );
	self.status = "ready"; -- buying failed
	--
	if arg2 == ERR_ITEM_NOT_FOUND or arg2 == ERR_AUCTION_HIGHER_BID or arg2 == ERR_AUCTION_BID_OWN then
		if arg2 == ERR_ITEM_NOT_FOUND or arg2 == ERR_AUCTION_HIGHER_BID then
			NS.Print( RED_FONT_COLOR_CODE .. L["That auction is no longer available"] .. FONT_COLOR_CODE_CLOSE );
		elseif arg2 == ERR_AUCTION_BID_OWN then
			NS.Print( RED_FONT_COLOR_CODE .. L["That auction belongs to a character on your account"] .. FONT_COLOR_CODE_CLOSE );
		end
		--
		NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] = NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] - 1;
		--
		if NS.auction.data.groups.visible[NS.auction.selected.groupKey]["numAuctions"] == 0 then
			-- Group removed
			table.remove( NS.auction.data.groups.visible, NS.auction.selected.groupKey );
			NS.AuctionGroup_Deselect();
			if next( NS.auction.data.groups.visible ) then
				-- More auctions exist
				if NS.buyAll then
					NS.AuctionGroup_OnClick( 1 );
				else
					AuctionFrameRestockShop_ScrollFrame:Update();
					if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
						NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
					else
						NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
					end
					AuctionFrameRestockShop_BuyAllButton:Enable();
				end
			else
				-- No auctions exist
				AuctionFrameRestockShop_ScrollFrame:Update();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
				else
					NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
				end
				AuctionFrameRestockShop_BuyAllButton:Reset();
			end
		else
			-- Single auction removed
			table.remove( NS.auction.data.groups.visible[NS.auction.selected.groupKey]["auctions"] );
			NS.AuctionGroup_OnClick( NS.auction.selected.groupKey );
		end
	else
		NS.StatusFrame_Message( arg2 );
		AuctionFrameRestockShop_BuyAllButton:Enable();
	end
	--
	AuctionFrameRestockShop_ShopButton:Enable();
end
--
function NS.scan:AfterAuctionWon()
	self.ailu = "IGNORE"; -- Ignore by default, change below where needed.
	--------------------------------------------------------------------------------------------------------------------------------------------
	local function NextAuction( groupKey )
		local auction = CopyTable( NS.auction.data.groups.visible[groupKey]["auctions"][#NS.auction.data.groups.visible[groupKey]["auctions"]] );
		if NS.auction.selected.auction["itemId"] == auction["itemId"] and NS.auction.selected.auction["page"] == auction["page"] then
			--self.query.item = [same item];
			self.query.page = auction["page"];
			NS.auction.selected.found = false;
			NS.auction.selected.groupKey = groupKey;
			NS.auction.selected.auction = auction;
			if NS.buyAll and groupKey == 1 then
				AuctionFrameRestockShop_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
			end
			AuctionFrameRestockShop_ScrollFrame:Update(); -- Highlight the selected group
			self.ailu = "LISTEN";
			self:Start( "SELECT_UPDATE" );
		else
			NS.AuctionGroup_OnClick( groupKey ); -- Item wasn't the same or wasn't on the same page, this will send a new QueryAuctionItems()
		end
	end
	--
	local function NoGroupKey()
		if next( NS.auction.data.groups.visible ) then
			-- More auction exist
			if NS.buyAll then
				NextAuction( 1 );
			else
				NS.AuctionGroup_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Select an auction to buy or click \"Buy All\""] );
				end
				AuctionFrameRestockShop_BuyAllButton:Enable();
			end
		else
			-- No auctions exist
			NS.AuctionGroup_Deselect();
			if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
				NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["No additional auctions matched your settings"] );
			else
				NS.StatusFrame_Message( L["No additional auctions matched your settings"] );
			end
			AuctionFrameRestockShop_BuyAllButton:Reset();
		end
	end
	--------------------------------------------------------------------------------------------------------------------------------------------
	local group = NS.auction.data.groups.visible[NS.auction.selected.groupKey];
	-- Update buyouts and money spent
	NS.numAuctionsWon = NS.numAuctionsWon + 1;
	NS.copperAuctionsWon = NS.copperAuctionsWon + NS.auction.selected.auction["buyoutPrice"];
	-- Full Stock notice
	if group["onHandQty"] < group["fullStockQty"] and ( group["onHandQty"] + group["count"] ) >= group["fullStockQty"] then
		NS.Print( string.format( L["You reached the %sFull Stock|r of %s%d|r on %s"], NORMAL_FONT_COLOR_CODE, NS.colorCode.full, group["fullStockQty"], group["itemLinkGeneric"] ) );
	end
	--
	self.status = "ready"; -- buying completed
	AuctionFrameRestockShop_ShopButton:Enable();
	--
	group["numAuctions"] = group["numAuctions"] - 1;
	--
	if group["numAuctions"] == 0 then
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
		table.remove( group["auctions"] );
		NS.AuctionDataGroups_OnHandQtyChanged();
		NS.auction.selected.groupKey = NS.AuctionDataGroups_FindGroupKey( NS.auction.selected.auction["itemLink"], NS.auction.selected.auction["count"], NS.auction.selected.auction["itemPrice"] );
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
--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------------------------------------------------------------------
NS.AddTooltipData = function( self, ... )
	if ( not NS.db["itemTooltipShoppingListSettings"] and not NS.db["itemTooltipItemId"] ) or NS.tooltipAdded then return end
	-- Get Item Id
	local itemName, itemLink = self:GetItem();
	local itemId = itemLink and tonumber( string.match( itemLink, "item:(%d+):" ) ) or nil;
	if not itemId then return end
	-- Header
	self:AddLine( YELLOW_FONT_COLOR_CODE .. NS.title .. ":|r" );
	-- Shopping List Settings
	if NS.db["itemTooltipShoppingListSettings"] then
		local itemKey = NS.FindItemKey( itemId );
		if itemKey then
			--
			-- Item found in current shopping list, show settings
			--
			-- Prepare and format settings
			local item = NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey];
			local itemValue = NS.GetItemValue( item["link"] );
			local onHandQty = NS.QOH( item["link"] );
			local restockPct = NS.RestockPct( onHandQty, item["fullStockQty"] );
			local restockColor = NS.RestockColor( "code", restockPct, item["maxPricePct"] );
			local maxPrice,status = NS.MaxPrice( itemValue, restockPct, item["maxPricePct"] );
			maxPrice = maxPrice == 0 and "" or NS.MoneyToString( maxPrice, HIGHLIGHT_FONT_COLOR_CODE ) .. " "; -- If full stock and no full price then leave it blank
			status = restockColor .. L[status] .. FONT_COLOR_CODE_CLOSE;
			restockPct = restockColor .. math.floor( restockPct ) .. "%" .. FONT_COLOR_CODE_CLOSE;
			local maxRestockCost;
			if itemValue == 0 then
				itemValue,maxPrice = nil,nil;
			else
				itemValue = NS.MoneyToString( itemValue, HIGHLIGHT_FONT_COLOR_CODE );
				maxRestockCost = NS.MaxRestockItemInfo( item );
				maxRestockCost = maxRestockCost == 0 and ( NS.colorCode.tooltip .. "(|r" .. status .. NS.colorCode.tooltip .. ")|r" ) or NS.MoneyToString( maxRestockCost, HIGHLIGHT_FONT_COLOR_CODE );
			end
			-- Add lines to tooltip
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["List"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. NS.db["shoppingLists"][NS.currentListKey]["name"] );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["On Hand"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. onHandQty .. "|r " .. NS.colorCode.tooltip .. "(|r" .. restockPct .. NS.colorCode.tooltip .. ")|r" );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Full Stock"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. item["fullStockQty"] );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Low"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. item["maxPricePct"]["low"] .. "%" );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Norm"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. item["maxPricePct"]["normal"] .. "%" );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Full"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. ( ( item["maxPricePct"]["full"] > 0 ) and ( item["maxPricePct"]["full"] .. "%" ) or "-" ) );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Item Value"] .. ":|r " .. ( itemValue and ( itemValue .. " " .. NS.colorCode.tooltip .. "(" .. NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] .. ")|r" ) or ( RED_FONT_COLOR_CODE .. string.format( L["Requires %s Data"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) .. FONT_COLOR_CODE_CLOSE ) ) );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Max Price"] .. ":|r " .. ( maxPrice and ( maxPrice .. NS.colorCode.tooltip .. "(|r" .. status .. NS.colorCode.tooltip .. ")|r"  ) or ( RED_FONT_COLOR_CODE .. L["Requires Item Value"] .. FONT_COLOR_CODE_CLOSE ) ) );
			self:AddLine( "  " .. NS.colorCode.tooltip .. L["Max Restock Cost"] .. ":|r " .. ( maxRestockCost and maxRestockCost or ( RED_FONT_COLOR_CODE .. L["Requires Item Value"] .. FONT_COLOR_CODE_CLOSE ) ) );
		end
	end
	-- Item Id
	if NS.db["itemTooltipItemId"] then
		-- Add line to tooltip
		self:AddLine( "  " .. NS.colorCode.tooltip .. L["Item ID"] .. ":|r " .. HIGHLIGHT_FONT_COLOR_CODE .. itemId );
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
NS.FindItemKey = function( itemId, shoppingList )
	shoppingList = shoppingList or NS.currentListKey;
	for k = 1, #NS.db["shoppingLists"][shoppingList]["items"] do
		if NS.db["shoppingLists"][shoppingList]["items"][k]["itemId"] == itemId then
			return k;
		end
	end
	return nil;
end
--
NS.QOH = function( itemLinkGeneric )
	local qoh = 0;
	local currentPlayerTotal, otherPlayersTotal, allPlayersAuctionsTotal, otherPlayersAuctionsTotal = ( function()
			if TSMAPI_FOUR then
				return TSMAPI_FOUR.Inventory.GetPlayerTotals( itemLinkGeneric );
			else
				return TSMAPI.Inventory:GetPlayerTotals( itemLinkGeneric );
			end
	end )(); -- numPlayer, numAlts, numAuctions, numAltAuctions
	if NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 1 then
		-- All Characters
		qoh = qoh + currentPlayerTotal + otherPlayersTotal + allPlayersAuctionsTotal;
		if NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] then
			local guildTotal = ( TSMAPI_FOUR and TSMAPI_FOUR.Inventory.GetGuildTotal( itemLinkGeneric ) ) or ( not TSMAPI_FOUR and TSMAPI.Inventory:GetGuildTotal( itemLinkGeneric ) ); -- Guild Bank(s)
			qoh = qoh + guildTotal;
		end
	elseif NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 2 then
		-- Current Character
		qoh = qoh + currentPlayerTotal + ( allPlayersAuctionsTotal - otherPlayersAuctionsTotal );
		if NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] then
			local guildBank = ( TSMAPI_FOUR and TSMAPI_FOUR.Inventory.GetGuildQuantity( itemLinkGeneric ) ) or ( not TSMAPI_FOUR and TSMAPI.Inventory:GetGuildQuantity( itemLinkGeneric ) ); -- Guild Bank
			qoh = qoh + guildBank;
		end
	end
	return qoh;
end
--
NS.RestockPct = function( onHandQty, fullStockQty )
	return ( onHandQty * 100 ) / fullStockQty;
end
--
NS.MaxPrice = function( itemValue, restockPct, maxPricePct )
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
	return maxPrice, status;
end
--
NS.GetItemValue = function( itemLink )
	local source = NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"];
	return ( NS.tsmPriceSources[source] and ( ( TSMAPI_FOUR and TSMAPI_FOUR.CustomPrice.GetItemPrice( itemLink, source ) ) or ( not TSMAPI_FOUR and TSMAPI:GetItemValue( itemLink, source ) ) or 0 ) ) or ( TSMAPI_FOUR and TSMAPI_FOUR.CustomPrice.GetValue( source, itemLink ) ) or ( not TSMAPI_FOUR and TSMAPI:GetCustomPriceValue( source, itemLink ) ) or 0;
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
--
NS.AddItemToList = function( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, texture, shoppingList )
	shoppingList = shoppingList or NS.currentListKey;
	--
	if fullStockQty < 1 or lowStockPrice < 1 or normalStockPrice < 1 or lowStockPrice < normalStockPrice or normalStockPrice < fullStockPrice then
		return nil;
	else
		local itemKey = NS.FindItemKey( itemId, shoppingList );
		local checked = true; -- Default
		local which = itemKey and "updated" or "added";
		--
		if not itemKey then
			itemKey = #NS.db["shoppingLists"][shoppingList]["items"] + 1;
		else
			checked = NS.db["shoppingLists"][shoppingList]["items"][itemKey]["checked"];
		end
		--
		local itemInfo = {
			["itemId"] = itemId,
			["name"] = name,
			["link"] = link,
			["quality"] = quality,
			["texture"] = texture,
			["fullStockQty"] = fullStockQty,
			["maxPricePct"] = {
				["low"] = lowStockPrice,
				["normal"] = normalStockPrice,
				["full"] = fullStockPrice
			},
			["checked"] = checked,
		};
		NS.db["shoppingLists"][shoppingList]["items"][itemKey] = itemInfo;
		NS.Sort( NS.db["shoppingLists"][shoppingList]["items"], "name", "ASC" );
		--
		return which;
	end
end
--
NS.NormalizeItemLink = function( itemLink )
	local itemString = string.match( itemLink, "item[%-?%d:]+" );
	local itemStringPieces = {};
	for piece in string.gmatch( itemString, "([^:]*):?" ) do
		if #itemStringPieces == 8 then
			piece = ""; -- uniqueID - Data pertaining to a specific instance of the item.
		end
		itemStringPieces[#itemStringPieces + 1] = piece;
	end
	if not string.match( itemString, ":$" ) then
		itemStringPieces[#itemStringPieces] = nil;
	end
	itemString = table.concat( itemStringPieces, ":" );
	return string.gsub( itemLink, "item[%-?%d:]+", itemString );
end
--
NS.MaxRestockItemInfo = function( item )
	local onHandQty = NS.QOH( item["link"] );
	--
	if onHandQty < item["fullStockQty"] then
		local itemValue = NS.GetItemValue( item["link"] );
		--
		local normStockQty = math.ceil( ( item["fullStockQty"] * NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] ) / 100 );
		local lowCount = onHandQty < normStockQty and normStockQty - onHandQty or 0;
		local normalCount = item["fullStockQty"] - onHandQty - lowCount;
		--
		if itemValue == 0 then
			return 0,lowCount,normalCount,onHandQty,item["fullStockQty"]; -- Return: Shortage but cost unknown
		end
		--
		local lowPrice = math.ceil( ( itemValue * item["maxPricePct"]["low"] ) / 100 );
		local normalPrice = math.ceil( ( itemValue * item["maxPricePct"]["normal"] ) / 100 );
		local cost = ( lowCount * lowPrice ) + ( normalCount * normalPrice );
		return cost,lowCount,normalCount,onHandQty,item["fullStockQty"]; -- Return: Shortage
	else
		return 0,0,0,onHandQty,item["fullStockQty"]; -- Return: No Shortage
	end
end
--
NS.MaxRestockListInfo = function()
	local items = NS.db["shoppingLists"][NS.currentListKey]["items"];
	local listCost,listLowCount,listNormalCount,listOnHandQty,listFullStockQty = 0,0,0,0,0;
	for i = 1, #items do
		local cost,lowCount,normalCount,onHandQty,fullStockQty = NS.MaxRestockItemInfo( items[i] );
		listCost = listCost + cost;
		listLowCount = listLowCount + lowCount;
		listNormalCount = listNormalCount + normalCount;
		listOnHandQty = listOnHandQty + onHandQty;
		listFullStockQty = listFullStockQty + fullStockQty;
	end
	return listCost,listLowCount,listNormalCount,listOnHandQty,listFullStockQty;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- TSMAPI_FOUR
--------------------------------------------------------------------------------------------------------------------------------------------
NS.TSMAPI_FOUR_GetPriceSources = function()
	local t = {};
	for source, moduleName, label in TSMAPI_FOUR.CustomPrice.Iterator() do
		t[source] = label;
	end
	return t;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------------------------------------------------------------------
NS.SlashCmdHandler = function( msg )
	if msg == "acceptbuttonclick" and NS.IsTabShown() then
		AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Click();
		return; -- Stop function
	end
	-- Switch to "Browse" AuctionFrame tab
	if NS.IsTabShown() then
		AuctionFrameTab1:Click();
	end
	-- Open an options frame tab
	if msg == "" or msg == "sl" or msg == "shoppinglists" then
		NS.options.MainFrame:ShowTab( 1 );
	elseif msg == "moreoptions" then
		NS.options.MainFrame:ShowTab( 2 );
	elseif msg == "glossary" then
		NS.options.MainFrame:ShowTab( 3 );
	elseif msg == "help" then
		NS.options.MainFrame:ShowTab( 4 );
	else
		NS.options.MainFrame:ShowTab( 4 );
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
NS.TextFrame( "Text", RestockShopInterfaceOptionsPanel, L["Use either slash command /rs or /restockshop"], {
	setAllPoints = true,
	setPoint = { "TOPLEFT", 16, -16 },
	justifyV = "TOP",
} );
--------------------------------------------------------------------------------------------------------------------------------------------
-- "RestockShop" AuctionFrame Tab (AuctionFrameRestockShop)
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Blizzard_AuctionUI_OnLoad = function()
	if AuctionFrameRestockShop then return end -- Make absolute sure this code only runs once
	--
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
			{ "TOPLEFT", 74, -24 },
			{ "RIGHT", -20, 0 },
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
		update = {
			numToDisplay = 14,
			buttonHeight = 20,
			UpdateFunction = function( sf )
				local items = NS.auction.data.groups.visible;
				local numItems = #items;
				FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight );
				local offset = FauxScrollFrame_GetOffset( sf );
				for num = 1, sf.numToDisplay do
					local bn = sf.buttonName .. num; -- button name
					local b = _G[bn]; -- button
					local k = offset + num; -- key
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
						if items[k]["pctMaxPrice"] > 100 then _G[bn .. "_PctItemValue"]:SetText( RED_FONT_COLOR_CODE .. _G[bn .. "_PctItemValue"]:GetText() .. FONT_COLOR_CODE_CLOSE ); end
						b:Show();
						if IsHighlightLocked() then b:LockHighlight(); end
					else
						b:Hide();
					end
				end
				--
				NS.UpdateTitleText();
			end
		},
	} );
	NS.TextFrame( "_ListStatusFrame", AuctionFrameRestockShop, "", {
		hidden = true,
		size = { 733, ( 334 - 22 ) },
		setPoint = { "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT" },
		fontObject = "GameFontHighlightLarge",
		justifyH = "CENTER",
		OnLoad = function( self )
			function self:Reset()
				_G[self:GetName() .. "Text"]:SetText( string.format( "%s\n\n%s   =   %s%d|r", NS.db["shoppingLists"][NS.currentListKey]["name"], NS.ListSummary(), NORMAL_FONT_COLOR_CODE, #NS.db["shoppingLists"][NS.currentListKey]["items"] ) );
				self:Show();
			end
		end,
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
				NS.AuctionGroup_Deselect();
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
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
			if NS.scan.status == "selected" then
				NS.scan.status = "buying";
				AuctionFrameRestockShop_DialogFrame_BuyoutFrame_AcceptButton:Disable();
				AuctionFrameRestockShop_DialogFrame_BuyoutFrame_CancelButton:Disable();
				AuctionFrameRestockShop_ShopButton:Disable();
				AuctionFrameRestockShop_BuyAllButton:Disable();
				RestockShopEventsFrame:RegisterEvent( "CHAT_MSG_SYSTEM" );
				PlaceAuctionBid( "list", NS.auction.selected.auction["buyoutIndex"], NS.auction.selected.auction["buyoutPrice"] );
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
				if next( NS.auction.data.groups.overpriced ) or next( NS.auction.data.groups.overstock ) or next( NS.auction.data.groups.uneven ) or next( NS.auction.data.groups.one ) then
					NS.StatusFrame_Message( L["Hidden auctions available."] .. " " .. L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
				else
					NS.StatusFrame_Message( L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
				end
				NS.AuctionGroup_Deselect();
			else
				NS.buyAll = true;
				self:SetText( L["Stop"] );
				NS.StatusFrame_Message( L["Scanning"] .. "..." );
				NS.AuctionGroup_OnClick( 1 );
			end
		end,
		OnLoad = function( self )
			function self:Reset()
				NS.buyAll = false;
				self:Disable();
				self:SetText( L["Buy All"] );
			end
		end,
	} );
	NS.Button( "_ShopButton", AuctionFrameRestockShop, L["Shop"], {
		size = { 80, 22 },
		setPoint = { "RIGHT", "#sibling", "LEFT" },
		OnClick = function( self )
			if not NS.scan.paused and ( NS.scan.status == "ready" or NS.scan.status == "selected" ) then
				-- Shop
				NS.Reset(); -- Resetting for fresh SHOP scan
				NS.scan:QueueAddList();
				NS.scan:Start( "SHOP" );
			else
				-- Abort
				NS.Reset();
			end
		end,
		OnLoad = function( self )
			function self:Reset()
				self:Enable();
				self:SetText( L["Shop"] );
			end
		end,
	} );
	NS.DropDownMenu( "_ShoppingListsDropDownMenu", AuctionFrameRestockShop, {
		setPoint = { "RIGHT", "#sibling", "LEFT", 15, -2 },
		buttons = function()
			local t = {};
			for i, list in ipairs( NS.db["shoppingLists"] ) do
				tinsert( t, { list["name"], i } );
			end
			return t;
		end,
		tooltip = function()
			local maxRestockCost,maxRestockLowCount,maxRestockNormalCount,maxRestockOnHandQty,maxRestockFullStockQty = NS.MaxRestockListInfo();
			local fullStockShortage = NS.FormatNum( maxRestockLowCount + maxRestockNormalCount );
			maxRestockCost = fullStockShortage == "0" and ( HIGHLIGHT_FONT_COLOR_CODE .. "(" .. L["Full"] .. ")" .. FONT_COLOR_CODE_CLOSE ) or NS.MoneyToString( maxRestockCost, HIGHLIGHT_FONT_COLOR_CODE );
			--
			GameTooltip:AddLine( HIGHLIGHT_FONT_COLOR_CODE .. NS.db["shoppingLists"][NS.currentListKey]["name"] .. FONT_COLOR_CODE_CLOSE );
			GameTooltip:AddDoubleLine( L["Item Value Source"] .. ": ", HIGHLIGHT_FONT_COLOR_CODE .. NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] .. FONT_COLOR_CODE_CLOSE );
			GameTooltip:AddDoubleLine( L["On Hand Tracking"] .. ": ", HIGHLIGHT_FONT_COLOR_CODE .. ( NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] == 1 and L["All Characters"] or L["Current Character"] ) .. " (" .. ( NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] == true and  L["including Guilds"] or L["not including Guilds"] ) .. ")|r" );
			GameTooltip:AddDoubleLine( NS.colorCode.low .. L["Low Stock %"] .. ":|r ", HIGHLIGHT_FONT_COLOR_CODE .. NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] .. "%|r" );
			GameTooltip:AddDoubleLine( NS.colorCode.full .. L["Hide Overstock Stacks %"] .. ":|r ", HIGHLIGHT_FONT_COLOR_CODE .. "(" .. ( NS.db["hideOverstockStacks"] and L["ON"] or L["OFF"] ) .. ") " .. NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] .. "%|r" );
			GameTooltip:AddDoubleLine( L["Full Stock"] .. ": ",  HIGHLIGHT_FONT_COLOR_CODE .. NS.FormatNum( maxRestockFullStockQty ) .. FONT_COLOR_CODE_CLOSE );
			GameTooltip:AddDoubleLine( L["Full Stock Shortage"] .. ": ",  HIGHLIGHT_FONT_COLOR_CODE .. fullStockShortage .. FONT_COLOR_CODE_CLOSE );
			GameTooltip:AddDoubleLine( L["Max Restock Cost"] .. ": ", maxRestockCost );
			return nil;
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
		bg = { "Interface\\FrameGeneral\\UI-Background-Marble", true, true },
		OnLoad = function( self )
			function self:Reset( flyoutPanelItem_OnClick )
				self.TitleText:SetText( NS.db["shoppingLists"][NS.currentListKey]["name"] );
				if not flyoutPanelItem_OnClick then
					AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when Reset() does NOT originate from clicking item in FlyoutPanel
				end
				AuctionFrameRestockShop_FlyoutPanel_ScrollFrame:Update();
				AuctionFrameRestockShop_FlyoutPanel_FooterText:SetText( NS.ListSummary() );
				--
				if NS.db["flyoutPanelOpen"] and not self:IsShown() then
					self:Show();
				elseif not NS.db["flyoutPanelOpen"] and self:IsShown() then
					self:Hide();
				end
			end
			self.TitleText:SetWordWrap( false );
			self.TitleText:SetPoint( "LEFT", 4, 0 );
			self.TitleText:SetPoint( "RIGHT", -28, 0 );
			self.TitleText:SetText( L["Shop Filters"] );
			self.CloseButton:SetScript( "OnClick", function( self )
				self:GetParent().FlyoutPanelButton:Click();
			end );
		end,
		OnShow = function( self )
			self.FlyoutPanelButton:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
			self.FlyoutPanelButton:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
		end,
		OnHide = function( self )
			self.FlyoutPanelButton:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" );
			self.FlyoutPanelButton:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down" );
		end,
	} );
	NS.ScrollFrame( "_ScrollFrame", AuctionFrameRestockShop_FlyoutPanel, {
		size = { 242, ( 20 * 17 - 5 ) },
		setPoint = { "TOPLEFT", 1, -27 },
		buttonTemplate = "AuctionFrameRestockShop_FlyoutPanel_ScrollFrameButtonTemplate",
		update = {
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
				if NS.scan.status == "scanning" and NS.scan.type == "SHOP" and NS.Count( NS.scan.items ) > 1 then
					local vScroll = ( numItems - #NS.scan.queue - sf.numToDisplay ) * sf.buttonHeight;
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
							if ( NS.scan.type == "SHOP" or NS.Count( NS.scan.items ) == 1 ) and NS.scan.query.item["itemId"] == items[k]["itemId"] then
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
						local onHandQty = NS.QOH( items[k]["link"] );
						local restockPct = NS.RestockPct( onHandQty, items[k]["fullStockQty"] );
						local restockStatus;
						if restockPct < NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] then
							restockStatus = NS.colorCode.low .. L["Low"] .. FONT_COLOR_CODE_CLOSE;
						elseif restockPct < 100 then
							restockStatus = NS.colorCode.norm .. L["Norm"] .. FONT_COLOR_CODE_CLOSE;
						elseif items[k]["maxPricePct"]["full"] > 0 then
							restockStatus = NS.colorCode.full .. L["Full"] .. FONT_COLOR_CODE_CLOSE;
						else
							restockStatus = NS.colorCode.maxFull .. L["Full"] .. FONT_COLOR_CODE_CLOSE;
						end
						_G[bn .. "_RestockStatus"]:SetText( restockStatus );
						--
						local scanTexture;
						if not NS.scan.items[items[k]["itemId"]] then
							scanTexture = "Waiting";
						else
							scanTexture = NS.scan.items[items[k]["itemId"]]["scanTexture"];
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
			if self.FlyoutPanel:IsShown() then
				self.FlyoutPanel:Hide();
				NS.db["flyoutPanelOpen"] = false;
			else
				self.FlyoutPanel:Show();
				NS.db["flyoutPanelOpen"] = true;
			end
		end,
		OnLoad = function( self )
			self.FlyoutPanel = _G[self:GetParent():GetName() .. "_FlyoutPanel"];
			self.FlyoutPanel.FlyoutPanelButton = self;
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
			if not NS.db["hideOverpricedStacks"] or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			elseif NS.scan.status == "scanning" then
				return tooltip .. "\n\n" .. RED_FONT_COLOR_CODE .. L["Scanning..."] .. FONT_COLOR_CODE_CLOSE;
			else
				local numAuctions = 0;
				for _,group in ipairs( NS.auction.data.groups.overpriced ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
				return tooltip .. "\n\n" .. RED_FONT_COLOR_CODE .. string.format( L["%d Auctions Hidden"], numAuctions ) .. FONT_COLOR_CODE_CLOSE;
			end
		end,
		OnClick = function ( self )
			NS.HideStacksButton_OnClick( self, "overpriced" );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
			function self:Reset()
				if NS.db["hideOverpricedStacks"] then
					self:LockHighlight();
				end
			end
			self:GetNormalTexture():SetVertexColor( 1.0, 0.1, 0.1 );
			self:GetPushedTexture():SetVertexColor( 1.0, 0.1, 0.1 );
			self:GetHighlightTexture():SetVertexColor( 1.0, 0.1, 0.1 );
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
			if not NS.db["hideOverstockStacks"] or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			elseif NS.scan.status == "scanning" then
				return tooltip .. "\n\n" .. NS.colorCode.full .. L["Scanning..."] .. FONT_COLOR_CODE_CLOSE;
			else
				local numAuctions = 0;
				for _,group in ipairs( NS.auction.data.groups.overstock ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
				return tooltip .. "\n\n" .. NS.colorCode.full .. string.format( L["%d Auctions Hidden"], numAuctions ) .. FONT_COLOR_CODE_CLOSE;
			end
		end,
		OnClick = function ( self )
			NS.HideStacksButton_OnClick( self, "overstock" );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
			function self:Reset()
				if NS.db["hideOverstockStacks"] then
					self:LockHighlight();
				end
			end
			self:GetNormalTexture():SetVertexColor( 0.25, 0.75, 0.25 );
			self:GetPushedTexture():SetVertexColor( 0.25, 0.75, 0.25 );
			self:GetHighlightTexture():SetVertexColor( 0.25, 0.75, 0.25 );
		end,
	} );
	NS.Button( "_HideUnevenStacksButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 32, 32 },
		setPoint = { "TOP", "#sibling", "BOTTOM", 0, -3 },
		normalTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Up",
		pushedTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Down",
		highlightTexture = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
		tooltip = function()
			local tooltip =  string.format( L["%sHide Uneven Stacks|r\n\nHides auctions not evenly divisible by 5\nShow only stacks of 5, 10, 15, 20, etc."], NS.colorCode.norm );
			if not NS.db["hideUnevenStacks"] or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			elseif NS.scan.status == "scanning" then
				return tooltip .. "\n\n" .. NS.colorCode.norm .. L["Scanning..."] .. FONT_COLOR_CODE_CLOSE;
			else
				local numAuctions = 0;
				for _,group in ipairs( NS.auction.data.groups.uneven ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
				return tooltip .. "\n\n" .. NS.colorCode.norm .. string.format( L["%d Auctions Hidden"], numAuctions ) .. FONT_COLOR_CODE_CLOSE;
			end
		end,
		OnClick = function ( self )
			NS.HideStacksButton_OnClick( self, "uneven" );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
			function self:Reset()
				if NS.db["hideUnevenStacks"] then
					self:LockHighlight();
				end
			end
			self:GetNormalTexture():SetVertexColor( 1.0, 1.0, 0.0 );
			self:GetPushedTexture():SetVertexColor( 1.0, 1.0, 0.0 );
			self:GetHighlightTexture():SetVertexColor( 1.0, 1.0, 0.0 );
		end,
	} );
	NS.Button( "_HideOneStacksButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 32, 32 },
		setPoint = { "TOP", "#sibling", "BOTTOM", 0, -3 },
		normalTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Up",
		pushedTexture = "Interface\\FriendsFrame\\UI-FriendsList-Large-Down",
		highlightTexture = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
		tooltip = function()
			local tooltip =  string.format( L["%sHide One Stacks|r\n\nHides auctions with a stack size of 1"], NS.colorCode.low );
			if not NS.db["hideOneStacks"] or AuctionFrameRestockShop_ListStatusFrame:IsShown() then
				return tooltip;
			elseif NS.scan.status == "scanning" then
				return tooltip .. "\n\n" .. NS.colorCode.low .. L["Scanning..."] .. FONT_COLOR_CODE_CLOSE;
			else
				local numAuctions = 0;
				for _,group in ipairs( NS.auction.data.groups.one ) do
					numAuctions = numAuctions + group["numAuctions"];
				end
				return tooltip .. "\n\n" .. NS.colorCode.low .. string.format( L["%d Auctions Hidden"], numAuctions ) .. FONT_COLOR_CODE_CLOSE;
			end
		end,
		OnClick = function ( self )
			NS.HideStacksButton_OnClick( self, "one" );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
			function self:Reset()
				if NS.db["hideOneStacks"] then
					self:LockHighlight();
				end
			end
			self:GetNormalTexture():SetVertexColor( 1.0, 0.5, 0.25 );
			self:GetPushedTexture():SetVertexColor( 1.0, 0.5, 0.25 );
			self:GetHighlightTexture():SetVertexColor( 1.0, 0.5, 0.25 );
		end,
	} );
	NS.Button( "_PauseResumeButton", AuctionFrameRestockShop, nil, {
		template = false,
		size = { 32, 32 },
		setPoint = { "TOP", "#sibling", "BOTTOM", 0, -3 },
		disabledTexture = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		normalTexture = "Interface\\TimeManager\\PauseButton",
		highlightTexture = "Interface\\Buttons\\UI-Common-MouseHilight",
		tooltip = function()
			if not NS.scan.paused then
				return BATTLENET_FONT_COLOR_CODE .. L["Pause"] .. "|r\n\n" .. L["You may pause your scan to purchase\nauctions and resume scanning afterwards"];
			else
				return BATTLENET_FONT_COLOR_CODE .. L["Resume"] .. "|r\n\n" .. L["You may resume scanning when you're ready"];
			end
		end,
		OnClick = function( self )
			if not NS.scan.paused then
				-- Pause
				self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" );
				self:LockHighlight();
				NS.scan:Pause();
			else
				-- Resume
				self:SetNormalTexture( "Interface\\TimeManager\\PauseButton" );
				self:UnlockHighlight();
				NS.scan:Resume();
			end
			GameTooltip:SetText( self.tooltip() );
		end,
		OnLoad = function( self )
			self.tooltipAnchor = { self, "ANCHOR_BOTTOMRIGHT", 3, 32 };
			function self:Reset()
				self:Disable();
				self:SetNormalTexture( "Interface\\TimeManager\\PauseButton" );
				self:UnlockHighlight();
			end
		end,
	} );
	-- Add "RestockShop" tab to AuctionFrame
	local numTab = AuctionFrame.numTabs + 1;
	NS.AuctionFrameTab = NS.Button( "AuctionFrameTab" .. numTab, AuctionFrame, NS.title, {
		topLevel = true,
		template = "AuctionTabTemplate",
		setPoint = { "LEFT", "AuctionFrameTab" .. ( numTab - 1 ), "RIGHT", -8, 0 },
		OnLoad = function( self )
			self:SetID( numTab );
		end,
	} );
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
			elseif	event == "AUCTION_ITEM_LIST_UPDATE"	then	NS.scan:OnAuctionItemListUpdate();
			elseif	event == "CHAT_MSG_SYSTEM"			then	NS.scan:OnChatMsgSystem( ... );
			elseif	event == "UI_ERROR_MESSAGE"			then	NS.scan:OnUIErrorMessage( ... );
		end
	end,
	OnLoad = function( self )
		self:RegisterEvent( "ADDON_LOADED" );
		self:RegisterEvent( "PLAYER_LOGIN" );
	end,
} );
