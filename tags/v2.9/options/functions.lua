--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local L = NS.localization;
--local background = f:CreateTexture( "TestFrameBackground", "BACKGROUND" );
--background:SetTexture( 1, 1, 1, 0.25 );
--background:SetAllPoints();
--------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------------------------------------------------------------------
local function lastChildName( parent )
	local children = { parent:GetChildren() };
	local lastChild = children[#children];
	return lastChild:GetName();
end

--
NS.options.TextFrame = function( name, parent, text, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "Frame", "$parent" .. name, parent );
	local fs = f:CreateFontString( "$parentText", "ARTWORK", set.fontObject or "GameFontNormal" );
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "BOTTOMLEFT", set.xOffset or 0, set.yOffset or 0 );
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	else
		f:SetPoint( "RIGHT", set.xOffset and 0 - math.abs( set.xOffset ) or 0, 0 );
	end
	fs:SetJustifyH( set.justifyH or "LEFT" );
	fs:SetJustifyV( set.justifyV or "CENTER" );
	fs:SetPoint( "TOPLEFT" );
	fs:SetText( text );
	if not set.size then
		f:SetHeight( fs:GetHeight() );
	end
	fs:SetPoint( "BOTTOMRIGHT" );
	return f;
end

--
NS.options.InputBox = function( name, parent, set  )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "EditBox", "$parent" .. name, parent, "InputBoxTemplate" );
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "BOTTOMLEFT", set.xOffset or 4, set.yOffset or 0 );
	f:SetFontObject( set.fontObject or ChatFontNormal );
	f:SetSize( set.size[1], set.size[2] );
	f:SetJustifyH( set.justifyH or "LEFT" );
	f:SetAutoFocus( set.autoFocus or false );
	if set.numeric ~= nil then
		f:SetNumeric( set.numeric );
	end
	if set.maxLetters then
		f:SetMaxLetters( set.maxLetters );
	end
	if set.onTabPressed then
		f:SetScript( "OnTabPressed", set.onTabPressed );
	end
	if set.onEnterPressed then
		f:SetScript( "OnEnterPressed", set.onEnterPressed );
	end
	f.db = set.db or nil;
	f.dbpc = set.dbpc or nil;
	return f;
end

--
NS.options.Button = function( name, parent, text, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "Button", "$parent" .. name, parent, set.template or "UIPanelButtonTemplate" );
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "TOPRIGHT", set.xOffset or 0, set.yOffset or 0 );
	f:SetScript( "OnClick", set.onClick );
	if set.tooltip then
		f.tooltip = set.tooltip;
		f:SetScript( "OnEnter", function ( self )
			GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT", 3 );
			GameTooltip:SetText( self.tooltip );
		end );
		f:SetScript( "OnLeave", GameTooltip_Hide );
	end
	if f:GetFontString() then
		f:SetText( text );
		local fs = f:GetFontString();
		if set.fontObject then
			fs:SetFontObject( set.fontObject );
		end
		if set.textColor then
			fs:SetTextColor( set.textColor[1], set.textColor[2], set.textColor[3] );
		end
		if set.justifyH then
			fs:SetJustifyH( set.justifyH );
		end
		fs:SetAllPoints();
	end
	return f;
end

--
NS.options.CheckButton = function( name, parent, text, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "CheckButton", "$parent" .. name, parent, set.template or "InterfaceOptionsCheckButtonTemplate" );
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "BOTTOMLEFT", set.xOffset or 3, set.yOffset or -1 );
	_G[f:GetName() .. 'Text']:SetText( text );
	if set.tooltip then
		f.tooltip = set.tooltip;
		f:SetScript( "OnEnter", function ( self )
			GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT", 25 );
			GameTooltip:SetText( self.tooltip );
		end );
		f:SetScript( "OnLeave", GameTooltip_Hide );
	end
	f:SetScript( "OnClick", function( cb )
		local checked = cb:GetChecked();
		if cb.db then
			NS.db[cb.db] = checked;
		elseif cb.dbpc then
			NS.dbpc[cb.dbpc] = checked;
		end
		if cb.onClick then
			cb.onClick( checked );
		end
	end );
	f.onClick = set.onClick or nil;
	f.db = set.db or nil;
	f.dbpc = set.dbpc or nil;
	return f;
