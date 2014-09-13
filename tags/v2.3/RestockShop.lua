--------------------------------------------------------------------------------------------------------------------------------------------
-- Change Log
--------------------------------------------------------------------------------------------------------------------------------------------
--[[

**2.3**
* Release date: 09/13/2014
* Bug fix, closing AH with BuyAll enabled caused LUA error

**2.2**
* Release date: 09/12/2014
* Fixed minor display bug with Flyout Panel highlighting

**2.1**
* Release date: 09/12/2014
* Flyout Panel now highlights each item as it scans your list
* For those times you don't want to scan the entire list, you can now click an item in the Flyout Panel to perform a single item scan, your item settings still apply
* Added more options to "Item Value Source" because TSM now offers several DBGlobal... (Global Data) sources via their TSM App

**2.0**
* Release date: 09/11/2014
* Shopping lists are now sorted alphabetically
* Shopping lists can no longer be given identical names, existing lists with identical names will not be edited but it's recommend you use "Copy List" and give them a new name then delete the original
* You no longer have to keep the "Default" shopping list (now named "Restock Shopping List"), you simply cannot delete all your lists, one must always remain
* The Undermine Journal is no longer an available "Item Value Source" because it was removed from TradeSkillMaster
* Deleted shopping lists are now completely removed from the SavedVariables, previously the items and name were removed but the table was kept for list indexing purposes
* Shopping lists dropdowns are now larger as not to hide longer list names
* Flyout Panel now truncates long shopping list names so the text won't overlap adjacent frames
* Fixed several truncated bits of text and dropdowns that somehow got messed up in patch 5.4.8
* To ensure internally used item data remains accurate from patch to patch item data will update automatically now when the WoW client build changes. Though rare, items that no longer exist after a patch will be displayed as "Poor" (gray) quality with their icon set to the black/red "?"
* Updated GetAddOnInfo() calls for patch 6.0
* Reverted manual depedency check added in v1.7 since TradeSkillMaster now loads optional dependencies

**1.9**
* Release date: 07/28/2014
* Added flyout panel on AH Tab that shows your shopping list and the progress of a shop scan
* Added Low, Norm, Full (green - with maxprice), and Full (gray - without maxprice) breakdown of shopping list on AH tab
* Gray "Full" as opposed to green "Full" labels represent items that are at full stock qty but have no full price (i.e. items that are skipped during AH scans)
* Fixed, closing AH with Buy All enabled caused LUA error

**1.8**
* Release date: 03/02/2014
* Fixed, auctions of the same "Name" and "% Max Price" will now be sorted in the proper order of "Item Price" as expected

**1.7**
* Release date: 02/21/2014
* Added Import/Export of items to and from your shopping lists, this includes exporting the item IDs of a TSM Group into RestockShop
* Added more options to "Item Value Source" from the addons Auctionator, Auctioneer, and TheUndermineJournal(GE)
* Added option to delete items from your shopping list without the confirmation dialog (Yes|No)
* Sorting in Buy All mode will now select the newly sorted first result and scroll to the top to make sure it's visible, previously the selected result may have been anywhere depending on the sort
* Buy All mode will now scroll to top each time it selects the first result, i.e. previously you couldn't see the selected (first) item if you clicked Buy All when scrolled down the list
* Fixed issue on Shopping Lists options panel where scrolling down a long shopping list and then selecting a much shorter list, the shorter list would appear empty until selecting it a second time
* Deleting an item from a shopping list now shows the item's link just as it does when adding an item, just to help confirm what items are being deleted
* Fixed issue with TSM invalid groups / price source when dependent on TheUndermineJournal(GE), was caused by RestockShop setting TSM as an addon dependency, doing so moved TSM up the alphabetical addon loading order ahead of TheUndermineJournal(GE) so TSM assumed the price source was unavailable
* Delay after submitting an item to a shopping list has been reduced to almost instant
* Localization added for zhCN locale Chinese (Simplified)

**1.6**
* Release date: 02/10/2014
* Auctions are now secondarily sorted in ascending order (Low to High) by "% Max Price" when sorting results by any other column except for "% Max Price"
* Default sorting column now "Name", previously "% Max Price"
* When an item is added or udated your shopping list will be sorted by name, A-Z; Scanning now done in list order also
* Shop button now becomes "Abort" button during scanning to abort a scan in progress
* Fixed an error displaying and buying items with a random enchant, they weren't grouping and matching by suffix correctly
* Fixed issue when adding/updating items very quickly, if you clicked on another row immediately after "Submit" it would use clicked item's settings to update

**1.5**
* Release date: 02/08/2014
* Increased buyout speed when buying multiple stacks of the same item
* Added slash command for fast macro buying /rs acceptbuttonclick
* Fixed "Accept" button mouseover issue, the button would go dead sometimes when rapidly clicking to buy several auctions
* DBMarket & DBMinBuyout now available as Item Value Source option, which means TradeSkillMaster_WoWuction is no longer required
* Added a chat notice when you reach Full Stock Qty on an item while buying auctions
* Added item price to auction not found, rescan notices
* After adding an item to a list, the Item ID is reselected for faster entry of multiple items
* Converted XML to LUA except for required templates
* Added structure for Localization, tooltips used when translations are truncated; localization added for ptBR locale Portuguese (Brazilian)

**1.4**
* Release date: 01/29/2014
* Fixed missing comparison (Shift + Mouseover) on item tooltips

**1.3**
* Release date: 01/19/2014
* Intial public release

--]]
--------------------------------------------------------------------------------------------------------------------------------------------
-- Initialize Variables
--------------------------------------------------------------------------------------------------------------------------------------------
local RESTOCKSHOP_VERSION = tonumber( GetAddOnMetadata( "RestockShop", "Version" ) );
local RESTOCKSHOP_WOW_CLIENT_BUILD = select( 2, GetBuildInfo() );
local RESTOCKSHOP_LOADED = false;
local RESTOCKSHOP_TAB = nil;
--
local RESTOCKSHOP_ITEMS = {};
local RESTOCKSHOP_SCANNING = false;
local RESTOCKSHOP_SCAN_TYPE = nil;
local RESTOCKSHOP_BUYALL = false;
local RESTOCKSHOP_CAN_BID = false;
local RESTOCKSHOP_AILU = "LISTEN";
local RESTOCKSHOP_CURRENT_LISTKEY = nil;
--
local RESTOCKSHOP_QUERY_QUEUE = {};
local RESTOCKSHOP_QUERY_ITEM = {};
local RESTOCKSHOP_QUERY_PAGE = 0;
local RESTOCKSHOP_QUERY_ATTEMPTS = 1;
local RESTOCKSHOP_QUERY_MAX_ATTEMPTS = 50;
local RESTOCKSHOP_QUERY_BATCH_ATTEMPTS = 1;
local RESTOCKSHOP_QUERY_MAX_BATCH_ATTEMPTS = 3;
local RESTOCKSHOP_QUERY_NUM_BATCH_AUCTIONS = nil;
local RESTOCKSHOP_QUERY_NUM_TOTAL_AUCTIONS = nil;
local RESTOCKSHOP_QUERY_TOTAL_PAGES = nil;
--
local RESTOCKSHOP_AUCTION_DATA_RAW = {};
local RESTOCKSHOP_AUCTION_DATA_GROUPS = {};
local RESTOCKSHOP_AUCTION_DATA_SORT_KEY = nil;
local RESTOCKSHOP_AUCTION_DATA_SORT_ORDER = nil;
local RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = nil;
local RESTOCKSHOP_AUCTION_SELECT_AUCTION = nil;
local RESTOCKSHOP_AUCTION_SELECT_FOUND = false;
--
local L = RESTOCKSHOP_LOCALIZATION;
--
RESTOCKSHOP_LOW_COLOR_CODE = "|cffff7f3f";
RESTOCKSHOP_NORM_COLOR_CODE = "|cffffff00";
RESTOCKSHOP_FULL_COLOR_CODE = "|cff3fbf3f";
RESTOCKSHOP_LOW_FONT_COLOR = { ["r"]= 1.0, ["g"]=0.5, ["b"]=0.25 };
RESTOCKSHOP_NORM_FONT_COLOR = { ["r"]=1.0, ["g"]=1.0, ["b"]=0.0 };
RESTOCKSHOP_FULL_FONT_COLOR = { ["r"]=0.25, ["g"]=0.75, ["b"]=0.25 };
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
for i = 1, GetNumAddOns() do
	local name,_,_,loaded,_,_,_ = GetAddOnInfo( i );
	if loaded == 1 or loaded == true then
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
		["version"] = RESTOCKSHOP_VERSION,
		["wowClientBuild"] = RESTOCKSHOP_WOW_CLIENT_BUILD,
		["itemValueSrc"] = "DBMarket",
		["lowStockPct"] = 30,
		["qoh"] = {
			["allCharacters"] = 1,
			["guilds"] = 1,
		},
		["itemTooltip"] = {
			["shoppingListSettings"] = 1,
			["itemId"] = 1,
		},
		["showDeleteItemConfirmDialog"] = 1,
		["flyoutPanelOpen"] = 1,
		["shoppingLists"] = {
			[1] = {
				["name"] = L["Restock Shopping List"],
				["items"] = {},
			},
		},
	};
end

--
function RestockShop_DefaultSavedVariablesPerCharacter()
	return {
		["version"] = RESTOCKSHOP_VERSION,
		["currentListName"] = L["Restock Shopping List"],
	};
end

--
function RestockShop_Upgrade()
	local vars = RestockShop_DefaultSavedVariables();
	local version = RESTOCKSHOP_SAVEDVARIABLES["version"];
	-- 1.7
	if version < 1.7 then
		RESTOCKSHOP_SAVEDVARIABLES["showDeleteItemConfirmDialog"] = vars["showDeleteItemConfirmDialog"];
	end
	-- 1.9
	if version < 1.9 then
		RESTOCKSHOP_SAVEDVARIABLES["flyoutPanelOpen"] = vars["flyoutPanelOpen"];
	end
	-- 2.0
	if version < 2.0 then
		if string.sub( RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"], 1, 3 ) == "TUJ" then
			RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] = vars["itemValueSrc"];
		end
		--
		local listKey = 1;
		while listKey <= #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] do
			if not RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["name"] then
				table.remove( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"], listKey ); -- Remove empty tables from previously deleted lists
			else
				listKey = listKey + 1;
			end
		end
		--
		table.sort ( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"],
			function ( list1, list2 )
				return list1["name"] < list2["name"]; -- Sort lists by name A-Z
			end
		);
		--
		RESTOCKSHOP_SAVEDVARIABLES["wowClientBuild"] = 0; -- Forces the item data update that was added this version
	end
	--
	print( "RestockShop: " .. string.format( L["Upgraded version %s to %s"], version, RESTOCKSHOP_VERSION ) );
	RESTOCKSHOP_SAVEDVARIABLES["version"] = RESTOCKSHOP_VERSION;
end

--
function RestockShop_UpgradePerCharacter()
	local varspercharacter = RestockShop_DefaultSavedVariablesPerCharacter();
	local version = RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"];
	--
	-- Not currently used, but will be going forward, SVPC version was introduced in 2.0 requiring SVPC to be overwritten with defaults because version will be nil
	--
	RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"] = RESTOCKSHOP_VERSION;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_OnAddonLoaded() -- ADDON_LOADED
	if IsAddOnLoaded( "RestockShop" ) then
		if not RESTOCKSHOP_LOADED then
			-- Set Default SavedVariables
			if not RESTOCKSHOP_SAVEDVARIABLES then
				RESTOCKSHOP_SAVEDVARIABLES = RestockShop_DefaultSavedVariables();
			end
			-- Set Default SavedVariablesPerCharacter
			if not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER or not RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"] then
				RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER = RestockShop_DefaultSavedVariablesPerCharacter();
			end
			-- Upgrade if old version
			if RESTOCKSHOP_SAVEDVARIABLES["version"] < RESTOCKSHOP_VERSION then
				RestockShop_Upgrade();
			end
			-- Upgrade Per Character if old version
			if RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["version"] < RESTOCKSHOP_VERSION then
				RestockShop_UpgradePerCharacter();
			end
			-- WoW client build changed, requery all lists for possible item changes
			if RESTOCKSHOP_SAVEDVARIABLES["wowClientBuild"] ~= RESTOCKSHOP_WOW_CLIENT_BUILD then
				RestockShop_WoWClientBuildChanged();
			end
			-- Make sure current list name exists, if not reset to first list
			for k, list in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] ) do
				if list["name"] == RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] then
					RESTOCKSHOP_CURRENT_LISTKEY = k;
					break;
				end
			end
			if not RESTOCKSHOP_CURRENT_LISTKEY then
				RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][1]["name"];
				RESTOCKSHOP_CURRENT_LISTKEY = 1;
			end
			-- Hook Item Tooltip
			ItemRefTooltip:HookScript( "OnTooltipSetItem", RestockShop_AddTooltipData );
			GameTooltip:HookScript( "OnTooltipSetItem", RestockShop_AddTooltipData );
			--
			RESTOCKSHOP_LOADED = true;
		end
		if IsAddOnLoaded( "Blizzard_AuctionUI" ) then
			RestockShopEventsFrame:UnregisterEvent( "ADDON_LOADED" );
			-- Add "RestockShop" Tab to AuctionFrame
			local n = AuctionFrame.numTabs + 1;
			RESTOCKSHOP_TAB = CreateFrame( "Button", "AuctionFrameTab" .. n, AuctionFrame, "AuctionTabTemplate" );
			RESTOCKSHOP_TAB:SetID( n );
			RESTOCKSHOP_TAB:SetText( "RestockShop" );
			RESTOCKSHOP_TAB:SetNormalFontObject( GameFontNormalSmall );
			RESTOCKSHOP_TAB:SetPoint( "LEFT", _G["AuctionFrameTab" .. n - 1], "RIGHT", -8, 0 );
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
	RestockShop_InitOptionsPanels();
	if not RESTOCKSHOP_SAVEDVARIABLES["flyoutPanelOpen"] then
		RestockShopFrame_FlyoutPanelButton:Click();
	end
end

--
function RestockShop_OnAuctionItemListUpdate() -- AUCTION_ITEM_LIST_UPDATE
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	if RESTOCKSHOP_AILU == "AUCTION_WON" then RestockShop_AfterAuctionWon(); end
	if RESTOCKSHOP_AILU == "IGNORE" then RESTOCKSHOP_AILU = "LISTEN"; return end
	if not RESTOCKSHOP_SCANNING then return end
	RESTOCKSHOP_QUERY_NUM_BATCH_AUCTIONS, RESTOCKSHOP_QUERY_NUM_TOTAL_AUCTIONS = GetNumAuctionItems( "list" );
	RESTOCKSHOP_QUERY_TOTAL_PAGES = ceil( RESTOCKSHOP_QUERY_NUM_TOTAL_AUCTIONS / NUM_AUCTION_ITEMS_PER_PAGE );
	RestockShop_ScanAuctionPage();
end

