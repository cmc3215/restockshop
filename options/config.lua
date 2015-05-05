--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
--------------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------------------------------------------------------------------
NS.options.cfg = {
	--
	mainFrame = {
		width		= 847,
		height		= 595,
		scale		= 1.0,
		frameStrata	= "HIGH",
		init		= function( MainFrame )
			tinsert( UISpecialFrames, MainFrame:GetName() );
		end,
		onShow		= function( MainFrame )
			MainFrame:ClearAllPoints();
			MainFrame:SetPoint( unpack( NS.db["optionsFramePosition"] ) );
		end,
		onHide		= function( MainFrame )
			local pos = { MainFrame:GetPoint() };
			if NS.db["rememberOptionsFramePosition"] and type( pos[2] ) ~= "table" then -- Filter out first time positioning garbage table info
				NS.db["optionsFramePosition"] = pos;
			end
		end,
	},
	--
	subFrameTabs = {
		{
			-- Shopping Lists
			mainFrameTitle	= NS.title,
			tabText			= "Shopping Lists",
			init			= function( subFrame )
				NS.options.TextFrame( "Description", subFrame, string.format( L["%sItem ID|r: Found on the item's game tooltip or Wowhead URL (e.g. /item=12345/)\n%sFull Stock|r: The max number of an item you want to keep in stock.\n%sLow|r, %sNorm|r, and %sFull|r: The item's max price at the corresponding stock quantity.\n%sNote:|r To avoid scanning for an item at %sFull Stock|r leave %sFull|r %sempty|r or set to %s0|r."], NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full, RED_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NS.colorCode.full, BATTLENET_FONT_COLOR_CODE, BATTLENET_FONT_COLOR_CODE ), {
					fontObject = "GameFontHighlight",
					relativeTo = "$parent",
					relativePoint = "TOPLEFT",
					xOffset = 8,
					yOffset = -8,
				} );
				NS.options.Button( "ApplyToAllItems", subFrame, L["Apply To All Items"], {
					size = { 249, 22 },
					hidden = true,
					relativeTo = "$parentDescription",
					relativePoint = "BOTTOMLEFT",
					xOffset = 91,
					yOffset = -10,
					tooltip = string.format( L["Updates all items that remain\n%sLow|r >= %sNorm|r >= %sFull|r"], NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full ),
					onClick = function( self )
						local sfn = subFrame:GetName();
						local field, value, desc, applyError;
						-- Full Stock
						if _G[sfn .. "FullStockQtyEditbox"]:HasFocus() then
							field = "Full Stock";
							value = _G[sfn .. "FullStockQtyEditbox"]:GetNumber();
							desc = NORMAL_FONT_COLOR_CODE .. "Full Stock|r of " .. NORMAL_FONT_COLOR_CODE .. value .. "|r";
							if value < 1 then
								applyError = true;
								print( "RestockShop: " .. string.format( L["%sFull Stock|r cannot be empty"], NORMAL_FONT_COLOR_CODE ) );
							end
						-- Low
						elseif _G[sfn .. "LowStockPriceEditbox"]:HasFocus() then
							field = "Low";
							value = _G[sfn .. "LowStockPriceEditbox"]:GetNumber();
							desc = NS.colorCode.low .. "Low|r max price of " .. NS.colorCode.low .. value .. "%|r";
							if value < 1 then
								applyError = true;
								print( "RestockShop: " .. string.format( L["%sLow|r cannot be empty"], NS.colorCode.low ) );
							end
						-- Norm
						elseif _G[sfn .. "NormalStockPriceEditbox"]:HasFocus() then
							field = "Norm";
							value = _G[sfn .. "NormalStockPriceEditbox"]:GetNumber();
							desc = NS.colorCode.norm .. "Norm|r max price of " .. NS.colorCode.norm .. value .. "%|r";
							if value < 1 then
								applyError = true;
								print( "RestockShop: " .. string.format( L["%sNorm|r cannot be empty"], NS.colorCode.norm ) );
							end
						-- Full
						elseif _G[sfn .. "FullStockPriceEditbox"]:HasFocus() then
							field = "Full";
							value = _G[sfn .. "FullStockPriceEditbox"]:GetNumber();
							desc = NS.colorCode.full .. "Full|r max price of " .. NS.colorCode.full .. value .. "%|r";
						end
						-- Confirm
						if desc and not applyError then
							StaticPopup_Show( "RESTOCKSHOP_APPLY_TO_ALL_ITEMS", desc, NS.db["shoppingLists"][NS.currentListKey]["name"], { ["shoppingList"] = NS.currentListKey, ["field"] = field, ["value"] = value } );
						end
					end,
				} );
				StaticPopupDialogs["RESTOCKSHOP_APPLY_TO_ALL_ITEMS"] = {
					text = L["Apply %s to all items on %s?"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						local itemsUpdated = 0;
						for i = 1, #NS.db["shoppingLists"][data["shoppingList"]]["items"] do
							if data["field"] == "Full Stock" then
								if data["value"] ~= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["fullStockQty"] then
									NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["fullStockQty"] = data["value"];
									itemsUpdated = itemsUpdated + 1;
								end
							elseif data["field"] == "Low" then
								if data["value"] >= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["normal"]
								and data["value"] ~= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["low"] then
									NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["low"] = data["value"];
									itemsUpdated = itemsUpdated + 1;
								end
							elseif data["field"] == "Norm" then
								if data["value"] >= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["full"]
								and data["value"] <= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["low"]
								and data["value"] ~= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["normal"] then
									NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["normal"] = data["value"];
									itemsUpdated = itemsUpdated + 1;
								end
							elseif data["field"] == "Full" then
								if data["value"] <= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["normal"]
								and data["value"] ~= NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["full"] then
									NS.db["shoppingLists"][data["shoppingList"]]["items"][i]["maxPricePct"]["full"] = data["value"];
									itemsUpdated = itemsUpdated + 1;
								end
							end
						end
						print( "RestockShop: " .. string.format( L["%d items updated."], itemsUpdated ) );
						subFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				NS.options.TextFrame( "ItemIdLabel", subFrame, L["Item ID"], {
					xOffset = -69,
					yOffset = 1,
					size = { ( 52 + 10 ), 20 },
				} );
				NS.options.TextFrame( "FullStockLabel", subFrame, L["Full Stock"], {
					relativePoint = "TOPRIGHT",
					xOffset = 10,
					size = { ( 45 + 14 ), 20 },
				} );
				NS.options.TextFrame( "LowStockPriceLabel", subFrame, NS.colorCode.low .. L["Low"] .. "|r", {
					relativePoint = "TOPRIGHT",
					xOffset = 15,
					size = { ( 32 + 25 ), 20 },
				} );
				NS.options.TextFrame( "NormalStockPriceLabel", subFrame, NS.colorCode.norm .. L["Norm"] .. "|r", {
					relativePoint = "TOPRIGHT",
					xOffset = 10,
					size = { ( 32 + 25 ), 20 },
				} );
				NS.options.TextFrame( "FullStockPriceLabel", subFrame, NS.colorCode.full .. L["Full"] .. "|r", {
					relativePoint = "TOPRIGHT",
					xOffset = 10,
					size = { ( 32 + 25 ), 20 },
				} );
				NS.options.InputBox( "ItemIdEditbox", subFrame, {
					numeric = true,
					maxLetters = 6,
					size = { 52, 20 },
					relativeTo = "$parentItemIdLabel",
					onTabPressed = function() _G[subFrame:GetName() .. "FullStockQtyEditbox"]:SetFocus(); end,
					onEnterPressed = function() _G[subFrame:GetName() .. "SubmitButton"]:Click(); end,
				} );
				NS.options.InputBox( "FullStockQtyEditbox", subFrame, {
					numeric = true,
					maxLetters = 5,
					size = { 45, 20 },
					relativeTo = "$parentFullStockLabel",
					onTabPressed = function() _G[subFrame:GetName() .. "LowStockPriceEditbox"]:SetFocus(); end,
					onEnterPressed = function() _G[subFrame:GetName() .. "SubmitButton"]:Click(); end,
					onEditFocusGained = function()
						_G[subFrame:GetName() .. "ApplyToAllItems"]:SetText( L["Full Stock"] .. " - " .. L["Apply To All Items"] );
						_G[subFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					onEditFocusLost = function() _G[subFrame:GetName() .. "ApplyToAllItems"]:Hide(); end,
				} );
				NS.options.InputBox( "LowStockPriceEditbox", subFrame, {
					numeric = true,
					maxLetters = 3,
					size = { 32, 20 },
					relativeTo = "$parentLowStockPriceLabel",
					onTabPressed = function() _G[subFrame:GetName() .. "NormalStockPriceEditbox"]:SetFocus(); end,
					onEnterPressed = function() _G[subFrame:GetName() .. "SubmitButton"]:Click(); end,
					onEditFocusGained = function()
						_G[subFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.low .. L["Low"] .. "|r - " .. L["Apply To All Items"] );
						_G[subFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					onEditFocusLost = function() _G[subFrame:GetName() .. "ApplyToAllItems"]:Hide(); end,
				} );
				NS.options.TextFrame( "LowStockPctSymbol", subFrame, "%", {
					relativeTo = "$parentLowStockPriceEditbox",
					relativePoint = "TOPRIGHT",
					xOffset = 5,
					size = { 20, 20 },
				} );
				NS.options.InputBox( "NormalStockPriceEditbox", subFrame, {
					numeric = true,
					maxLetters = 3,
					size = { 32, 20 },
					relativeTo = "$parentNormalStockPriceLabel",
					onTabPressed = function() _G[subFrame:GetName() .. "FullStockPriceEditbox"]:SetFocus(); end,
					onEnterPressed = function() _G[subFrame:GetName() .. "SubmitButton"]:Click(); end,
					onEditFocusGained = function()
						_G[subFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.norm .. L["Norm"] .. "|r - " .. L["Apply To All Items"] );
						_G[subFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					onEditFocusLost = function() _G[subFrame:GetName() .. "ApplyToAllItems"]:Hide(); end,
				} );
				NS.options.TextFrame( "NormalStockPctSymbol", subFrame, "%", {
					relativeTo = "$parentNormalStockPriceEditbox",
					relativePoint = "TOPRIGHT",
					xOffset = 5,
					size = { 20, 20 },
				} );
				NS.options.InputBox( "FullStockPriceEditbox", subFrame, {
					numeric = true,
					maxLetters = 3,
					size = { 32, 20 },
					relativeTo = "$parentFullStockPriceLabel",
					onTabPressed = function() _G[subFrame:GetName() .. "ItemIdEditbox"]:SetFocus(); end,
					onEnterPressed = function() _G[subFrame:GetName() .. "SubmitButton"]:Click(); end,
					onEditFocusGained = function()
						_G[subFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.full .. L["Full"] .. "|r - " .. L["Apply To All Items"] );
						_G[subFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					onEditFocusLost = function() _G[subFrame:GetName() .. "ApplyToAllItems"]:Hide(); end,
				} );
				NS.options.TextFrame( "FullStockPctSymbol", subFrame, "%", {
					relativeTo = "$parentFullStockPriceEditbox",
					relativePoint = "TOPRIGHT",
					xOffset = 5,
					size = { 20, 20 },
				} );
				NS.options.TextFrame( "PricesDescription", subFrame, L["Max prices, percentage of Item's Value"], {
					relativeTo = "$parentLowStockPriceEditbox",
					fontObject = "GameFontNormalSmall",
					xOffset = -8,
					yOffset = -4,
				} );
				NS.options.Button( "SubmitButton", subFrame, L["Submit"], {
					size = { 80, 22 },
					relativeTo = "$parentFullStockPriceEditbox",
					xOffset = 30,
					onClick = function( self )
						self:Disable();
						--
						local sfn = subFrame:GetName();
						--
						local itemId = _G[sfn .. "ItemIdEditbox"]:GetNumber();
						local fullStockQty = _G[sfn .. "FullStockQtyEditbox"]:GetNumber();
						local lowStockPrice = _G[sfn .. "LowStockPriceEditbox"]:GetNumber();
						local normalStockPrice = _G[sfn .. "NormalStockPriceEditbox"]:GetNumber();
						local fullStockPrice = _G[sfn .. "FullStockPriceEditbox"]:GetNumber();
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
							-- Full Stock
							if fullStockQty < 1 then
								submitError = true;
								print( "RestockShop: " .. string.format( L["%sFull Stock|r cannot be empty"], NORMAL_FONT_COLOR_CODE ) );
							end
							-- Low %
							if lowStockPrice < 1 then
								submitError = true;
								print( "RestockShop: " .. string.format( L["%sLow|r cannot be empty"], NS.colorCode.low ) );
							end
							-- Norm %
							if normalStockPrice < 1 then
								submitError = true;
								print( "RestockShop: " .. string.format( L["%sNorm|r cannot be empty"], NS.colorCode.norm ) );
							end
							-- Low < Norm
							if lowStockPrice ~= 0 and normalStockPrice ~= 0 and lowStockPrice < normalStockPrice then
								submitError = true;
								print( "RestockShop: " .. string.format( L["%sLow|r cannot be smaller than %sNorm|r"], NS.colorCode.low, NS.colorCode.norm ) );
							end
							-- Norm < Full
							if normalStockPrice ~= 0 and fullStockPrice ~= 0 and normalStockPrice < fullStockPrice then
								submitError = true;
								print( "RestockShop: " .. string.format( L["%sNorm|r cannot be smaller than %sFull|r"], NS.colorCode.norm, NS.colorCode.full ) );
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
									itemKey = #NS.db["shoppingLists"][NS.currentListKey]["items"] + 1;
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
								NS.db["shoppingLists"][NS.currentListKey]["items"][itemKey] = itemInfo;
								table.sort ( NS.db["shoppingLists"][NS.currentListKey]["items"],
									function ( item1, item2 )
										return item1["name"] < item2["name"]; -- Sort by name A-Z
									end
								);
								_G[sfn .. "ScrollFrame"]:Update();
								-- Focus Item Id
								_G[sfn .. "ItemIdEditbox"]:ClearFocus();
								_G[sfn .. "ItemIdEditbox"]:SetFocus();
							end
							--
							self:Enable();
						end
						local _,_,_,latencyWorld = GetNetStats();
						local delay = ( latencyWorld > 0 and latencyWorld or 300 ) * 3 * 0.001;
						RestockShop_TimeDelayFunction( delay, CompleteSubmission ); -- Delay to allow client to retrieve item info from server
					end,
				} );
				-- Gray frame top right
				local OptionsFrame = NS.options.Frame( "Options", subFrame, {
					anchor = "TOPRIGHT",
					relativeTo = "$parent",
					relativePoint = "TOPRIGHT",
					xOffset = -8,
					yOffset = -8,
					size = { 332, 184 },
					background = { 1, 1, 1, 0.1 },
				} );
				NS.options.TextFrame( "Description", OptionsFrame, L["These settings apply only to the current shopping list"], {
					fontObject = "GameFontRedSmall",
					anchor = "TOPLEFT",
					relativeTo = "$parent",
					relativePoint = "TOPLEFT",
					xOffset = 8,
					yOffset = -8,
				} );
				NS.options.TextFrame( "ItemValueSrcLabel", OptionsFrame, L["Item Value Source"], {
					fontObject = "GameFontNormalSmall",
					yOffset = -18,
				} );
				NS.options.DropDownMenu( "ItemValueSrcDropDownMenu", OptionsFrame, {
					tooltip = string.format( L["Sets the data source for Item Value.\nYou must have the corresponding addon\ninstalled and it's price data available.\n\nItem Value is the base price from which\n%sLow|r, %sNorm|r, and %sFull|r prices are calculated."], NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full ),
					buttons = {
						{ L["AtrValue"], "AtrValue" },
						{ L["AucAppraiser"], "AucAppraiser" },
						{ L["AucMarket"], "AucMarket" },
						{ L["AucMinBuyout"], "AucMinBuyout" },
						{ L["DBGlobalMarketAvg"], "DBGlobalMarketAvg" },
						{ L["DBGlobalMinBuyoutAvg"], "DBGlobalMinBuyoutAvg" },
						{ L["DBGlobalSaleAvg"], "DBGlobalSaleAvg" },
						{ L["DBMarket"], "DBMarket" },
						{ L["DBMinBuyout"], "DBMinBuyout" },
						{ L["wowuctionMarket"], "wowuctionMarket" },
						{ L["wowuctionMedian"], "wowuctionMedian" },
						{ L["wowuctionRegionMarket"], "wowuctionRegionMarket" },
						{ L["wowuctionRegionMedian"], "wowuctionRegionMedian" },
					},
					onClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] = info.value;
						_G[subFrame.name .. "ScrollFrame"]:Update();
					end,
					width = 149,
				} );
				NS.options.TextFrame( "OnHandTrackingLabel", OptionsFrame, L["On Hand Tracking"], {
					fontObject = "GameFontNormalSmall",
					xOffset = 12,
					yOffset = -8,
				} );
				NS.options.DropDownMenu( "QOHAllCharactersDropDownMenu", OptionsFrame, {
					tooltip = string.format( L["Sets which characters to\ninclude for On Hand values.\n\n%sWARNING!|r\nTradeSkillMaster_ItemTracker\nsettings affect On Hand values."], RED_FONT_COLOR_CODE ),
					buttons = {
						{ L["All Characters"], 1 },
						{ L["Current Character"], 2 },
					},
					onClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] = info.value;
						_G[subFrame.name .. "ScrollFrame"]:Update();
					end,
					width = 109,
				} );
				NS.options.CheckButton( "QOHGuildsCheckButton", OptionsFrame, L["Include Guild Bank(s)"], {
					tooltip = string.format( L["On Hand values include the\nGuild Bank(s) based on whether\nyou selected All Characters\nor Current Character.\n\n%sWARNING!|r\nTradeSkillMaster_ItemTracker\nsettings affect On Hand values."], RED_FONT_COLOR_CODE ),
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					anchor = "TOPLEFT",
					relativePoint = "TOPRIGHT",
					xOffset = -2,
					yOffset = -1,
					onClick = function( checked )
						NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] = checked;
						_G[subFrame.name .. "ScrollFrame"]:Update();
					end,
				} );
				NS.options.TextFrame( "LowStockPctLabel", OptionsFrame, string.format( L["%sLow Stock %%|r"], NS.colorCode.low ), {
					fontObject = "GameFontNormalSmall",
					relativeTo = "$parentQOHAllCharactersDropDownMenu",
					xOffset = 12,
					yOffset = -8,
					size = { 62, 10 },
				} );
				NS.options.DropDownMenu( "LowStockPctDropDownMenu", OptionsFrame, {
					tooltip = string.format( L["When an item's On Hand quantity\nfalls below this percentage it's\nconsidered %sLow|r."], NS.colorCode.low ),
					buttons = {
						{ "10%", 10 },
						{ "20%", 20 },
						{ "30%", 30 },
						{ "40%", 40 },
						{ "50%", 50 },
						{ "60%", 60 },
						{ "70%", 70 },
						{ "80%", 80 },
						{ "90%", 90 },
					},
					onClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] = info.value;
						_G[subFrame.name .. "ScrollFrame"]:Update();
					end,
					width = 49,
				} );
				NS.options.TextFrame( "HideOverstockStacksPctLabel", OptionsFrame, string.format( L["%sHide Overstock Stacks %%|r"], NS.colorCode.full ), {
					fontObject = "GameFontNormalSmall",
					relativeTo = "$parentLowStockPctLabel",
					relativePoint = "TOPRIGHT",
					xOffset = 28,
					size = { 120, 10 },
				} );
				NS.options.DropDownMenu( "HideOverstockStacksPctDropDownMenu", OptionsFrame, {
					tooltip = L["Hides auctions that when purchased\nwould cause you to exceed your\nFull Stock by more than this\npercentage.\n\n(Toggle on/off at the Auction House)"],
					buttons = {
						{ "0%", 0 },
						{ "10%", 10 },
						{ "20%", 20 },
						{ "30%", 30 },
						{ "40%", 40 },
						{ "50%", 50 },
						{ "60%", 60 },
						{ "70%", 70 },
						{ "80%", 80 },
						{ "90%", 90 },
					},
					onClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] = info.value;
					end,
					width = 49,
				} );
				NS.options.Button( "ApplyToAllLists", OptionsFrame, L["Apply To All"], {
					tooltip = L["Apply these settings\nto all shopping lists."],
					size = { 96, 22 },
					anchor = "BOTTOMRIGHT",
					relativeTo = "$parent",
					relativePoint = "BOTTOMRIGHT",
					xOffset = -6,
					yOffset = 6,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_APPLY_TO_ALL_LISTS", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				StaticPopupDialogs["RESTOCKSHOP_APPLY_TO_ALL_LISTS"] = {
					text = L["Apply settings from %s to all lists?"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						for i = 1, #NS.db["shoppingLists"] do
							NS.db["shoppingLists"][i]["itemValueSrc"] = NS.db["shoppingLists"][data["shoppingList"]]["itemValueSrc"];
							NS.db["shoppingLists"][i]["lowStockPct"] = NS.db["shoppingLists"][data["shoppingList"]]["lowStockPct"];
							NS.db["shoppingLists"][i]["qohAllCharacters"] = NS.db["shoppingLists"][data["shoppingList"]]["qohAllCharacters"];
							NS.db["shoppingLists"][i]["qohGuilds"] = NS.db["shoppingLists"][data["shoppingList"]]["qohGuilds"];
							NS.db["shoppingLists"][i]["hideOverstockStacksPct"] = NS.db["shoppingLists"][data["shoppingList"]]["hideOverstockStacksPct"];
						end
						print( "RestockShop: " .. L["Settings applied."] );
						subFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				--
				NS.options.TextFrame( "CurrentShoppingList", subFrame, L["Current Shopping List:"], {
					relativeTo = "$parentDescription",
					yOffset = -120,
					size = { 131, 20 },
				} );
				NS.options.DropDownMenu( "ShoppingListsDropDownMenu", subFrame, {
					anchor = "LEFT",
					relativePoint = "RIGHT",
					xOffset = -12,
					yOffset = -1,
					width = 195,
					buttons = function()
						local t = {};
						for k, v in ipairs( NS.db["shoppingLists"] ) do
							tinsert( t, { v["name"], k } );
						end
						return t;
					end,
					onClick = function( info )
						NS.dbpc["currentListName"] = info.text;
						NS.currentListKey = info.value;
						subFrame:Refresh();
					end,
				} );
				NS.options.TextFrame( "ItemsLabel", subFrame, L["Items:"], {
					anchor = "LEFT",
					relativePoint = "RIGHT",
					xOffset = -6,
					size = { 36, 20 },
				} );
				NS.options.TextFrame( "ItemsNum", subFrame, "", {
					fontObject = "GameFontHighlight",
					anchor = "LEFT",
					relativePoint = "RIGHT",
					xOffset = 4,
					size = { 70, 20 },
				} );
				NS.options.Button( "ItemIdColumnHeaderButton", subFrame, "  " .. L["Item ID"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 67, 19 },
					relativeTo = "$parentCurrentShoppingList",
					relativePoint = "BOTTOMLEFT",
					yOffset = -6,
				} );
				NS.options.Button( "NameColumnHeaderButton", subFrame, "  " .. NAME, {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 217, 19 },
					xOffset = -2,
				} );
				NS.options.Button( "OnHandColumnHeaderButton", subFrame, "  " .. L["On Hand"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 82, 19 },
					xOffset = -2,
				} );
				NS.options.Button( "FullStockQtyColumnHeaderButton", subFrame, "  " .. L["Full Stock"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 82, 19 },
					xOffset = -2,
				} );
				NS.options.Button( "LowStockPriceColumnHeaderButton", subFrame, "  " .. L["Low"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					xOffset = -2,
					textColor = { NS.fontColor.low.r, NS.fontColor.low.g, NS.fontColor.low.b },
				} );
				NS.options.Button( "NormalStockPriceColumnHeaderButton", subFrame, "  " .. L["Norm"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					xOffset = -2,
					textColor = { NS.fontColor.norm.r, NS.fontColor.norm.g, NS.fontColor.norm.b },
				} );
				NS.options.Button( "FullStockPriceColumnHeaderButton", subFrame, "  " .. L["Full"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					xOffset = -2,
					textColor = { NS.fontColor.full.r, NS.fontColor.full.g, NS.fontColor.full.b },
				} );
				NS.options.Button( "ItemValueColumnHeaderButton", subFrame, "  " .. L["Item Value"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 152, 19 },
					xOffset = -2,
				} );
				NS.options.Button( "DeleteColumnHeaderButton", subFrame, "", {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 32, 19 },
					xOffset = -2,
				} );
				NS.options.ScrollFrame( "ScrollFrame", subFrame, {
					size = { 785, 276 },
					yOffset = -6,
					relativeTo = "$parentItemIdColumnHeaderButton",
					buttonTemplate = "RestockShopInterfaceOptionsPanelShoppingLists_ScrollFrame_EntryTemplate",
					udpate = {
						numToDisplay = 15,
						buttonHeight = 16,
						alwaysShowScrollBar = true,
						updateFunction = function( sf )
							local items = NS.db["shoppingLists"][NS.currentListKey]["items"];
							local numItems = #items;
							_G[subFrame.name .. "ItemsNumText"]:SetText( numItems );
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							for num = 1, sf.numToDisplay do
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local k = FauxScrollFrame_GetOffset( sf ) + num; -- key
								b:UnlockHighlight();
								if k <= numItems then
									_G[bn .. "_ItemId"]:SetText( items[k]["itemId"] );
									_G[bn .. "_IconTexture"]:SetTexture( items[k]["texture"] );
									_G[bn .. "_IconTexture"]:GetParent():SetScript( "OnEnter", function() GameTooltip:SetOwner( _G[bn .. "_IconTexture"]:GetParent(), "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[k]["link"] ); end );
									_G[bn .. "_IconTexture"]:GetParent():SetScript( "OnLeave", GameTooltip_Hide );
									_G[bn .. "_Name"]:SetText( items[k]["name"] );
									_G[bn .. "_Name"]:SetTextColor( GetItemQualityColor( items[k]["quality"] ) );
									_G[bn .. "_OnHand"]:SetText( RestockShop_QOH( items[k]["tsmItemString"] ) );
									_G[bn .. "_FullStockQty"]:SetText( items[k]["fullStockQty"] );
									_G[bn .. "_LowStockPrice"]:SetText( items[k]["maxPricePct"]["low"] .. "%" );
									_G[bn .. "_NormalStockPrice"]:SetText( items[k]["maxPricePct"]["normal"] .. "%" );
									if items[k]["maxPricePct"]["full"] == 0 then
										_G[bn .. "_FullStockPrice"]:SetText( "-" );
									else
										_G[bn .. "_FullStockPrice"]:SetText( items[k]["maxPricePct"]["full"] .. "%" );
									end
									MoneyFrame_Update( bn .. "_ItemValue_SmallMoneyFrame", TSMAPI:GetItemValue( items[k]["link"], NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] ) or 0 );
									_G[bn .. "_DeleteButton"]:SetScript( "OnClick", function() StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEM_DELETE", items[k]["name"], NS.db["shoppingLists"][NS.currentListKey]["name"], { ["shoppingList"] = NS.currentListKey, ["itemId"] = items[k]["itemId"] } ); end );
									b:SetScript( "OnClick", function()
										local sfn = subFrame.name;
										_G[sfn .. "ItemIdEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["itemId"] );
										_G[sfn .. "FullStockQtyEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["fullStockQty"] );
										_G[sfn .. "LowStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["low"] );
										_G[sfn .. "NormalStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["normal"] );
										_G[sfn .. "FullStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["full"] );
										_G[sfn .. "ItemIdEditbox"]:ClearFocus();
										_G[sfn .. "ItemIdEditbox"]:SetFocus();
									end );
									b:Show();
								else
									b:Hide();
								end
							end
						end
					},
					scrollbarTop = { size = { 31, 250 } },
					scrollbarBottom = { size = { 31, 100 } },
				} );
				NS.options.Button( "CreateListButton", subFrame, L["Create List"], {
					size = { 96, 22 },
					anchor = "BOTTOMLEFT",
					relativeTo = NS.options.MainFrame.name,
					relativePoint = "BOTTOMLEFT",
					xOffset = 15,
					yOffset = 4,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_CREATE" );
					end,
				} );
				NS.options.Button( "CopyListButton", subFrame, L["Copy List"], {
					size = { 96, 22 },
					xOffset = 10,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_COPY", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.options.Button( "DeleteListButton", subFrame, L["Delete List"], {
					size = { 96, 22 },
					xOffset = 10,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_DELETE", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.options.Button( "ImportItemsButton", subFrame, L["Import Items"], {
					size = { 116, 22 },
					xOffset = 10,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.options.Button( "ExportItemsButton", subFrame, L["Export Items"], {
					size = { 116, 22 },
					xOffset = 10,
					onClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_EXPORT", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				local function CreateList( shoppingListName, data )
					shoppingListName = strtrim( shoppingListName );
					-- Empty list name
					if shoppingListName == "" then
						print( "RestockShop: " .. L["List name cannot be empty"] );
					else
						-- Duplicate list name
						local duplicate = false;
						for _, list in ipairs( NS.db["shoppingLists"] ) do
							if shoppingListName == list["name"] then
								duplicate = true;
								print( "RestockShop: " .. RED_FONT_COLOR_CODE .. L["List not created, that name already exists"] .. "|r" );
								break;
							end
						end
						-- Add new list
						if not duplicate then
							-- Insert into list table
							table.insert( NS.db["shoppingLists"], {} );
							-- Create or Copy?
							if data then
								-- Copy List, copy all items and settings from the original list into the new list
								NS.db["shoppingLists"][#NS.db["shoppingLists"]] = CopyTable( NS.db["shoppingLists"][data["shoppingList"]] );
							else
								-- Create List, copy all settings from default variables
								local vars = RestockShop_DefaultSavedVariables();
								NS.db["shoppingLists"][#NS.db["shoppingLists"]] = CopyTable( vars["shoppingLists"][1] );
							end
							-- Update Name
							NS.db["shoppingLists"][#NS.db["shoppingLists"]]["name"] = shoppingListName;
							-- Sort lists
							table.sort ( NS.db["shoppingLists"],
								function ( list1, list2 )
									return list1["name"] < list2["name"]; -- Sort by name A-Z
								end
							);
							-- Set newly created list to the selected list
							for k, list in ipairs( NS.db["shoppingLists"] ) do
								if shoppingListName == list["name"] then
									NS.dbpc["currentListName"] = shoppingListName;
									NS.currentListKey = k;
									break;
								end
							end
							-- Refreshes the dropdown menu and shopping list scrollframe
							subFrame:Refresh();
							-- Notfiy user
							print( "RestockShop: " .. L["List created"] );
						end
					end
				end
				local function ImportItems( importString, data )
					--
					-- Function: importItem()
					local function importItem( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, maxStack, texture )
						if fullStockQty < 1 or lowStockPrice < 1 or normalStockPrice < 1 or lowStockPrice < normalStockPrice or normalStockPrice < fullStockPrice then
							return false;
						else
							local itemKey = RestockShop_FindItemKey( itemId );
							if not itemKey then
								itemKey = #NS.db["shoppingLists"][data["shoppingList"]]["items"] + 1;
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
							NS.db["shoppingLists"][data["shoppingList"]]["items"][itemKey] = itemInfo;
							table.sort ( NS.db["shoppingLists"][data["shoppingList"]]["items"],
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
						_G[subFrame.name .. "ImportItemsButton"]:Disable();
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
							_G[subFrame.name .. "ScrollFrame"]:Update();
							_G[subFrame.name .. "ImportItemsButton"]:Enable();
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
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEM_DELETE"] = {
					text = L["Delete item? %s from %s"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						local itemKey = RestockShop_FindItemKey( data["itemId"], data["shoppingList"] );
						if not itemKey then return end
						print( "RestockShop: " .. L["Item deleted"] .. " " .. NS.db["shoppingLists"][data["shoppingList"]]["items"][itemKey]["link"] );
						table.remove( NS.db["shoppingLists"][data["shoppingList"]]["items"], itemKey );
						_G[subFrame.name .. "ScrollFrame"]:Update();
					end,
					OnCancel = function ( self ) end,
					OnShow = function ( self )
						if not NS.db["showDeleteItemConfirmDialog"] then
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
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_CREATE"] = {
					text = L["Create List"],
					button1 = ACCEPT,
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 50,
					OnAccept = function ( self )
						CreateList( self.editBox:GetText() );
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
						CreateList( parent.editBox:GetText() );
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
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_COPY"] = {
					text = L["Copy List: %s"],
					button1 = ACCEPT,
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 50,
					OnAccept = function ( self, data )
						CreateList( self.editBox:GetText(), data );
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
						CreateList( parent.editBox:GetText(), data );
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
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLIST_DELETE"] = {
					text = L["Delete list? %s"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						if #NS.db["shoppingLists"] == 1 then
							print( "RestockShop: " .. RED_FONT_COLOR_CODE .. L["You can't delete your only list, you must keep at least one"] .. "|r" );
							return;
						end
						table.remove( NS.db["shoppingLists"], data["shoppingList"] );
						-- Select first shopping list
						NS.dbpc["currentListName"] = NS.db["shoppingLists"][1]["name"];
						NS.currentListKey = 1;
						--
						subFrame:Refresh();
						print( "RestockShop: " .. L["List deleted"] );
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT"] = {
					text = L["Import items to list: %s\n\n|cffffd200TSM|r\nComma-delimited Item IDs\nNo subgroup structure\n|cff82c5ff12345,12346|r\n\nor\n\n|cffffd200RestockShop|r\nComma-delimited items\nColon-delimited settings\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\n"],
					button1 = ACCEPT,
					button2 = CANCEL,
					hasEditBox = 1,
					maxLetters = 0,
					OnAccept = function ( self, data )
						ImportItems( self.editBox:GetText(), data );
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
						ImportItems( parent.editBox:GetText(), data );
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
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEMS_EXPORT"] = {
					text = L["Export items from list: %s\n\n|cffffd200TSM|r\nComma-delimited Item IDs\n|cff82c5ff12345,12346|r\n\nor\n\n|cffffd200RestockShop|r\nComma-delimited items\nColon-delimited settings\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\n"];
					button1 = "TSM",
					button2 = CANCEL,
					button3 = "RestockShop",
					hasEditBox = 1,
					maxLetters = 0,
					OnAccept = function ( self, data )
						local exportTable = {};
						for k, v in ipairs( NS.db["shoppingLists"][data["shoppingList"]]["items"] ) do
							table.insert( exportTable, v["itemId"] );
						end
						local exportString = table.concat( exportTable, "," );
						self.editBox:SetText( exportString );
						_G[self:GetName() .. "Button1Text"]:SetText( "dontHide" ); -- Don't hide the dialog this way instead of returning true for button Sound consistency with OnAlt
					end,
					OnCancel = function ( self ) end,
					OnAlt = function ( self, data )
						local exportTable = {};
						for k, v in ipairs( NS.db["shoppingLists"][data["shoppingList"]]["items"] ) do
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
			end,
			refresh			= function( subFrame )
				local dm, sfn = nil, subFrame.name;
				local ofn = sfn .. "Options";
				-- Dropdown Menus
				dm = _G[ofn .. "ItemValueSrcDropDownMenu"];
				UIDropDownMenu_Initialize( dm, NS.options.DropDownMenu_Initialize );
				UIDropDownMenu_SetSelectedValue( dm, NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] );
				--
				dm = _G[ofn .. "QOHAllCharactersDropDownMenu"];
				UIDropDownMenu_Initialize( dm, NS.options.DropDownMenu_Initialize );
				UIDropDownMenu_SetSelectedValue( dm, NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] );
				--
				dm = _G[ofn .. "LowStockPctDropDownMenu"];
				UIDropDownMenu_Initialize( dm, NS.options.DropDownMenu_Initialize );
				UIDropDownMenu_SetSelectedValue( dm, NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] );
				--
				dm = _G[ofn .. "HideOverstockStacksPctDropDownMenu"];
				UIDropDownMenu_Initialize( dm, NS.options.DropDownMenu_Initialize );
				UIDropDownMenu_SetSelectedValue( dm, NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] );
				--
				dm = _G[sfn .. "ShoppingListsDropDownMenu"];
				UIDropDownMenu_Initialize( dm, NS.options.DropDownMenu_Initialize );
				UIDropDownMenu_SetSelectedValue( dm, NS.currentListKey );
				-- Check Buttons
				_G[ofn .. "QOHGuildsCheckButton"]:SetChecked( NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] );
				-- ScrollFrame
				sf = _G[sfn .. "ScrollFrame"];
				sf:SetVerticalScroll( 0 );
				sf:Update();
			end,
		},
		{
			-- More Options
			mainFrameTitle	= NS.title,
			tabText			= "More Options",
			init			= function( subFrame )
				NS.options.TextFrame( "Description", subFrame, L["These options apply to all shopping lists and characters on your account."], {
					fontObject = "GameFontRedSmall",
					relativeTo = "$parent",
					relativePoint = "TOPLEFT",
					xOffset = 8,
					yOffset = -8,
				} );
				NS.options.TextFrame( "ItemTooltipLabel", subFrame, L["Item Tooltip"], {
					yOffset = -18,
				} );
				NS.options.CheckButton( "ItemTooltipShoppingListSettingsCheckButton", subFrame, L["Shopping List Settings"], {
					tooltip = L["Displays item settings for the\ncurrently selected shopping\nlist in the item's tooltip."],
					db = "itemTooltipShoppingListSettings",
				} );
				NS.options.CheckButton( "ItemTooltipItemIdCheckButton", subFrame, L["Item ID"], {
					tooltip = L["Displays the Item ID in the\ntooltip of all items."],
					xOffset = 0,
					yOffset = -1,
					db = "itemTooltipItemId",
				} );
				NS.options.TextFrame( "MiscLabel", subFrame, L["Miscellaneous"], {
					xOffset = -3,
					yOffset = -8,
				} );
				NS.options.CheckButton( "ShowDeleteItemConfirmDialogCheckButton", subFrame, L["Show Delete Item Confirmation Dialog"], {
					tooltip = L["Confirm before deleting an\nitem from a shopping list."],
					db = "showDeleteItemConfirmDialog",
				} );
				NS.options.CheckButton( "rememberOptionsFramePositionCheckButton", subFrame, L["Remember Options Frame Position"], {
					tooltip = L["Remember drag position or\nplace in center when opened."],
					xOffset = 0,
					yOffset = -1,
					onClick = function( checked )
						if not checked then
							local vars = RestockShop_DefaultSavedVariables();
							NS.db["optionsFramePosition"] = vars["optionsFramePosition"];
						end
					end,
					db = "rememberOptionsFramePosition",
				} );
			end,
			refresh			= function( subFrame )
				local sfn = subFrame.name;
				-- Check Buttons
				_G[sfn .. "ItemTooltipShoppingListSettingsCheckButton"]:SetChecked( NS.db["itemTooltipShoppingListSettings"] );
				_G[sfn .. "ItemTooltipItemIdCheckButton"]:SetChecked( NS.db["itemTooltipItemId"] );
				_G[sfn .. "ShowDeleteItemConfirmDialogCheckButton"]:SetChecked( NS.db["showDeleteItemConfirmDialog"] );
				_G[sfn .. "rememberOptionsFramePositionCheckButton"]:SetChecked( NS.db["rememberOptionsFramePosition"] );
			end,
		},
		{
			-- Help
			mainFrameTitle	= NS.title,
			tabText			= "Help",
			init			= function( subFrame )
				NS.options.TextFrame( "Description", subFrame, string.format( L["%s version %s"], NS.title, NS.stringVersion ), {
					fontObject = "GameFontRedSmall",
					relativeTo = "$parent",
					relativePoint = "TOPLEFT",
					xOffset = 8,
					yOffset = -8,
				} );
				NS.options.TextFrame( "SlashCommandsHeader", subFrame, string.format( L["%sSlash Commands|r"], BATTLENET_FONT_COLOR_CODE ), {
					fontObject = "GameFontNormalLarge",
					yOffset = -18,
				} );
				NS.options.TextFrame( "SlashCommands", subFrame, string.format(
						L["%s/rs|r - Opens options frame to \"Shopping Lists\"\n" ..
						"%s/rs moreoptions|r - Opens options frame to \"More Options\"\n" ..
						"%s/rs help|r - Opens options frame to \"Help\"\n" ..
						"%s/rs acceptbuttonclick|r - Clicks the Accept button on the Auction House tab. Useful in a Macro for fast key or mouse bound buying."],
						NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE
					), {
					fontObject = "GameFontHighlight",
					yOffset = -8,
				} );
				NS.options.TextFrame( "ItemStatusesHeader", subFrame, string.format( L["%sItem Statuses|r"], BATTLENET_FONT_COLOR_CODE ), {
					fontObject = "GameFontNormalLarge",
					yOffset = -18,
				} );
				NS.options.TextFrame( "ItemStatuses", subFrame, string.format(
						L["%sLow|r - On Hand percent is at or below %sLow Stock %%|r.\n" ..
						"%sNorm|r - On Hand percent is above %sLow Stock %%|r but below 100%%.\n" ..
						"%sFull|r - On Hand percent is at or above 100%% and a %sFull|r max price %% is available to continue shopping and buying.\n" ..
						"%sFull|r - On Hand percent is at or above 100%% and no %sFull|r max price %% is available, this item will be skipped when shopping."],
						NS.colorCode.low, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.low, NS.colorCode.full, NS.colorCode.full, NS.colorCode.maxFull, NS.colorCode.full
					), {
					fontObject = "GameFontHighlight",
					yOffset = -8,
				} );
				NS.options.TextFrame( "ItemValueSouresHeader", subFrame, string.format( L["%sItem Value Sources|r"], BATTLENET_FONT_COLOR_CODE ), {
					fontObject = "GameFontNormalLarge",
					yOffset = -18,
				} );
				NS.options.TextFrame( "ItemValueSources", subFrame, string.format(
						L["%sAtrValue|r - Auctionator Auction Value\n" ..
						"%sAucAppraiser|r - Auctioneer Appraiser\n" ..
						"%sAucMarket|r - Auctioneer Market Value\n" ..
						"%sAucMinBuyout|r - Auctioneer Minimum Buyout\n" ..
						"%sDBGlobalMarketAvg|r - AuctionDB Global Market Value Average (via TSM App)\n" ..
						"%sDBGlobalMinBuyoutAvg|r - AuctionDB Global Minimum Buyout Average (via TSM App)\n" ..
						"%sDBGlobalSaleAvg|r - AuctionDB Global Sale Average (via TSM App)\n" ..
						"%sDBMarket|r - AuctionDB Market Value\n" ..
						"%sDBMinBuyout|r - AuctionDB Minimum Buyout\n" ..
						"%swowuctionMarket|r - WoWuction Realm Market Value\n" ..
						"%swowuctionMedian|r - WoWuction Realm Median Price\n" ..
						"%swowuctionRegionMarket|r - WoWuction Region Market Value\n" ..
						"%swowuctionRegionMedian|r - WoWuction Region Median Price"],
						NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE
					), {
					fontObject = "GameFontHighlight",
					yOffset = -8,
				} );
				NS.options.TextFrame( "NeedMoreHelpHeader", subFrame, string.format( L["%sNeed More Help?|r"], BATTLENET_FONT_COLOR_CODE ), {
					fontObject = "GameFontNormalLarge",
					yOffset = -18,
				} );
				NS.options.TextFrame( "NeedMoreHelp", subFrame, string.format(
						L["%sQuestions, comments, and suggestions can be made on Curse. Please submit bug reports on CurseForge.|r\n\n" ..
						"http://www.curse.com/addons/wow/restockshop\n" ..
						"http://wow.curseforge.com/addons/restockshop/tickets/"],
						NORMAL_FONT_COLOR_CODE
					), {
					fontObject = "GameFontHighlight",
					yOffset = -8,
				} );
			end,
			refresh			= function( subFrame ) return end,
		},
	},
};
