﻿RESTOCKSHOP_LOCALIZATION = setmetatable( {}, { __index = function( self, key )
	self[key] = key; -- Use original phrase for undefined keys
	return key;
end } );
--
local L = RESTOCKSHOP_LOCALIZATION;
-- enUS, enGB
if GetLocale() == "enUS" or GetLocale() == "enGB" then
-- deDE
elseif GetLocale() == "deDE" then
-- esES
elseif GetLocale() == "esES" then
-- frFR
elseif GetLocale() == "frFR" then
-- itIT
elseif GetLocale() == "itIT" then
-- koKR
elseif GetLocale() == "koKR" then
-- ptBR
elseif GetLocale() == "ptBR" then
-- ruRU
elseif GetLocale() == "ruRU" then
-- zhCN
elseif GetLocale() == "zhCN" then
-- zhTW
elseif GetLocale() == "zhTW" then
end

-- L["Abort"] = ""
-- L["Addon %s required"] = ""
-- L["All Characters"] = ""
-- L["Asking server about %d item(s)... %d second(s) please"] = ""
-- L["AtrValue (Auctionator - Auction Value)"] = ""
-- L["Attempting to import %d items..."] = ""
-- L["AucAppraiser (Auctioneer - Appraiser)"] = ""
-- L["AucMarket (Auctioneer - Market Value)"] = ""
-- L["AucMinBuyout (Auctioneer - Minimum Buyout)"] = ""
-- L["Buy All"] = ""
-- L["Buy All has been stopped"] = ""
-- L["Confirm before deleting an\\nitem from a shopping list."] = ""
-- L["Copy List"] = ""
-- L["Copy List: %s"] = ""
-- L["Could not query Auction House after several attempts, please try again in a few moments"] = ""
-- L["Create List"] = ""
-- L["Current Character"] = ""
-- L["Current Shopping List:"] = ""
-- L["DBGlobalMarketAvg (AuctionDB - Global Market Value Average (via TSM App))"] = ""
-- L["DBGlobalMarketMedian (AuctionDB - Global Market Value Median (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutAvg (AuctionDB - Global Minimum Buyout Average (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutMedian (AuctionDB - Global Minimum Buyout Median (via TSM App))"] = ""
-- L["DBGlobalSaleAvg (AuctionDB - Global Sale Average (via TSM App))"] = ""
-- L["DBMarket (AuctionDB Market Value)"] = ""
-- L["DBMinBuyout (AuctionDB Minimum Buyout)"] = ""
-- L["Delete item? %s from %s"] = ""
-- L["Delete List"] = ""
-- L["Delete list? %s"] = ""
-- L["%d invalid item(s) not imported:"] = ""
-- L["Displays item settings for the\\ncurrently selected shopping\\nlist in the item's tooltip."] = ""
-- L["Displays the Item ID in the\\ntooltip of all items."] = ""
-- L["%d items remaining"] = ""
-- L["%d of %d items imported"] = ""
-- L["%d stacks of %d"] = ""
-- L["Export Items"] = ""
-- L["Export items from list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = ""
-- L["Full"] = ""
-- L["Full Stock Qty"] = ""
-- L["Hidden auctions available."] = ""
-- L["Hides auctions that when purchased\\nwould cause you to exceed your\\nFull Stock Qty by more than this\\npercentage.\\n\\n(Toggle on/off at the Auction House)"] = ""
-- L["Import Items"] = ""
-- L["Import items to list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\nNo subgroup structure\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = ""
-- L["Include Guild Bank(s)"] = ""
-- L["Item added"] = ""
-- L["Item deleted"] = ""
-- L["Item ID"] = ""
-- L["Item not found, check your %sItem ID|r"] = ""
-- L["Item Price"] = ""
-- L["Item Tooltip"] = ""
-- L["Item updated"] = ""
-- L["% Item Value"] = ""
-- L["Item Value"] = ""
-- L["Item Value Source"] = ""
-- L["List"] = ""
-- L["List created"] = ""
-- L["List deleted"] = ""
-- L["List name cannot be empty"] = ""
-- L["List not created, that name already exists"] = ""
-- L["Low"] = ""
-- L["Macro %s/rs acceptbuttonclick|r for fast key or mouse bound buying"] = ""
-- L["% Max Price"] = ""
-- L["Max Price"] = ""
-- L["Max prices, percentage of Item's Value"] = ""
-- L["Miscellaneous"] = ""
-- L["No additional auctions matched your settings"] = ""
-- L["No auctions were found that matched your settings"] = ""
-- L["Norm"] = ""
-- L["On Hand"] = ""
-- L["On Hand Tracking"] = ""
-- L["On Hand values include the\\nGuild Bank(s) based on whether\\nyou selected All Characters\\nor Current Character.\\n\\n%sWARNING!|r\\nTradeSkillMaster_ItemTracker\\nsettings affect On Hand values."] = ""
-- L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] = ""
-- L["Requires Item Value"] = ""
-- L["Requires %s Data"] = ""
-- L["Restock %"] = ""
-- L["Restock Shopping List"] = ""
-- L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"] = ""
-- L["Scanning"] = ""
-- L["Scanning %s: Page %d of %d"] = ""
-- L["Select an auction to buy or click \"Buy All\""] = ""
-- L["Selection ignored, busy scanning"] = ""
-- L["Sets the data source for Item Value.\\nYou must have the corresponding addon\\ninstalled and it's price data available.\\n\\nItem Value is the base price from which\\n%sLow|r, %sNorm|r, and %sFull|r prices are calculated."] = ""
-- L["Sets which characters to\\ninclude for On Hand values.\\n\\n%sWARNING!|r\\nTradeSkillMaster_ItemTracker\\nsettings affect On Hand values."] = ""
-- L["%sFull Stock Qty|r cannot be empty"] = ""
-- L["%sHide Overpriced Stacks|r\\n\\nHides auctions whose %% Item Value exceeds\\nthe current max price: %sLow|r, %sNorm|r, or %sFull|r %%"] = ""
-- L["%sHide Overstock Stacks %%|r"] = ""
-- L["%sHide Overstock Stacks|r\\n\\nHides auctions that when purchased would cause you\\nto exceed your \"Full Stock Qty\" by more than %s%s%%|r"] = ""
-- L["Shop"] = ""
-- L["Shopping Lists"] = ""
-- L["Shopping List Settings"] = ""
-- L["Show Delete Item Confirmation Dialog"] = ""
-- L["%sItem ID|r can be found in the item's in-game tooltip or Wowhead URL (e.g. /item=12345/)\\n%sFull Stock Qty|r is the max number of an item you want to keep in stock.\\n%sLow|r, %sNorm|r, and %sFull|r contain the item's max price at the corresponding stock quantity.\\n%sNote:|r To avoid scanning for an item at %sFull Stock Qty|r leave %sFull|r %sempty|r or set to %s0|r."] = ""
-- L["%sItem not added, incorrect or missing data|r"] = ""
-- L["Skipping %s: %sFull Stock Qty|r reached and no %sFull|r price set"] = ""
-- L["Skipping %s: %sRequires %s data|r"] = ""
-- L["%sLow|r cannot be empty"] = ""
-- L["%sLow|r cannot be smaller than %sNorm|r"] = ""
-- L["%sLow Stock %%|r"] = ""
-- L["%sNorm|r cannot be empty"] = ""
-- L["%sNorm|r cannot be smaller than %sFull|r"] = ""
-- L["%s%sx%d|r for %s per item not found after rescan"] = ""
-- L["%s%sx%d|r for %s per item not found, rescanning item"] = ""
-- L["%s%sx%d|r for %s per item was found after rescan"] = ""
-- L["Stack Size"] = ""
-- L["Stop"] = ""
-- L["Submit"] = ""
-- L["That auction belonged to you and couldn't be won"] = ""
-- L["That auction was no longer available"] = ""
-- L["These options apply to all characters on your account."] = ""
-- L["Unknown command"] = ""
-- L["Upgraded version %s to %s"] = ""
-- L["When an item's On Hand quantity\\nfalls below this percentage it's\\nconsidered %sLow|r."] = ""
-- L["wowuctionMarket (WoWuction Realm Market Value)"] = ""
-- L["wowuctionMedian (WoWuction Realm Median Price)"] = ""
-- L["wowuctionRegionMarket (WoWuction Region Market Value)"] = ""
-- L["wowuctionRegionMedian (WoWuction Region Median Price)"] = ""
-- L["You can't carry anymore of that item"] = ""
-- L["You can't delete your only list, you must keep at least one"] = ""
-- L["You don't have enough money to buy that auction"] = ""
-- L["You reached the %sFull Stock Qty|r of %s%d|r on %s"] = ""