end

--
NS.options.DropDownMenu = function( name, parent, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "Frame", "$parent" .. name, parent, "UIDropDownMenuTemplate" );
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "BOTTOMLEFT", set.xOffset or -12, set.yOffset or -2 );
	if set.tooltip then
		f.tooltip = set.tooltip;
		f:SetScript( "OnEnter", function ( self )
			GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT", 3 );
			GameTooltip:SetText( self.tooltip );
		end );
		f:SetScript( "OnLeave", GameTooltip_Hide );
	end
	UIDropDownMenu_SetWidth( f, set.width );
	f.buttons = set.buttons;
	f.onClick = set.onClick or nil;
	f.db = set.db or nil;
	f.dbpc = set.dbpc or nil;
	return f;
end

--
NS.options.ScrollFrame = function( name, parent, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "ScrollFrame", "$parent" .. name, parent, "FauxScrollFrameTemplate" );
	f:SetSize( set.size[1], set.size[2] );
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "BOTTOMLEFT", set.xOffset or 0, set.yOffset or 0 );
	f:SetScript( "OnVerticalScroll", function ( self, offset )
		FauxScrollFrame_OnVerticalScroll( self, offset, self.buttonHeight, self.updateFunction );
	end );
	-- Add properties for use with update function
	for k, v in pairs( set.udpate ) do
		f[k] = v; --FauxScrollFrame_Update( frame, numItems, numToDisplay, buttonHeight, button, smallWidth, bigWidth, highlightFrame, smallHighlightWidth, bigHighlightWidth, alwaysShowScrollBar );
	end
	-- Create buttons
	local buttonName = "ScrollFrameButton";
	NS.options.Button( buttonName .. 1, parent, "", {
		template = set.buttonTemplate,
		relativeTo = "$parent" .. name,
		relativePoint = "TOPLEFT",
		xOffset = 1,
		yOffset = 5,
	} );
	for i = 2, f.numToDisplay do
		NS.options.Button( buttonName .. i, parent, "", {
			template = set.buttonTemplate,
			relativeTo = "$parent" .. buttonName .. ( i - 1 ),
			relativePoint = "BOTTOMLEFT",
			yOffset = -3,
		} );
	end
	-- Button name for use with update function
	f.buttonName = parent.name .. buttonName;
	-- Methods
	function f:Update()
		self.updateFunction( self );
	end
	--
	local tx = f:CreateTexture( nil, "ARTWORK" );
	tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
	tx:SetSize( set.scrollbarTop.size[1], set.scrollbarTop.size[2] );
	tx:SetPoint( "TOPLEFT", "$parent", "TOPRIGHT", -2, 5 );
	tx:SetTexCoord( 0, 0.484375, 0, 1.0 );
	tx = f:CreateTexture( nil, "ARTWORK" );
	tx:SetTexture( "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" );
	tx:SetSize( set.scrollbarBottom.size[1], set.scrollbarBottom.size[2] );
	tx:SetPoint( "BOTTOMLEFT", "$parent", "BOTTOMRIGHT", -2, -2 );
	tx:SetTexCoord( 0.515625, 1.0, 0, 0.4140625 );
	return f;
end

--
NS.options.Frame = function( name, parent, set )
	set.relativeTo = set.relativeTo or lastChildName( parent );
	local f = CreateFrame( "Frame", "$parent" .. name, parent, set.template or nil );
	if set.size then
		f:SetSize( set.size[1], set.size[2] );
	end
	f:SetPoint( set.anchor or "TOPLEFT", set.relativeTo, set.relativePoint or "TOPLEFT", set.xOffset or 0, set.yOffset or 0 );
	if set.background then
		local bg = f:CreateTexture( "$parentBG", "BACKGROUND" );
		bg:SetTexture( unpack( set.background ) );
		bg:SetAllPoints();
	end
	return f;
end

--
NS.options.DropDownMenu_Initialize = function( dropdownMenu )
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
			if dm.onClick then
				dm.onClick( info );
			end
		end
		UIDropDownMenu_AddButton( info );
	end
end
