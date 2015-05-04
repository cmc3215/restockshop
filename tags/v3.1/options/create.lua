--------------------------------------------------------------------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------------------------------------------------------------------
local NS = select( 2, ... );
local cfg = NS.options.cfg;
local MainFrame, SubFrameHeader, SubFrameTabs, SubFrames = nil, nil, {}, {};
--------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------------------------------------------------------------------------
local CreateMainFrame = function()
	local f = CreateFrame( "Frame", NS.addon .. "OptionsMainFrame", UIParent, "ButtonFrameTemplate" );
	f:Hide();
	-- Settings
	f.name = f:GetName();
	f:SetFrameStrata( cfg.mainFrame.frameStrata );
	f:SetWidth( cfg.mainFrame.width );
	f:SetHeight( cfg.mainFrame.height );
	f:SetScale( cfg.mainFrame.scale );
	-- Title
	f.title = _G[f.name .. "TitleText"];
	f.title:SetText( NS.addon );
	-- Portrait
	ButtonFrameTemplate_HidePortrait( f );
	-- Inset
	f.Inset:SetPoint( "TOPLEFT", 4, -50 );
	-- Drag
	f:EnableMouse( true );
	f:SetMovable( true );
	f:RegisterForDrag( "LeftButton" );
	f:SetScript( "OnDragStart", f.StartMoving );
	f:SetScript( "OnDragStop", f.StopMovingOrSizing );
	-- Show/Hide
	f:SetScript( "OnShow", cfg.mainFrame.onShow ); -- OnShow MainFrame
	f:SetScript( "OnHide", function( self )
		PanelTemplates_DeselectTab( SubFrameTabs[PanelTemplates_GetSelectedTab( SubFrameHeader )] );
		cfg.mainFrame.onHide( self ); -- OnHide MainFrame
	end );
	-- Initialize
	f:SetScript( "OnEvent", function( self, event )
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent( "PLAYER_LOGIN" );
			self:SetScript( "OnEvent", nil );
			cfg.mainFrame.init( self ); -- Init MainFrame
			for i = 1, #cfg.subFrameTabs do
				cfg.subFrameTabs[i].init( SubFrames[i] ); -- Init SubFrames
			end
		end
	end );
	f:RegisterEvent( "PLAYER_LOGIN" );
	--
	function f:ShowTab( index )
		self:Show();
		SubFrameTabs[index or 1]:Click();
	end
	return f;
end

--
local CreateSubFrameHeader = function()
	local f = CreateFrame( "Frame", "$parentSubFrameHeader", MainFrame, nil );
	f.name = f:GetName();
	f.numTabs = #cfg.subFrameTabs;
	f:SetPoint( "TOPLEFT", 20, -20 );
	f:SetPoint( "TOPRIGHT", -10, -20 );
	f:SetHeight( 30 );
	return f;
end

--
local CreateSubFrameTabs = function( index )
	local f = CreateFrame( "Button", "$parentTab" .. index, SubFrameHeader, "TabButtonTemplate" );
	f.id = index;
	if index == 1 then
		f:SetPoint( "BOTTOMLEFT", 0, 0 );
	else
		f:SetPoint( "LEFT", "$parentTab" .. ( index - 1 ), "RIGHT", 0, 0 );
	end
	f:HookScript( "OnClick", function( self )
		PanelTemplates_SetTab( SubFrameHeader, self.id ); -- select tab clicked
		for i = 1, #SubFrames do
			SubFrames[i]:Hide(); --hide all subframes
		end
		MainFrame.title:SetText( cfg.subFrameTabs[index].mainFrameTitle ); --change mainframe title
		SubFrames[self.id]:Show(); --show and refresh selectedTab subframe
	end );
	f:SetText( cfg.subFrameTabs[index].tabText );
	PanelTemplates_TabResize( f, 0 ); --make the button fit
	return f;
end

--
local CreateSubFrames = function( index )
	local f = CreateFrame( "Frame", "$parentTab" .. index .. "SubFrame", MainFrame, nil );
	f.name = f:GetName();
	f:SetPoint( "TOPLEFT", 10, -55 );
	f:SetPoint( "BOTTOMRIGHT", -10, 30 );
	f:SetScript( "OnShow", function( self )
		self:Refresh();
	end );
	function f:Refresh()
		cfg.subFrameTabs[index].refresh( self );
	end
	f:Hide();
	return f;
end

--------------------------------------------------------------------------------------------------------------------------------------------
MainFrame = CreateMainFrame();
SubFrameHeader = CreateSubFrameHeader();
for i = 1, #cfg.subFrameTabs do
	tinsert( SubFrameTabs, CreateSubFrameTabs( i ) );
	tinsert( SubFrames, CreateSubFrames( i ) );
end
NS.options.MainFrame = MainFrame;
--NS.options.SubFrameHeader = SubFrameHeader;
--NS.options.SubFrameTabs = SubFrameTabs;
--NS.options.SubFrames = SubFrames;