--
function RestockShop_OnChatMsgSystem( ... ) -- CHAT_MSG_SYSTEM
	local arg1 = select( 1, ... );
	if not arg1 then return end
	if arg1 == ERR_AUCTION_BID_PLACED then
		-- Bid Acccepted.
		RESTOCKSHOP_AILU = "IGNORE"; -- Ignore the list update after "Bid accepted."
		RestockShopEventsFrame:RegisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
		RestockShopEventsFrame:UnregisterEvent( "UI_ERROR_MESSAGE" );
	elseif arg1:match( string.gsub( ERR_AUCTION_WON_S, "%%s", "" ) ) and arg1 == string.format( ERR_AUCTION_WON_S, RESTOCKSHOP_AUCTION_SELECT_AUCTION["name"] ) then
		-- You won an auction for %s
		RESTOCKSHOP_AILU = "AUCTION_WON"; -- Helps decide to Ignore or Listen to the list update after "You won an auction for %s"
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
		RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] = RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] - 1;
		--
		if RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] == 0 then
			-- Group removed
			table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS, RESTOCKSHOP_AUCTION_SELECT_GROUPKEY );
			RestockShopFrame_ScrollFrame_Auction_Deselect();
			if next( RESTOCKSHOP_AUCTION_DATA_GROUPS ) then
				-- More auctions exist
				if RESTOCKSHOP_BUYALL then
					RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
				else
					RestockShopFrame_ScrollFrame_Update();
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
					RestockShopFrame_BuyAllButton:Enable();
				end
			else
				-- No auctions exist
				RestockShopFrame_ScrollFrame_Update();
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
				RestockShopFrame_BuyAllButton_Reset();
			end
		else
			-- Single auction removed
			table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["auctions"] );
			RestockShopFrame_ScrollFrame_Entry_OnClick( RESTOCKSHOP_AUCTION_SELECT_GROUPKEY );
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
	if RESTOCKSHOP_TAB:GetID() == self:GetID() then
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
	RestockShop_StopScanning();
	RestockShopFrame_DialogFrame_BuyoutFrame_CancelButton:Click();
	RestockShopFrame_ScrollFrame_Auction_Deselect();
	RestockShop_SetCanBid( false );
	--
	RESTOCKSHOP_ITEMS = {};
	RESTOCKSHOP_QUERY_ITEM = {};
	RESTOCKSHOP_QUERY_QUEUE = {};
	RESTOCKSHOP_AUCTION_DATA_GROUPS = {};
	--
	RestockShopFrame_HideSortButtonArrows();
	RestockShopFrame_NameSortButton:Click();
	RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 );
	RestockShopFrame_ScrollFrame_Update();
	--
	RestockShopFrame_ListStatusFrame_Text:SetText( string.format( "%s\n\n%s   =   %s%d|r", RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], RestockShopFrame_ListSummary(), NORMAL_FONT_COLOR_CODE, #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"] ) );
	RestockShopFrame_ListStatusFrame:Show();
	--
	RestockShopFrame_DialogFrame_StatusFrame_Update( L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] );
	--
	RestockShopFrame_ShoppingListsDropDownMenu_Load();
	RestockShopFrame_ShopButton_Reset();
	RestockShopFrame_BuyAllButton_Reset();
	--
	RestockShopFrame_FlyoutPanel.TitleText:SetText( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"] );
	if not flyoutPanelEntryClick then
		RestockShopFrame_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 ); -- Only reset vertical scroll when NOT clicking entry in FlyoutPanel
	end
	RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
	RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
	--
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
	_G["RestockShopFrame_PctMaxPriceSortButtonArrow"]:Hide();
	_G["RestockShopFrame_ItemPriceSortButtonArrow"]:Hide();
	_G["RestockShopFrame_OnHandSortButtonArrow"]:Hide();
end

--
function RestockShopFrame_ListSummary()
	local low, norm, fullGreen, fullGray = 0, 0, 0, 0;
	for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"] ) do
		local restockPct = RestockShop_RestockPct( RestockShop_QOH( v["tsmItemString"] ), v["fullStockQty"] );
		if restockPct < RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] then
			low = low + 1;
		elseif restockPct < 100 then
			norm = norm + 1;
		elseif v["maxPricePct"]["full"] > 0 then
			fullGreen = fullGreen + 1;
		else
			fullGray = fullGray + 1;
		end
	end
	return string.format( "|cffffffff%d|r |cff7674d9(|r%s" .. L["Low"] .. "|r|cff7674d9)|r  |cffffffff%d|r |cff7674d9(|r%s" .. L["Norm"] .. "|r|cff7674d9)|r  |cffffffff%d|r |cff7674d9(|r%s" .. L["Full"] .. "|r|cff7674d9)|r  |cffffffff%d|r |cff7674d9(|r%s" .. L["Full"] .. "|r|cff7674d9)|r", low, RESTOCKSHOP_LOW_COLOR_CODE, norm, RESTOCKSHOP_NORM_COLOR_CODE, fullGreen, RESTOCKSHOP_FULL_COLOR_CODE, fullGray, GRAY_FONT_COLOR_CODE );
end

--
function RestockShopFrame_ScrollFrame_UnlockHighlights()
	for numEntry = 1, 15 do
		_G["RestockShopFrame_ScrollFrame_Entry" .. numEntry]:UnlockHighlight();
	end
end

--
function RestockShopFrame_ScrollFrame_Update()
	local groups = RESTOCKSHOP_AUCTION_DATA_GROUPS;
	local numItems, numToDisplay, valueStep = #groups, 15, 16;
	local dataOffset = FauxScrollFrame_GetOffset( RestockShopFrame_ScrollFrame );
	FauxScrollFrame_Update( RestockShopFrame_ScrollFrame, numItems, numToDisplay, valueStep );
	for numEntry = 1, numToDisplay do
		local EntryFrameName = "RestockShopFrame_ScrollFrame_Entry" .. numEntry;
		local EntryFrame = _G[EntryFrameName];
		local offsetKey = dataOffset + numEntry;
		EntryFrame:UnlockHighlight();
		if offsetKey <= numItems then
			_G[EntryFrameName .. "_OnHand"]:SetText( groups[offsetKey]["onHandQty"] );
			--
			local restockColor, maxPriceUsed = nil, nil;
			if groups[offsetKey]["restockPct"] < RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] then
				restockColor = RESTOCKSHOP_LOW_FONT_COLOR;
				maxPriceUsed = RESTOCKSHOP_LOW_COLOR_CODE .. L["Low"] .. "|r";
			elseif groups[offsetKey]["restockPct"] < 100 then
				restockColor = RESTOCKSHOP_NORM_FONT_COLOR;
				maxPriceUsed = RESTOCKSHOP_NORM_COLOR_CODE .. L["Norm"] .. "|r";
			else
				restockColor = RESTOCKSHOP_FULL_FONT_COLOR;
				maxPriceUsed = RESTOCKSHOP_FULL_COLOR_CODE .. L["Full"] .. "|r";
			end
			_G[EntryFrameName .. "_Restock"]:SetText( math.floor( groups[offsetKey]["restockPct"] ) .. "%" );
			_G[EntryFrameName .. "_Restock"]:SetTextColor( restockColor["r"], restockColor["g"], restockColor["b"] );
			--
			_G[EntryFrameName .. "_IconTexture"]:SetTexture( groups[offsetKey]["texture"] );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( groups[offsetKey]["itemLink"] ); end );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnLeave", function( self ) GameTooltip:Hide(); end );
			_G[EntryFrameName .. "_Name"]:SetText( groups[offsetKey]["name"] );
			_G[EntryFrameName .. "_Name"]:SetTextColor( GetItemQualityColor( groups[offsetKey]["quality"] ) );
			_G[EntryFrameName .. "_Stacks"]:SetText( string.format( L["%d stacks of %d"], groups[offsetKey]["numAuctions"], groups[offsetKey]["count"] ) );
			MoneyFrame_Update( EntryFrameName .. "_ItemPrice_SmallMoneyFrame", groups[offsetKey]["itemPrice"] );
			_G[EntryFrameName .. "_PctMaxPrice"]:SetText( math.floor( groups[offsetKey]["pctMaxPrice"] ) .. "% |cff7674d9(|r" .. maxPriceUsed .. "|cff7674d9)|r" );
			--
			EntryFrame:SetScript( "OnClick", function () RestockShopFrame_ScrollFrame_Entry_OnClick( offsetKey ); end );
			EntryFrame:Show();
			if RESTOCKSHOP_AUCTION_SELECT_GROUPKEY and RESTOCKSHOP_AUCTION_SELECT_GROUPKEY == offsetKey then
				EntryFrame:LockHighlight();
			end
		else
			EntryFrame:Hide();
		end
	end
end

--
function RestockShopFrame_ScrollFrame_Entry_OnClick( groupKey )
	if RESTOCKSHOP_SCANNING then
		print( "RestockShop: " .. L["Selection ignored, busy scanning"] );
		return; -- Stop function
	end
	--
	RestockShop_SetCanBid( false );
	--
	local auction = RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["auctions"][#RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["auctions"]];
	RESTOCKSHOP_QUERY_PAGE = auction["page"];
	RESTOCKSHOP_AUCTION_SELECT_FOUND = false;
	RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = groupKey;
	RESTOCKSHOP_AUCTION_SELECT_AUCTION = auction; -- Cannot use index, ownerFullName, or buyoutPrice yet, these may change after scanning the page
	if RESTOCKSHOP_BUYALL and groupKey == 1 then
		RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
	end
	RestockShopFrame_ScrollFrame_Update();
	--
	RESTOCKSHOP_QUERY_QUEUE = {};
	table.insert( RESTOCKSHOP_QUERY_QUEUE, RESTOCKSHOP_ITEMS[auction["itemId"]] );
	RESTOCKSHOP_SCAN_TYPE = "SELECT";
	RestockShop_ScanAuctionQueue();
end

--
function RestockShopFrame_ScrollFrame_Auction_Deselect()
	RestockShopFrame_ScrollFrame_UnlockHighlights();
	RESTOCKSHOP_AUCTION_SELECT_FOUND = false;
	RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = nil;
	RESTOCKSHOP_AUCTION_SELECT_AUCTION = nil;
	RestockShop_SetCanBid( false );
end

--
function RestockShopFrame_FlyoutPanel_ScrollFrame_Update()
	local items = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"];
	local numItems, numToDisplay, valueStep = #items, 17, 16;
	local dataOffset = FauxScrollFrame_GetOffset( RestockShopFrame_FlyoutPanel_ScrollFrame );
	FauxScrollFrame_Update( RestockShopFrame_FlyoutPanel_ScrollFrame, numItems, numToDisplay, valueStep );
	--
	local flyoutWidth = ( function() if numItems > 17 then return 254 else return 227 end end )();
	RestockShopFrame_FlyoutPanel:SetWidth( flyoutWidth );
	--
	if numItems > 17 and #RESTOCKSHOP_QUERY_QUEUE > 0 then
		local vScroll = ( numItems - #RESTOCKSHOP_QUERY_QUEUE - ( 17 - 1 ) ) * 16;
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
			_G[EntryFrameName .. "_IconTexture"]:SetTexture( items[offsetKey]["texture"] );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnEnter", function() GameTooltip:SetOwner( _G[EntryFrameName .. "_IconTexture"]:GetParent(), "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[offsetKey]["link"] ); end );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnLeave", function() GameTooltip:Hide(); end );
			_G[EntryFrameName .. "_Name"]:SetText( items[offsetKey]["name"] );
			_G[EntryFrameName .. "_Name"]:SetTextColor( GetItemQualityColor( items[offsetKey]["quality"] ) );
			--
			local onHandQty = RestockShop_QOH( items[offsetKey]["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, items[offsetKey]["fullStockQty"] );
			local restockStatus = nil;
			if restockPct < RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] then
				restockStatus = RESTOCKSHOP_LOW_COLOR_CODE .. L["Low"] .. "|r";
			elseif restockPct < 100 then
				restockStatus = RESTOCKSHOP_NORM_COLOR_CODE .. L["Norm"] .. "|r";
			elseif items[offsetKey]["maxPricePct"]["full"] == 0 then
				restockStatus = GRAY_FONT_COLOR_CODE .. L["Full"] .. "|r";
			else
				restockStatus = RESTOCKSHOP_FULL_COLOR_CODE .. L["Full"] .. "|r";
			end
			_G[EntryFrameName .. "_RestockStatus"]:SetText( restockStatus );
			--
			local scanTexture = nil;
			if not RESTOCKSHOP_ITEMS[items[offsetKey]["itemId"]] then
				scanTexture = "Waiting";
			else
				scanTexture = RESTOCKSHOP_ITEMS[items[offsetKey]["itemId"]]["scanTexture"];
			end
			_G[EntryFrameName .. "_ScanTexture"]:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-" .. scanTexture );
			--
			EntryFrame:SetScript( "OnClick", function () RestockShopFrame_FlyoutPanel_ScrollFrame_Entry_OnClick( offsetKey ); end );
			EntryFrame:Show();
			if ( RESTOCKSHOP_SCAN_TYPE == "SHOP" or RestockShop_Count( RESTOCKSHOP_ITEMS ) == 1 ) and RESTOCKSHOP_QUERY_ITEM["itemId"] == items[offsetKey]["itemId"] then
				EntryFrame:LockHighlight();
			end
		else
			EntryFrame:Hide();
		end
	end
end

--
function RestockShopFrame_FlyoutPanel_ScrollFrame_Entry_OnClick( itemKey )
	RestockShopFrame_Reset( true );
	RestockShopFrame_ListStatusFrame:Hide();
	RESTOCKSHOP_AUCTION_DATA_RAW = {};
	--
	local item = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey];
	table.insert( RESTOCKSHOP_QUERY_QUEUE, item );
	RESTOCKSHOP_ITEMS[item["itemId"]] = item;
	RESTOCKSHOP_ITEMS[item["itemId"]]["scanTexture"] = "Waiting";
	RESTOCKSHOP_SCAN_TYPE = "SHOP";
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
		if RESTOCKSHOP_CURRENT_LISTKEY ~= info.value then
			RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] = info.text;
			RESTOCKSHOP_CURRENT_LISTKEY = info.value;
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
			for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] ) do
				DropDownMenu_AddButton( frame, v["name"], k );
			end
		end
	end
	-- Shopping Lists Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "_ShoppingListsDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "_ShoppingListsDropDownMenu"], RESTOCKSHOP_CURRENT_LISTKEY );
	UIDropDownMenu_SetWidth( _G[panelName .. "_ShoppingListsDropDownMenu"], 195 );
end

--
function RestockShopFrame_ShopButton_Reset()
	RestockShopFrame_ShopButton:Enable();
	RestockShopFrame_ShopButton:SetText( L["Shop"] );
end

