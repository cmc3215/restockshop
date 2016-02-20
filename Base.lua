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
	local fs = f:CreateFontString( "$parentText", "ARTWORK", set.fontObject or "GameFontNormal" );
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
	if text and f:GetFontString() then
		f:SetText( text );
		local fs = f:GetFontString();
		if set.fontObject then
			f:SetNormalFontObject( set.fontObject );
			f:SetHighlightFontObject( set.fontObject );
			f:SetDisabledFontObject( set.fontObject );
		end
		if set.textColor then
			fs:SetTextColor( set.textColor[1], set.textColor[2], set.textColor[3] );
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
	if set.OnDisable then
		f:SetScript( "OnDisable", set.OnDisable );
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
	return f;
end

--
NS.Frame = function( name, parent, set )
	local f = CreateFrame( "Frame", ( set.topLevel and name or "$parent" .. name ), parent, set.template or nil );
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
		f.Bg:SetTexture( unpack( set.bg ) );
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
	f.dbpc = set.dbpc; -- Saved position variable per character
	-- Position and Dragging
	f:EnableMouse( true );
	f:SetMovable( true );
	f:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
	f:RegisterForDrag( "LeftButton", "RightButton" );
	function f:BeingDragged()
		local xpos,ypos = GetCursorPosition();
		local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom();
		xpos = xmin - xpos / UIParent:GetScale() + 70
		ypos = ypos / UIParent:GetScale() - ymin - 70
		local pos = math.deg( math.atan2( ypos, xpos ) );
		if pos < 0 then pos = pos + 360; end
		NS.dbpc[self.dbpc] = pos;
		self:UpdatePos();
	end
	function f:UpdatePos()
		self:SetPoint( "TOPLEFT", "Minimap", "TOPLEFT", 53 - ( 80 * cos( NS.dbpc[self.dbpc] ) ), ( 80 * sin( NS.dbpc[self.dbpc] ) ) - 53 );
	end
	f:SetScript( "OnDragStart", function( self )
		self:SetScript( "OnUpdate", function( self ) self:BeingDragged(); end );
	end );
	f:SetScript( "OnDragStop", function( self )
		self:SetScript( "OnUpdate", nil );
	end );
	-- Appearance
	f:SetFrameStrata( "MEDIUM" );
	f:SetSize( 31, 31 );
	f:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" );
	-- Icon
	local icon = f:CreateTexture( nil, "ARTWORK" );
	icon:SetSize( 17, 17 );
	icon:SetPoint( "TOPLEFT", 7, -6 );
	icon:SetTexture( texture );
	-- Overlay
	local overlay = f:CreateTexture( nil, "OVERLAY" );
	overlay:SetSize( 53, 53 );
	overlay:SetPoint( "TOPLEFT" );
	overlay:SetTexture( "Interface\\Minimap\\MiniMap-TrackingBorder" );
	-- Background
	local background = f:CreateTexture( nil, "BACKGROUND" );
	background:SetSize( 20, 20 );
	background:SetTexture( "Interface\\Minimap\\UI-Minimap-Background" );
	background:SetPoint( "TOPLEFT", 7, -5 );
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
NS.Print_t = function( t )
	for k, v in pairs( t ) do
		if type( v ) == "table" then
			print( k .. "=TABLE:" );
			NS.Print_t( v );
		elseif type( v ) == "string" or type( v ) == "number" then
			print( k .. "=" .. v );
		elseif type( v ) == "boolean" then
			print( k .. "=" .. ( v and "true" or "false" ) );
		end
	end
end

--
NS.SecondsToStrTime = function( seconds )
	local originalSeconds = seconds;
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
	return ( days > 0 and hours == 0 and days .. " day" ) or ( days > 0 and days .. " day " .. hours .. " hr" ) or ( hours > 0 and minutes == 0 and hours .. " hr" ) or ( hours > 0 and hours .. " hr " .. minutes .. " min" ) or ( minutes > 0 and minutes .. " min" ) or seconds .. " sec";
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
NS.FindKeyByName = function( t, name )
	if not name then return nil end
	for k, v in ipairs( t ) do
		if v["name"] == name then
			return k;
		end
	end
	return nil;
end

--
NS.FindKeyByField = function( t, f, fv )
	if not fv then return nil end
	for k, v in ipairs( t ) do
		if v[f] == fv then
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

