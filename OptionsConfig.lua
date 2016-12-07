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
		width		= 848,
		height		= 590,
		frameStrata	= "MEDIUM",
		frameLevel	= "TOP",
		buttonBar	= true,
		Init		= function( MainFrame ) end,
		OnShow		= function( MainFrame )
			MainFrame:ClearAllPoints();
			MainFrame:SetPoint( unpack( NS.db["optionsFramePosition"] ) );
		end,
		OnHide		= function( MainFrame )
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
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, string.format( L["%sItem ID|r: Found in the item's tooltip or Wowhead URL (e.g. /item=12345/)\n%sFull Stock|r: The max number of an item you want to keep in stock.\n%sLow|r, %sNorm|r, %sFull|r: The item's max price at the corresponding stock quantity.\n%sNote:|r To avoid scanning an item at %sFull Stock|r leave %sFull|r %sempty|r or set to %s0|r."], NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full, RED_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NS.colorCode.full, BATTLENET_FONT_COLOR_CODE, BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.Button( "ApplyToAllItems", SubFrame, L["Apply To All Items"], {
					hidden = true,
					size = { 249, 22 },
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 91, -10 },
					tooltip = string.format( L["Updates all items that remain\n%sLow|r >= %sNorm|r >= %sFull|r"], NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full ),
					OnClick = function( self )
						local sfn = SubFrame:GetName();
						local field, value, desc, applyError;
						-- Full Stock
						if _G[sfn .. "FullStockQtyEditbox"]:HasFocus() then
							field = "Full Stock";
							value = _G[sfn .. "FullStockQtyEditbox"]:GetNumber();
							desc = NORMAL_FONT_COLOR_CODE .. "Full Stock|r of " .. NORMAL_FONT_COLOR_CODE .. value .. "|r";
							if value < 1 then
								applyError = true;
								NS.Print( string.format( L["%sFull Stock|r cannot be empty"], NORMAL_FONT_COLOR_CODE ) );
							end
						-- Low
						elseif _G[sfn .. "LowStockPriceEditbox"]:HasFocus() then
							field = "Low";
							value = _G[sfn .. "LowStockPriceEditbox"]:GetNumber();
							desc = NS.colorCode.low .. "Low|r max price of " .. NS.colorCode.low .. value .. "%|r";
							if value < 1 then
								applyError = true;
								NS.Print( string.format( L["%sLow|r cannot be empty"], NS.colorCode.low ) );
							end
						-- Norm
						elseif _G[sfn .. "NormalStockPriceEditbox"]:HasFocus() then
							field = "Norm";
							value = _G[sfn .. "NormalStockPriceEditbox"]:GetNumber();
							desc = NS.colorCode.norm .. "Norm|r max price of " .. NS.colorCode.norm .. value .. "%|r";
							if value < 1 then
								applyError = true;
								NS.Print( string.format( L["%sNorm|r cannot be empty"], NS.colorCode.norm ) );
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
						NS.Print( string.format( L["%d items updated."], itemsUpdated ) );
						SubFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				NS.TextFrame( "ItemIdLabel", SubFrame, L["Item ID"], {
					size = { ( 52 + 10 ), 20 },
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -69, 1 },
				} );
				NS.TextFrame( "FullStockLabel", SubFrame, L["Full Stock"], {
					size = { ( 48 + 14 ), 20 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
				} );
				NS.TextFrame( "LowStockPriceLabel", SubFrame, NS.colorCode.low .. L["Low"] .. "|r", {
					size = { ( 32 + 25 ), 20 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 15, 0 },
				} );
				NS.TextFrame( "NormalStockPriceLabel", SubFrame, NS.colorCode.norm .. L["Norm"] .. "|r", {
					size = { ( 32 + 25 ), 20 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
				} );
				NS.TextFrame( "FullStockPriceLabel", SubFrame, NS.colorCode.full .. L["Full"] .. "|r", {
					size = { ( 32 + 25 ), 20 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
				} );
				NS.InputBox( "ItemIdEditbox", SubFrame, {
					size = { 52, 20 },
					setPoint = { "TOPLEFT", "$parentItemIdLabel", "BOTTOMLEFT", 4, 0 },
					numeric = true,
					maxLetters = 6,
					OnTabPressed = function() _G[SubFrame:GetName() .. "FullStockQtyEditbox"]:SetFocus(); end,
					OnEnterPressed = function() _G[SubFrame:GetName() .. "SubmitButton"]:Click(); end,
					OnEditFocusGained = function( self )
						self:HighlightText();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
					end,
					OnTextChanged = function( self, userInput )
						NS.editItemId = _G[SubFrame:GetName() .. "ItemIdEditbox"]:GetNumber();
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				NS.InputBox( "FullStockQtyEditbox", SubFrame, {
					size = { 45, 20 },
					numeric = true,
					maxLetters = 5,
					setPoint = { "TOPLEFT", "$parentFullStockLabel", "BOTTOMLEFT", 4, 0 },
					OnTabPressed = function() _G[SubFrame:GetName() .. "LowStockPriceEditbox"]:SetFocus(); end,
					OnEnterPressed = function() _G[SubFrame:GetName() .. "SubmitButton"]:Click(); end,
					OnEditFocusGained = function( self )
						self:HighlightText();
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:SetText( L["Full Stock"] .. " - " .. L["Apply To All Items"] );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Hide();
					end,
				} );
				NS.InputBox( "LowStockPriceEditbox", SubFrame, {
					size = { 32, 20 },
					numeric = true,
					maxLetters = 3,
					setPoint = { "TOPLEFT", "$parentLowStockPriceLabel", "BOTTOMLEFT", 4, 0 },
					OnTabPressed = function() _G[SubFrame:GetName() .. "NormalStockPriceEditbox"]:SetFocus(); end,
					OnEnterPressed = function() _G[SubFrame:GetName() .. "SubmitButton"]:Click(); end,
					OnEditFocusGained = function( self )
						self:HighlightText();
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.low .. L["Low"] .. "|r - " .. L["Apply To All Items"] );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Hide();
					end,
				} );
				NS.TextFrame( "LowStockPctSymbol", SubFrame, "%", {
					size = { 20, 20 },
					setPoint = { "TOPLEFT", "$parentLowStockPriceEditbox", "TOPRIGHT", 5, 0 },
				} );
				NS.InputBox( "NormalStockPriceEditbox", SubFrame, {
					size = { 32, 20 },
					numeric = true,
					maxLetters = 3,
					setPoint = { "TOPLEFT", "$parentNormalStockPriceLabel", "BOTTOMLEFT", 4, 0 },
					OnTabPressed = function() _G[SubFrame:GetName() .. "FullStockPriceEditbox"]:SetFocus(); end,
					OnEnterPressed = function() _G[SubFrame:GetName() .. "SubmitButton"]:Click(); end,
					OnEditFocusGained = function( self )
						self:HighlightText();
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.norm .. L["Norm"] .. "|r - " .. L["Apply To All Items"] );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Hide();
					end,
				} );
				NS.TextFrame( "NormalStockPctSymbol", SubFrame, "%", {
					size = { 20, 20 },
					setPoint = { "TOPLEFT", "$parentNormalStockPriceEditbox", "TOPRIGHT", 5, 0 },
				} );
				NS.InputBox( "FullStockPriceEditbox", SubFrame, {
					size = { 32, 20 },
					numeric = true,
					maxLetters = 3,
					setPoint = { "TOPLEFT", "$parentFullStockPriceLabel", "BOTTOMLEFT", 4, 0 },
					OnTabPressed = function() _G[SubFrame:GetName() .. "ItemIdEditbox"]:SetFocus(); end,
					OnEnterPressed = function() _G[SubFrame:GetName() .. "SubmitButton"]:Click(); end,
					OnEditFocusGained = function( self )
						self:HighlightText();
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:SetText( NS.colorCode.full .. L["Full"] .. "|r - " .. L["Apply To All Items"] );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Show();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
						_G[SubFrame:GetName() .. "ApplyToAllItems"]:Hide();
					end,
				} );
				NS.TextFrame( "FullStockPctSymbol", SubFrame, "%", {
					size = { 20, 20 },
					setPoint = { "TOPLEFT", "$parentFullStockPriceEditbox", "TOPRIGHT", 5, 0 },
				} );
				NS.TextFrame( "PricesDescription", SubFrame, L["Max prices, percentage of Item's Value"], {
					setPoint = {
						{ "TOPLEFT", "$parentLowStockPriceEditbox", "BOTTOMLEFT", -12, -4 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalSmall",
				} );
				NS.Button( "SubmitButton", SubFrame, L["Submit"], {
					size = { 80, 22 },
					setPoint = { "TOPLEFT", "$parentFullStockPriceEditbox", "TOPRIGHT", 30, 0 },
					OnClick = function( self )
						self:Disable();
						--
						local sfn = SubFrame:GetName();
						local CompleteSubmission;
						--
						local itemId = _G[sfn .. "ItemIdEditbox"]:GetNumber();
						local fullStockQty = _G[sfn .. "FullStockQtyEditbox"]:GetNumber();
						local lowStockPrice = _G[sfn .. "LowStockPriceEditbox"]:GetNumber();
						local normalStockPrice = _G[sfn .. "NormalStockPriceEditbox"]:GetNumber();
						local fullStockPrice = _G[sfn .. "FullStockPriceEditbox"]:GetNumber();
						--
						CompleteSubmission = function( name,link,quality,level,minLevel,type,subType,stackCount,equipLoc,texture,sellPrice,classID,subClassID )
							local submitError = false;
							-- Item Id
							if not name then
								submitError = true;
								NS.Print( string.format( L["Item not found, check your %sItem ID|r"], NORMAL_FONT_COLOR_CODE ) );
							end
							-- Full Stock
							if fullStockQty < 1 then
								submitError = true;
								NS.Print( string.format( L["%sFull Stock|r cannot be empty"], NORMAL_FONT_COLOR_CODE ) );
							end
							-- Low %
							if lowStockPrice < 1 then
								submitError = true;
								NS.Print( string.format( L["%sLow|r cannot be empty"], NS.colorCode.low ) );
							end
							-- Norm %
							if normalStockPrice < 1 then
								submitError = true;
								NS.Print( string.format( L["%sNorm|r cannot be empty"], NS.colorCode.norm ) );
							end
							-- Low < Norm
							if lowStockPrice ~= 0 and normalStockPrice ~= 0 and lowStockPrice < normalStockPrice then
								submitError = true;
								NS.Print( string.format( L["%sLow|r cannot be smaller than %sNorm|r"], NS.colorCode.low, NS.colorCode.norm ) );
							end
							-- Norm < Full
							if normalStockPrice ~= 0 and fullStockPrice ~= 0 and normalStockPrice < fullStockPrice then
								submitError = true;
								NS.Print( string.format( L["%sNorm|r cannot be smaller than %sFull|r"], NS.colorCode.norm, NS.colorCode.full ) );
							end
							-- Final result...
							if submitError then
								-- Submit Error
								NS.Print( string.format( L["%sItem not added, incorrect or missing data|r"], RED_FONT_COLOR_CODE ) );
							else
								-- Updated or Added
								local which = NS.AddItemToList( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, texture );
								NS.Print( string.format( L["Item %s"], which ) .. " " .. link ); -- Item {updated/added}
								_G[sfn .. "ScrollFrame"]:Update();
								_G[sfn .. "ItemIdEditbox"]:ClearFocus();
								_G[sfn .. "ItemIdEditbox"]:SetFocus();
							end
							--
							self:Enable();
						end
						--
						NS.GetItemInfo( itemId, CompleteSubmission );
					end,
				} );
				-- Gray frame top right
				local OptionsFrame = NS.Frame( "Options", SubFrame, {
					size = { 332, 184 },
					setPoint = { "TOPRIGHT", "$parent", "TOPRIGHT", -8, -8 },
					bg = { 1, 1, 1, 0.1 },
					bgSetAllPoints = true,
				} );
				NS.TextFrame( "Description", OptionsFrame, L["These settings apply only to the current shopping list"], {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontRedSmall",
				} );
				NS.TextFrame( "ItemValueSrcLabel", OptionsFrame, L["Item Value Source"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontNormalSmall",
				} );
				NS.InputBox( "ItemValueSrcEditbox", OptionsFrame, {
					size = { 190, 20 },
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 11, -4 },
					maxLetters = 50,
					tooltip = string.format( L["TradeSkillMaster price source or\ncustom price source. See Glossary\ntab for descriptions or type /tsm sources.\n\nItem Value is the base price from which\n%sLow|r, %sNorm|r, and %sFull|r prices are calculated."], NS.colorCode.low, NS.colorCode.norm, NS.colorCode.full ),
					OnEnterPressed = function( self )
						self:ClearFocus();
					end,
					OnEditFocusGained = function( self )
						self:HighlightText();
					end,
					OnEditFocusLost = function( self )
						self:HighlightText( 0, 0 );
						local source = strtrim( self:GetText() );
						if source ~= "" and string.match( source, "%a" ) and source ~= NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] then
							-- Validate
							if not NS.tsmPriceSources[source] and not TSMAPI:ValidateCustomPrice( source ) then
								NS.Print( RED_FONT_COLOR_CODE .. string.format( L["Not a valid price source or custom price source."], source ) .. FONT_COLOR_CODE_CLOSE );
							end
							-- Update
							NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] = source;
							_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
						else
							-- Ignore and reset
							self:SetText( NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] );
						end
					end,
				} );
				NS.TextFrame( "OnHandTrackingLabel", OptionsFrame, L["On Hand Tracking"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", -11, -8 },
						{ "RIGHT", -12 },
					},
					fontObject = "GameFontNormalSmall",
				} );
				NS.DropDownMenu( "QOHAllCharactersDropDownMenu", OptionsFrame, {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -12, -2 },
					tooltip = string.format( L["Sets which characters to\ninclude for On Hand values.\n\n%sWARNING!|r\nTradeSkillMaster options\nalso affect On Hand values.\n(e.g. Forget Characters, Ignore Guilds)"], RED_FONT_COLOR_CODE ),
					buttons = {
						{ L["All Characters"], 1 },
						{ L["Current Character"], 2 },
					},
					OnClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] = info.value;
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
					width = 116,
				} );
				NS.CheckButton( "QOHGuildsCheckButton", OptionsFrame, L["Include Guild Bank(s)"], {
					template = "InterfaceOptionsSmallCheckButtonTemplate",
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, -1 },
					tooltip = string.format( L["On Hand values include the\nGuild Bank(s) based on whether\nyou selected All Characters\nor Current Character.\n\n%sWARNING!|r\nTradeSkillMaster options\nalso affect On Hand values.\n(e.g. Forget Characters, Ignore Guilds)"], RED_FONT_COLOR_CODE ),
					OnClick = function( checked )
						NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] = checked;
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
				} );
				NS.TextFrame( "LowStockPctLabel", OptionsFrame, string.format( L["%sLow Stock %%|r"], NS.colorCode.low ), {
					size = { 68, 10 },
					setPoint = { "TOPLEFT", "$parentQOHAllCharactersDropDownMenu", "BOTTOMLEFT", 12, -8 },
					fontObject = "GameFontNormalSmall",
				} );
				NS.DropDownMenu( "LowStockPctDropDownMenu", OptionsFrame, {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -12, -2 },
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
					OnClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] = info.value;
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
					end,
					width = 49,
				} );
				NS.TextFrame( "HideOverstockStacksPctLabel", OptionsFrame, string.format( L["%sHide Overstock Stacks %%|r"], NS.colorCode.full ), {
					size = { 130, 10 },
					setPoint = { "TOPLEFT", "$parentLowStockPctLabel", "TOPRIGHT", 28, 0 },
					fontObject = "GameFontNormalSmall",
				} );
				NS.DropDownMenu( "HideOverstockStacksPctDropDownMenu", OptionsFrame, {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", -12, -2 },
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
					OnClick = function( info )
						NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] = info.value;
					end,
					width = 49,
				} );
				NS.Button( "ApplyToAllLists", OptionsFrame, L["Apply To All"], {
					size = { 96, 22 },
					setPoint = { "BOTTOMRIGHT", -6, 6 },
					tooltip = L["Apply these settings\nto all shopping lists."],
					OnClick = function()
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
						NS.Print( L["Settings applied."] );
						SubFrame:Refresh();
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				--
				NS.TextFrame( "CurrentShoppingList", SubFrame, L["Current Shopping List:"], {
					size = { 142, 20 },
					setPoint = { "TOPLEFT", "$parentDescription", "BOTTOMLEFT", 0, -120 },
				} );
				NS.DropDownMenu( "ShoppingListsDropDownMenu", SubFrame, {
					setPoint = { "LEFT", "#sibling", "RIGHT", -12, -1 },
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
						maxRestockCost = fullStockShortage == "0" and ( HIGHLIGHT_FONT_COLOR_CODE .. "(" .. L["Full"] .. ")" .. FONT_COLOR_CODE_CLOSE ) or TSMAPI:MoneyToString( maxRestockCost, HIGHLIGHT_FONT_COLOR_CODE, "OPT_PAD" );
						--
						GameTooltip:AddLine( HIGHLIGHT_FONT_COLOR_CODE .. NS.db["shoppingLists"][NS.currentListKey]["name"] .. FONT_COLOR_CODE_CLOSE );
						GameTooltip:AddDoubleLine( L["Full Stock"] .. ": ",  HIGHLIGHT_FONT_COLOR_CODE .. NS.FormatNum( maxRestockFullStockQty ) .. FONT_COLOR_CODE_CLOSE );
						GameTooltip:AddDoubleLine( L["Full Stock Shortage"] .. ": ",  HIGHLIGHT_FONT_COLOR_CODE .. fullStockShortage .. FONT_COLOR_CODE_CLOSE );
						GameTooltip:AddDoubleLine( L["Max Restock Cost"] .. ": ", maxRestockCost );
						return nil;
					end,
					OnClick = function( info )
						NS.dbpc["currentListName"] = info.text;
						NS.currentListKey = info.value;
						SubFrame:Refresh();
					end,
					width = 195,
				} );
				NS.TextFrame( "ItemsLabel", SubFrame, L["Items:"], {
					size = { 40, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", -6, 0 },
				} );
				NS.TextFrame( "ItemsNum", SubFrame, "", {
					size = { 70, 20 },
					setPoint = { "LEFT", "#sibling", "RIGHT", 4, 0 },
					fontObject = "GameFontHighlight",
				} );
				NS.Button( "ItemIdColumnHeaderButton", SubFrame, "  " .. L["Item ID"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 67, 19 },
					setPoint = { "TOPLEFT", "$parentCurrentShoppingList", "BOTTOMLEFT", 0, -6 },
				} );
				NS.Button( "NameColumnHeaderButton", SubFrame, "  " .. NAME, {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 217, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "OnHandColumnHeaderButton", SubFrame, "  " .. L["On Hand"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 82, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "FullStockQtyColumnHeaderButton", SubFrame, "  " .. L["Full Stock"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 82, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "LowStockPriceColumnHeaderButton", SubFrame, "  " .. L["Low"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
					textColor = { NS.fontColor.low.r, NS.fontColor.low.g, NS.fontColor.low.b },
				} );
				NS.Button( "NormalStockPriceColumnHeaderButton", SubFrame, "  " .. L["Norm"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
					textColor = { NS.fontColor.norm.r, NS.fontColor.norm.g, NS.fontColor.norm.b },
				} );
				NS.Button( "FullStockPriceColumnHeaderButton", SubFrame, "  " .. L["Full"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 57, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
					textColor = { NS.fontColor.full.r, NS.fontColor.full.g, NS.fontColor.full.b },
				} );
				NS.Button( "ItemValueColumnHeaderButton", SubFrame, "  " .. L["Item Value"], {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 152, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.Button( "DeleteColumnHeaderButton", SubFrame, "", {
					template = "RestockShopColumnHeaderButtonTemplate",
					size = { 32, 19 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", -2, 0 },
				} );
				NS.ScrollFrame( "ScrollFrame", SubFrame, {
					size = { 785, ( 20 * 14 - 5 ) },
					setPoint = { "TOPLEFT", "$parentItemIdColumnHeaderButton", "BOTTOMLEFT", 1, -3 },
					buttonTemplate = "RestockShop_Options_ShoppingListsTab_ScrollFrameButtonTemplate",
					udpate = {
						numToDisplay = 14,
						buttonHeight = 20,
						alwaysShowScrollBar = true,
						UpdateFunction = function( sf )
							local items = NS.db["shoppingLists"][NS.currentListKey]["items"];
							local numItems = #items;
							local sfn = SubFrame:GetName();
							_G[sfn .. "ItemsNumText"]:SetText( numItems );
							FauxScrollFrame_Update( sf, numItems, sf.numToDisplay, sf.buttonHeight, nil, nil, nil, nil, nil, nil, sf.alwaysShowScrollBar );
							for num = 1, sf.numToDisplay do
								local bn = sf.buttonName .. num; -- button name
								local b = _G[bn]; -- button
								local k = FauxScrollFrame_GetOffset( sf ) + num; -- key
								b:UnlockHighlight();
								if k <= numItems then
									local OnClick = function()
										_G[sfn .. "ItemIdEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["itemId"] );
										_G[sfn .. "FullStockQtyEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["fullStockQty"] );
										_G[sfn .. "LowStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["low"] );
										_G[sfn .. "NormalStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["normal"] );
										_G[sfn .. "FullStockPriceEditbox"]:SetNumber( NS.db["shoppingLists"][NS.currentListKey]["items"][k]["maxPricePct"]["full"] );
										_G[sfn .. "ItemIdEditbox"]:ClearFocus();
										_G[sfn .. "ItemIdEditbox"]:SetFocus();
									end
									local IsHighlightLocked = function()
										if NS.editItemId == NS.db["shoppingLists"][NS.currentListKey]["items"][k]["itemId"] then
											return true;
										else
											return false;
										end
									end
									b:SetScript( "OnClick", OnClick );
									_G[bn .. "_ItemId"]:SetText( items[k]["itemId"] );
									_G[bn .. "_IconTexture"]:SetNormalTexture( items[k]["texture"] );
									_G[bn .. "_IconTexture"]:SetScript( "OnEnter", function( self ) GameTooltip:SetOwner( self, "ANCHOR_RIGHT" ); GameTooltip:SetHyperlink( items[k]["link"] ); b:LockHighlight(); end );
									_G[bn .. "_IconTexture"]:SetScript( "OnLeave", function() GameTooltip_Hide(); if not IsHighlightLocked() then b:UnlockHighlight(); end end );
									_G[bn .. "_IconTexture"]:SetScript( "OnClick", OnClick );
									_G[bn .. "_Name"]:SetText( items[k]["name"] );
									_G[bn .. "_Name"]:SetTextColor( GetItemQualityColor( items[k]["quality"] ) );
									_G[bn .. "_OnHand"]:SetText( NS.QOH( items[k]["link"] ) );
									_G[bn .. "_FullStockQty"]:SetText( items[k]["fullStockQty"] );
									_G[bn .. "_LowStockPrice"]:SetText( items[k]["maxPricePct"]["low"] .. "%" );
									_G[bn .. "_NormalStockPrice"]:SetText( items[k]["maxPricePct"]["normal"] .. "%" );
									if items[k]["maxPricePct"]["full"] == 0 then
										_G[bn .. "_FullStockPrice"]:SetText( "-" );
									else
										_G[bn .. "_FullStockPrice"]:SetText( items[k]["maxPricePct"]["full"] .. "%" );
									end
									MoneyFrame_Update( bn .. "_ItemValue_SmallMoneyFrame", NS.GetItemValue( items[k]["link"] ) );
									_G[bn .. "_DeleteButton"]:SetScript( "OnClick", function() StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEM_DELETE", items[k]["name"], NS.db["shoppingLists"][NS.currentListKey]["name"], { ["shoppingList"] = NS.currentListKey, ["itemId"] = items[k]["itemId"] } ); end );
									b:Show();
									if IsHighlightLocked() then b:LockHighlight(); end
								else
									b:Hide();
								end
							end
						end
					},
				} );
				NS.Button( "CreateListButton", SubFrame, L["Create List"], {
					size = { 96, 22 },
					setPoint = { "BOTTOMLEFT", NS.options.MainFrame:GetName(), "BOTTOMLEFT", 15, 4 },
					OnClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_CREATE" );
					end,
				} );
				NS.Button( "CopyListButton", SubFrame, L["Copy List"], {
					size = { 96, 22 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
					OnClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_COPY", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.Button( "DeleteListButton", SubFrame, L["Delete List"], {
					size = { 96, 22 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
					OnClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLIST_DELETE", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.Button( "ImportItemsButton", SubFrame, L["Import Items"], {
					size = { 116, 22 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
					OnClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				NS.Button( "ExportItemsButton", SubFrame, L["Export Items"], {
					size = { 116, 22 },
					setPoint = { "TOPLEFT", "#sibling", "TOPRIGHT", 10, 0 },
					OnClick = function()
						StaticPopup_Show( "RESTOCKSHOP_SHOPPINGLISTITEMS_EXPORT", NS.db["shoppingLists"][NS.currentListKey]["name"], nil, { ["shoppingList"] = NS.currentListKey } );
					end,
				} );
				local function CreateList( shoppingListName, data )
					shoppingListName = strtrim( shoppingListName );
					if shoppingListName == "" then
						-- Empty list name
						NS.Print( L["List name cannot be empty"] );
					elseif NS.FindKeyByField( NS.db["shoppingLists"], "name", shoppingListName ) then
						-- Duplicate name
						NS.Print( RED_FONT_COLOR_CODE .. L["List not created, that name already exists"] .. FONT_COLOR_CODE_CLOSE );
					else
						-- Insert list
						table.insert( NS.db["shoppingLists"], {} );
						-- Copy or Create?
						if data then
							-- Copy List: Copy all items and settings from the original list into the new list
							NS.db["shoppingLists"][#NS.db["shoppingLists"]] = CopyTable( NS.db["shoppingLists"][data["shoppingList"]] );
						else
							-- Create List: Copy all settings from default variables
							local vars = NS.DefaultSavedVariables();
							NS.db["shoppingLists"][#NS.db["shoppingLists"]] = CopyTable( vars["shoppingLists"][1] );
						end
						-- Update Name
						NS.db["shoppingLists"][#NS.db["shoppingLists"]]["name"] = shoppingListName;
						-- Sort lists
						NS.Sort( NS.db["shoppingLists"], "name", "ASC" );
						-- Set newly created list to the selected list
						NS.dbpc["currentListName"] = shoppingListName;
						NS.currentListKey = NS.FindKeyByField( NS.db["shoppingLists"], "name", shoppingListName );
						-- Refreshes the dropdown menu and shopping list scrollframe
						SubFrame:Refresh();
						-- Notfiy user
						NS.Print( L["List created"] );
					end
				end
				local function ImportItems( importString, data )
					importString = strtrim( importString );
					if importString == "" then return end -- Ignore empty string
					--
					_G[SubFrame:GetName() .. "ImportItemsButton"]:Disable();
					local items = NS.Explode( ",", importString );
					local itemsInvalid,importedTotal = {}, 0;
					local itemId,fullStockQty,lowStockPrice,normalStockPrice,fullStockPrice,itemNum,NextItem,CompleteItem;
					NS.Print( string.format( L["Attempting to import %d items..."], #items ) );
					--
					NextItem = function()
						if itemNum <= #items then
							itemId,fullStockQty,lowStockPrice,normalStockPrice,fullStockPrice = nil,nil,nil,nil,nil;
							--
							if string.find( items[itemNum], "^i:%d+$" ) then
								_,itemId = strsplit( ":", items[itemNum] );
							elseif string.find( items[itemNum], "^%d+:%d+:%d+:%d+:%d+$" ) then
								itemId,fullStockQty,lowStockPrice,normalStockPrice,fullStockPrice = strsplit( ":", items[itemNum] );
							elseif string.find( items[itemNum], "^%d+$" ) then
								itemId = items[itemNum];
							end
							--
							if itemId then
								itemId = tonumber( itemId );
								fullStockQty = fullStockQty and tonumber( fullStockQty ) or 1;
								lowStockPrice = lowStockPrice and tonumber( lowStockPrice ) or 100;
								normalStockPrice = normalStockPrice and tonumber( normalStockPrice ) or 100;
								fullStockPrice = fullStockPrice and tonumber( fullStockPrice ) or 0;
								return NS.GetItemInfo( itemId, CompleteItem );
							else
								return CompleteItem();
							end
						else
							-- ALL ITEMS COMPLETE
							NS.Print( string.format( L["%d of %d items imported"], importedTotal, #items ) );
							if #itemsInvalid > 0 then
								NS.Print( string.format( L["%d invalid item(s) not imported:"], #itemsInvalid ) );
								for _,invalidItem in ipairs( itemsInvalid ) do
									NS.Print( RED_FONT_COLOR_CODE .. invalidItem .. FONT_COLOR_CODE_CLOSE );
								end
							end
							_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
							_G[SubFrame:GetName() .. "ImportItemsButton"]:Enable();
						end
					end
					--
					CompleteItem = function( name,link,quality,level,minLevel,type,subType,stackCount,equipLoc,texture,sellPrice,classID,subClassID )
						if name and NS.AddItemToList( itemId, fullStockQty, lowStockPrice, normalStockPrice, fullStockPrice, name, link, quality, texture, data["shoppingList"] ) then
							importedTotal = importedTotal + 1;
						else
							table.insert( itemsInvalid, items[itemNum] );
						end
						--
						itemNum = itemNum + 1;
						return NextItem();
					end
					--
					itemNum = 1;
					NextItem();
				end
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEM_DELETE"] = {
					text = L["Delete item? %s from %s"];
					button1 = YES,
					button2 = NO,
					OnAccept = function ( self, data )
						local itemKey = NS.FindItemKey( data["itemId"], data["shoppingList"] );
						if not itemKey then return end
						NS.Print( L["Item deleted"] .. " " .. NS.db["shoppingLists"][data["shoppingList"]]["items"][itemKey]["link"] );
						table.remove( NS.db["shoppingLists"][data["shoppingList"]]["items"], itemKey );
						_G[SubFrame:GetName() .. "ScrollFrame"]:Update();
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
							NS.Print( RED_FONT_COLOR_CODE .. L["You can't delete your only list, you must keep at least one"] .. "|r" );
							return;
						end
						table.remove( NS.db["shoppingLists"], data["shoppingList"] );
						-- Select first shopping list
						NS.dbpc["currentListName"] = NS.db["shoppingLists"][1]["name"];
						NS.currentListKey = 1;
						--
						SubFrame:Refresh();
						NS.Print( L["List deleted"] );
					end,
					OnCancel = function ( self ) end,
					showAlert = 1,
					hideOnEscape = 1,
					timeout = 0,
					exclusive = 1,
					whileDead = 1,
				};
				StaticPopupDialogs["RESTOCKSHOP_SHOPPINGLISTITEMS_IMPORT"] = {
					text = L["Import items to list: %s\n\n|cffffd200TSM|r\nComma-delimited Item IDs\nNo subgroup structure\n|cff82c5ffi:12345,i:12346|r or |cff82c5ff12345,12346|r\n\nor\n\n|cffffd200RestockShop|r\nComma-delimited items\nColon-delimited settings\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\n"],
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
					button3 = NS.title,
					hasEditBox = 1,
					maxLetters = 0,
					OnAccept = function ( self, data )
						local exportTable = {};
						for _,item in ipairs( NS.db["shoppingLists"][data["shoppingList"]]["items"] ) do
							table.insert( exportTable, item["itemId"] );
						end
						local exportString = table.concat( exportTable, "," );
						self.editBox:SetText( exportString );
						_G[self:GetName() .. "Button1Text"]:SetText( "dontHide" ); -- Don't hide the dialog this way instead of returning true for button Sound consistency with OnAlt
					end,
					OnCancel = function ( self ) end,
					OnAlt = function ( self, data )
						local exportTable = {};
						for _,item in ipairs( NS.db["shoppingLists"][data["shoppingList"]]["items"] ) do
							table.insert( exportTable, strjoin( ":", item["itemId"], item["fullStockQty"], item["maxPricePct"]["low"], item["maxPricePct"]["normal"], item["maxPricePct"]["full"] ) );
						end
						local exportString = table.concat( exportTable, "," );
						self.editBox:SetText( exportString );
						_G[self:GetName() .. "Button3Text"]:SetText( "dontHide" ); -- Don't hide dialog this way because Blizzard only has a dontHide option for OnAccept
					end,
					OnShow = function ( self )
						_G[self:GetName() .. "Button1Text"]:SetText( "TSM" );
						_G[self:GetName() .. "Button3Text"]:SetText( NS.title );
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
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				local ofn = sfn .. "Options";
				--
				_G[ofn .. "ItemValueSrcEditbox"]:SetText( NS.db["shoppingLists"][NS.currentListKey]["itemValueSrc"] );
				_G[ofn .. "QOHAllCharactersDropDownMenu"]:Reset( NS.db["shoppingLists"][NS.currentListKey]["qohAllCharacters"] );
				_G[ofn .. "LowStockPctDropDownMenu"]:Reset( NS.db["shoppingLists"][NS.currentListKey]["lowStockPct"] );
				_G[ofn .. "HideOverstockStacksPctDropDownMenu"]:Reset( NS.db["shoppingLists"][NS.currentListKey]["hideOverstockStacksPct"] );
				--
				_G[ofn .. "QOHGuildsCheckButton"]:SetChecked( NS.db["shoppingLists"][NS.currentListKey]["qohGuilds"] );
				--
				_G[sfn .. "ShoppingListsDropDownMenu"]:Reset( NS.currentListKey );
				_G[sfn .. "ScrollFrame"]:Reset();
			end,
		},
		{
			-- More Options
			mainFrameTitle	= NS.title,
			tabText			= "More Options",
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, L["These options apply to all shopping lists and characters on your account."], {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontRedSmall",
				} );
				NS.TextFrame( "ItemTooltipLabel", SubFrame, L["Item Tooltip"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
				} );
				NS.CheckButton( "ItemTooltipShoppingListSettingsCheckButton", SubFrame, L["Shopping List Settings"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 3, -1 },
					tooltip = L["Displays item settings for the\ncurrently selected shopping\nlist in the item's tooltip."],
					db = "itemTooltipShoppingListSettings",
				} );
				NS.CheckButton( "ItemTooltipItemIdCheckButton", SubFrame, L["Item ID"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Displays the Item ID in the\ntooltip of all items."],
					db = "itemTooltipItemId",
				} );
				NS.TextFrame( "MiscLabel", SubFrame, L["Miscellaneous"], {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", -3, -8 },
						{ "RIGHT", -3 },
					},
				} );
				NS.CheckButton( "ShowDeleteItemConfirmDialogCheckButton", SubFrame, L["Show Delete Item Confirmation Dialog"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 3, -1 },
					tooltip = L["Confirm before deleting an\nitem from a shopping list."],
					db = "showDeleteItemConfirmDialog",
				} );
				NS.CheckButton( "rememberOptionsFramePositionCheckButton", SubFrame, L["Remember Options Frame Position"], {
					setPoint = { "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -1 },
					tooltip = L["Remember drag position or\nplace in center when opened."],
					OnClick = function( checked )
						if not checked then
							local vars = NS.DefaultSavedVariables();
							NS.db["optionsFramePosition"] = vars["optionsFramePosition"];
						end
					end,
					db = "rememberOptionsFramePosition",
				} );
			end,
			Refresh			= function( SubFrame )
				local sfn = SubFrame:GetName();
				-- Check Buttons
				_G[sfn .. "ItemTooltipShoppingListSettingsCheckButton"]:SetChecked( NS.db["itemTooltipShoppingListSettings"] );
				_G[sfn .. "ItemTooltipItemIdCheckButton"]:SetChecked( NS.db["itemTooltipItemId"] );
				_G[sfn .. "ShowDeleteItemConfirmDialogCheckButton"]:SetChecked( NS.db["showDeleteItemConfirmDialog"] );
				_G[sfn .. "rememberOptionsFramePositionCheckButton"]:SetChecked( NS.db["rememberOptionsFramePosition"] );
			end,
		},
		{
			-- Glossary
			mainFrameTitle	= NS.title,
			tabText			= "Glossary",
			Init			= function( SubFrame )
				NS.TextFrame( "ItemStatusesHeader", SubFrame, string.format( L["%sItem Statuses|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "ItemStatuses", SubFrame, string.format(
						L["%sLow|r - On Hand percent is at or below %sLow Stock %%|r.\n" ..
						"%sNorm|r - On Hand percent is above %sLow Stock %%|r but below 100%%.\n" ..
						"%sFull|r - On Hand percent is at or above 100%% and a %sFull|r max price %% is available to continue shopping and buying.\n" ..
						"%sFull|r - On Hand percent is at or above 100%% and no %sFull|r max price %% is available, this item will be skipped when shopping."],
						NS.colorCode.low, NS.colorCode.low, NS.colorCode.norm, NS.colorCode.low, NS.colorCode.full, NS.colorCode.full, NS.colorCode.maxFull, NS.colorCode.full
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "ItemValueSouresHeader", SubFrame, string.format( L["%sItem Value Sources|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "ItemValueSources", SubFrame, ( function()
						local sources = {};
						for source, description in pairs( NS.tsmPriceSources ) do
							table.insert( sources, NORMAL_FONT_COLOR_CODE .. source .. "|r - " .. description );
						end
						table.sort( sources );
						return table.concat( sources, "\n" );
					end )(), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontHighlight",
				} );
			end,
			Refresh			= function( SubFrame ) return end,
		},
		{
			-- Help
			mainFrameTitle	= NS.title,
			tabText			= "Help",
			Init			= function( SubFrame )
				NS.TextFrame( "Description", SubFrame, string.format( L["%s version %s"], NS.title, NS.versionString ), {
					setPoint = {
						{ "TOPLEFT", "$parent", "TOPLEFT", 8, -8 },
						{ "RIGHT", -8 },
					},
					fontObject = "GameFontRedSmall",
				} );
				NS.TextFrame( "SlashCommandsHeader", SubFrame, string.format( L["%sSlash Commands|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "SlashCommands", SubFrame, string.format(
						L["%s/rs|r - Opens options frame to \"Shopping Lists\"\n" ..
						"%s/rs moreoptions|r - Opens options frame to \"More Options\"\n" ..
						"%s/rs glossary|r - Opens options frame to \"Glossary\"\n" ..
						"%s/rs help|r - Opens options frame to \"Help\"\n" ..
						"%s/rs acceptbuttonclick|r - Clicks the Accept button on the Auction House tab. Useful in a Macro for fast key or mouse bound buying."],
						NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE, NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontHighlight",
				} );
				NS.TextFrame( "NeedMoreHelpHeader", SubFrame, string.format( L["%sNeed More Help?|r"], BATTLENET_FONT_COLOR_CODE ), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -18 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontNormalLarge",
				} );
				NS.TextFrame( "NeedMoreHelp", SubFrame, string.format(
						L["%sQuestions, comments, and suggestions can be made on Curse. Please submit bug reports on CurseForge.|r\n\n" ..
						"http://www.curse.com/addons/wow/restockshop\n" ..
						"http://wow.curseforge.com/addons/restockshop/tickets/"],
						NORMAL_FONT_COLOR_CODE
					), {
					setPoint = {
						{ "TOPLEFT", "#sibling", "BOTTOMLEFT", 0, -8 },
						{ "RIGHT", 0 },
					},
					fontObject = "GameFontHighlight",
				} );
			end,
			Refresh			= function( SubFrame ) return end,
		},
	},
};