--
function RestockShopFrame_BuyAllButton_Reset()
	RESTOCKSHOP_BUYALL = false;
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
	RESTOCKSHOP_AUCTION_DATA_SORT_KEY = itemInfoKey;
	RESTOCKSHOP_AUCTION_DATA_SORT_ORDER = order;
	RestockShop_SortAuctionDataGroups();
	if RESTOCKSHOP_BUYALL then
		RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
	else
		RestockShopFrame_ScrollFrame_Update();
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Interface Options Panel Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_InitOptionsPanels()
	-- RestockShopInterfaceOptionsPanelParent
	local panel = _G["RestockShopInterfaceOptionsPanelParent"];
	panel.name = "RestockShop";
	panel.okay = function ( self ) return end
	panel.cancel = function ( self ) return end
	InterfaceOptions_AddCategory( panel );
	-- RestockShopInterfaceOptionsPanel
	local subpanel = _G["RestockShopInterfaceOptionsPanel"];
	subpanel.name = "Options";
	subpanel.okay = RestockShopInterfaceOptionsPanel_Okay;
	subpanel.cancel = function ( self ) return end
	subpanel.parent = "RestockShop";
	RestockShopInterfaceOptionsPanel_Load();
	InterfaceOptions_AddCategory( subpanel );
	-- RestockShopInterfaceOptionsPanelShoppingLists
	local subpanel = _G["RestockShopInterfaceOptionsPanelShoppingLists"];
	subpanel.name = L["Shopping Lists"];
	subpanel.okay = function ( self ) return end
	subpanel.cancel = function ( self ) return end
	subpanel.parent = "RestockShop";
	RestockShopInterfaceOptionsPanelShoppingLists_Load();
	InterfaceOptions_AddCategory( subpanel );
	-- Delete an item from a list
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEM_DELETE"] = {
		text = L["Delete item? %s from %s"];
		button1 = YES,
		button2 = NO,
		OnAccept = function ( self, data )
			local itemKey = RestockShop_FindItemKey( data["itemId"], data["shoppingList"] );
			if not itemKey then return end
			print( "RestockShop: " .. L["Item deleted"] .. " " .. RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"][itemKey]["link"] );
			table.remove( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"], itemKey );
			RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
		end,
		OnCancel = function ( self ) end,
		OnShow = function ( self )
			if not RESTOCKSHOP_SAVEDVARIABLES["showDeleteItemConfirmDialog"] then
				local OnAccept = StaticPopupDialogs[self.which].OnAccept;
				OnAccept( self, self.data );
				self:Hide();
			end
		end,
		showAlert = 1,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
	-- Create a list
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_CREATE"] = {
		text = L["Create List"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 50,
		OnAccept = function ( self )
			RestockShop_CreateList( self.editBox:GetText() );
		end,
		OnCancel = function ( self ) end,
		OnShow = function ( self )
			self.editBox:SetFocus();
		end,
		OnHide = function ( self )
			self.editBox:SetText( "" );
		end,
		EditBoxOnEnterPressed = function ( self )
			local parent = self:GetParent();
			RestockShop_CreateList( parent.editBox:GetText() );
			parent:Hide();
		end,
		EditBoxOnEscapePressed = function( self )
			self:GetParent():Hide();
		end,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
	-- Copy a list
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_COPY"] = {
		text = L["Copy List: %s"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 50,
		OnAccept = function ( self, data )
			RestockShop_CreateList( self.editBox:GetText(), data );
		end,
		OnCancel = function ( self ) end,
		OnShow = function ( self )
			self.editBox:SetFocus();
		end,
		OnHide = function ( self )
			self.editBox:SetText( "" );
		end,
		EditBoxOnEnterPressed = function ( self, data )
			local parent = self:GetParent();
			RestockShop_CreateList( parent.editBox:GetText(), data );
			parent:Hide();
		end,
		EditBoxOnEscapePressed = function( self )
			self:GetParent():Hide();
		end,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
	-- Delete a list
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_DELETE"] = {
		text = L["Delete list? %s"];
		button1 = YES,
		button2 = NO,
		OnAccept = function ( self, data )
			if #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] == 1 then
				print( "RestockShop: " .. RED_FONT_COLOR_CODE .. L["You can't delete your only list, you must keep at least one"] .. "|r" );
				return;
			end
			table.remove( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"], data["shoppingList"] );
			-- Select first shopping list
			RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][1]["name"];
			RESTOCKSHOP_CURRENT_LISTKEY = 1;
			--
			RestockShopInterfaceOptionsPanelShoppingLists_Load();
			RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
			print( "RestockShop: " .. L["List deleted"] );
		end,
		OnCancel = function ( self ) end,
		showAlert = 1,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
	-- Import Items
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT"] = {
		text = L["Import items to list: %s\n\n|cffffd200TSM|r\nComma-delimited Item IDs\nNo subgroup structure\n|cff82c5ff12345,12346|r\n\nor\n\n|cffffd200RestockShop|r\nComma-delimited items\nColon-delimited settings\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\n"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 0,
		OnAccept = function ( self, data )
			RestockShop_ImportItems( self.editBox:GetText(), data );
		end,
		OnCancel = function ( self ) end,
		OnShow = function ( self )
			self.editBox:SetFocus();
		end,
		OnHide = function ( self )
			self.editBox:SetText( "" );
		end,
		EditBoxOnEnterPressed = function ( self, data )
			local parent = self:GetParent();
			RestockShop_ImportItems( parent.editBox:GetText(), data );
			parent:Hide();
		end,
		EditBoxOnEscapePressed = function( self )
			self:GetParent():Hide();
		end,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
	-- Export Items
	StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEMS_EXPORT"] = {
		text = L["Export items from list: %s\n\n|cffffd200TSM|r\nComma-delimited Item IDs\n|cff82c5ff12345,12346|r\n\nor\n\n|cffffd200RestockShop|r\nComma-delimited items\nColon-delimited settings\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\n"];
		button1 = "TSM",
		button2 = CANCEL,
		button3 = "RestockShop",
		hasEditBox = 1,
		maxLetters = 0,
		OnAccept = function ( self, data )
			local exportTable = {};
			for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"] ) do
				table.insert( exportTable, v["itemId"] );
			end
			local exportString = table.concat( exportTable, "," );
			self.editBox:SetText( exportString );
			_G[self:GetName() .. "Button1Text"]:SetText( "dontHide" ); -- Don't hide the dialog this way instead of returning true for button Sound consistency with OnAlt
		end,
		OnCancel = function ( self ) end,
		OnAlt = function ( self, data )
			local exportTable = {};
			for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"] ) do
				table.insert( exportTable, strjoin( ":", v["itemId"], v["fullStockQty"], v["maxPricePct"]["low"], v["maxPricePct"]["normal"], v["maxPricePct"]["full"] ) );
			end
			local exportString = table.concat( exportTable, "," );
			self.editBox:SetText( exportString );
			_G[self:GetName() .. "Button3Text"]:SetText( "dontHide" ); -- Don't hide dialog this way because Blizzard only has a dontHide option for OnAccept
		end,
		OnShow = function ( self )
			_G[self:GetName() .. "Button1Text"]:SetText( "TSM" );
			_G[self:GetName() .. "Button3Text"]:SetText( "RestockShop" );
			self.editBox:SetFocus();
			self.editBox:SetCursorPosition( 0 );
			self.editBox:HighlightText();
		end,
		OnHide = function ( self )
			if _G[self:GetName() .. "Button1Text"]:GetText() == "dontHide" or _G[self:GetName() .. "Button3Text"]:GetText() == "dontHide" then
				self:Show();
			else
				self.editBox:SetText( "" );
			end
		end,
		EditBoxOnEscapePressed = function( self )
			self:GetParent():Hide();
		end,
		hideOnEscape = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
	};
end

--
function RestockShopInterfaceOptionsPanel_Load()
	local panelName = "RestockShopInterfaceOptionsPanel";
	-- Dropdown Button Click
	local function DropDownMenuButton_OnClick( info )
		UIDropDownMenu_SetSelectedValue( info.owner, info.value );
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
		if frameName == "RestockShopInterfaceOptionsPanelItemValueSrcDropDownMenu" then
			DropDownMenu_AddButton( frame, L["AtrValue (Auctionator - Auction Value)"], "AtrValue" );
			DropDownMenu_AddButton( frame, L["AucAppraiser (Auctioneer - Appraiser)"], "AucAppraiser" );
			DropDownMenu_AddButton( frame, L["AucMarket (Auctioneer - Market Value)"], "AucMarket" );
			DropDownMenu_AddButton( frame, L["AucMinBuyout (Auctioneer - Minimum Buyout)"], "AucMinBuyout" );
			DropDownMenu_AddButton( frame, L["DBGlobalMarketAvg (AuctionDB - Global Market Value Average (via TSM App))"], "DBGlobalMarketAvg" );
			DropDownMenu_AddButton( frame, L["DBGlobalMarketMedian (AuctionDB - Global Market Value Median (via TSM App))"], "DBGlobalMarketMedian" );
			DropDownMenu_AddButton( frame, L["DBGlobalMinBuyoutAvg (AuctionDB - Global Minimum Buyout Average (via TSM App))"], "DBGlobalMinBuyoutAvg" );
			DropDownMenu_AddButton( frame, L["DBGlobalMinBuyoutMedian (AuctionDB - Global Minimum Buyout Median (via TSM App))"], "DBGlobalMinBuyoutMedian" );
			DropDownMenu_AddButton( frame, L["DBGlobalSaleAvg (AuctionDB - Global Sale Average (via TSM App))"], "DBGlobalSaleAvg" );
			DropDownMenu_AddButton( frame, L["DBMarket (AuctionDB Market Value)"], "DBMarket" );
			DropDownMenu_AddButton( frame, L["DBMinBuyout (AuctionDB Minimum Buyout)"], "DBMinBuyout" );
			DropDownMenu_AddButton( frame, L["wowuctionMarket (WoWuction Realm Market Value)"], "wowuctionMarket" );
			DropDownMenu_AddButton( frame, L["wowuctionMedian (WoWuction Realm Median Price)"], "wowuctionMedian" );
			DropDownMenu_AddButton( frame, L["wowuctionRegionMarket (WoWuction Region Market Value)"], "wowuctionRegionMarket" );
			DropDownMenu_AddButton( frame, L["wowuctionRegionMedian (WoWuction Region Median Price)"], "wowuctionRegionMedian" );
		elseif frameName == "RestockShopInterfaceOptionsPanelLowStockPctDropDownMenu" then
			DropDownMenu_AddButton( frame, "10%", 10 );
			DropDownMenu_AddButton( frame, "20%", 20 );
			DropDownMenu_AddButton( frame, "30%", 30 );
			DropDownMenu_AddButton( frame, "40%", 40 );
			DropDownMenu_AddButton( frame, "50%", 50 );
			DropDownMenu_AddButton( frame, "60%", 60 );
			DropDownMenu_AddButton( frame, "70%", 70 );
			DropDownMenu_AddButton( frame, "80%", 80 );
			DropDownMenu_AddButton( frame, "90%", 90 );
		elseif frameName == "RestockShopInterfaceOptionsPanelQOHAllCharactersDropDownMenu" then
			DropDownMenu_AddButton( frame, L["All Characters"], 1 );
			DropDownMenu_AddButton( frame, L["Current Character"], 2 );
		end
	end
	-- Item Value Source Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "ItemValueSrcDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "ItemValueSrcDropDownMenu"], RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] );
	UIDropDownMenu_SetWidth( _G[panelName .. "ItemValueSrcDropDownMenu"], 488 );
	-- QOH All Characters Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "QOHAllCharactersDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "QOHAllCharactersDropDownMenu"], RESTOCKSHOP_SAVEDVARIABLES["qoh"]["allCharacters"] );
	UIDropDownMenu_SetWidth( _G[panelName .. "QOHAllCharactersDropDownMenu"], 116 );
	-- Low Stock % Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "LowStockPctDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "LowStockPctDropDownMenu"], RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] );
	UIDropDownMenu_SetWidth( _G[panelName .. "LowStockPctDropDownMenu"], 49 );
	-- Check Buttons
	_G[panelName .. "QOHGuildsCheckButton"]:SetChecked( RESTOCKSHOP_SAVEDVARIABLES["qoh"]["guilds"] );
	_G[panelName .. "ItemTooltipShoppingListSettingsCheckButton"]:SetChecked( RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["shoppingListSettings"] );
	_G[panelName .. "ItemTooltipItemIdCheckButton"]:SetChecked( RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["itemId"] );
	_G[panelName .. "showDeleteItemConfirmDialogCheckButton"]:SetChecked( RESTOCKSHOP_SAVEDVARIABLES["showDeleteItemConfirmDialog"] );
end

--
function RestockShopInterfaceOptionsPanel_Okay()
	local panelName = "RestockShopInterfaceOptionsPanel";
	RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] = UIDropDownMenu_GetSelectedValue( _G[panelName .. "ItemValueSrcDropDownMenu"] );
	RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] = UIDropDownMenu_GetSelectedValue( _G[panelName .. "LowStockPctDropDownMenu"] );
	RESTOCKSHOP_SAVEDVARIABLES["qoh"]["allCharacters"] = UIDropDownMenu_GetSelectedValue( _G[panelName .. "QOHAllCharactersDropDownMenu"] );
	RESTOCKSHOP_SAVEDVARIABLES["qoh"]["guilds"] = _G[panelName .. "QOHGuildsCheckButton"]:GetChecked();
	RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["shoppingListSettings"] = _G[panelName .. "ItemTooltipShoppingListSettingsCheckButton"]:GetChecked();
	RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["itemId"] = _G[panelName .. "ItemTooltipItemIdCheckButton"]:GetChecked();
	RESTOCKSHOP_SAVEDVARIABLES["showDeleteItemConfirmDialog"] = _G[panelName .. "showDeleteItemConfirmDialogCheckButton"]:GetChecked();
end

--
function RestockShopInterfaceOptionsPanelShoppingLists_Load()
	local panelName = "RestockShopInterfaceOptionsPanelShoppingLists";
	-- Dropdown Button Click
	local function DropDownMenuButton_OnClick( info )
		UIDropDownMenu_SetSelectedValue( info.owner, info.value );
		RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] = info.text;
		RESTOCKSHOP_CURRENT_LISTKEY = info.value;
		_G[panelName .. "_ScrollFrame"]:SetVerticalScroll( 0 );
		RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update( 0 );
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
		if frameName == ( panelName .. "ShoppingListsDropDownMenu" ) then
			for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] ) do
				DropDownMenu_AddButton( frame, v["name"], k );
			end
		end
	end
	-- Shopping Lists Dropdown
	UIDropDownMenu_Initialize( _G[panelName .. "ShoppingListsDropDownMenu"], DropDownMenu_Initialize );
	UIDropDownMenu_SetSelectedValue( _G[panelName .. "ShoppingListsDropDownMenu"], RESTOCKSHOP_CURRENT_LISTKEY );
	UIDropDownMenu_SetWidth( _G[panelName .. "ShoppingListsDropDownMenu"], 195 );
	-- Shopping Lists Scrollframe
	RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
end

