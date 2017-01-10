--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
NS.addon = ...;
NS.title = GetAddOnMetadata( NS.addon, "Title" );
NS.versionString = GetAddOnMetadata( NS.addon, "Version" );
NS.version = tonumber( NS.versionString );
NS.UI = {};
--------------------------------------------------------------------------------------------------------------------------------------------
-- FRAME CREATION
--------------------------------------------------------------------------------------------------------------------------------------------
NS.LastChild = function( parent )
	local children = { parent:GetChildren() };
	return children[#children - 1]:GetName();
end
--
NS.SetPoint = function( frame, parent, setPoint )
	if type( setPoint[1] ) ~= "table" then
		setPoint = { setPoint };
	end
	for _,point in ipairs( setPoint ) do
		for k, v in ipairs( point ) do
			if v == "#sibling" then
				point[k] = NS.LastChild( parent );
			end
		end
		frame:SetPoint( unpack( point ) );
	end
end
--
NS.Tooltip = function( frame, tooltip, tooltipAnchor )
	frame.tooltip = tooltip;
	frame.tooltipAnchor = tooltipAnchor;
	frame:SetScript( "OnEnter", function( self )
		GameTooltip:SetOwner( unpack( self.tooltipAnchor ) );
		local tooltipText = type( self.tooltip ) ~= "function" and self.tooltip or self.tooltip();
		if tooltipText then -- Function may have only SetHyperlink, etc. without returning text
			GameTooltip:SetText( tooltipText );
		end
		GameTooltip:Show();
	end );
	frame:SetScript( "OnLeave", GameTooltip_Hide );
end
--
NS.TextFrame = function( name, parent, text, set )
	local f = CreateFrame( "Frame", "$parent" .. name, parent );
	local fs = f:CreateFontString( "$parentText", set.layer or "ARTWORK", set.fontObject or "GameFontNormal" );
	--
	fs:SetText( text );
	--
	if set.hidden then
		f:Hide();
	end
	--
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	--
	if set.setAllPoints then
		f:SetAllPoints();
	end
	--
	if set.setPoint then
		NS.SetPoint( f, parent, set.setPoint );
	end
	-- Text alignment
	fs:SetJustifyH( set.justifyH or "LEFT" );
	fs:SetJustifyV( set.justifyV or "CENTER" );
	-- Stretch Fontstring to fill container frame or, if no size is set, stretch container frame to fit Fontstring
	fs:SetPoint( "TOPLEFT" );
	if not set.size then
		f:SetHeight( fs:GetHeight() + ( set.addHeight or 0 ) ); -- Sometimes height is slightly less than needed, addHeight to fit
	end
	fs:SetPoint( "BOTTOMRIGHT" );
	--
	if set.OnShow then
		f:SetScript( "OnShow", set.OnShow );
	end
	if set.OnLoad then
		set.OnLoad( f );
	end
	return f;
end
--
NS.InputBox = function( name, parent, set  )
	local f = CreateFrame( "EditBox", "$parent" .. name, parent, set.template or "InputBoxTemplate" );
	--
	f:SetSize( set.size[1], set.size[2] );
	NS.SetPoint( f, parent, set.setPoint );
	--
	f:SetJustifyH( set.justifyH or "LEFT" );
	f:SetFontObject( set.fontObject or ChatFontNormal );
	f:SetAutoFocus( set.autoFocus or false );
	if set.numeric ~= nil then
		f:SetNumeric( set.numeric );
	end
	if set.maxLetters then
		f:SetMaxLetters( set.maxLetters );
	end
	-- Tooltip
	if set.tooltip then
		NS.Tooltip( f, set.tooltip, set.tooltipAnchor or { f, "ANCHOR_TOPRIGHT", 20, 0 } );
	end
	--
	if set.OnTabPressed then
		f:SetScript( "OnTabPressed", set.OnTabPressed );
	end
	if set.OnEnterPressed then
		f:SetScript( "OnEnterPressed", set.OnEnterPressed );
	end
	if set.OnEditFocusGained then
		f:SetScript( "OnEditFocusGained", set.OnEditFocusGained );
	end
	if set.OnEditFocusLost then
		f:SetScript( "OnEditFocusLost", set.OnEditFocusLost );
	end
	if set.OnTextChanged then
		f:SetScript( "OnTextChanged", set.OnTextChanged );
	end
	return f;
end
--
NS.Button = function( name, parent, text, set )
	local f = CreateFrame( "Button", ( set.topLevel and name or "$parent" .. name ), parent, ( set.template == nil and "UIPanelButtonTemplate" ) or ( set.template ~= false and set.template ) or nil );
	f.id = set.id or nil;
	if set.hidden then
		f:Hide();
	end
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	if set.setAllPoints then
		f:SetAllPoints();
	end
	if set.setPoint then
		NS.SetPoint( f, parent, set.setPoint );
	end
	-- Text
	if text then
		local fs = f:GetFontString();
		if not fs then
			fs = f:CreateFontString( "$parentText" );
			f:SetNormalFontObject( "GameFontNormal" );
			f:SetHighlightFontObject( "GameFontHighlight" );
			f:SetDisabledFontObject( "GameFontDisable" );
		end
		f:SetText( text );
		if set.fontObject then
			f:SetNormalFontObject( set.fontObject );
			f:SetHighlightFontObject( set.fontObject );
			f:SetDisabledFontObject( set.fontObject );
		end
		if set.textColor then
			fs:SetTextColor( set.textColor[1], set.textColor[2], set.textColor[3] );
		end
		if set.justifyV then
			fs:SetJustifyV( set.justifyV );
		end
		if set.justifyH then
			fs:SetJustifyH( set.justifyH );
		end
		if set.textSetAllPoints then
			fs:SetAllPoints();
		end
	end
	-- Textures
	if set.normalTexture then
		f:SetNormalTexture( set.normalTexture );
	end
	if set.pushedTexture then
		f:SetPushedTexture( set.pushedTexture );
	end
	if set.highlightTexture then
		f:SetHighlightTexture( set.highlightTexture, "ADD" );
	end
	if set.disabledTexture then
		f:SetDisabledTexture( set.disabledTexture );
	end
	-- Tooltip
	if set.tooltip then
		NS.Tooltip( f, set.tooltip, set.tooltipAnchor or { f, "ANCHOR_TOPRIGHT", 3, 0 } );
	end
	--
	if set.OnClick then
		if f:GetScript( "OnClick" ) then
			f:HookScript( "OnClick", set.OnClick );
		else
			f:SetScript( "OnClick", set.OnClick );
		end
	end
	if set.OnEnable then
		f:SetScript( "OnEnable", set.OnEnable );
	end
	if set.OnDisable then
		f:SetScript( "OnDisable", set.OnDisable );
	end
	if set.OnShow then
		f:SetScript( "OnShow", set.OnShow );
	end
	if set.OnHide then
		f:SetScript( "Onhide", set.OnHide );
	end
	if set.OnEnter then
		f:SetScript( "OnEnter", set.OnEnter );
	end
	if set.OnLeave then
		f:SetScript( "OnLeave", set.OnLeave );
	end
	if set.OnLoad then
		set.OnLoad( f );
	end
	return f;
end
--
NS.CheckButton = function( name, parent, text, set )
	local f = CreateFrame( "CheckButton", "$parent" .. name, parent, set.template or "InterfaceOptionsCheckButtonTemplate" );
	--
	_G[f:GetName() .. 'Text']:SetText( text );
	--
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	--
	if set.setPoint then
		NS.SetPoint( f, parent, set.setPoint );
	end
	--
	if set.tooltip then
		NS.Tooltip( f, set.tooltip, set.tooltipAnchor or { f, "ANCHOR_TOPLEFT", 25, 0 } );
	end
	--
	f:SetScript( "OnClick", function( cb )
		local checked = cb:GetChecked();
		if cb.db then
			NS.db[cb.db] = checked;
		elseif cb.dbpc then
			NS.dbpc[cb.dbpc] = checked;
		end
		if set.OnClick then
			set.OnClick( checked, cb );
		end
	end );
	--
	f.db = set.db or nil;
	f.dbpc = set.dbpc or nil;
	--
	return f;
end
--
NS.ScrollFrame = function( name, parent, set )
	local f = CreateFrame( "ScrollFrame", "$parent" .. name, parent, "FauxScrollFrameTemplate" );
	--
	f:SetSize( set.size[1], set.size[2] );
	NS.SetPoint( f, parent, set.setPoint );
	--
	f:SetScript( "OnVerticalScroll", function ( self, offset )
		FauxScrollFrame_OnVerticalScroll( self, offset, self.buttonHeight, self.UpdateFunction );
	end );
	-- Add properties for use with vertical scroll and update function ... FauxScrollFrame_Update( frame, numItems, numToDisplay, buttonHeight, button, smallWidth, bigWidth, highlightFrame, smallHighlightWidth, bigHighlightWidth, alwaysShowScrollBar );
	for k, v in pairs( set.udpate ) do
		f[k] = v;
	end
	-- Create buttons
	local buttonName = "_ScrollFrameButton";
	NS.Button( buttonName .. 1, parent, nil, {
		template = set.buttonTemplate,
		setPoint = { "TOPLEFT", "$parent" .. name, "TOPLEFT", 0, 3 },
	} );
	for i = 2, f.numToDisplay do
		NS.Button( buttonName .. i, parent, nil, {
			template = set.buttonTemplate,
			setPoint = { "TOP", "$parent" .. buttonName .. ( i - 1 ), "BOTTOM" },
		} );
	end
	-- Button name for use with update function
	f.buttonName = parent:GetName() .. buttonName;
	-- Update()
	function f:Update()
		self.UpdateFunction( self );
	end
	-- Scrollbar Textures
	local tx = f:CreateTexture( nil, "ARTWORK" );
	tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
	tx:SetSize( 31, 250 );
	tx:SetPoint( "TOPLEFT", "$parent", "TOPRIGHT", -2, 5 );
	tx:SetTexCoord( 0, 0.484375, 0, 1.0 );
	--
	local baseScrollbarSize = ( 250 - 5 ) + ( 100 - 2 );
	if set.size[2] > baseScrollbarSize then
		tx = f:CreateTexture( nil, "ARTWORK" );
		tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
		tx:SetSize( 31, set.size[2] - baseScrollbarSize  );
		tx:SetPoint( "TOPLEFT", "$parent", "TOPRIGHT", -2, ( -250 + 5 ) );
		tx:SetTexCoord( 0, 0.484375, 0.1, 0.9 );
	end
	--
	tx = f:CreateTexture( nil, "ARTWORK" );
	tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
	tx:SetSize( 31, 100 );
	tx:SetPoint( "BOTTOMLEFT", "$parent", "BOTTOMRIGHT", -2, -2 );
	tx:SetTexCoord( 0.515625, 1.0, 0, 0.4140625 );
	--
	function f:Reset()
		self:SetVerticalScroll( 0 );
		self:Update();
	end
	if set.OnLoad then
		set.OnLoad( f );
	end
	return f;
end
--
NS.Frame = function( name, parent, set )
	local f = CreateFrame( set.type or "Frame", ( set.topLevel and name or "$parent" .. name ), parent, set.template or nil );
	--
	if set.hidden then
		f:Hide();
	end
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	if set.frameStrata then
		f:SetFrameStrata( set.frameStrata );
	end
	if set.frameLevel then
		if set.frameLevel == "TOP" then
			f:SetToplevel( true );
		else
			f:SetFrameLevel( set.frameLevel );
		end
	end
	if set.setAllPoints then
		f:SetAllPoints();
	end
	if set.setPoint then
		NS.SetPoint( f, parent, set.setPoint );
	end
	if set.bg then
		f.Bg = f.Bg or f:CreateTexture( "$parentBG", "BACKGROUND" );
		if type( set.bg[1] ) == "number" then
			f.Bg:SetColorTexture( unpack( set.bg ) );
		else
			f.Bg:SetTexture( unpack( set.bg ) );
		end
	end
	if set.bgSetAllPoints then
		f.Bg:SetAllPoints();
	end
	if set.registerForDrag then
		f:EnableMouse( true );
		f:SetMovable( true );
		f:RegisterForDrag( set.registerForDrag );
		f:SetScript( "OnDragStart", f.StartMoving );
		f:SetScript( "OnDragStop", f.StopMovingOrSizing );
	end
	if set.OnShow then
		f:SetScript( "OnShow", set.OnShow );
	end
	if set.OnHide then
		f:SetScript( "OnHide", set.OnHide );
	end
	if set.OnEvent then
		f:SetScript( "OnEvent", set.OnEvent );
	end
	if set.OnLoad then
		set.OnLoad( f );
	end
	return f;
end
--
NS.DropDownMenu = function( name, parent, set )
	local f = CreateFrame( "Frame", "$parent" .. name, parent, "UIDropDownMenuTemplate" );
	--
	NS.SetPoint( f, parent, set.setPoint );
	--
	if set.tooltip then
		NS.Tooltip( f, set.tooltip, set.tooltipAnchor or { f, "ANCHOR_TOPRIGHT", 3, 0 } );
	end
	--
	UIDropDownMenu_SetWidth( f, set.width );
	--
	f.buttons = set.buttons;
	f.OnClick = set.OnClick or nil;
	f.db = set.db or nil;
	f.dbpc = set.dbpc or nil;
	--
	function f:Reset( selectedValue )
		UIDropDownMenu_Initialize( self, NS.DropDownMenu_Initialize );
		UIDropDownMenu_SetSelectedValue( self, selectedValue );
	end
	--
	return f;
end
--
NS.DropDownMenu_Initialize = function( dropdownMenu )
	local dm = dropdownMenu;
	for _,button in ipairs( type( dm.buttons ) == "function" and dm.buttons() or dm.buttons ) do
		local info, text, value = {}, unpack( button );
		info.owner = dm;
		info.text = text;
		info.value = value;
		info.checked = nil;
		info.func = function()
			UIDropDownMenu_SetSelectedValue( info.owner, info.value );
			if dm.db and NS.db[dm.db] then
				NS.db[dm.db] = info.value;
			elseif dm.dbpc and NS.dbpc[dm.dbpc] then
				NS.dbpc[dm.dbpc] = info.value;
			end
			if dm.OnClick then
				dm.OnClick( info );
			end
		end
		UIDropDownMenu_AddButton( info );
	end
end
--
NS.MinimapButton = function( name, texture, set )
	local f = CreateFrame( "Button", name, Minimap );
	f:SetFrameStrata( "MEDIUM" );
	f.dbpc = set.dbpc; -- Saved position variable per character
	local h,i,o,bg;
	local fSize,hSize,iSize,oSize,bgSize;
	local iOffsetX,iOffsetY,bgOffsetX,bgOffsetY;
	local arc,radius;
	-- Position and Dragging
	f:EnableMouse( true );
	f:SetMovable( true );
	f:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
	f:RegisterForDrag( "LeftButton", "RightButton" );
	local BeingDragged = function()
		local xpos,ypos = GetCursorPosition();
		local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom();
		xpos = xmin - xpos / UIParent:GetScale() + 70;
		ypos = ypos / UIParent:GetScale() - ymin - 70;
		local pos = math.deg( math.atan2( ypos, xpos ) );
		if pos < 0 then pos = pos + 360; end
		NS.dbpc[f.dbpc] = pos;
		f:UpdatePos();
	end
	f:SetScript( "OnDragStart", function()
		f:SetScript( "OnUpdate", BeingDragged );
	end );
	f:SetScript( "OnDragStop", function()
		f:SetScript( "OnUpdate", nil );
	end );
	function f:UpdatePos()
		f:ClearAllPoints();
		f:SetPoint( "TOPLEFT", "Minimap", "TOPLEFT", arc - ( radius * cos( NS.dbpc[f.dbpc] ) ), ( radius * sin( NS.dbpc[f.dbpc] ) ) - arc );
	end
	function f:UpdateSize( large )
		h:ClearAllPoints();
		if large then
			-- Large
			fSize,hSize,iSize,oSize,bgSize = 54,50,30,76,32;
			iOffsetX,iOffsetY,bgOffsetX,bgOffsetY = 7.5,-6.5,6,-6;
			if set.square then
				iSize = 22;
				iOffsetX,iOffsetY = 11.5,-10.5;
			end
			arc,radius = 48,87.5;
			h:SetPoint( "TOPLEFT", -3, 3 );
		else
			-- Normal
			fSize,hSize,iSize,oSize,bgSize = 32,32,21,54,22;
			iOffsetX,iOffsetY,bgOffsetX,bgOffsetY = 5.7,-5,5,-5;
			if set.square then
				iSize = 16;
				iOffsetX,iOffsetY = 8,-7;
			end
			arc,radius = 54,80.5;
			h:SetAllPoints();
		end
		f:SetSize( fSize, fSize );
		h:SetSize( hSize, hSize );
		i:SetSize( iSize, iSize );
		i:SetPoint( "TOPLEFT", iOffsetX, iOffsetY );
		o:SetSize( oSize, oSize );
		bg:SetSize( bgSize, bgSize );
		bg:SetPoint( "TOPLEFT", bgOffsetX, bgOffsetY );
	end
	-- Highlight
	f:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" );
	h = f:GetHighlightTexture();
	-- Icon
	i = f:CreateTexture( nil, "ARTWORK" );
	i:SetTexture( texture );
	if set.texCoord then
		i:SetTexCoord( unpack( set.texCoord ) );
	end
	-- Overlay
	o = f:CreateTexture( nil, "OVERLAY" );
	o:SetPoint( "TOPLEFT" );
	o:SetTexture( "Interface\\Minimap\\MiniMap-TrackingBorder" );
	-- Background
	bg = f:CreateTexture( nil, "BACKGROUND" );
	bg:SetTexture( "Interface\\Minimap\\UI-Minimap-Background" );
	-- Size
	f:UpdateSize();
	-- Tooltip
	if set.tooltip then
		NS.Tooltip( f, set.tooltip, set.tooltipAnchor or { f, "ANCHOR_LEFT", 3, 0 } );
	end
	-- LeftClick / RightClick
	f:SetScript( "OnClick", function( self, ... )
		local btn = select( 1, ... );
		if btn == "LeftButton" and set.OnLeftClick then
			set.OnLeftClick( self, ... );
		elseif btn == "RightButton" and set.OnRightClick then
			set.OnRightClick( self, ... );
		end
	end );
	if set.OnLoad then
		set.OnLoad( f );
	end
	return f;
end
--------------------------------------------------------------------------------------------------------------------------------------------
-- GENERAL
--------------------------------------------------------------------------------------------------------------------------------------------
NS.Explode = function( sep, str )
	local t = {};
	for v in string.gmatch( str, "[^%" .. sep .. "]+" ) do
		table.insert( t, v );
	end
	return t;
end
--
NS.TruncatedText_OnEnter = function( self )
	local fs = _G[self:GetName() .. "Text"];
	if fs:IsTruncated() then
		GameTooltip:SetOwner( self, "ANCHOR_TOP" );
		GameTooltip:SetText( fs:GetText() );
	end
end
--
NS.Count = function( t )
	local count = 0;
	for _ in pairs( t ) do
		count = count + 1;
	end
	return count;
end
--
NS.Print = function( msg )
	print( ORANGE_FONT_COLOR_CODE .. "<|r" .. NORMAL_FONT_COLOR_CODE .. NS.addon .. "|r" .. ORANGE_FONT_COLOR_CODE .. ">|r " .. msg );
end
--
NS.SecondsToStrTime = function( seconds, colorCode )
	-- Seconds In Min, Hour, Day
    local secondsInAMinute = 60;
    local secondsInAnHour  = 60 * secondsInAMinute;
    local secondsInADay    = 24 * secondsInAnHour;
    -- Days
    local days = math.floor( seconds / secondsInADay );
    -- Hours
    local hourSeconds = seconds % secondsInADay;
    local hours = math.floor( hourSeconds / secondsInAnHour );
    -- Minutes
    local minuteSeconds = hourSeconds % secondsInAnHour;
    local minutes = floor( minuteSeconds / secondsInAMinute );
    -- Seconds
    local remainingSeconds = minuteSeconds % secondsInAMinute;
    local seconds = math.ceil( remainingSeconds );
	--
	local strTime = ( days > 0 and hours == 0 and days .. " day" ) or ( days > 0 and days .. " day " .. hours .. " hr" ) or ( hours > 0 and minutes == 0 and hours .. " hr" ) or ( hours > 0 and hours .. " hr " .. minutes .. " min" ) or ( minutes > 0 and minutes .. " min" ) or seconds .. " sec";
	return colorCode and ( colorCode .. strTime .. "|r" ) or strTime;
end
--
NS.StrTimeToSeconds = function( str )
	if not str then return 0; end
	local t1, i1, t2, i2 = strsplit( " ", str ); -- x day   -   x day x hr   -   x hr y min   -   x hr   -   x min   -   x sec
	local M = function( i )
		if i == "hr" then
			return 3600;
		elseif i == "min" then
			return 60;
		elseif i == "sec" then
			return 1;
		else
			return 86400; -- day
		end
	end
	return t1 * M( i1 ) + ( t2 and t2 * M( i2 ) or 0 );
end
--
NS.FormatNum = function( num )
	while true do
		num, k = string.gsub( num, "^(-?%d+)(%d%d%d)", "%1,%2" );
		if ( k == 0 ) then break end
	end
	return num;
end
--
NS.MoneyToString = function( money, colorCode )
	local negative = money < 0;
	money = math.abs( money );
	--
	local gold = money >= COPPER_PER_GOLD and NS.FormatNum( math.floor( money / COPPER_PER_GOLD ) ) or nil;
	local silver = math.floor( ( money % COPPER_PER_GOLD ) / COPPER_PER_SILVER );
	local copper = math.floor( money % COPPER_PER_SILVER );
	--
	gold = ( gold and colorCode ) and ( colorCode .. gold .. FONT_COLOR_CODE_CLOSE ) or gold;
	silver = ( silver > 0 and colorCode ) and ( colorCode .. silver .. FONT_COLOR_CODE_CLOSE ) or ( silver > 0 and silver ) or nil;
	copper = colorCode .. copper .. FONT_COLOR_CODE_CLOSE;
	--
	local g,s,c = "|cffffd70ag|r","|cffc7c7cfs|r","|cffeda55fc|r";
	local moneyText = copper .. c;
	if silver then
		moneyText = silver .. s .. " " .. moneyText;
	end
	if gold then
		moneyText = gold .. g .. " " .. moneyText;
	end
	if negative then
		moneyText = colorCode and ( colorCode "-|r" .. moneyText ) or ( "-" .. moneyText );
	end
	return moneyText;
end
--
NS.FindKeyByField = function( t, f, v )
	if not v then return nil end
	for k = 1, #t do
		if t[k][f] == v then
			return k;
		end
	end
	return nil;
end
--
NS.PairsFindKeyByField = function( t, f, v )
	if not v then return nil end
	for k,_ in pairs( t ) do
		if t[k][f] == v then
			return k;
		end
	end
	return nil;
end
--
NS.FindKeyByValue = function( t, v )
	if not v then return nil end
	for k = 1, #t do
		if t[k] == v then
			return k;
		end
	end
	return nil;
end
--
NS.Sort = function( t, k, order )
	table.sort ( t,
		function ( e1, e2 )
			if order == "ASC" then
				return e1[k] < e2[k];
			elseif order == "DESC" then
				return e1[k] > e2[k];
			end
		end
	);
end
--
NS.GetItemInfo = function( itemIdNameLink, Callback, maxAttempts, after )
	if not itemIdNameLink or itemIdNameLink == 0 then return Callback(); end
	local attempts,CheckItemInfo;
	CheckItemInfo = function()
		local name,link,quality,level,minLevel,type,subType,stackCount,equipLoc,texture,sellPrice,classID,subClassID = GetItemInfo( itemIdNameLink );
		if not name and attempts < maxAttempts then
			attempts = attempts + 1;
			return C_Timer.After( after, CheckItemInfo );
		elseif not name then
			return Callback();
		else
			return Callback( name,link,quality,level,minLevel,type,subType,stackCount,equipLoc,texture,sellPrice,classID,subClassID );
		end
	end
	attempts = 1;
	maxAttempts = maxAttempts or 50;
	after = after or 0.10;
	CheckItemInfo();
end
--
NS.GetWeeklyQuestResetTime = function()
	local TUE,WED,THU = 2, 3, 4;
	local resetWeekdays = { ["US"] = TUE, ["EU"] = WED, ["CN"] = THU, ["KR"] = THU, ["TW"] = THU };
	local resetWeekday = resetWeekdays[GetCVar( "portal" ):upper()];
	local resetTime = time() + GetQuestResetTime();
	while tonumber( date( "%w", resetTime ) ) ~= resetWeekday do
		resetTime = resetTime + 86400;
	end
	return resetTime;
end