--
function RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update()
	local items = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"];
	local numItems, numToDisplay, valueStep = #items, 15, 16;
	local dataOffset = FauxScrollFrame_GetOffset( RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame );
	FauxScrollFrame_Update( RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame, numItems, numToDisplay, valueStep );
	for numEntry = 1, numToDisplay do
		local EntryFrameName = "RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Entry" .. numEntry;
		local EntryFrame = _G[EntryFrameName];
		local offsetKey = dataOffset + numEntry;
		EntryFrame:UnlockHighlight();
		if offsetKey <= numItems then
			_G[EntryFrameName .. "_ItemId"]:SetText( items[offsetKey]["itemId"] );
			_G[EntryFrameName .. "_IconTexture"]:SetTexture( items[offsetKey]["texture"] );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnEnter", function() GameTooltip:SetOwner( _G[EntryFrameName .. "_IconTexture"]:GetParent(), "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[offsetKey]["link"] ); end );
			_G[EntryFrameName .. "_IconTexture"]:GetParent():SetScript( "OnLeave", function() GameTooltip:Hide(); end );
			_G[EntryFrameName .. "_Name"]:SetText( items[offsetKey]["name"] );
			_G[EntryFrameName .. "_Name"]:SetTextColor( GetItemQualityColor( items[offsetKey]["quality"] ) );
			_G[EntryFrameName .. "_FullStockQty"]:SetText( items[offsetKey]["fullStockQty"] );
			_G[EntryFrameName .. "_LowStockPrice"]:SetText( items[offsetKey]["maxPricePct"]["low"] .. "%" );
			_G[EntryFrameName .. "_NormalStockPrice"]:SetText( items[offsetKey]["maxPricePct"]["normal"] .. "%" );
			if items[offsetKey]["maxPricePct"]["full"] == 0 then
				_G[EntryFrameName .. "_FullStockPrice"]:SetText( "-" );
			else
				_G[EntryFrameName .. "_FullStockPrice"]:SetText( items[offsetKey]["maxPricePct"]["full"] .. "%" );
			end
			_G[EntryFrameName .. "_DeleteButton"]:SetScript( "OnClick", function() StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEM_DELETE", items[offsetKey]["name"], RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], { ["shoppingList"] = RESTOCKSHOP_CURRENT_LISTKEY, ["itemId"] = items[offsetKey]["itemId"] } ); end );
			EntryFrame:SetScript( "OnClick", function () RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Entry_OnClick( offsetKey ); end );
			EntryFrame:Show();
		else
			EntryFrame:Hide();
		end
	end
end

--
function RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Entry_OnClick( itemKey )
	local panelName = "RestockShopInterfaceOptionsPanelShoppingLists";
	_G[panelName .. "ItemIdEditbox"]:SetNumber( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey]["itemId"] );
	_G[panelName .. "FullStockQtyEditbox"]:SetNumber( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey]["fullStockQty"] );
	_G[panelName .. "LowStockPriceEditbox"]:SetNumber( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey]["maxPricePct"]["low"] );
	_G[panelName .. "NormalStockPriceEditbox"]:SetNumber( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey]["maxPricePct"]["normal"] );
	_G[panelName .. "FullStockPriceEditbox"]:SetNumber( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey]["maxPricePct"]["full"] );
	_G[panelName .. "ItemIdEditbox"]:ClearFocus();
	_G[panelName .. "ItemIdEditbox"]:SetFocus();
end

--
function RestockShop_CreateList( shoppingListName, data )
	shoppingListName = strtrim( shoppingListName );
	-- Empty list name
	if shoppingListName == "" then
		print( "RestockShop: " .. L["List name cannot be empty"] );
	else
		-- Duplicate list name
		local duplicate = false;
		for _, list in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] ) do
			if shoppingListName == list["name"] then
				duplicate = true;
				print( "RestockShop: " .. RED_FONT_COLOR_CODE .. L["List not created, that name already exists"] .. "|r" );
				break;
			end
		end
		-- Add new list
		if not duplicate then
			-- Insert into list table
			table.insert( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"], { ["name"] = shoppingListName, ["items"] = {} } );
			-- Copy List? This function also used for copying lists, just copy all items into the new list
			if data then
				RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][#RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"]]["items"] = CopyTable( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"] );
			end
			-- Sort lists
			table.sort ( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"],
				function ( list1, list2 )
					return list1["name"] < list2["name"]; -- Sort by name A-Z
				end
			);
			-- Set newly created list to the selected list
			for k, list in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] ) do
				if shoppingListName == list["name"] then
					RESTOCKSHOP_SAVEDVARIABLESPERCHARACTER["currentListName"] = shoppingListName;
					RESTOCKSHOP_CURRENT_LISTKEY = k;
					break;
				end
			end
			-- Refreshes the dropdown menu and shopping list scrollframe
			RestockShopInterfaceOptionsPanelShoppingLists_Load();
			RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
			-- Notfiy user
			print( "RestockShop: " .. L["List created"] );
		end
	end
end

--
function RestockShop_ImportItems( importString, data )
	--
	local panelName = "RestockShopInterfaceOptionsPanelShoppingLists";
	-- Function: importItem()
	local function importItem( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, maxStack, texture )
		if fullStockQty < 1 or lowStockPrice < 1 or normalStockPrice < 1 or lowStockPrice < normalStockPrice or normalStockPrice < fullStockPrice then
			return false;
		else
			local itemKey = RestockShop_FindItemKey( itemId );
			if not itemKey then
				itemKey = #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"] + 1;
			end
			local itemInfo = {
				["itemId"] = itemId,
				["name"] = name,
				["link"] = link,
				["quality"] = quality,
				["tsmItemString"] = RestockShop_TSMItemString( link ),
				["maxStack"] = maxStack,
				["texture"] = texture,
				["fullStockQty"] = fullStockQty,
				["maxPricePct"] = {
					["low"] = lowStockPrice,
					["normal"] = normalStockPrice,
					["full"] = fullStockPrice
				}
			};
			RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"][itemKey] = itemInfo;
			table.sort ( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][data["shoppingList"]]["items"],
				function ( item1, item2 )
					return item1["name"] < item2["name"]; -- Sort by name A-Z
				end
			);
			--
			return true;
		end
	end
	-- Process non-empty importString submissions
	importString = strtrim( importString );
	if importString ~= "" then
		_G[panelName .. "ImportItemsButton"]:Disable();
		local items, itemsToRecheck, itemsInvalid, importedTotal = RestockShop_Explode( ",", importString ), {}, {}, 0;
		print( "RestockShop: " .. string.format( L["Attempting to import %d items..."], #items ) );
		for k, v in ipairs( items ) do
			local itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice;
			local invalid = false;
			if string.find( v, "^%d+$" ) then
				itemId = v;
			elseif string.find( v, "^%d+:%d+:%d+:%d+:%d+$" ) then
				itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice = strsplit( ":", v );
			end
			if itemId then
				itemId = tonumber( itemId );
				fullStockQty = fullStockQty and tonumber( fullStockQty ) or 1;
				lowStockPrice = lowStockPrice and tonumber( lowStockPrice ) or 100;
				normalStockPrice = normalStockPrice and tonumber( normalStockPrice ) or 100;
				fullStockPrice = fullStockPrice and tonumber( fullStockPrice ) or 0;
				local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( itemId );
				if name then
					if importItem( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, maxStack, texture ) then
						importedTotal = importedTotal + 1;
					else
						invalid = true;
					end
				else
					items[k] = { itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice };
					table.insert( itemsToRecheck, k );
				end
			else
				invalid = true;
			end
			if invalid then
				table.insert( itemsInvalid, v );
			end
		end
		-- Function: completeImport()
		local function completeImport()
			for _, v in ipairs( itemsToRecheck ) do
				local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( items[v][1] );
				if name and importItem( items[v][1], items[v][2], items[v][3], items[v][4], items[v][5], name, link, quality, maxStack, texture ) then
					importedTotal = importedTotal + 1;
				else
					table.insert( itemsInvalid, strjoin( ":" , items[v][1], items[v][2], items[v][3], items[v][4], items[v][5] ) );
				end
			end
			print( "RestockShop: " .. string.format( L["%d of %d items imported"], importedTotal, #items ) );
			if #itemsInvalid > 0 then
				print( "RestockShop: " .. string.format( L["%d invalid item(s) not imported:"], #itemsInvalid ) );
				for _, v in ipairs( itemsInvalid ) do
					print( "RestockShop: " .. RED_FONT_COLOR_CODE .. v .. "|r" );
				end
			end
			RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
			_G[panelName .. "ImportItemsButton"]:Enable();
		end
		--
		local _,_,_,latencyWorld = GetNetStats();
		local delay = math.ceil( #itemsToRecheck * ( ( latencyWorld > 0 and latencyWorld or 300 ) * 0.10 * 0.001 ) );
		if delay > 0 then
			print( "RestockShop: " .. string.format( L["Asking server about %d item(s)... %d second(s) please"], #itemsToRecheck, delay ) );
		end
		RestockShop_TimeDelayFunction( delay, completeImport );
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_AfterAuctionWon()
	RESTOCKSHOP_AILU = "IGNORE"; -- Ignore by default, change below where needed.
	-- NextAuction()
	local function NextAuction( groupKey )
		local auction = RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["auctions"][#RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["auctions"]];
		if RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemId"] == auction["itemId"] and RESTOCKSHOP_AUCTION_SELECT_AUCTION["page"] == auction["page"] then
			RESTOCKSHOP_QUERY_PAGE = auction["page"];
			RESTOCKSHOP_AUCTION_SELECT_FOUND = false;
			RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = groupKey;
			RESTOCKSHOP_AUCTION_SELECT_AUCTION = auction; -- Cannot use index, ownerFullName, or buyoutPrice yet, these may change after scanning the page
			if RESTOCKSHOP_BUYALL and groupKey == 1 then
				RestockShopFrame_ScrollFrame:SetVerticalScroll( 0 ); -- Scroll to top when first group is selected during Buy All
			end
			RestockShopFrame_ScrollFrame_Update(); -- Highlight the selected group
			RestockShop_StartScanning();
			RESTOCKSHOP_AILU = "LISTEN";
		else
			RestockShopFrame_ScrollFrame_Entry_OnClick( groupKey ); -- Item wasn't the same or wasn't on the same page, this will send a new QueryAuctionItems()
		end
	end
	-- NoGroupKey()
	local function NoGroupKey()
		if next( RESTOCKSHOP_AUCTION_DATA_GROUPS ) then
			-- More auction exist
			if RESTOCKSHOP_BUYALL then
				NextAuction( 1 );
			else
				RestockShopFrame_ScrollFrame_Auction_Deselect();
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
				RestockShopFrame_BuyAllButton:Enable();
			end
		else
			-- No auctions exist
			RestockShopFrame_ScrollFrame_Auction_Deselect();
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
			RestockShopFrame_BuyAllButton_Reset();
		end
	end
	-- Full Stock Qty notice
	if RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["onHandQty"] < RESTOCKSHOP_AUCTION_SELECT_AUCTION["fullStockQty"] and ( RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["onHandQty"] + RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"] ) >= RESTOCKSHOP_AUCTION_SELECT_AUCTION["fullStockQty"] then
		print( "RestockShop: " .. string.format( L["You reached the %sFull Stock Qty|r of %s%d|r on %s"], NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_FULL_COLOR_CODE, RESTOCKSHOP_AUCTION_SELECT_AUCTION["fullStockQty"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemLink"] ) );
	end
	--
	RestockShopFrame_ShopButton:Enable();
	--
	RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] = RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] - 1;
	--
	if RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["numAuctions"] == 0 then
		-- Group removed
		table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS, RESTOCKSHOP_AUCTION_SELECT_GROUPKEY );
		RestockShop_AuctionDataGroups_OnHandQtyChanged();
		RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = nil;
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
		NoGroupKey();
	else
		-- Single auction removed
		table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS[RESTOCKSHOP_AUCTION_SELECT_GROUPKEY]["auctions"] );
		RestockShop_AuctionDataGroups_OnHandQtyChanged();
		RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = RestockShop_FindGroupKey( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemId"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["name"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"] );
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update();
		RestockShopFrame_FlyoutPanel_Footer:SetText( RestockShopFrame_ListSummary() );
		if not RESTOCKSHOP_AUCTION_SELECT_GROUPKEY then
			NoGroupKey();
		else
			NextAuction( RESTOCKSHOP_AUCTION_SELECT_GROUPKEY );
		end
	end
end

--
function RestockShop_AddTooltipData( self, ... )
	if not RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["shoppingListSettings"] and not RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["itemId"] then return end
	-- Get Item Id
	local itemName, itemLink = self:GetItem();
	local itemId = itemLink and tonumber( string.match( itemLink, "item:(%d+):" ) ) or nil;
	if not itemId then return end
	-- Shopping List Settings
	if RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["shoppingListSettings"] then
		local itemKey = RestockShop_FindItemKey( itemId );
		if itemKey then
			-- Item found in current shopping list
			if strtrim( _G[self:GetName() .. "TextLeft" .. self:NumLines()]:GetText() ) ~= "" then
				self:AddLine( " " ); -- Blank line at top
			end
			-- Prepare data
			local item = RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey];
			local itemValue = TSMAPI:GetItemValue( item["link"], RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] );
			local onHandQty, restockPct, maxPrice, restock = RestockShop_QOH( item["tsmItemString"] ), nil, nil, nil;
			if type( itemValue ) ~= "number" or itemValue == 0 then
				itemValue = nil;
			else
				restockPct = RestockShop_RestockPct( onHandQty, item["fullStockQty"] );
				maxPrice, restock = RestockShop_MaxPrice( itemValue, restockPct, item["maxPricePct"], "returnRestock" );
				-- Format settings info
				itemValue = TSMAPI:FormatTextMoney( itemValue, "|cffffffff", true );
				maxPrice = ( maxPrice > 0 ) and ( TSMAPI:FormatTextMoney( maxPrice, "|cffffffff", true ) .. " " ) or ""; -- If full stock and no full price then leave it blank
				local restockColor = ( restockPct >= 100 and item["maxPricePct"]["full"] == 0 ) and GRAY_FONT_COLOR_CODE or _G["RESTOCKSHOP_" .. string.upper( restock ) .. "_COLOR_CODE"];
				restockPct = restockColor .. math.floor( restockPct ) .. "%|r";
				restock = restockColor .. L[restock] .. "|r";
			end
			-- Add lines to tooltip
			self:AddLine( "|cffffff00RestockShop:" );
			self:AddLine( "  |cff7674d9" .. L["List"] .. ":|r |cffffffff" .. RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"] );
			self:AddLine( "  |cff7674d9" .. L["On Hand"] .. ":|r |cffffffff" .. onHandQty .. "|r" .. ( restockPct and ( " |cff7674d9(|r" .. restockPct .. "|cff7674d9)|r" ) or "" ) );
			self:AddLine( "  |cff7674d9" .. L["Full Stock Qty"] .. ":|r |cffffffff" .. item["fullStockQty"] );
			self:AddLine( "  |cff7674d9" .. L["Low"] .. ":|r |cffffffff" .. item["maxPricePct"]["low"] .. "%" );
			self:AddLine( "  |cff7674d9" .. L["Norm"] .. ":|r |cffffffff" .. item["maxPricePct"]["normal"] .. "%" );
			self:AddLine( "  |cff7674d9" .. L["Full"] .. ":|r |cffffffff" .. ( ( item["maxPricePct"]["full"] > 0 ) and ( item["maxPricePct"]["full"] .. "%" ) or "-" ) );
			self:AddLine( "  |cff7674d9" .. L["Item Value"] .. ":|r |cffffffff" .. ( itemValue and ( itemValue .. " |cff7674d9(" .. RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] .. ")|r" ) or ( "|cffff2020" .. string.format( L["Requires %s Data"], RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] ) .. "|r" ) ) );
			self:AddLine( "  |cff7674d9" .. L["Max Price"] .. ":|r " .. ( maxPrice and ( maxPrice .. "|cff7674d9(|r" .. restock .. "|cff7674d9)|r"  ) or "|cffff2020" .. L["Requires Item Value"] .. "|r" ) );
			self:AddLine( " " ); -- Blank line at bottom
		end
	end
	-- Item Id
	if RESTOCKSHOP_SAVEDVARIABLES["itemTooltip"]["itemId"] then
		self:AddLine( L["Item ID"] .. " " .. itemId  );
	end
	-- Makes added lines show immediately
	self:Show();
end

--
function RestockShop_WoWClientBuildChanged()
	-- Forward Declarations
	local listKey, queueList;
	-- Function: updateItem()
	local function updateItem( listKey, itemKey, name, link, quality, maxStack, texture )
		RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["name"] = name or RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["name"];
		RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["link"] = link or RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["link"];
		RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["quality"] = quality or 0;
		RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["maxStack"] = maxStack or RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["maxStack"];
		RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"][itemKey]["texture"] = texture or "Interface\\ICONS\\INV_Misc_QuestionMark";
	end
	-- Function: updateList()
	local function updateList()
		for itemKey, item in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"] ) do
			local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( item["itemId"] );
			updateItem( listKey, itemKey, name, link, quality, maxStack, texture );
		end
		--
		table.sort ( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"],
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
		for itemKey, item in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"] ) do
			local name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( item["itemId"] );
		end
		--
		local _,_,_,latencyWorld = GetNetStats();
		local delay = math.ceil( #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["items"] * ( ( latencyWorld > 0 and latencyWorld or 300 ) * 0.10 * 0.001 ) );
		delay = delay > 0 and delay or 1;
		RestockShop_TimeDelayFunction( delay, updateList );
	end
	-- Forward Declared Function: queueList()
	queueList = function()
		if listKey <= #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"] then
			if RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][listKey]["name"] then
				queryList();
			else
				listKey = listKey + 1;
				queueList();
			end
		else
			-- Update complete, save new build
			RESTOCKSHOP_SAVEDVARIABLES["wowClientBuild"] = RESTOCKSHOP_WOW_CLIENT_BUILD;
		end
	end
	--
	listKey = 1;
	RestockShop_TimeDelayFunction( 30, queueList ); -- Delay allows time for WoW client to establish latency
end

--
function RestockShop_SortAuctionDataGroups()
	if not next( RESTOCKSHOP_AUCTION_DATA_GROUPS ) then return end
	table.sort ( RESTOCKSHOP_AUCTION_DATA_GROUPS,
		function ( item1, item2 )
			if RESTOCKSHOP_AUCTION_DATA_SORT_ORDER == "ASC" then
				if RESTOCKSHOP_AUCTION_DATA_SORT_KEY ~= "pctMaxPrice" and item1[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] == item2[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] then
					return item1["pctMaxPrice"] < item2["pctMaxPrice"];
				else
					return item1[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] < item2[RESTOCKSHOP_AUCTION_DATA_SORT_KEY];
				end
			elseif RESTOCKSHOP_AUCTION_DATA_SORT_ORDER == "DESC" then
				if RESTOCKSHOP_AUCTION_DATA_SORT_KEY ~= "pctMaxPrice" and item1[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] == item2[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] then
					return item1["pctMaxPrice"] < item2["pctMaxPrice"];
				else
					return item1[RESTOCKSHOP_AUCTION_DATA_SORT_KEY] > item2[RESTOCKSHOP_AUCTION_DATA_SORT_KEY];
				end
			end
		end
	);
	-- Have to find the groupKey again if you reorder them
	if RESTOCKSHOP_AUCTION_SELECT_GROUPKEY then
		RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = RestockShop_FindGroupKey( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemId"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["name"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"] );
	end
end

--
function RestockShop_FindGroupKey( itemId, name, count, itemPrice )
	for k, v in ipairs( RESTOCKSHOP_AUCTION_DATA_GROUPS ) do
		if v["itemId"] == itemId and v["name"] == name and v["count"] == count and v["itemPrice"] == itemPrice then
			return k;
		end
	end
	return nil;
end

--
function RestockShop_FindItemKey( itemId, shoppingList )
	shoppingList = shoppingList or RESTOCKSHOP_CURRENT_LISTKEY;
	for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][shoppingList]["items"] ) do
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
	RESTOCKSHOP_CAN_BID = enable;
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
	local options = RESTOCKSHOP_SAVEDVARIABLES["qoh"];
	local currentPlayerTotal, otherPlayersTotal = TSMAPI:ModuleAPI( "ItemTracker", "playertotal", tsmItemString ); -- Bags, Bank, and Mail
	if options["allCharacters"] == 1 then
		-- All Characters
		qoh = qoh + currentPlayerTotal + otherPlayersTotal; -- Bags, Bank, and Mail
		qoh = qoh + TSMAPI:ModuleAPI( "ItemTracker", "auctionstotal", tsmItemString ); -- Auction Listings
		if options["guilds"] then
			qoh = qoh + TSMAPI:ModuleAPI( "ItemTracker", "guildtotal", tsmItemString ); -- Guild Bank
		end
	elseif options["allCharacters"] == 2 then
		-- Current Character
		qoh = qoh + currentPlayerTotal;
		local playerAuctions = TSMAPI:ModuleAPI( "ItemTracker", "playerauctions", GetUnitName( "player" ) ); -- Auction Listings
		qoh = qoh + ( playerAuctions[tsmItemString] or 0 );
		if options["guilds"] then
			local guild,_,_ = GetGuildInfo( "player" );
			if guild then
				local guildBank = TSMAPI:ModuleAPI( "ItemTracker", "guildbank", guild );
				qoh = qoh + ( guildBank[tsmItemString] or 0 );
			end
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
	if restockPct < RESTOCKSHOP_SAVEDVARIABLES["lowStockPct"] then
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
function RestockShop_AuctionDataGroups_OnHandQtyChanged()
	-- Remove: If restockPct is 100+ and no maxPricePct["full"] ---OR--- If pctMaxPrice is over 100
	-- Update: onHandQty, restockPct, pctMaxPrice
	-- This function should be run when an auction is won, uses the RESTOCKSHOP_AUCTION_SELECT_AUCTION
	-- ONLY Updates or Removes Groups for the ItemId that was won
	local groupKey = 1;
	while groupKey <= #RESTOCKSHOP_AUCTION_DATA_GROUPS do
		local group = RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey];
		if group["itemId"] == RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemId"] then
			local onHandQty = RestockShop_QOH( group["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, group["fullStockQty"] );
			local pctMaxPrice = math.ceil( ( group["itemPrice"] * 100 ) / RestockShop_MaxPrice( group["itemValue"], restockPct, RESTOCKSHOP_ITEMS[group["itemId"]]["maxPricePct"] ) );
			--
			if ( restockPct >= 100 and RESTOCKSHOP_ITEMS[group["itemId"]]["maxPricePct"]["full"] == 0 ) or pctMaxPrice > 100 then
				-- Remove
				table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS, groupKey );
			else
				-- Update
				RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["onHandQty"] = onHandQty;
				RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["restockPct"] = restockPct;
				RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["pctMaxPrice"] = pctMaxPrice;
				groupKey = groupKey + 1; -- INCREMENT ONLY IF NOT REMOVING. table.remove resequences the groupKeys, making the next actual group takeover the same groupKey you just deleted.
			end
		else
			groupKey = groupKey + 1; -- ItemId wasn't a match, increment to try the next group
		end
	end
end

--
function RestockShop_AuctionDataGroups_RemoveItemId( itemId )
	-- This function is run just before raw data from a RESCAN is used to form new data groups, out with the old before in with the new
	local groupKey = 1;
	while groupKey <= #RESTOCKSHOP_AUCTION_DATA_GROUPS do
		if RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["itemId"] == itemId then
			-- Match, remove group
			table.remove( RESTOCKSHOP_AUCTION_DATA_GROUPS, groupKey );
		else
			-- Not a match, increment to try next group
			groupKey = groupKey + 1;
		end
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Scan Functions
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_StartScanning()
	RESTOCKSHOP_SCANNING = true;
	RestockShop_SetCanBid( false );
	RestockShopFrame_ShopButton:SetText( L["Abort"] );
	RestockShopFrame_BuyAllButton:Disable();
end

--
function RestockShop_StopScanning()
	RestockShopEventsFrame:UnregisterEvent( "AUCTION_ITEM_LIST_UPDATE" );
	RESTOCKSHOP_SCANNING = false;
	RESTOCKSHOP_QUERY_PAGE = 0;
	RESTOCKSHOP_QUERY_ATTEMPTS = 1;
	RESTOCKSHOP_QUERY_BATCH_ATTEMPTS = 1;
	RestockShopFrame_ShopButton:Enable();
end

--
function RestockShop_ScanAuctionQueue()
	if RESTOCKSHOP_SCANNING then return end
	if RESTOCKSHOP_SCAN_TYPE == "SHOP" then
		local footerText = ( function()
			if #RESTOCKSHOP_QUERY_QUEUE == 0 then
				return RestockShopFrame_ListSummary();
			else
				return string.format( L["%d items remaining"], #RESTOCKSHOP_QUERY_QUEUE );
			end
		end )();
		RestockShopFrame_FlyoutPanel_Footer:SetText( footerText );
	end
	if not next( RESTOCKSHOP_QUERY_QUEUE ) then
		-- Auction scan complete, queue empty
		if RESTOCKSHOP_SCAN_TYPE ~= "SELECT" then
			-- Assemble into sortable groups (itemid has x stacks of y for z copper)
			if RESTOCKSHOP_SCAN_TYPE == "RESCAN" then
				-- Remove groups for rescanned item, new groups will be created from raw data
				RestockShop_AuctionDataGroups_RemoveItemId( RESTOCKSHOP_QUERY_ITEM["itemId"] );
			end
			--
			for itemId, pages in pairs( RESTOCKSHOP_AUCTION_DATA_RAW ) do -- [ItemId] => [Page] => [Index] => ItemInfo
				for page, indexes in pairs( pages ) do
					for index, itemInfo in pairs( indexes ) do
						local groupKey = RestockShop_FindGroupKey( itemInfo["itemId"], itemInfo["name"], itemInfo["count"], itemInfo["itemPrice"] );
						if groupKey then
							table.insert( RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["auctions"], itemInfo );
							RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["numAuctions"] = RESTOCKSHOP_AUCTION_DATA_GROUPS[groupKey]["numAuctions"] + 1;
						else
							table.insert( RESTOCKSHOP_AUCTION_DATA_GROUPS, {
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
			RestockShop_SortAuctionDataGroups();
			RestockShopFrame_ScrollFrame_Update();
		end
		RestockShop_ScanComplete();
		return; -- Stop function, queue is empty, scan completed
	end
	-- Remove and query last item in the queue
	RESTOCKSHOP_QUERY_ITEM = table.remove( RESTOCKSHOP_QUERY_QUEUE );
	RestockShopFrame_FlyoutPanel_ScrollFrame_Update(); -- Update scanTexture and Highlight query item, also moves vertical scroll
	--
	RestockShop_StartScanning();
	--
	if RESTOCKSHOP_SCAN_TYPE ~= "SELECT" then
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Scanning"] .. " " .. RESTOCKSHOP_QUERY_ITEM["name"] .. "..." );
	end
	--
	local itemValue = TSMAPI:GetItemValue( RESTOCKSHOP_QUERY_ITEM["link"], RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] );
	--
	if type( itemValue ) ~= "number" or itemValue <= 0 then
		-- Skipping: No Item Value
		print( "RestockShop: " .. string.format( L["Skipping %s: %sRequires %s data|r"], RESTOCKSHOP_QUERY_ITEM["link"], RED_FONT_COLOR_CODE, RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] ) );
		RESTOCKSHOP_ITEMS[RESTOCKSHOP_QUERY_ITEM["itemId"]]["scanTexture"] = "NotReady";
		RestockShop_StopScanning();
		RestockShop_ScanAuctionQueue();
	elseif RESTOCKSHOP_QUERY_ITEM["maxPricePct"]["full"] == 0 and RestockShop_QOH( RESTOCKSHOP_QUERY_ITEM["tsmItemString"] ) >= RESTOCKSHOP_QUERY_ITEM["fullStockQty"] then
		-- Skipping: Full Stock Qty reached and no Full price set
		--print( "RestockShop: " .. string.format( L["Skipping %s: %sFull Stock Qty|r reached and no %sFull|r price set"], RESTOCKSHOP_QUERY_ITEM["link"], NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_FULL_COLOR_CODE ) );
		RESTOCKSHOP_ITEMS[RESTOCKSHOP_QUERY_ITEM["itemId"]]["scanTexture"] = "NotReady";
		RestockShop_StopScanning();
		RestockShop_ScanAuctionQueue();
	else
		-- OK: SendAuctionQuery()
		if RESTOCKSHOP_SCAN_TYPE ~= "SELECT" then
			RESTOCKSHOP_AUCTION_DATA_RAW[RESTOCKSHOP_QUERY_ITEM["itemId"]] = {}; -- Select scan only reads, it won't be rewriting the raw data
		end
		RestockShop_SendAuctionQuery();
	end
end

--
function RestockShop_SendAuctionQuery()
	if not RESTOCKSHOP_SCANNING then return end
	if CanSendAuctionQuery() and RESTOCKSHOP_AILU ~= "IGNORE" then
		RESTOCKSHOP_QUERY_ATTEMPTS = 1; -- Set to default on successful attempt
		local name = RESTOCKSHOP_QUERY_ITEM["name"];
		local page = RESTOCKSHOP_QUERY_PAGE or nil;
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
	elseif RESTOCKSHOP_QUERY_ATTEMPTS < RESTOCKSHOP_QUERY_MAX_ATTEMPTS then
		-- Increment attempts, delay and reattempt
		RESTOCKSHOP_QUERY_ATTEMPTS = RESTOCKSHOP_QUERY_ATTEMPTS + 1;
		RestockShop_TimeDelayFunction( 0.10, RestockShop_SendAuctionQuery );
	else
		-- Aborting scan of this item, return to queue if NOT SELECT
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Could not query Auction House after several attempts, please try again in a few moments"] );
		RestockShop_StopScanning();
		if RESTOCKSHOP_SCAN_TYPE == "SELECT" then
			RestockShopFrame_ScrollFrame_Auction_Deselect(); -- Select failed, deselect auction and allow user to manually click again
			return; -- Stop function, a failed Select should never be allowed to complete, just deselect or rescan
		end
		RestockShop_ScanAuctionQueue();
	end
end

--
function RestockShop_ScanAuctionPage()
	if not RESTOCKSHOP_SCANNING then return end
	if RESTOCKSHOP_SCAN_TYPE ~= "SELECT" then
		RESTOCKSHOP_AUCTION_DATA_RAW[RESTOCKSHOP_QUERY_ITEM["itemId"]][RESTOCKSHOP_QUERY_PAGE] = {};
		RestockShopFrame_DialogFrame_StatusFrame_Update( string.format( L["Scanning %s: Page %d of %d"], RESTOCKSHOP_QUERY_ITEM["name"], ( RESTOCKSHOP_QUERY_PAGE + 1 ), RESTOCKSHOP_QUERY_TOTAL_PAGES ) );
	end
	local incompleteData = false;
	for i = 1, RESTOCKSHOP_QUERY_NUM_BATCH_AUCTIONS do
		-- name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo
		local name,texture,count,quality,_,_,_,_,_,buyoutPrice,_,_,_,_,ownerFullName,_,itemId,_ = GetAuctionItemInfo( "list", i );
		ownerFullName = ownerFullName or owner or "Unknown"; -- Note: Auction may not have an owner(FullName), the character could have been deleted
		if itemId == RESTOCKSHOP_QUERY_ITEM["itemId"] and buyoutPrice > 0 then
			local onHandQty = RestockShop_QOH( RESTOCKSHOP_QUERY_ITEM["tsmItemString"] );
			local restockPct = RestockShop_RestockPct( onHandQty, RESTOCKSHOP_QUERY_ITEM["fullStockQty"] );
			local itemValue = TSMAPI:GetItemValue( RESTOCKSHOP_QUERY_ITEM["link"], RESTOCKSHOP_SAVEDVARIABLES["itemValueSrc"] );
			local itemPrice = math.ceil( buyoutPrice / count );
			local maxPrice = RestockShop_MaxPrice( itemValue, restockPct, RESTOCKSHOP_QUERY_ITEM["maxPricePct"] );
			local pctMaxPrice = ( itemPrice * 100 ) / maxPrice;
			if itemPrice <= maxPrice then
				if ownerFullName ~= GetUnitName( "player" ) then
					-- Matching Auction, record info
					if RESTOCKSHOP_SCAN_TYPE == "SELECT" then
						-- SELECT match found?
						if not RESTOCKSHOP_AUCTION_SELECT_FOUND and RESTOCKSHOP_AUCTION_SELECT_AUCTION["name"] == name and RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"] == count and RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"] == itemPrice then
							RESTOCKSHOP_AUCTION_SELECT_FOUND = true;
							RESTOCKSHOP_AUCTION_SELECT_AUCTION["index"] = i;
							RESTOCKSHOP_AUCTION_SELECT_AUCTION["buyoutPrice"] = buyoutPrice;
							RESTOCKSHOP_AUCTION_SELECT_AUCTION["ownerFullName"] = ownerFullName;
							break; -- Not recording any additional data, just stop loop and continue on below to page scan completion checks
						end
					else
						-- Record raw data if not a SELECT scan
						RESTOCKSHOP_AUCTION_DATA_RAW[itemId][RESTOCKSHOP_QUERY_PAGE][i] = {
							["restockPct"] = restockPct,
							["name"] = name,
							["texture"] = texture,
							["count"] = count,
							["quality"] = quality,
							["itemPrice"] = itemPrice,
							["buyoutPrice"] = buyoutPrice,
							["pctMaxPrice"] = pctMaxPrice,
							["ownerFullName"] = ownerFullName,
							["itemId"] = itemId,
							["itemLink"] = RESTOCKSHOP_QUERY_ITEM["link"],
							["itemValue"] = itemValue,
							["tsmItemString"] = RESTOCKSHOP_QUERY_ITEM["tsmItemString"],
							["onHandQty"] = onHandQty,
							["fullStockQty"] = RESTOCKSHOP_QUERY_ITEM["fullStockQty"],
							["page"] = RESTOCKSHOP_QUERY_PAGE,
							["index"] = i,
						};
					end
				end
			elseif ( not incompleteData or ( incompleteData and RESTOCKSHOP_QUERY_BATCH_ATTEMPTS == RESTOCKSHOP_QUERY_MAX_BATCH_ATTEMPTS ) ) and count == RESTOCKSHOP_QUERY_ITEM["maxStack"] then
				-- Item scan complete, max price exceeded ... maybe ...
				-- *** <Random Enchantment> *** Only stop at max price if item is NOT randomly enchanted because the alphabetical name sorting throws off the buyout sorting for identical item ID's
				local _,_,_,_,_,_,_,suffixId = strsplit( ":", string.match( GetAuctionItemLink( "list", i ), "item[%-?%d:]+" ) );
				if suffixId == "0" then
					-- Not a <Random Enchantment> item, stop scanning, max price exceeded
					RESTOCKSHOP_ITEMS[RESTOCKSHOP_QUERY_ITEM["itemId"]]["scanTexture"] = "Ready";
					RestockShop_StopScanning();
					if RESTOCKSHOP_SCAN_TYPE == "SELECT" and not RESTOCKSHOP_AUCTION_SELECT_FOUND then
						print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item not found, rescanning item"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemLink"], YELLOW_FONT_COLOR_CODE, RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], TSMAPI:FormatTextMoney( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"], "|cffffffff", true ) ) );
						RestockShop_RescanItem();
						return; -- Stop function, starting rescan
					end
					RestockShop_ScanAuctionQueue(); -- Return to queue
					return; -- Stop function
				end
			end
		end
	end
	-- Page scan data incomplete, requery page
	if incompleteData and RESTOCKSHOP_QUERY_BATCH_ATTEMPTS < RESTOCKSHOP_QUERY_MAX_BATCH_ATTEMPTS then
		RESTOCKSHOP_QUERY_BATCH_ATTEMPTS = RESTOCKSHOP_QUERY_BATCH_ATTEMPTS + 1;
		RestockShop_TimeDelayFunction( 0.25, RestockShop_SendAuctionQuery ); -- Delay for missing data to be provided
		return; -- Stop function, requery in progress
	end
	-- Page scan complete, query next page unless doing SELECT scan
	if RESTOCKSHOP_SCAN_TYPE ~= "SELECT" and RESTOCKSHOP_QUERY_PAGE < ( RESTOCKSHOP_QUERY_TOTAL_PAGES - 1 ) then -- Subtract 1 because the first page is 0
		RESTOCKSHOP_QUERY_PAGE = RESTOCKSHOP_QUERY_PAGE + 1; -- Increment to next page
		RESTOCKSHOP_QUERY_BATCH_ATTEMPTS = 1; -- Reset to default
		RestockShop_SendAuctionQuery(); -- Send query for next page to scan
	else
	-- Item scan completed
		RESTOCKSHOP_ITEMS[RESTOCKSHOP_QUERY_ITEM["itemId"]]["scanTexture"] = "Ready";
		RestockShop_StopScanning();
		if RESTOCKSHOP_SCAN_TYPE == "SELECT" and not RESTOCKSHOP_AUCTION_SELECT_FOUND then
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item not found, rescanning item"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemLink"], YELLOW_FONT_COLOR_CODE, RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], TSMAPI:FormatTextMoney( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"], "|cffffffff", true ) ) );
			RestockShop_RescanItem();
			return; -- Stop function, starting rescan
		end
		RestockShop_ScanAuctionQueue(); -- Return to queue
	end
end

--
function RestockShop_ScanComplete()
	if RESTOCKSHOP_SCAN_TYPE == "SHOP" then
		-- Shop
		if RestockShop_Count( RESTOCKSHOP_ITEMS ) > 1 then
			RESTOCKSHOP_QUERY_ITEM = {}; -- Reset to unlock highlight when scanning more than one item
		end
		RestockShopFrame_FlyoutPanel_ScrollFrame_Update(); -- Update scanTexture and Highlight
		--
		if next( RESTOCKSHOP_AUCTION_DATA_GROUPS ) then
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
			RestockShopFrame_BuyAllButton:Enable();
		else
			RestockShopFrame_DialogFrame_StatusFrame_Update( L["No auctions were found that matched your settings"] );
		end
	elseif RESTOCKSHOP_SCAN_TYPE == "SELECT" then
		-- Select, this scan type only completes if it found what it was looking for, always. Otherwise it would generate a rescan.
		local auction = RESTOCKSHOP_AUCTION_SELECT_AUCTION;
		local _,_,_,hexColor = GetItemQualityColor( auction["quality"] );
		local BuyoutFrameName = "RestockShopFrame_DialogFrame_BuyoutFrame";
		_G[BuyoutFrameName .. "_TextureFrame_Texture"]:SetTexture( auction["texture"] );
		_G[BuyoutFrameName .. "_TextureFrame"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( auction["itemLink"] ); end );
		_G[BuyoutFrameName .. "_TextureFrame"]:SetScript( "OnLeave", function( self ) GameTooltip:Hide(); end );
		_G[BuyoutFrameName .. "_DescriptionFrame_Text"]:SetText( "|c" .. hexColor .. auction["name"] .. "|r x " .. auction["count"] );
		MoneyFrame_Update( BuyoutFrameName .. "_SmallMoneyFrame", auction["buyoutPrice"] );
		RestockShop_SetCanBid( true );
		RestockShopFrame_DialogFrame_BuyoutFrame_SetActive();
		RestockShopFrame_BuyAllButton:Enable();
	elseif RESTOCKSHOP_SCAN_TYPE == "RESCAN" then
		-- Rescanned the specific item from the selected group. If the group exists after a rescan, then reselect it.
		RESTOCKSHOP_AUCTION_SELECT_GROUPKEY = RestockShop_FindGroupKey( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemId"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["name"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"] );
		if not RESTOCKSHOP_AUCTION_SELECT_GROUPKEY then
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item not found after rescan"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemLink"], YELLOW_FONT_COLOR_CODE, RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], TSMAPI:FormatTextMoney( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"], "|cffffffff", true ) ) );
			if next( RESTOCKSHOP_AUCTION_DATA_GROUPS ) then
				if RESTOCKSHOP_BUYALL then
					RestockShopFrame_ScrollFrame_Entry_OnClick( 1 );
				else
					RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
					RestockShopFrame_ScrollFrame_Auction_Deselect();
					RestockShopFrame_BuyAllButton:Enable();
				end
			else
				RestockShopFrame_DialogFrame_StatusFrame_Update( L["No additional auctions matched your settings"] );
				RestockShopFrame_ScrollFrame_Auction_Deselect();
				RestockShopFrame_BuyAllButton_Reset();
			end
		else
			print( "RestockShop: " .. string.format( L["%s%sx%d|r for %s per item was found after rescan"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemLink"], YELLOW_FONT_COLOR_CODE, RESTOCKSHOP_AUCTION_SELECT_AUCTION["count"], TSMAPI:FormatTextMoney( RESTOCKSHOP_AUCTION_SELECT_AUCTION["itemPrice"], "|cffffffff", true ) ) );
			RestockShopFrame_ScrollFrame_Entry_OnClick( RESTOCKSHOP_AUCTION_SELECT_GROUPKEY );
		end
	end
	--
	RestockShopFrame_ShopButton_Reset();
end

--
function RestockShop_RescanItem()
	RESTOCKSHOP_AUCTION_DATA_RAW = {};
	RESTOCKSHOP_QUERY_QUEUE = {};
	table.insert( RESTOCKSHOP_QUERY_QUEUE, RESTOCKSHOP_ITEMS[RESTOCKSHOP_QUERY_ITEM["itemId"]] );
	RESTOCKSHOP_SCAN_TYPE = "RESCAN";
	RestockShop_ScanAuctionQueue();
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------------------------------------------------------------------
function RestockShop_SlashCmdHandler( msg )
	if msg == "sl" or msg == "shoppinglists" then
		InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanelShoppingLists"] );
		InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanelShoppingLists"] );
	elseif msg == "acceptbuttonclick" then
		if not RESTOCKSHOP_CAN_BID then return end
		RestockShopFrame_DialogFrame_BuyoutFrame_AcceptButton:Click();
	elseif msg ~= "" then
		print( "RestockShop: " .. L["Unknown command"] );
	else
		InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanel"] );
		InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanel"] );
	end
end
--
SLASH_RESTOCKSHOP1 = "/restockshop";
SLASH_RESTOCKSHOP2 = "/rs";
SlashCmdList["RESTOCKSHOP"] = RestockShop_SlashCmdHandler;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Create Frames
--------------------------------------------------------------------------------------------------------------------------------------------
local f, fs, tx = nil, nil, nil;
local backdrop1 = { ["bgFile"] = "Interface\\DialogFrame\\UI-DialogBox-Background", ["tile"] = true, ["tileSize"] = 64, ["insets"] = { ["left"] = 5, ["right"] = 5, ["top"] = 5, ["bottom"] = 5 } };
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopInterfaceOptionsPanelParent
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopInterfaceOptionsPanelParent", UIParent );
f:Hide();
f:SetScript( "OnShow", function ( self )
	InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanel"] );
end );
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopInterfaceOptionsPanel
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopInterfaceOptionsPanel", UIParent );
f:Hide();
f:SetBackdrop( backdrop1 );
f:SetScript( "OnShow", function ( self )
	if RestockShopFrame:IsShown() then
		AuctionFrameTab1:Click();
	end
	RestockShopInterfaceOptionsPanel_Load();
end );
-- RestockShopInterfaceOptionsPanel > Title
fs = f:CreateFontString( "$parentTitle", "ARTWORK", "GameFontNormalLarge" );
fs:SetText( "RestockShop /rs" );
fs:SetJustifyH( "LEFT" );
fs:SetJustifyV( "TOP" );
fs:SetPoint( "TOPLEFT", 16, -16 );
-- RestockShopInterfaceOptionsPanel > SubText
fs = f:CreateFontString( "$parentSubText", "ARTWORK", "GameFontHighlightSmall" );
fs:SetText( string.format( L["These options allow you to control how %s\"Item Value\"|r and %s\"On Hand\"|r quantities are calculated. %s\"Low Stock %%\"|r determines at what %s\"On Hand\"|r percentage of %s\"Full Stock Qty\"|r an item's max price becomes the %s\"Low\"|r setting."], NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_LOW_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_LOW_COLOR_CODE ) );
fs:SetNonSpaceWrap( true );
fs:SetMaxLines( 3 );
fs:SetJustifyH( "LEFT" );
fs:SetJustifyV( "TOP" );
fs:SetSize( 0, 32 );
fs:SetPoint( "TOPLEFT", "$parentTitle", "BOTTOMLEFT", 0, -8 );
fs:SetPoint( "RIGHT", -32, 0 );
-- RestockShopInterfaceOptionsPanel > ItemValueSrcDropDownMenuLabel
f = CreateFrame( "Frame", "$parentItemValueSrcDropDownMenuLabel", RestockShopInterfaceOptionsPanel );
f:SetSize( 200, 20 );
f:SetPoint( "TOPLEFT", "$parentSubText", "BOTTOMLEFT", 0, -8 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Item Value Source (Auctionator, Auctioneer, AuctionDB, WoWuction)"] );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanel > ItemValueSrcDropDownMenu
f = CreateFrame( "Frame", "$parentItemValueSrcDropDownMenu", RestockShopInterfaceOptionsPanel, "UIDropDownMenuTemplate" );
f:SetPoint( "TOPLEFT", "$parentItemValueSrcDropDownMenuLabel", "BOTTOMLEFT", -12, 2 );
-- RestockShopInterfaceOptionsPanel > QOHAllCharactersDropDownMenuLabel
f = CreateFrame( "Frame", "$parentQOHAllCharactersDropDownMenuLabel", RestockShopInterfaceOptionsPanel );
f:SetSize( 200, 20 );
f:SetPoint( "TOPLEFT", "$parentItemValueSrcDropDownMenu", "BOTTOMLEFT", 12, -8 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["On Hand Tracking (TSM ItemTracker)"] );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanel > QOHAllCharactersDropDownMenu
f = CreateFrame( "Frame", "$parentQOHAllCharactersDropDownMenu", RestockShopInterfaceOptionsPanel, "UIDropDownMenuTemplate" );
f:SetPoint( "TOPLEFT", "$parentQOHAllCharactersDropDownMenuLabel", "BOTTOMLEFT", -12, 2 );
-- RestockShopInterfaceOptionsPanel > QOHGuildsCheckButton
f = CreateFrame( "CheckButton", "$parentQOHGuildsCheckButton", RestockShopInterfaceOptionsPanel, "InterfaceOptionsSmallCheckButtonTemplate" );
f:SetPoint( "TOPLEFT", "$parentQOHAllCharactersDropDownMenu", "TOPRIGHT", -2, -1 );
_G[f:GetName() .. 'Text']:SetText( L["Include Guild Bank(s)"] );
-- RestockShopInterfaceOptionsPanel > LowStockPctDropDownMenuLabel
f = CreateFrame( "Frame", "$parentLowStockPctDropDownMenuLabel", RestockShopInterfaceOptionsPanel );
f:SetSize( 200, 20 );
f:SetPoint( "TOPLEFT", "$parentQOHAllCharactersDropDownMenu", "BOTTOMLEFT", 12, -8 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( string.format( L["%sLow Stock %%|r (Percent of Item's Full Stock Qty)"], RESTOCKSHOP_LOW_COLOR_CODE ) );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanel > LowStockPctDropDownMenu
f = CreateFrame( "Frame", "$parentLowStockPctDropDownMenu", RestockShopInterfaceOptionsPanel, "UIDropDownMenuTemplate" );
f:SetPoint( "TOPLEFT", "$parentLowStockPctDropDownMenuLabel", "BOTTOMLEFT", -12, 2 );
-- RestockShopInterfaceOptionsPanel > ItemTooltipLabel
f = CreateFrame( "Frame", "$parentItemTooltipLabel", RestockShopInterfaceOptionsPanel );
f:SetSize( 200, 20 );
f:SetPoint( "TOPLEFT", "$parentLowStockPctDropDownMenu", "BOTTOMLEFT", 12, -8 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Item Tooltip"] );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanel > ItemTooltipShoppingListSettingsCheckButton
f = CreateFrame( "CheckButton", "$parentItemTooltipShoppingListSettingsCheckButton", RestockShopInterfaceOptionsPanel, "InterfaceOptionsSmallCheckButtonTemplate" );
f:SetPoint( "TOPLEFT", "$parentItemTooltipLabel", "BOTTOMLEFT", 3, -1 );
_G[f:GetName() .. 'Text']:SetText( L["Shopping List Settings"] );
f.tooltip = L["Display item settings for the currently selected shopping list in the item's tooltip"];
f:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT", 25 );
	GameTooltip:SetText( self.tooltip );
end );
f:SetScript( "OnLeave", GameTooltip_Hide );
-- RestockShopInterfaceOptionsPanel > ItemTooltipItemIdCheckButton
f = CreateFrame( "CheckButton", "$parentItemTooltipItemIdCheckButton", RestockShopInterfaceOptionsPanel, "InterfaceOptionsSmallCheckButtonTemplate" );
f:SetPoint( "TOPLEFT", "$parentItemTooltipShoppingListSettingsCheckButton", "BOTTOMLEFT", 0, -1 );
_G[f:GetName() .. 'Text']:SetText( L["Item ID"] );
f.tooltip = L["Display the Item ID in the tooltip of all items"];
f:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT", 25 );
	GameTooltip:SetText( self.tooltip );
end );
f:SetScript( "OnLeave", GameTooltip_Hide );
-- RestockShopInterfaceOptionsPanel > MiscLabel
f = CreateFrame( "Frame", "$parentMiscLabel", RestockShopInterfaceOptionsPanel );
f:SetSize( 200, 20 );
f:SetPoint( "TOPLEFT", "$parentItemTooltipItemIdCheckButton", "BOTTOMLEFT", -3, -8 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Miscellaneous"] );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanel > showDeleteItemConfirmDialogCheckButton
f = CreateFrame( "CheckButton", "$parentshowDeleteItemConfirmDialogCheckButton", RestockShopInterfaceOptionsPanel, "InterfaceOptionsSmallCheckButtonTemplate" );
f:SetPoint( "TOPLEFT", "$parentMiscLabel", "BOTTOMLEFT", 3, -1 );
_G[f:GetName() .. 'Text']:SetText( L["Show Delete Item Confirmation Dialog"] );
f.tooltip = L["Confirm before deleting an item from a shopping list"];
f:SetScript( "OnEnter", function ( self )
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT", 25 );
	GameTooltip:SetText( self.tooltip );
end );
f:SetScript( "OnLeave", GameTooltip_Hide );
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopInterfaceOptionsPanelShoppingLists
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopInterfaceOptionsPanelShoppingLists", UIParent );
f:Hide();
f:SetBackdrop( backdrop1 );
f:SetScript( "OnShow", function ( self )
	if RestockShopFrame:IsShown() then
		AuctionFrameTab1:Click();
	end
	FauxScrollFrame_SetOffset( RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame, 0 );
	RestockShopInterfaceOptionsPanelShoppingLists_Load();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > Title
fs = f:CreateFontString( "$parentTitle", "ARTWORK", "GameFontNormalLarge" );
fs:SetText( L["Shopping Lists"] .. " /rs sl" );
fs:SetJustifyH( "LEFT" );
fs:SetJustifyV( "TOP" );
fs:SetPoint( "TOPLEFT", 16, -16 );
-- RestockShopInterfaceOptionsPanelShoppingLists > SubText
fs = f:CreateFontString( "$parentSubText", "ARTWORK", "GameFontHighlightSmall" );
fs:SetText( string.format( L["These options allow you to create, copy, and delete shopping lists and the items they contain. ITEMS - %s\"Full Stock Qty\"|r is the maximum number of an item you want to keep in stock. %s\"Low\"|r, %s\"Norm\"|r, and %s\"Full\"|r contain an item's max price in terms of it's %s\"Item Value\"|r at the corresponding stock quantity. If you want to stop shopping for an item at %s\"Full Stock Qty\"|r leave %s\"Full\"|r %sempty|r or set to %s0|r."], NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_LOW_COLOR_CODE, RESTOCKSHOP_NORM_COLOR_CODE, RESTOCKSHOP_FULL_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, RESTOCKSHOP_FULL_COLOR_CODE, BATTLENET_FONT_COLOR_CODE, BATTLENET_FONT_COLOR_CODE ) );
fs:SetNonSpaceWrap( true );
fs:SetMaxLines( 5 );
fs:SetJustifyH( "LEFT" );
fs:SetJustifyV( "TOP" );
fs:SetSize( 0, 32 );
fs:SetPoint( "TOPLEFT", "$parentTitle", "BOTTOMLEFT", 0, -8 );
fs:SetPoint( "RIGHT", -32, 0 );
-- RestockShopInterfaceOptionsPanelShoppingLists > ItemIdLabel
f = CreateFrame( "Frame", "$parentItemIdLabel", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( ( 52 + 10 ), 20 );
f:SetPoint( "TOPLEFT", "$parentSubText", "BOTTOMLEFT", 77, -31 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Item ID"] );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > ItemIdEditbox
f = CreateFrame( "EditBox", "$parentItemIdEditbox", RestockShopInterfaceOptionsPanelShoppingLists, "InputBoxTemplate" );
f:SetAutoFocus( false );
f:SetNumeric( true );
f:SetMaxLetters( 6 );
f:SetSize( 52, 20 );
f:SetPoint( "TOPLEFT", "$parentItemIdLabel", "BOTTOMLEFT", 4, 0 );
f:SetFontObject( ChatFontNormal );
f:SetScript( "OnTabPressed", function ( self )
	_G[self:GetParent():GetName() .. "FullStockQtyEditbox"]:SetFocus();
end );
f:SetScript( "OnEnterPressed", function ( self )
	_G[self:GetParent():GetName() .. "_SubmitButton"]:Click();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockQtyLabel
f = CreateFrame( "Frame", "$parentFullStockQtyLabel", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( ( 45 + 28 ), 20 );
f:SetPoint( "LEFT", "$parentItemIdLabel", "RIGHT", 10, 0 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Full Stock Qty"] );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockQtyEditbox
f = CreateFrame( "EditBox", "$parentFullStockQtyEditbox", RestockShopInterfaceOptionsPanelShoppingLists, "InputBoxTemplate" );
f:SetAutoFocus( false );
f:SetNumeric( true );
f:SetMaxLetters( 5 );
f:SetSize( 45, 20 );
f:SetPoint( "TOPLEFT", "$parentFullStockQtyLabel", "BOTTOMLEFT", 4, 0 );
f:SetFontObject( ChatFontNormal );
f:SetScript( "OnTabPressed", function ( self )
	_G[self:GetParent():GetName() .. "LowStockPriceEditbox"]:SetFocus();
end );
f:SetScript( "OnEnterPressed", function ( self )
	_G[self:GetParent():GetName() .. "_SubmitButton"]:Click();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > LowStockPriceLabel
f = CreateFrame( "Frame", "$parentLowStockPriceLabel", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( ( 32 + 25 ), 20 );
f:SetPoint( "LEFT", "$parentFullStockQtyLabel", "RIGHT", 15, 0 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( RESTOCKSHOP_LOW_COLOR_CODE .. L["Low"] .. "|r" );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > LowStockPriceEditbox
f = CreateFrame( "EditBox", "$parentLowStockPriceEditbox", RestockShopInterfaceOptionsPanelShoppingLists, "InputBoxTemplate" );
f:SetAutoFocus( false );
f:SetNumeric( true );
f:SetMaxLetters( 3 );
f:SetSize( 32, 20 );
f:SetPoint( "TOPLEFT", "$parentLowStockPriceLabel", "BOTTOMLEFT", 4, 0 );
f:SetFontObject( ChatFontNormal );
f:SetScript( "OnTabPressed", function ( self )
	_G[self:GetParent():GetName() .. "NormalStockPriceEditbox"]:SetFocus();
end );
f:SetScript( "OnEnterPressed", function ( self )
	_G[self:GetParent():GetName() .. "_SubmitButton"]:Click();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > %
f = CreateFrame( "Frame", nil, RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( 20, 20 );
f:SetPoint( "TOPLEFT", "$parentLowStockPriceEditbox", "TOPRIGHT", 5, 0 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( "%" );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanelShoppingLists > NormalStockPriceLabel
f = CreateFrame( "Frame", "$parentNormalStockPriceLabel", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( ( 32 + 25 ), 20 );
f:SetPoint( "LEFT", "$parentLowStockPriceLabel", "RIGHT", 10, 0 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( RESTOCKSHOP_NORM_COLOR_CODE .. L["Norm"] .. "|r" );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > NormalStockPriceEditbox
f = CreateFrame( "EditBox", "$parentNormalStockPriceEditbox", RestockShopInterfaceOptionsPanelShoppingLists, "InputBoxTemplate" );
f:SetAutoFocus( false );
f:SetNumeric( true );
f:SetMaxLetters( 3 );
f:SetSize( 32, 20 );
f:SetPoint( "TOPLEFT", "$parentNormalStockPriceLabel", "BOTTOMLEFT", 4, 0 );
f:SetFontObject( ChatFontNormal );
f:SetScript( "OnTabPressed", function ( self )
	_G[self:GetParent():GetName() .. "FullStockPriceEditbox"]:SetFocus();
end );
f:SetScript( "OnEnterPressed", function ( self )
	_G[self:GetParent():GetName() .. "_SubmitButton"]:Click();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > %
f = CreateFrame( "Frame", nil, RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( 20, 20 );
f:SetPoint( "TOPLEFT", "$parentNormalStockPriceEditbox", "TOPRIGHT", 5, 0 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( "%" );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockPriceLabel
f = CreateFrame( "Frame", "$parentFullStockPriceLabel", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( ( 32 + 25 ), 20 );
f:SetPoint( "LEFT", "$parentNormalStockPriceLabel", "RIGHT", 10, 0 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( RESTOCKSHOP_FULL_COLOR_CODE .. L["Full"] .. "|r" );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockPriceEditbox
f = CreateFrame( "EditBox", "$parentFullStockPriceEditbox", RestockShopInterfaceOptionsPanelShoppingLists, "InputBoxTemplate" );
f:SetAutoFocus( false );
f:SetNumeric( true );
f:SetMaxLetters( 3 );
f:SetSize( 32, 20 );
f:SetPoint( "TOPLEFT", "$parentFullStockPriceLabel", "BOTTOMLEFT", 4, 0 );
f:SetFontObject( ChatFontNormal );
f:SetScript( "OnTabPressed", function ( self )
	_G[self:GetParent():GetName() .. "ItemIdEditbox"]:SetFocus();
end );
f:SetScript( "OnEnterPressed", function ( self )
	_G[self:GetParent():GetName() .. "_SubmitButton"]:Click();
end );
-- RestockShopInterfaceOptionsPanelShoppingLists > %
f = CreateFrame( "Frame", nil, RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( 20, 20 );
f:SetPoint( "TOPLEFT", "$parentFullStockPriceEditbox", "TOPRIGHT", 5, 0 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( "%" );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanelShoppingLists > PricesDescription
f = CreateFrame( "Frame", "$parentPricesDescription", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( 120, 20 );
f:SetPoint( "TOPLEFT", "$parentLowStockPriceEditbox", "BOTTOMLEFT", -12, 0 );
fs = f:CreateFontString( nil, "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Max prices, percentage of Item's Value"] );
fs:SetJustifyH( "LEFT" );
fs:SetPoint( "LEFT" );
-- RestockShopInterfaceOptionsPanelShoppingLists > SubmitButton
f = CreateFrame( "Button", "$parent_SubmitButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Submit"] );
f:SetSize( 80, 22 );
f:SetPoint( "LEFT", "$parentFullStockPriceEditbox", "RIGHT", 30, 0 );
f:SetScript( "OnClick", function ( self )
	self:Disable();
	--
	local parentName = self:GetParent():GetName();
	--
	local itemId = _G[parentName .. "ItemIdEditbox"]:GetNumber();
	local fullStockQty = _G[parentName .. "FullStockQtyEditbox"]:GetNumber();
	local lowStockPrice = _G[parentName .. "LowStockPriceEditbox"]:GetNumber();
	local normalStockPrice = _G[parentName .. "NormalStockPriceEditbox"]:GetNumber();
	local fullStockPrice = _G[parentName .. "FullStockPriceEditbox"]:GetNumber();
	--
	local name, link, maxStack, texture = nil, nil, nil, nil;
	name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( itemId ); -- name,link,quality,iLevel,reqLevel,class,subclass,maxStack,equipSlot,texture,vendorPrice = GetItemInfo( ItemID or ItemString or ItemLink );
	--
	local function CompleteSubmission()
		local submitError = false;
		-- Item Id
		if not name then
			name,link,quality,_,_,_,_,maxStack,_,texture,_ = GetItemInfo( itemId );
			if not name then
				submitError = true;
				print( "RestockShop: " .. string.format( L["Item not found, check your %sItem ID|r"], NORMAL_FONT_COLOR_CODE ) );
			end
		end
		-- Full Stock Qty
		if fullStockQty < 1 then
			submitError = true;
			print( "RestockShop: " .. string.format( L["%sFull Stock Qty|r cannot be empty"], NORMAL_FONT_COLOR_CODE ) );
		end
		-- Low %
		if lowStockPrice < 1 then
			submitError = true;
			print( "RestockShop: " .. string.format( L["%sLow|r cannot be empty"], RESTOCKSHOP_LOW_COLOR_CODE ) );
		end
		-- Norm %
		if normalStockPrice < 1 then
			submitError = true;
			print( "RestockShop: " .. string.format( L["%sNorm|r cannot be empty"], RESTOCKSHOP_NORM_COLOR_CODE ) );
		end
		-- Low < Norm
		if lowStockPrice ~= 0 and normalStockPrice ~= 0 and lowStockPrice < normalStockPrice then
			submitError = true;
			print( "RestockShop: " .. string.format( L["%sLow|r cannot be smaller than %sNorm|r"], RESTOCKSHOP_LOW_COLOR_CODE, RESTOCKSHOP_NORM_COLOR_CODE ) );
		end
		-- Norm < Full
		if normalStockPrice ~= 0 and fullStockPrice ~= 0 and normalStockPrice < fullStockPrice then
			submitError = true;
			print( "RestockShop: " .. string.format( L["%sNorm|r cannot be smaller than %sFull|r"], RESTOCKSHOP_NORM_COLOR_CODE, RESTOCKSHOP_FULL_COLOR_CODE ) );
		end
		--
		if submitError then
			-- Sumbit Error
			print( "RestockShop: " .. string.format( L["%sItem not added, incorrect or missing data|r"], RED_FONT_COLOR_CODE ) );
		else
			-- Updated or Added
			local itemKey = RestockShop_FindItemKey( itemId );
			if itemKey then
				print( "RestockShop: " .. L["Item updated"] .. " " .. link );
			else
				print( "RestockShop: " .. L["Item added"] .. " " .. link );
				itemKey = #RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"] + 1;
			end
			-- Item Info
			local itemInfo = {
				["itemId"] = itemId,
				["name"] = name,
				["link"] = link,
				["quality"] = quality,
				["tsmItemString"] = RestockShop_TSMItemString( link ),
				["maxStack"] = maxStack,
				["texture"] = texture,
				["fullStockQty"] = fullStockQty,
				["maxPricePct"] = {
					["low"] = lowStockPrice,
					["normal"] = normalStockPrice,
					["full"] = fullStockPrice
				}
			};
			-- Update and sort the current shopping list
			RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"][itemKey] = itemInfo;
			table.sort ( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"],
				function ( item1, item2 )
					return item1["name"] < item2["name"]; -- Sort by name A-Z
				end
			);
			RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update();
			-- Focus Item Id
			_G[parentName .. "ItemIdEditbox"]:ClearFocus();
			_G[parentName .. "ItemIdEditbox"]:SetFocus();
		end
		--
		self:Enable();
	end
	local _,_,_,latencyWorld = GetNetStats();
	local delay = ( latencyWorld > 0 and latencyWorld or 300 ) * 3 * 0.001;
	RestockShop_TimeDelayFunction( delay, CompleteSubmission ); -- Delay to allow client to retrieve item info from server
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 80 - 16 ), 22 );
-- RestockShopInterfaceOptionsPanelShoppingLists > currentShoppingListText
f = CreateFrame( "Frame", "$parentCurrentShoppingListText", RestockShopInterfaceOptionsPanelShoppingLists );
f:SetSize( 116, 20 );
f:SetPoint( "TOPLEFT", "$parentSubText", "BOTTOMLEFT", 0, -120 );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:CreateFontString( "$parentText", "BACKGROUND", "GameFontNormalSmall" );
fs:SetText( L["Current Shopping List:"] );
fs:SetMaxLines( 1 );
fs:SetJustifyH( "LEFT" );
fs:SetAllPoints();
-- RestockShopInterfaceOptionsPanelShoppingLists > ShoppingListsDropDownMenu
f = CreateFrame( "Frame", "$parentShoppingListsDropDownMenu", RestockShopInterfaceOptionsPanelShoppingLists, "UIDropDownMenuTemplate" );
f:SetPoint( "LEFT", "$parentCurrentShoppingListText", "RIGHT", -12, -1 );
-- RestockShopInterfaceOptionsPanelShoppingLists > ItemIdSortButton
f = CreateFrame( "Button", "$parent_ItemIdSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( L["Item ID"] );
f:SetSize( 66, 19 );
f:SetPoint( "TOPLEFT", "$parentCurrentShoppingListText", "BOTTOMLEFT", 0, -6 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 66 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > NameSortButton
f = CreateFrame( "Button", "$parent_NameSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( NAME );
f:SetSize( 220, 19 );
f:SetPoint( "LEFT", "$parent_ItemIdSortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 220 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockQtySortButton
f = CreateFrame( "Button", "$parent_FullStockQtySortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( L["Full Stock Qty"] );
f:SetSize( 93, 19 );
f:SetPoint( "LEFT", "$parent_NameSortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 93 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > LowStockPriceSortButton
f = CreateFrame( "Button", "$parent_LowStockPriceSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( L["Low"] );
f:SetSize( 55, 19 );
f:SetPoint( "LEFT", "$parent_FullStockQtySortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( RESTOCKSHOP_LOW_FONT_COLOR["r"], RESTOCKSHOP_LOW_FONT_COLOR["g"], RESTOCKSHOP_LOW_FONT_COLOR["b"] );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 55 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > NormalStockPriceSortButton
f = CreateFrame( "Button", "$parent_NormalStockPriceSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( L["Norm"] );
f:SetSize( 55, 19 );
f:SetPoint( "LEFT", "$parent_LowStockPriceSortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( RESTOCKSHOP_NORM_FONT_COLOR["r"], RESTOCKSHOP_NORM_FONT_COLOR["g"], RESTOCKSHOP_NORM_FONT_COLOR["b"] );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 55 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > FullStockPriceSortButton
f = CreateFrame( "Button", "$parent_FullStockPriceSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( L["Full"] );
f:SetSize( 55, 19 );
f:SetPoint( "LEFT", "$parent_NormalStockPriceSortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetTextColor( RESTOCKSHOP_FULL_FONT_COLOR["r"], RESTOCKSHOP_FULL_FONT_COLOR["g"], RESTOCKSHOP_FULL_FONT_COLOR["b"] );
fs:SetJustifyH( "LEFT" );
fs:SetSize( ( 55 - 16 ), 19 );
-- RestockShopInterfaceOptionsPanelShoppingLists > DeleteIconSortButton
f = CreateFrame( "Button", "$parent_DeleteIconSortButton", RestockShopInterfaceOptionsPanelShoppingLists, "AuctionSortButtonTemplate" );
f:SetText( "" );
f:SetSize( 30, 19 );
f:SetPoint( "LEFT", "$parent_FullStockPriceSortButton", "RIGHT", -2, 0 );
f:SetHighlightTexture( nil );
_G[f:GetName() .. "Arrow"]:SetTexture( nil );
-- RestockShopInterfaceOptionsPanelShoppingLists > ScrollFrame
f = CreateFrame( "ScrollFrame", "$parent_ScrollFrame", RestockShopInterfaceOptionsPanelShoppingLists, "FauxScrollFrameTemplate" );
f:SetSize( 560, 276 );
f:SetPoint( "TOPLEFT", "$parent_ItemIdSortButton", "BOTTOMLEFT", 0, -6 );
f:SetScript( "OnVerticalScroll", function ( self, offset )
	FauxScrollFrame_OnVerticalScroll( self, offset, 16, RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update );
end );
f:SetScript( "OnShow", RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_Update );
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
-- RestockShopInterfaceOptionsPanelShoppingLists > ScrollFrame_Entry(i) x 15
f = CreateFrame( "Button", "$parent_ScrollFrame_Entry1", RestockShopInterfaceOptionsPanelShoppingLists, "RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_EntryTemplate" );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "TOPLEFT", 1, 5 );
for i = 2, 15 do
	f = CreateFrame( "Button", ( "$parent_ScrollFrame_Entry" .. i ), RestockShopInterfaceOptionsPanelShoppingLists, "RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_EntryTemplate" );
	f:SetPoint( "TOPLEFT", ( "$parent_ScrollFrame_Entry" .. ( i - 1 ) ), "BOTTOMLEFT", 0, -3 );
end
-- RestockShopInterfaceOptionsPanelShoppingLists > CreateListButton
f = CreateFrame( "Button", "$parentCreateListButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Create List"] );
f:SetSize( 96, 22 );
f:SetPoint( "TOPLEFT", "$parent_ScrollFrame", "BOTTOMLEFT", 0, -12 );
f:SetScript( "OnClick", function ( self )
	StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_CREATE" );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 96 - 16 ), 22 );
-- RestockShopInterfaceOptionsPanelShoppingLists > CopyListButton
f = CreateFrame( "Button", "$parentCopyListButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Copy List"] );
f:SetSize( 96, 22 );
f:SetPoint( "LEFT", "$parentCreateListButton", "RIGHT", 10, 0 );
f:SetScript( "OnClick", function ( self )
	StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_COPY", RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], nil, { ["shoppingList"] = RESTOCKSHOP_CURRENT_LISTKEY } );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 96 - 16 ), 22 );
-- RestockShopInterfaceOptionsPanelShoppingLists > DeleteListButton
f = CreateFrame( "Button", "$parentDeleteListButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Delete List"] );
f:SetSize( 96, 22 );
f:SetPoint( "LEFT", "$parentCopyListButton", "RIGHT", 10, 0 );
f:SetScript( "OnClick", function ( self )
	StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_DELETE", RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], nil, { ["shoppingList"] = RESTOCKSHOP_CURRENT_LISTKEY } );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 96 - 16 ), 22 );
-- RestockShopInterfaceOptionsPanelShoppingLists > ImportItemsButton
f = CreateFrame( "Button", "$parentImportItemsButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Import Items"] );
f:SetSize( 116, 22 );
f:SetPoint( "LEFT", "$parentDeleteListButton", "RIGHT", 10, 0 );
f:SetScript( "OnClick", function ( self )
	StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT", RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], nil, { ["shoppingList"] = RESTOCKSHOP_CURRENT_LISTKEY } );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 116 - 16 ), 22 );
-- RestockShopInterfaceOptionsPanelShoppingLists > ExportItemsButton
f = CreateFrame( "Button", "$parentExportItemsButton", RestockShopInterfaceOptionsPanelShoppingLists, "UIPanelButtonTemplate" );
f:SetText( L["Export Items"] );
f:SetSize( 116, 22 );
f:SetPoint( "LEFT", "$parentImportItemsButton", "RIGHT", 10, 0 );
f:SetScript( "OnClick", function ( self )
	StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_EXPORT", RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["name"], nil, { ["shoppingList"] = RESTOCKSHOP_CURRENT_LISTKEY } );
end );
f:SetScript( "OnEnter", RestockShop_TruncatedText_OnEnter );
f:SetScript( "OnLeave", TruncatedButton_OnLeave );
fs = f:GetFontString();
fs:SetSize( ( 116 - 16 ), 22 );
--------------------------------------------------------------------------------------------------------------------------------------------
-- RestockShopFrame
--------------------------------------------------------------------------------------------------------------------------------------------
f = CreateFrame( "Frame", "RestockShopFrame", UIParent );
f:Hide();
--f:SetSize( 758, 447 ); 66 x removed from close button
f:SetSize( 824, 447 );
f:SetScript( "OnShow", function ( self )
	InterfaceOptionsFrame:Hide();
	FauxScrollFrame_SetOffset( RestockShopFrame_ScrollFrame, 0 );
	RestockShopFrame_Reset();
end );
f:SetScript( "OnHide", RestockShopFrame_Reset );
-- RestockShopFrame > Title
fs = f:CreateFontString( "$parent_Title", "BACKGROUND", "GameFontNormal" );
fs:SetText( "RestockShop v" .. GetAddOnMetadata( "RestockShop", "Version" ) .. " : " .. string.format( L["Macro %s/rs acceptbuttonclick|r for fast key or mouse bound buying"], BATTLENET_FONT_COLOR_CODE ) );
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
-- RestockShopFrame > PctMaxPriceSortButton
f = CreateFrame( "Button", "$parent_PctMaxPriceSortButton", RestockShopFrame, "AuctionSortButtonTemplate" );
f:SetText( L["% Max Price"] );
f:SetSize( 101, 19 );
f:SetPoint( "LEFT", "$parent_ItemPriceSortButton", "RIGHT", -2, 0 );
f:SetScript( "OnClick", function ( self )
	RestockShopFrame_SortColumn_OnClick( self, "pctMaxPrice" );
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
	if RESTOCKSHOP_BUYALL then
		RestockShopFrame_BuyAllButton:Click();
	else
		RestockShopFrame_ScrollFrame_Auction_Deselect();
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Select an auction to buy or click \"Buy All\""] );
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
	if RESTOCKSHOP_CAN_BID then
		RestockShop_SetCanBid( false );
		RestockShopFrame_ShopButton:Disable();
		RestockShopFrame_BuyAllButton:Disable();
		RestockShopEventsFrame:RegisterEvent( "CHAT_MSG_SYSTEM" );
		RestockShopEventsFrame:RegisterEvent( "UI_ERROR_MESSAGE" );
		PlaceAuctionBid( "list", RESTOCKSHOP_AUCTION_SELECT_AUCTION["index"], RESTOCKSHOP_AUCTION_SELECT_AUCTION["buyoutPrice"] );
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
	if RESTOCKSHOP_BUYALL then
		RESTOCKSHOP_BUYALL = false;
		self:SetText( L["Buy All"] );
		RestockShopFrame_DialogFrame_StatusFrame_Update( L["Buy All has been stopped"] .. ". " .. L["Select an auction to buy or click \"Buy All\""] );
		RestockShopFrame_ScrollFrame_Auction_Deselect();
	else
		RESTOCKSHOP_BUYALL = true;
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
	if RESTOCKSHOP_SCANNING then
		RestockShopFrame_Reset();
	else
		RESTOCKSHOP_ITEMS = {};
		RESTOCKSHOP_QUERY_QUEUE= {};
		RESTOCKSHOP_AUCTION_DATA_RAW = {};
		RESTOCKSHOP_AUCTION_DATA_GROUPS = {};
		RestockShopFrame_ScrollFrame_Auction_Deselect();
		RestockShopFrame_ScrollFrame_Update();
		RestockShopFrame_ListStatusFrame:Hide();
		RestockShopFrame_BuyAllButton_Reset();
		RestockShopFrame_FlyoutPanel_ScrollFrame:SetVerticalScroll( 0 );
		for k, v in ipairs( RESTOCKSHOP_SAVEDVARIABLES["shoppingLists"][RESTOCKSHOP_CURRENT_LISTKEY]["items"] ) do
			table.insert( RESTOCKSHOP_QUERY_QUEUE, v );
			RESTOCKSHOP_ITEMS[v["itemId"]] = v;
			RESTOCKSHOP_ITEMS[v["itemId"]]["scanTexture"] = "Waiting";
		end
		table.sort ( RESTOCKSHOP_QUERY_QUEUE, function ( item1, item2 )
			return item1["name"] > item2["name"]; -- Sort by name Z-A because items are pulled from the end of the queue which will become A-Z
		end	);
		RESTOCKSHOP_SCAN_TYPE = "SHOP";
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
	InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanelShoppingLists"] );
	InterfaceOptionsFrame_OpenToCategory( _G["RestockShopInterfaceOptionsPanelShoppingLists"] );
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
f:SetText( L["Shopping Lists"] );
f:SetSize( 28, 28 );
f:SetPoint( "TOPRIGHT", "$parent_FlyoutPanel", "TOPLEFT", -4, 2 );
f:SetScript( "OnClick", function ( self )
	local flyoutPanel = _G[self:GetParent():GetName() .. "_FlyoutPanel"];
	if flyoutPanel:IsShown() then
		flyoutPanel:Hide();
		RESTOCKSHOP_SAVEDVARIABLES["flyoutPanelOpen"] = nil;
		self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up" );
		self:SetDisabledTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled" );
		self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down" );
	else
		flyoutPanel:Show();
		RESTOCKSHOP_SAVEDVARIABLES["flyoutPanelOpen"] = 1;
		self:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
		self:SetDisabledTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled" );
		self:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
	end
end );
f:SetNormalTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up" );
f:SetHighlightTexture( "Interface\\Buttons\\UI-Common-MouseHilight", "ADD" );
f:SetDisabledTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled" );
f:SetPushedTexture( "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down" );
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
