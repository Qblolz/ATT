local addon, ATTdbs = ...
ATTdbs.LibSimpleOptions = {}
local LibSimpleOptions = ATTdbs.LibSimpleOptions
local lib = ATTdbs.LibSimpleOptions

local _G = _G
local tonumber, type, string, table = _G.tonumber, _G.type, _G.string, _G.table
local tinsert = table.insert
local strsub, strlen, strmatch, gsub = _G.strsub, _G.strlen, _G.strmatch, _G.gsub
local max, match = _G.max, _G.match
local securecall, issecure = _G.securecall, _G.issecure
local wipe = table.wipe
-- WoW
local CreateFrame, GetCursorPosition, GetCVar, GetScreenHeight, GetScreenWidth, PlaySound = _G.CreateFrame,
	_G.GetCursorPosition, _G.GetCVar, _G.GetScreenHeight, _G.GetScreenWidth, _G.PlaySound
local GetBuildInfo = _G.GetBuildInfo
local GameTooltip, GetAppropriateTooltip, tooltip, GetValueOrCallFunction
local CloseMenus, ShowUIPanel = _G.CloseMenus, _G.ShowUIPanel
local GameTooltip_SetTitle, GameTooltip_AddInstructionLine, GameTooltip_AddNormalLine, GameTooltip_AddColoredLine = _G.GameTooltip_SetTitle
	, _G.GameTooltip_AddInstructionLine, _G.GameTooltip_AddNormalLine, _G.GameTooltip_AddColoredLine

-- ----------------------------------------------------------------------------

-- Determine WoW TOC Version
local WoWClassicEra, WoWClassicTBC, WoWRetail
local wowtocversion = select(4, GetBuildInfo())

if wowtocversion < 20000 then
	WoWClassicEra = true
elseif wowtocversion > 19999 and wowtocversion < 90000 then
	WoWClassicTBC = true
else
	WoWRetail = true
end


if WoWClassicEra or WoWClassicTBC then
	GameTooltip = _G.GameTooltip
	tooltip = GameTooltip
else -- Retail
	GameTooltip = _G.GameTooltip
	GetAppropriateTooltip = _G.GetAppropriateTooltip
	tooltip = GetAppropriateTooltip()
	GetValueOrCallFunction = _G.GetValueOrCallFunction
end

-- //////////////////////////////////////////////////////////////
local LSOL_UIDROPDOWNMENU_MINBUTTONS = 8;
local LSOL_UIDROPDOWNMENU_MAXBUTTONS = 1;
-- For Classic checkmarks, this is the additional padding that we give to the button text.
local LSOL_UIDROPDOWNMENU_CLASSIC_CHECK_PADDING = 4;
local LSOL_UIDROPDOWNMENU_MAXLEVELS = 2;
local LSOL_UIDROPDOWNMENU_BUTTON_HEIGHT = 16;
local LSOL_UIDROPDOWNMENU_BORDER_HEIGHT = 15;
-- The current open menu
local LSOL_UIDROPDOWNMENU_OPEN_MENU = nil;
-- The current menu being initialized
local LSOL_UIDROPDOWNMENU_INIT_MENU = nil;
-- Current level shown of the open menu
local LSOL_UIDROPDOWNMENU_MENU_LEVEL = 1;
-- Current value of the open menu
local LSOL_UIDROPDOWNMENU_MENU_VALUE = nil;
-- Time to wait to hide the menu
local LSOL_UIDROPDOWNMENU_SHOW_TIME = 2;
-- Default dropdown text height
local LSOL_UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = nil;
-- List of open menus
local LSOL_OPEN_DROPDOWNMENUS = {};

local LSOL_DropDownList1, LSOL_DropDownList2

local delegateFrame = CreateFrame("FRAME");

delegateFrame:SetScript("OnAttributeChanged", function(self, attribute, value)
	if (attribute == "createframes" and value == true) then
		lib:UIDropDownMenu_CreateFrames(self:GetAttribute("createframes-level"), self:GetAttribute("createframes-index"));
	elseif (attribute == "initmenu") then
		LSOL_UIDROPDOWNMENU_INIT_MENU = value;
	elseif (attribute == "openmenu") then
		LSOL_UIDROPDOWNMENU_OPEN_MENU = value;
	end
end);

function lib:UIDropDownMenu_InitializeHelper(frame)
	-- This deals with the potentially tainted stuff!
	if (frame ~= LSOL_UIDROPDOWNMENU_OPEN_MENU) then
		LSOL_UIDROPDOWNMENU_MENU_LEVEL = 1;
	end

	-- Set the frame that's being intialized
	delegateFrame:SetAttribute("initmenu", frame);

	-- Hide all the buttons
	local button, dropDownList;
	for i = 1, LSOL_UIDROPDOWNMENU_MAXLEVELS, 1 do
		dropDownList = _G["LSOL_DropDownList" .. i];
		if (i >= LSOL_UIDROPDOWNMENU_MENU_LEVEL or frame ~= LSOL_UIDROPDOWNMENU_OPEN_MENU) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			
			for j = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS, 1 do
				button = _G["LSOL_DropDownList" .. i .. "Button" .. j];
				button:Hide();
			end
			dropDownList:Hide();
		end
	end
	frame:SetHeight(LSOL_UIDROPDOWNMENU_BUTTON_HEIGHT * 2);
end

-- //////////////////////////////////////////////////////////////
-- LSOL_UIDropDownMenuButtonTemplate
local function create_MenuButton(name, parent)
	local f = CreateFrame("Button", name, parent or nil)
	f:SetWidth(100)
	f:SetHeight(16)
	f:SetFrameLevel(f:GetParent():GetFrameLevel() + 2)

	f.Highlight = f:CreateTexture(name .. "Highlight", "BACKGROUND")
	f.Highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	f.Highlight:SetBlendMode("ADD")
	f.Highlight:SetAllPoints()
	f.Highlight:Hide()

	f.Check = f:CreateTexture(name .. "Check", "ARTWORK")
	f.Check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
	f.Check:SetSize(16, 16)
	f.Check:SetPoint("LEFT", f, 0, 0)
	f.Check:SetTexCoord(0, 0.5, 0.5, 1)

	f.UnCheck = f:CreateTexture(name .. "UnCheck", "ARTWORK")
	f.UnCheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
	f.UnCheck:SetSize(16, 16)
	f.UnCheck:SetPoint("LEFT", f, 0, 0)
	f.UnCheck:SetTexCoord(0.5, 1, 0.5, 1)

	f.Icon = f:CreateTexture(name .. "Icon", "ARTWORK")
	f.Icon:SetSize(16, 16)
	f.Icon:SetPoint("RIGHT", f, 0, 0)
	f.Icon:Hide()

	-- ColorSwatch
	local fcw
	fcw = CreateFrame("Button", name .. "ColorSwatch", f,
		BackdropTemplateMixin and DropDownMenuButtonMixin and "BackdropTemplate,ColorSwatchTemplate" or
		BackdropTemplateMixin and "BackdropTemplate" or nil)
	fcw:SetPoint("RIGHT", f, -6, 0)
	fcw:Hide()
	if not DropDownMenuButtonMixin then
		fcw:SetSize(16, 16)
		fcw.SwatchBg = fcw:CreateTexture(name .. "ColorSwatchSwatchBg", "BACKGROUND")
		fcw.SwatchBg:SetVertexColor(1, 1, 1)
		fcw.SwatchBg:SetWidth(14)
		fcw.SwatchBg:SetHeight(14)
		fcw.SwatchBg:SetPoint("CENTER", fcw, 0, 0)
		local button1NormalTexture = fcw:CreateTexture(name .. "ColorSwatchNormalTexture")
		button1NormalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
		button1NormalTexture:SetAllPoints()
		fcw:SetNormalTexture(button1NormalTexture)
	end
	fcw:SetScript("OnEnter", function(self, motion)
		lib:CloseDropDownMenus(self:GetParent():GetParent():GetID() + 1)
		_G[self:GetName() .. "SwatchBg"]:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		lib:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
	end)
	fcw:SetScript("OnLeave", function(self, motion)
		_G[self:GetName() .. "SwatchBg"]:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		lib:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
	end)
	f.ColorSwatch = fcw

	-- ExpandArrow
	local fea = CreateFrame("Button", name .. "ExpandArrow", f)

	fea:SetSize(16, 16)
	fea:SetPoint("RIGHT", f, 0, 0)
	fea:Hide()
	local button2NormalTexture = fea:CreateTexture(name .. "ExpandArrowNormalTexture")
	button2NormalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
	button2NormalTexture:SetAllPoints()
	fea:SetNormalTexture(button2NormalTexture)
	fea:SetScript("OnMouseDown", function(self, button)
		if self:IsEnabled() then
			lib:ToggleDropDownMenu(self:GetParent():GetParent():GetID() + 1, self:GetParent().value, nil, nil, nil, nil,
				self:GetParent().menuList, self);
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		end
	end)
	fea:SetScript("OnEnter", function(self, motion)
		local level = self:GetParent():GetParent():GetID() + 1
		lib:CloseDropDownMenus(level)
		if self:IsEnabled() then
			local listFrame = _G["LSOL_DropDownList" .. level];
			if (not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self) then
				lib:ToggleDropDownMenu(level, self:GetParent().value, nil, nil, nil, nil, self:GetParent().menuList, self)
			end
		end
		lib:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
	end)
	fea:SetScript("OnLeave", function(self, motion)
		lib:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
	end)
	f.ExpandArrow = fea

	-- InvisibleButton
	local fib = CreateFrame("Button", name .. "InvisibleButton", f)
	fib:Hide()
	fib:SetPoint("TOPLEFT", f, 0, 0)
	fib:SetPoint("BOTTOMLEFT", f, 0, 0)
	fib:SetPoint("RIGHT", fcw, "LEFT", 0, 0)
	fib:SetScript("OnEnter", function(self, motion)
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StopCounting(self:GetParent():GetParent());
		end
		lib:CloseDropDownMenus(self:GetParent():GetParent():GetID() + 1);
		local parent = self:GetParent();
		if (parent.tooltipTitle and parent.tooltipWhileDisabled) then
			if (parent.tooltipOnButton) then
				tooltip:SetOwner(parent, "ANCHOR_RIGHT");
				GameTooltip_SetTitle(tooltip, parent.tooltipTitle);
				if parent.tooltipInstruction then
					GameTooltip_AddInstructionLine(tooltip, parent.tooltipInstruction);
				end
				if parent.tooltipText then
					GameTooltip_AddNormalLine(tooltip, parent.tooltipText, true);
				end
				if parent.tooltipWarning then
					GameTooltip_AddColoredLine(tooltip, parent.tooltipWarning, RED_FONT_COLOR, true);
				end
				tooltip:Show();
			end
		end
	end)
	fib:SetScript("OnLeave", function(self, motion)
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StartCounting(self:GetParent():GetParent());
		end
		tooltip:Hide();
	end)
	f.invisibleButton = fib

	-- UIDropDownMenuButton Scripts
	local function button_OnEnter(self)
		if (self.hasArrow) then
			local level = self:GetParent():GetID() + 1;
			local listFrame = _G["LSOL_DropDownList" .. level];
			if (not listFrame or not listFrame:IsShown() or select(2, listFrame:GetPoint()) ~= self) then
				lib:ToggleDropDownMenu(self:GetParent():GetID() + 1, self.value, nil, nil, nil, nil, self.menuList, self);
			end
		else
			lib:CloseDropDownMenus(self:GetParent():GetID() + 1);
		end
		self.Highlight:Show();
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StopCounting(self:GetParent());
		end

		if (self.tooltipTitle and not self.noTooltipWhileEnabled) then
			if (self.tooltipOnButton) then
				tooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip_SetTitle(tooltip, self.tooltipTitle);
				if self.tooltipText then
					GameTooltip_AddNormalLine(tooltip, self.tooltipText, true);
				end
				tooltip:Show();
			end
		end

		if (self.mouseOverIcon ~= nil) then
			self.Icon:SetTexture(self.mouseOverIcon);
			self.Icon:Show();
		end
		if (WoWRetail) then
			GetValueOrCallFunction(self, "funcOnEnter", self);
		end
	end

	local function button_OnLeave(self)
		self.Highlight:Hide();
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StartCounting(self:GetParent());
		end

		tooltip:Hide();

		if (self.mouseOverIcon ~= nil) then
			if (self.icon ~= nil) then
				self.Icon:SetTexture(self.icon);
			else
				self.Icon:Hide();
			end
		end

		if (WoWRetail) then
			GetValueOrCallFunction(self, "funcOnLeave", self);
		end
	end

	local function button_OnClick(self)
		local checked = self.checked;
		if (type(checked) == "function") then
			checked = checked(self);
		end

		if (self.keepShownOnClick) then
			if not self.notCheckable then
				if (checked) then
					_G[self:GetName() .. "Check"]:Hide();
					_G[self:GetName() .. "UnCheck"]:Show();
					checked = false;
				else
					_G[self:GetName() .. "Check"]:Show();
					_G[self:GetName() .. "UnCheck"]:Hide();
					checked = true;
				end
			end
		else
			self:GetParent():Hide();
		end

		if (type(self.checked) ~= "function") then
			self.checked = checked;
		end

		-- saving this here because func might use a dropdown, changing this self's attributes
		local playSound = true;
		if (self.noClickSound) then
			playSound = false;
		end

		local func = self.func;
		if (func) then
			func(self, self.arg1, self.arg2, checked);
		else
			return;
		end

		if (playSound) then
			PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
		end
	end

	f:SetScript("OnClick", function(self, button, down)
		button_OnClick(self, button, down)
	end)
	f:SetScript("OnEnter", function(self, motion)
		button_OnEnter(self)
	end)
	f:SetScript("OnLeave", function(self, motion)
		button_OnLeave(self)
	end)
	f:SetScript("OnEnable", function(self)
		self.invisibleButton:Hide()
	end)
	f:SetScript("OnDisable", function(self)
		self.invisibleButton:Show()
	end)

	local text1 = f:CreateFontString(name .. "NormalText")
	f:SetFontString(text1)
	text1:SetPoint("LEFT", f, -5, 0)
	f:SetNormalFontObject("GameFontHighlightSmallLeft")
	f:SetHighlightFontObject("GameFontHighlightSmallLeft")
	f:SetDisabledFontObject("GameFontDisableSmallLeft")

	return f
end

-- //////////////////////////////////////////////////////////////
-- LSOL_UIDropDownListTemplate
local function creatre_DropDownList(name, parent)
	-- This has been removed from Backdrop.lua, so we added the definition here.
	local BACKDROP_DIALOG_DARK = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 9, },
	}
	local BACKDROP_TOOLTIP_16_16_5555 = {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileEdge = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	}

	local f = _G[name] or CreateFrame("Button", name)
	f:SetParent(parent or nil)
	f:Hide()
	f:SetFrameStrata("DIALOG")
	f:EnableMouse(true)

	local fbd = _G[name .. "Backdrop"] or
		CreateFrame("Frame", name .. "Backdrop", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	fbd:SetAllPoints()
	fbd:SetBackdrop(BACKDROP_DIALOG_DARK)
	f.Backdrop = fbd

	local fmb = _G[name .. "MenuBackdrop"] or
		CreateFrame("Frame", name .. "MenuBackdrop", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	fmb:SetAllPoints()
	fmb:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
	fmb:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	fmb:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
		TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	f.MenuBackdrop = fmb

	f.Button1 = _G[name .. "Button1"] or create_MenuButton(name .. "Button1", f) -- to replace the inherits of "UIDropDownMenuButtonTemplate"
	f.Button1:SetID(1)

	f:SetScript("OnClick", function(self)
		self:Hide()
	end)
	f:SetScript("OnEnter", function(self, motion)
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StopCounting(self, motion)
		end
	end)
	f:SetScript("OnLeave", function(self, motion)
		if (WoWClassicEra or WoWClassicTBC) then
			lib:UIDropDownMenu_StartCounting(self, motion)
		end
	end)
	-- If dropdown is visible then see if its timer has expired, if so hide the frame
	f:SetScript("OnUpdate", function(self, elapsed)
		if (self.shouldRefresh) then
			lib:UIDropDownMenu_RefreshDropDownSize(self);
			self.shouldRefresh = false;
		end
		if (WoWClassicEra or WoWClassicTBC) then
			if (not self.showTimer or not self.isCounting) then
				return;
			elseif (self.showTimer < 0) then
				self:Hide();
				self.showTimer = nil;
				self.isCounting = nil;
			else
				self.showTimer = self.showTimer - elapsed;
			end
		end
	end)
	f:SetScript("OnShow", function(self)
		if (self.onShow) then
			self.onShow();
			self.onShow = nil;
		end

		for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS do
			if (not self.noResize) then
				_G[self:GetName() .. "Button" .. i]:SetWidth(self.maxWidth);
			end
		end

		if (not self.noResize) then
			self:SetWidth(self.maxWidth + 25);
		end
		if (WoWClassicEra or WoWClassicTBC) then
			self.showTimer = nil;
		end
		if (self:GetID() > 1) then
			self.parent = _G["LSOL_DropDownList" .. (self:GetID() - 1)];
		end
	end)
	f:SetScript("OnHide", function(self)
		local id = self:GetID()
		if (self.onHide) then
			self.onHide(id + 1);
			self.onHide = nil;
		end
		lib:CloseDropDownMenus(id + 1);
		LSOL_OPEN_DROPDOWNMENUS[id] = nil;
		if (id == 1) then
			LSOL_UIDROPDOWNMENU_OPEN_MENU = nil;
		end

		lib:UIDropDownMenu_ClearCustomFrames(self);
	end)

	return f
end

-- //////////////////////////////////////////////////////////////
-- LSOL_UIDropDownMenuTemplate
local function create_DropDownMenu(name, parent)
	local f
	if type(name) == "table" then
		f = name
		name = f:GetName()
	else
		f = CreateFrame("Frame", name, parent or nil)
	end

	if not name then name = "" end

	f:SetSize(40, 32)

	f.Left = f:CreateTexture(name .. "Left", "ARTWORK")
	f.Left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	f.Left:SetSize(25, 64)
	f.Left:SetPoint("TOPLEFT", f, 0, 17)
	f.Left:SetTexCoord(0, 0.1953125, 0, 1)

	f.Middle = f:CreateTexture(name .. "Middle", "ARTWORK")
	f.Middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	f.Middle:SetSize(115, 64)
	f.Middle:SetPoint("LEFT", f.Left, "RIGHT")
	f.Middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)

	f.Right = f:CreateTexture(name .. "Right", "ARTWORK")
	f.Right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	f.Right:SetSize(25, 64)
	f.Right:SetPoint("LEFT", f.Middle, "RIGHT")
	f.Right:SetTexCoord(0.8046875, 1, 0, 1)

	f.Text = f:CreateFontString(name .. "Text", "ARTWORK", "GameFontHighlightSmall")
	f.Text:SetWordWrap(false)
	f.Text:SetJustifyH("RIGHT")
	f.Text:SetSize(0, 10)
	f.Text:SetPoint("RIGHT", f.Right, -43, 2)

	f.Icon = f:CreateTexture(name .. "Icon", "OVERLAY")
	f.Icon:Hide()
	f.Icon:SetSize(16, 16)
	f.Icon:SetPoint("LEFT", 30, 2)

	-- // UIDropDownMenuButtonScriptTemplate
	f.Button = CreateFrame("Button", name .. "Button", f)
	f.Button:SetMotionScriptsWhileDisabled(true)
	f.Button:SetSize(24, 24)
	f.Button:SetPoint("TOPRIGHT", f.Right, -16, -18)

	f.Button.NormalTexture = f.Button:CreateTexture(name .. "NormalTexture")
	f.Button.NormalTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	f.Button.NormalTexture:SetSize(24, 24)
	f.Button.NormalTexture:SetPoint("RIGHT", f.Button, 0, 0)
	f.Button:SetNormalTexture(f.Button.NormalTexture)

	f.Button.PushedTexture = f.Button:CreateTexture(name .. "PushedTexture")
	f.Button.PushedTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	f.Button.PushedTexture:SetSize(24, 24)
	f.Button.PushedTexture:SetPoint("RIGHT", f.Button, 0, 0)
	f.Button:SetPushedTexture(f.Button.PushedTexture)

	f.Button.DisabledTexture = f.Button:CreateTexture(name .. "DisabledTexture")
	f.Button.DisabledTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	f.Button.DisabledTexture:SetSize(24, 24)
	f.Button.DisabledTexture:SetPoint("RIGHT", f.Button, 0, 0)
	f.Button:SetDisabledTexture(f.Button.DisabledTexture)

	f.Button.HighlightTexture = f.Button:CreateTexture(name .. "HighlightTexture")
	f.Button.HighlightTexture:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	f.Button.HighlightTexture:SetSize(24, 24)
	f.Button.HighlightTexture:SetPoint("RIGHT", f.Button, 0, 0)
	f.Button.HighlightTexture:SetBlendMode("ADD")
	f.Button:SetHighlightTexture(f.Button.HighlightTexture)

	-- Button Script
	f.Button:SetScript("OnEnter", function(self, motion)
		local parent = self:GetParent()
		local myscript = parent:GetScript("OnEnter")
		if (myscript ~= nil) then
			myscript(parent)
		end
	end)
	f.Button:SetScript("OnLeave", function(self, motion)
		local parent = self:GetParent()
		local myscript = parent:GetScript("OnLeave")
		if (myscript ~= nil) then
			myscript(parent)
		end
	end)
	f.Button:SetScript("OnMouseDown", function(self, button)
		if self:IsEnabled() then
			local parent = self:GetParent()
			lib:ToggleDropDownMenu(nil, nil, parent)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
	end)

	-- UIDropDownMenu Script
	f:SetScript("OnHide", function(self)
		lib:CloseDropDownMenus()
	end)

	return f
end

-- End of frame templates
-- //////////////////////////////////////////////////////////////

-- //////////////////////////////////////////////////////////////
-- Handling two frames from LibUIDropDownMenu.xml
local function create_DropDownButtons()
	LSOL_DropDownList1 = creatre_DropDownList("LSOL_DropDownList1")
	LSOL_DropDownList1:SetToplevel(true)
	LSOL_DropDownList1:SetFrameStrata("FULLSCREEN_DIALOG")
	LSOL_DropDownList1:Hide()
	LSOL_DropDownList1:SetID(1)
	LSOL_DropDownList1:SetSize(180, 10)
	local _, fontHeight, _ = _G["LSOL_DropDownList1Button1NormalText"]:GetFont()
	LSOL_UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = fontHeight

	LSOL_DropDownList2 = creatre_DropDownList("LSOL_DropDownList2")
	LSOL_DropDownList2:SetToplevel(true)
	LSOL_DropDownList2:SetFrameStrata("FULLSCREEN_DIALOG")
	LSOL_DropDownList2:Hide()
	LSOL_DropDownList2:SetID(2)
	LSOL_DropDownList2:SetSize(180, 10)

	-- UIParent integration; since we customize the name of DropDownList, we need to add it to golbal UIMenus table.
	--tinsert(UIMenus, "LSOL_DropDownList1");
	--tinsert(UIMenus, "LSOL_DropDownList2");

	-- Alternative by Dahk Celes (DDC) that avoids tainting UIMenus and CloseMenus()
	hooksecurefunc("CloseMenus", function()
		LSOL_DropDownList1:Hide()
		LSOL_DropDownList2:Hide()
	end)
end

do
	if lib then
		create_DropDownButtons()
	end
end

-- //////////////////////////////////////////////////////////////
-- Global function to replace LSOL_UIDropDownMenuTemplate
function lib:Create_UIDropDownMenu(name, parent)
	return create_DropDownMenu(name, parent)
end

local function GetChild(frame, name, key)
	if (frame[key]) then
		return frame[key];
	elseif name then
		return _G[name .. key];
	end

	return nil;
end

function lib:UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList)
	frame.menuList = menuList;

	--securecall("initializeHelper", frame);
	lib:UIDropDownMenu_InitializeHelper(frame)

	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if (initFunction) then
		lib:UIDropDownMenu_SetInitializeFunction(frame, initFunction);
		initFunction(frame, level, frame.menuList);
	end

	--master frame
	if (level == nil) then
		level = 1;
	end

	local dropDownList = _G["LSOL_DropDownList" .. level];
	dropDownList.dropdown = frame;
	dropDownList.shouldRefresh = true;

	lib:UIDropDownMenu_SetDisplayMode(frame, displayMode);
end

function lib:UIDropDownMenu_SetInitializeFunction(frame, initFunction)
	frame.initialize = initFunction;
end

function lib:UIDropDownMenu_SetDisplayMode(frame, displayMode)
	-- Change appearance based on the displayMode
	-- Note: this is a one time change based on previous behavior.
	if (displayMode == "MENU") then
		local name = frame:GetName();
		GetChild(frame, name, "Left"):Hide();
		GetChild(frame, name, "Middle"):Hide();
		GetChild(frame, name, "Right"):Hide();
		local button = GetChild(frame, name, "Button");
		local buttonName = button:GetName();
		GetChild(button, buttonName, "NormalTexture"):SetTexture(nil);
		GetChild(button, buttonName, "DisabledTexture"):SetTexture(nil);
		GetChild(button, buttonName, "PushedTexture"):SetTexture(nil);
		GetChild(button, buttonName, "HighlightTexture"):SetTexture(nil);
		local text = GetChild(frame, name, "Text");

		button:ClearAllPoints();
		button:SetPoint("LEFT", text, "LEFT", -9, 0);
		button:SetPoint("RIGHT", text, "RIGHT", 6, 0);
		frame.displayMode = "MENU";
	end
end

function lib:UIDropDownMenu_RefreshDropDownSize(self)
	self.maxWidth = lib:UIDropDownMenu_GetMaxButtonWidth(self);
	self:SetWidth(self.maxWidth + 25);

	for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS, 1 do
		local icon = _G[self:GetName() .. "Button" .. i .. "Icon"];

		if (icon.tFitDropDownSizeX) then
			icon:SetWidth(self.maxWidth - 5);
		end
	end
end

-- Start the countdown on a frame
function lib:UIDropDownMenu_StartCounting(frame)
	if (frame.parent) then
		lib:UIDropDownMenu_StartCounting(frame.parent);
	else
		frame.showTimer = LSOL_UIDROPDOWNMENU_SHOW_TIME;
		frame.isCounting = 1;
	end
end

-- Stop the countdown on a frame
function lib:UIDropDownMenu_StopCounting(frame)
	if (frame.parent) then
		lib:UIDropDownMenu_StopCounting(frame.parent);
	else
		frame.isCounting = nil;
	end
end

-- Create (return) empty table
function lib:UIDropDownMenu_CreateInfo()
	return {};
end

function lib:UIDropDownMenu_CreateFrames(level, index)
	while (level > LSOL_UIDROPDOWNMENU_MAXLEVELS) do
		LSOL_UIDROPDOWNMENU_MAXLEVELS = LSOL_UIDROPDOWNMENU_MAXLEVELS + 1;
		--local newList = CreateFrame("Button", "LSOL_DropDownList"..LSOL_UIDROPDOWNMENU_MAXLEVELS, nil, "LSOL_UIDropDownListTemplate");
		local newList = creatre_DropDownList("LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MAXLEVELS)
		newList:SetFrameStrata("FULLSCREEN_DIALOG");
		newList:SetToplevel(true);
		newList:Hide();
		newList:SetID(LSOL_UIDROPDOWNMENU_MAXLEVELS);
		newList:SetWidth(180)
		newList:SetHeight(10)
		--		for i = WoWRetail and 1 or (LSOL_UIDROPDOWNMENU_MINBUTTONS+1), LSOL_UIDROPDOWNMENU_MAXBUTTONS do
		for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS do
			--local newButton = CreateFrame("Button", "LSOL_DropDownList"..LSOL_UIDROPDOWNMENU_MAXLEVELS.."Button"..i, newList, "LSOL_UIDropDownMenuButtonTemplate");
			local newButton = create_MenuButton("LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MAXLEVELS .. "Button" .. i, newList)
			newButton:SetID(i);
		end
	end

	while (index > LSOL_UIDROPDOWNMENU_MAXBUTTONS) do
		LSOL_UIDROPDOWNMENU_MAXBUTTONS = LSOL_UIDROPDOWNMENU_MAXBUTTONS + 1;
		for i = 1, LSOL_UIDROPDOWNMENU_MAXLEVELS do
			--local newButton = CreateFrame("Button", "LSOL_DropDownList"..i.."Button"..LSOL_UIDROPDOWNMENU_MAXBUTTONS, _G["LSOL_DropDownList"..i], "LSOL_UIDropDownMenuButtonTemplate");
			local newButton = create_MenuButton("LSOL_DropDownList" .. i .. "Button" .. LSOL_UIDROPDOWNMENU_MAXBUTTONS,
				_G["LSOL_DropDownList" .. i])
			newButton:SetID(LSOL_UIDROPDOWNMENU_MAXBUTTONS);
		end
	end
end

function lib:UIDropDownMenu_AddSeparator(level)
	local separatorInfo = {
		hasArrow = false;
		dist = 0;
		isTitle = true;
		isUninteractable = true;
		notCheckable = true;
		iconOnly = true;
		icon = "Interface\\Common\\UI-TooltipDivider-Transparent";
		tCoordLeft = 0;
		tCoordRight = 1;
		tCoordTop = 0;
		tCoordBottom = 1;
		tSizeX = 0;
		tSizeY = 8;
		tFitDropDownSizeX = true;
		iconInfo = {
			tCoordLeft = 0,
			tCoordRight = 1,
			tCoordTop = 0,
			tCoordBottom = 1,
			tSizeX = 0,
			tSizeY = 8,
			tFitDropDownSizeX = true
		},
	};

	lib:UIDropDownMenu_AddButton(separatorInfo, level);
end

function lib:UIDropDownMenu_AddSpace(level)
	local spaceInfo = {
		hasArrow = false,
		dist = 0,
		isTitle = true,
		isUninteractable = true,
		notCheckable = true,
	};

	lib:UIDropDownMenu_AddButton(spaceInfo, level);
end

function lib:UIDropDownMenu_AddButton(info, level)
	--[[
	Might to uncomment this if there are performance issues
	if ( not LSOL_UIDROPDOWNMENU_OPEN_MENU ) then
		return;
	end
	]]
	if (not level) then
		level = 1;
	end

	local listFrame = _G["LSOL_DropDownList" .. level];
	local index;
	if (listFrame) then
		index = listFrame.numButtons and (listFrame.numButtons + 1) or 1
	else
		index = 0
	end
	--local index = listFrame and (listFrame.numButtons + 1) or 1;
	local width;

	delegateFrame:SetAttribute("createframes-level", level);
	delegateFrame:SetAttribute("createframes-index", index);
	delegateFrame:SetAttribute("createframes", true);

	listFrame = listFrame or _G["LSOL_DropDownList" .. level];
	local listFrameName = listFrame:GetName();

	-- Set the number of buttons in the listframe
	listFrame.numButtons = index;

	local button = _G[listFrameName .. "Button" .. index];
	local normalText = _G[button:GetName() .. "NormalText"];
	local icon = _G[button:GetName() .. "Icon"];
	-- This button is used to capture the mouse OnEnter/OnLeave events if the dropdown button is disabled, since a disabled button doesn't receive any events
	-- This is used specifically for drop down menu time outs
	local invisibleButton = _G[button:GetName() .. "InvisibleButton"];

	-- Default settings
	button:SetDisabledFontObject(GameFontDisableSmallLeft);
	invisibleButton:Hide();
	button:Enable();

	-- If not clickable then disable the button and set it white
	if (info.notClickable) then
		info.disabled = true;
		button:SetDisabledFontObject(GameFontHighlightSmallLeft);
	end

	-- Set the text color and disable it if its a title
	if (info.isTitle) then
		info.disabled = true;
		button:SetDisabledFontObject(GameFontNormalSmallLeft);
	end

	-- Disable the button if disabled and turn off the color code
	if (info.disabled) then
		button:Disable();
		invisibleButton:Show();
		info.colorCode = nil;
	end

	-- If there is a color for a disabled line, set it
	if (info.disablecolor) then
		info.colorCode = info.disablecolor;
	end

	-- Configure button
	if (info.text) then
		-- look for inline color code this is only if the button is enabled
		if (info.colorCode) then
			button:SetText(info.colorCode .. info.text .. "|r");
		else
			button:SetText(info.text);
		end

		-- Set icon
		if (info.icon or info.mouseOverIcon) then
			icon:SetSize(16, 16);
			if (info.icon and C_Texture.GetAtlasInfo(info.icon)) then
				icon:SetAtlas(info.icon);
			else
				icon:SetTexture(info.icon);
			end
			icon:ClearAllPoints();
			icon:SetPoint("RIGHT", info.iconXOffset or 0, 0);

			if (info.tCoordLeft) then
				icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
			else
				icon:SetTexCoord(0, 1, 0, 1);
			end
			icon:Show();
		else
			icon:Hide();
		end

		-- Check to see if there is a replacement font
		if (info.fontObject) then
			button:SetNormalFontObject(info.fontObject);
			button:SetHighlightFontObject(info.fontObject);
		else
			button:SetNormalFontObject(GameFontHighlightSmallLeft);
			button:SetHighlightFontObject(GameFontHighlightSmallLeft);
		end
	else
		button:SetText("");
		icon:Hide();
	end

	button.iconOnly = nil;
	button.icon = nil;
	button.iconInfo = nil;

	if (info.iconInfo) then
		icon.tFitDropDownSizeX = info.iconInfo.tFitDropDownSizeX;
	else
		icon.tFitDropDownSizeX = nil;
	end
	if (info.iconOnly and info.icon) then
		button.iconOnly = true;
		button.icon = info.icon;
		button.iconInfo = info.iconInfo;

		lib:UIDropDownMenu_SetIconImage(icon, info.icon, info.iconInfo);
		icon:ClearAllPoints();
		icon:SetPoint("LEFT");
	end

	-- Pass through attributes
	button.func = info.func;
	button.funcOnEnter = info.funcOnEnter;
	button.funcOnLeave = info.funcOnLeave;
	if (WoWRetail) then
		button.iconXOffset = info.iconXOffset;
		button.ignoreAsMenuSelection = info.ignoreAsMenuSelection;
	else
		button.classicChecks = info.classicChecks;
	end
	button.owner = info.owner;
	button.hasOpacity = info.hasOpacity;
	button.opacity = info.opacity;
	button.opacityFunc = info.opacityFunc;
	button.cancelFunc = info.cancelFunc;
	button.swatchFunc = info.swatchFunc;
	button.keepShownOnClick = info.keepShownOnClick;
	button.tooltipTitle = info.tooltipTitle;
	button.tooltipText = info.tooltipText;
	button.tooltipInstruction = info.tooltipInstruction;
	button.tooltipWarning = info.tooltipWarning;
	button.arg1 = info.arg1;
	button.arg2 = info.arg2;
	button.hasArrow = info.hasArrow;
	button.hasColorSwatch = info.hasColorSwatch;
	button.notCheckable = info.notCheckable;
	button.menuList = info.menuList;
	button.tooltipWhileDisabled = info.tooltipWhileDisabled;
	button.noTooltipWhileEnabled = info.noTooltipWhileEnabled;
	button.tooltipOnButton = info.tooltipOnButton;
	button.noClickSound = info.noClickSound;
	button.padding = info.padding;
	button.icon = info.icon;
	button.mouseOverIcon = info.mouseOverIcon;

	if (info.value) then
		button.value = info.value;
	elseif (info.text) then
		button.value = info.text;
	else
		button.value = nil;
	end

	local expandArrow = _G[listFrameName .. "Button" .. index .. "ExpandArrow"];
	expandArrow:SetShown(info.hasArrow);
	expandArrow:SetEnabled(not info.disabled);

	-- If not checkable move everything over to the left to fill in the gap where the check would be
	local xPos = 5;
	local yPos = -((button:GetID() - 1) * LSOL_UIDROPDOWNMENU_BUTTON_HEIGHT) - LSOL_UIDROPDOWNMENU_BORDER_HEIGHT;
	local displayInfo = normalText;
	if (info.iconOnly) then
		displayInfo = icon;
	end

	displayInfo:ClearAllPoints();
	if (info.notCheckable) then
		if (info.justifyH and info.justifyH == "CENTER") then
			displayInfo:SetPoint("CENTER", button, "CENTER", -7, 0);
		else
			displayInfo:SetPoint("LEFT", button, "LEFT", 0, 0);
		end
		xPos = xPos + 10;

	else
		xPos = xPos + 12;
		displayInfo:SetPoint("LEFT", button, "LEFT", 20, 0);
	end

	-- Adjust offset if displayMode is menu
	local frame = LSOL_UIDROPDOWNMENU_OPEN_MENU;
	if (frame and frame.displayMode == "MENU") then
		if (not info.notCheckable) then
			xPos = xPos - 6;
		end
	end

	-- If no open frame then set the frame to the currently initialized frame
	frame = frame or LSOL_UIDROPDOWNMENU_INIT_MENU;

	if (info.leftPadding) then
		xPos = xPos + info.leftPadding;
	end
	button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", xPos, yPos);

	-- See if button is selected by id or name
	if (frame) then
		if (lib:UIDropDownMenu_GetSelectedName(frame)) then
			if (button:GetText() == lib:UIDropDownMenu_GetSelectedName(frame)) then
				info.checked = 1;
			end
		elseif (lib:UIDropDownMenu_GetSelectedID(frame)) then
			if (button:GetID() == lib:UIDropDownMenu_GetSelectedID(frame)) then
				info.checked = 1;
			end
		elseif (lib:UIDropDownMenu_GetSelectedValue(frame)) then
			if (button.value == lib:UIDropDownMenu_GetSelectedValue(frame)) then
				info.checked = 1;
			end
		end
	end

	if not info.notCheckable then
		local check = _G[listFrameName .. "Button" .. index .. "Check"];
		local uncheck = _G[listFrameName .. "Button" .. index .. "UnCheck"];
		if (info.disabled) then
			check:SetDesaturated(true);
			check:SetAlpha(0.5);
			uncheck:SetDesaturated(true);
			uncheck:SetAlpha(0.5);
		else
			check:SetDesaturated(false);
			check:SetAlpha(1);
			uncheck:SetDesaturated(false);
			uncheck:SetAlpha(1);
		end
		if (WoWClassicEra or WoWClassicTBC) then
			check:SetSize(16, 16);
			uncheck:SetSize(16, 16);
			normalText:SetPoint("LEFT", check, "RIGHT", 0, 0);
		end

		if info.customCheckIconAtlas or info.customCheckIconTexture then
			check:SetTexCoord(0, 1, 0, 1);
			uncheck:SetTexCoord(0, 1, 0, 1);

			if info.customCheckIconAtlas then
				check:SetAtlas(info.customCheckIconAtlas);
				uncheck:SetAtlas(info.customUncheckIconAtlas or info.customCheckIconAtlas);
			else
				check:SetTexture(info.customCheckIconTexture);
				uncheck:SetTexture(info.customUncheckIconTexture or info.customCheckIconTexture);
			end
		elseif info.classicChecks then
			check:SetTexCoord(0, 1, 0, 1);
			uncheck:SetTexCoord(0, 1, 0, 1);

			check:SetSize(24, 24);
			uncheck:SetSize(24, 24);

			check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
			uncheck:SetTexture("");

			normalText:SetPoint("LEFT", check, "RIGHT", LSOL_UIDROPDOWNMENU_CLASSIC_CHECK_PADDING, 0);
		elseif info.isNotRadio then
			check:SetTexCoord(0.0, 0.5, 0.0, 0.5);
			check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
			uncheck:SetTexCoord(0.5, 1.0, 0.0, 0.5);
			uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
		else
			check:SetTexCoord(0.0, 0.5, 0.5, 1.0);
			check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
			uncheck:SetTexCoord(0.5, 1.0, 0.5, 1.0);
			uncheck:SetTexture("Interface\\Common\\UI-DropDownRadioChecks");
		end

		-- Checked can be a function now
		local checked = info.checked;
		if (type(checked) == "function") then
			checked = checked(button);
		end

		-- Show the check if checked
		if (checked) then
			button:LockHighlight();
			check:Show();
			uncheck:Hide();
		else
			button:UnlockHighlight();
			check:Hide();
			uncheck:Show();
		end
	else
		_G[listFrameName .. "Button" .. index .. "Check"]:Hide();
		_G[listFrameName .. "Button" .. index .. "UnCheck"]:Hide();
	end
	button.checked = info.checked;

	-- If has a colorswatch, show it and vertex color it
	local colorSwatch = _G[listFrameName .. "Button" .. index .. "ColorSwatch"];
	if (info.hasColorSwatch) then
		if (WoWClassicEra or WoWClassicTBC) then
			_G["LSOL_DropDownList" .. level .. "Button" .. index .. "ColorSwatch" .. "NormalTexture"]:SetVertexColor(info.r,
				info.g, info.b);
		else
			_G["LSOL_DropDownList" .. level .. "Button" .. index .. "ColorSwatch"].Color:SetVertexColor(info.r, info.g, info.b);
		end
		button.r = info.r;
		button.g = info.g;
		button.b = info.b;
		colorSwatch:Show();
	else
		colorSwatch:Hide();
	end

	lib:UIDropDownMenu_CheckAddCustomFrame(listFrame, button, info);

	button:SetShown(button.customFrame == nil);

	button.minWidth = info.minWidth;

	width = max(lib:UIDropDownMenu_GetButtonWidth(button), info.minWidth or 0);
	--Set maximum button width
	if (width > (listFrame and listFrame.maxWidth or 0)) then
		listFrame.maxWidth = width;
	end

	if (WoWRetail) then
		local customFrameCount = listFrame.customFrames and #listFrame.customFrames or 0;
		local height = ((index - customFrameCount) * LSOL_UIDROPDOWNMENU_BUTTON_HEIGHT) +
			(LSOL_UIDROPDOWNMENU_BORDER_HEIGHT * 2);
		for frameIndex = 1, customFrameCount do
			local frame = listFrame.customFrames[frameIndex];
			height = height + frame:GetPreferredEntryHeight();
		end

		-- Set the height of the listframe
		listFrame:SetHeight(height);
	else
		-- Set the height of the listframe
		listFrame:SetHeight((index * LSOL_UIDROPDOWNMENU_BUTTON_HEIGHT) + (LSOL_UIDROPDOWNMENU_BORDER_HEIGHT * 2));
	end

end

function lib:UIDropDownMenu_CheckAddCustomFrame(self, button, info)
	local customFrame = info.customFrame;
	button.customFrame = customFrame;
	if customFrame then
		customFrame:SetOwningButton(button);
		customFrame:ClearAllPoints();
		customFrame:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0);
		customFrame:Show();

		lib:UIDropDownMenu_RegisterCustomFrame(self, customFrame);
	end
end

function lib:UIDropDownMenu_RegisterCustomFrame(self, customFrame)
	self.customFrames = self.customFrames or {}
	table.insert(self.customFrames, customFrame);
end

function lib:UIDropDownMenu_GetMaxButtonWidth(self)
	local maxWidth = 0;
	for i = 1, self.numButtons do
		local button = _G[self:GetName() .. "Button" .. i];
		local width = lib:UIDropDownMenu_GetButtonWidth(button);
		if (width > maxWidth) then
			maxWidth = width;
		end
	end
	return maxWidth;
end

function lib:UIDropDownMenu_GetButtonWidth(button)
	local minWidth = button.minWidth or 0;
	if button.customFrame and button.customFrame:IsShown() then
		return math.max(minWidth, button.customFrame:GetPreferredEntryWidth());
	end

	if not button:IsShown() then
		return 0;
	end

	local width;
	local buttonName = button:GetName();
	local icon = _G[buttonName .. "Icon"];
	local normalText = _G[buttonName .. "NormalText"];

	if (button.iconOnly and icon) then
		width = icon:GetWidth();
	elseif (normalText and normalText:GetText()) then
		width = normalText:GetWidth() + 40;

		if (button.icon) then
			-- Add padding for the icon
			width = width + 10;
		end
		if (button.classicChecks) then
			width = width + LSOL_UIDROPDOWNMENU_CLASSIC_CHECK_PADDING;
		end
	else
		return minWidth;
	end

	-- Add padding if has and expand arrow or color swatch
	if (button.hasArrow or button.hasColorSwatch) then
		width = width + 10;
	end
	if (button.notCheckable) then
		width = width - 30;
	end
	if (button.padding) then
		width = width + button.padding;
	end

	return math.max(minWidth, width);
end

function lib:UIDropDownMenu_Refresh(frame, useValue, dropdownLevel)
	local maxWidth = 0;
	local somethingChecked = nil;
	if (not dropdownLevel) then
		dropdownLevel = LSOL_UIDROPDOWNMENU_MENU_LEVEL;
	end

	local listFrame = _G["LSOL_DropDownList" .. dropdownLevel];
	listFrame.numButtons = listFrame.numButtons or 0;
	-- Just redraws the existing menu
	for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["LSOL_DropDownList" .. dropdownLevel .. "Button" .. i];
		local checked = nil;

		if (i <= listFrame.numButtons) then
			-- See if checked or not
			if (lib:UIDropDownMenu_GetSelectedName(frame)) then
				if (button:GetText() == lib:UIDropDownMenu_GetSelectedName(frame)) then
					checked = 1;
				end
			elseif (lib:UIDropDownMenu_GetSelectedID(frame)) then
				if (button:GetID() == lib:UIDropDownMenu_GetSelectedID(frame)) then
					checked = 1;
				end
			elseif (lib:UIDropDownMenu_GetSelectedValue(frame)) then
				if (button.value == lib:UIDropDownMenu_GetSelectedValue(frame)) then
					checked = 1;
				end
			end
		end
		if (button.checked and type(button.checked) == "function") then
			checked = button.checked(button);
		end

		if not button.notCheckable and button:IsShown() then
			-- If checked show check image
			local checkImage = _G["LSOL_DropDownList" .. dropdownLevel .. "Button" .. i .. "Check"];
			local uncheckImage = _G["LSOL_DropDownList" .. dropdownLevel .. "Button" .. i .. "UnCheck"];
			if (checked) then
				if not button.ignoreAsMenuSelection then
					somethingChecked = true;
					local icon = GetChild(frame, frame:GetName(), "Icon");
					if (button.iconOnly and icon and button.icon) then
						lib:UIDropDownMenu_SetIconImage(icon, button.icon, button.iconInfo);
					elseif (useValue) then
						lib:UIDropDownMenu_SetText(frame, button.value);
						icon:Hide();
					else
						lib:UIDropDownMenu_SetText(frame, button:GetText());
						icon:Hide();
					end
				end
				button:LockHighlight();
				checkImage:Show();
				uncheckImage:Hide();
			else
				button:UnlockHighlight();
				checkImage:Hide();
				uncheckImage:Show();
			end
		end

		if (button:IsShown()) then
			local width = lib:UIDropDownMenu_GetButtonWidth(button);
			if (width > maxWidth) then
				maxWidth = width;
			end
		end
	end
	if (somethingChecked == nil) then
		lib:UIDropDownMenu_SetText(frame, VIDEO_QUALITY_LABEL6);
		local icon = GetChild(frame, frame:GetName(), "Icon");
		icon:Hide();
	end
	if (not frame.noResize) then
		for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS do
			local button = _G["LSOL_DropDownList" .. dropdownLevel .. "Button" .. i];
			button:SetWidth(maxWidth);
		end
		lib:UIDropDownMenu_RefreshDropDownSize(_G["LSOL_DropDownList" .. dropdownLevel]);
	end
end

function lib:UIDropDownMenu_RefreshAll(frame, useValue)
	for dropdownLevel = LSOL_UIDROPDOWNMENU_MENU_LEVEL, 2, -1 do
		local listFrame = _G["LSOL_DropDownList" .. dropdownLevel];
		if (listFrame:IsShown()) then
			lib:UIDropDownMenu_Refresh(frame, nil, dropdownLevel);
		end
	end
	-- useValue is the text on the dropdown, only needs to be set once
	lib:UIDropDownMenu_Refresh(frame, useValue, 1);
end

function lib:UIDropDownMenu_SetIconImage(icon, texture, info)
	icon:SetTexture(texture);
	if (info.tCoordLeft) then
		icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
	else
		icon:SetTexCoord(0, 1, 0, 1);
	end
	if (info.tSizeX) then
		icon:SetWidth(info.tSizeX);
	else
		icon:SetWidth(16);
	end
	if (info.tSizeY) then
		icon:SetHeight(info.tSizeY);
	else
		icon:SetHeight(16);
	end
	icon:Show();
end

function lib:UIDropDownMenu_SetSelectedName(frame, name, useValue)
	frame.selectedName = name;
	frame.selectedID = nil;
	frame.selectedValue = nil;
	lib:UIDropDownMenu_Refresh(frame, useValue);
end

function lib:UIDropDownMenu_SetSelectedValue(frame, value, useValue)
	-- useValue will set the value as the text, not the name
	frame.selectedName = nil;
	frame.selectedID = nil;
	frame.selectedValue = value;
	lib:UIDropDownMenu_Refresh(frame, useValue);
end

function lib:UIDropDownMenu_SetSelectedID(frame, id, useValue)
	frame.selectedID = id;
	frame.selectedName = nil;
	frame.selectedValue = nil;
	lib:UIDropDownMenu_Refresh(frame, useValue);
end

function lib:UIDropDownMenu_GetSelectedName(frame)
	return frame.selectedName;
end

function lib:UIDropDownMenu_GetSelectedID(frame)
	if (frame.selectedID) then
		return frame.selectedID;
	else
		local listFrame = _G["LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MENU_LEVEL];
		for i = 1, listFrame.numButtons do
			local button = _G["LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i];
			-- See if checked or not
			if (lib:UIDropDownMenu_GetSelectedName(frame)) then
				if (button:GetText() == lib:UIDropDownMenu_GetSelectedName(frame)) then
					return i;
				end
			elseif (lib:UIDropDownMenu_GetSelectedValue(frame)) then
				if (button.value == lib:UIDropDownMenu_GetSelectedValue(frame)) then
					return i;
				end
			end
		end
	end
end

function lib:UIDropDownMenu_GetSelectedValue(frame)
	return frame.selectedValue;
end

function lib:HideDropDownMenu(level)
	local listFrame = _G["LSOL_DropDownList" .. level];
	listFrame:Hide();
end

function lib:ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button,
                                autoHideDelay)
	if (not level) then
		level = 1;
	end
	delegateFrame:SetAttribute("createframes-level", level);
	delegateFrame:SetAttribute("createframes-index", 0);
	delegateFrame:SetAttribute("createframes", true);
	LSOL_UIDROPDOWNMENU_MENU_LEVEL = level;
	LSOL_UIDROPDOWNMENU_MENU_VALUE = value;
	local listFrameName = "LSOL_DropDownList" .. level;
	local listFrame = _G[listFrameName];
	if (WoWRetail) then
		lib:UIDropDownMenu_ClearCustomFrames(listFrame);
	end

	local tempFrame;
	local point, relativePoint, relativeTo;
	if (not dropDownFrame) then
		tempFrame = button:GetParent();
	else
		tempFrame = dropDownFrame;
	end
	if (listFrame:IsShown() and (LSOL_UIDROPDOWNMENU_OPEN_MENU == tempFrame)) then
		listFrame:Hide();
	else
		-- Set the dropdownframe scale
		local uiScale;
		local uiParentScale = UIParent:GetScale();
		if (GetCVar("useUIScale") == "1") then
			uiScale = tonumber(GetCVar("uiscale"));
			if (uiParentScale < uiScale) then
				uiScale = uiParentScale;
			end
		else
			uiScale = uiParentScale;
		end
		listFrame:SetScale(uiScale);

		-- Hide the listframe anyways since it is redrawn OnShow()
		listFrame:Hide();

		-- Frame to anchor the dropdown menu to
		local anchorFrame;

		-- Display stuff
		-- Level specific stuff
		if (level == 1) then
			delegateFrame:SetAttribute("openmenu", dropDownFrame);
			listFrame:ClearAllPoints();
			-- If there's no specified anchorName then use left side of the dropdown menu
			if (not anchorName) then
				-- See if the anchor was set manually using setanchor
				if (dropDownFrame.xOffset) then
					xOffset = dropDownFrame.xOffset;
				end
				if (dropDownFrame.yOffset) then
					yOffset = dropDownFrame.yOffset;
				end
				if (dropDownFrame.point) then
					point = dropDownFrame.point;
				end
				if (dropDownFrame.relativeTo) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = GetChild(LSOL_UIDROPDOWNMENU_OPEN_MENU, LSOL_UIDROPDOWNMENU_OPEN_MENU:GetName(), "Left");
				end
				if (dropDownFrame.relativePoint) then
					relativePoint = dropDownFrame.relativePoint;
				end
			elseif (anchorName == "cursor") then
				relativeTo = nil;
				local cursorX, cursorY = GetCursorPosition();
				cursorX = cursorX / uiScale;
				cursorY = cursorY / uiScale;

				if (not xOffset) then
					xOffset = 0;
				end
				if (not yOffset) then
					yOffset = 0;
				end
				xOffset = cursorX + xOffset;
				yOffset = cursorY + yOffset;
			else
				-- See if the anchor was set manually using setanchor
				if (dropDownFrame.xOffset) then
					xOffset = dropDownFrame.xOffset;
				end
				if (dropDownFrame.yOffset) then
					yOffset = dropDownFrame.yOffset;
				end
				if (dropDownFrame.point) then
					point = dropDownFrame.point;
				end
				if (dropDownFrame.relativeTo) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = anchorName;
				end
				if (dropDownFrame.relativePoint) then
					relativePoint = dropDownFrame.relativePoint;
				end
			end
			if (not xOffset or not yOffset) then
				xOffset = 8;
				yOffset = 22;
			end
			if (not point) then
				point = "TOPLEFT";
			end
			if (not relativePoint) then
				relativePoint = "BOTTOMLEFT";
			end
			listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
		else
			if (not dropDownFrame) then
				dropDownFrame = LSOL_UIDROPDOWNMENU_OPEN_MENU;
			end
			listFrame:ClearAllPoints();
			-- If this is a dropdown button, not the arrow anchor it to itself
			if (strsub(button:GetParent():GetName(), 0, 14) == "LSOL_DropDownList" and strlen(button:GetParent():GetName()) == 15
				) then
				anchorFrame = button;
			else
				anchorFrame = button:GetParent();
			end
			point = "TOPLEFT";
			relativePoint = "TOPRIGHT";
			listFrame:SetPoint(point, anchorFrame, relativePoint, 0, 0);
		end

		if dropDownFrame.hideBackdrops then
			_G[listFrameName .. "Backdrop"]:Hide();
			_G[listFrameName .. "MenuBackdrop"]:Hide();
		else
			-- Change list box appearance depending on display mode
			if (dropDownFrame and dropDownFrame.displayMode == "MENU") then
				_G[listFrameName .. "Backdrop"]:Hide();
				_G[listFrameName .. "MenuBackdrop"]:Show();
			else
				_G[listFrameName .. "Backdrop"]:Show();
				_G[listFrameName .. "MenuBackdrop"]:Hide();
			end
		end
		if (WoWClassicEra or WoWClassicTBC) then
			dropDownFrame.menuList = menuList;
		end

		lib:UIDropDownMenu_Initialize(dropDownFrame, dropDownFrame.initialize, nil, level, menuList);
		-- If no items in the drop down don't show it
		if (listFrame.numButtons == 0) then
			return;
		end

		if (WoWRetail) then
			listFrame.onShow = dropDownFrame.listFrameOnShow;
		end

		-- Check to see if the dropdownlist is off the screen, if it is anchor it to the top of the dropdown button
		listFrame:Show();
		-- Hack since GetCenter() is returning coords relative to 1024x768
		local x, y = listFrame:GetCenter();
		-- Hack will fix this in next revision of dropdowns
		if (not x or not y) then
			listFrame:Hide();
			return;
		end

		listFrame.onHide = dropDownFrame.onHide;

		--  We just move level 1 enough to keep it on the screen. We don't necessarily change the anchors.
		if (level == 1) then
			local offLeft = listFrame:GetLeft() / uiScale;
			local offRight = (GetScreenWidth() - listFrame:GetRight()) / uiScale;
			local offTop = (GetScreenHeight() - listFrame:GetTop()) / uiScale;
			local offBottom = listFrame:GetBottom() / uiScale;

			local xAddOffset, yAddOffset = 0, 0;
			if (offLeft < 0) then
				xAddOffset = -offLeft;
			elseif (offRight < 0) then
				xAddOffset = offRight;
			end

			if (offTop < 0) then
				yAddOffset = offTop;
			elseif (offBottom < 0) then
				yAddOffset = -offBottom;
			end

			listFrame:ClearAllPoints();
			if (anchorName == "cursor") then
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			else
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			end
		else
			-- Determine whether the menu is off the screen or not
			local offscreenY, offscreenX;
			if ((y - listFrame:GetHeight() / 2) < 0) then
				offscreenY = 1;
			end
			if (listFrame:GetRight() > GetScreenWidth()) then
				offscreenX = 1;
			end
			if (offscreenY and offscreenX) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = -14;
			elseif (offscreenY) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				xOffset = 0;
				yOffset = -14;
			elseif (offscreenX) then
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = 14;
			else
				xOffset = 0;
				yOffset = 14;
			end

			listFrame:ClearAllPoints();
			listFrame.parentLevel = tonumber(strmatch(anchorFrame:GetName(), "LSOL_DropDownList(%d+)"));
			listFrame.parentID = anchorFrame:GetID();
			listFrame:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset);
		end

		if (WoWClassicEra or WoWClassicTBC) then
			if (autoHideDelay and tonumber(autoHideDelay)) then
				listFrame.showTimer = autoHideDelay;
				listFrame.isCounting = 1;
			end
		end
	end
end

function lib:CloseDropDownMenus(level)
	if (not level) then
		level = 1;
	end
	for i = level, LSOL_UIDROPDOWNMENU_MAXLEVELS do
		_G["LSOL_DropDownList" .. i]:Hide();
	end
	-- yes, we also want to close the menus which created by built-in UIDropDownMenus
	for i = level, UIDROPDOWNMENU_MAXLEVELS do
		_G["DropDownList" .. i]:Hide();
	end
end

local function containsMouse()
	local result = false

	for i = 1, LSOL_UIDROPDOWNMENU_MAXLEVELS do
		local dropdown = _G["LSOL_DropDownList" .. i];
		if dropdown:IsShown() and dropdown:IsMouseOver() then
			result = true;
		end
	end
	for i = 1, UIDROPDOWNMENU_MAXLEVELS do
		local dropdown = _G["DropDownList" .. i];
		if dropdown:IsShown() and dropdown:IsMouseOver() then
			result = true;
		end
	end
	if LSOL_UIDROPDOWNMENU_OPEN_MENU and LSOL_UIDROPDOWNMENU_OPEN_MENU.Button:IsMouseOver() then
		result = true;
	end

	return result;
end

function lib:containsMouse()
	containsMouse()
end

-- GLOBALSOL_MOUSE_DOWN event is only available in retail, not classic
function lib:UIDropDownMenu_HandleGlobalMouseEvent(button, event)
	if event == "GLOBALSOL_MOUSE_DOWN" and (button == "LeftButton" or button == "RightButton") then
		if not containsMouse() then
			lib:CloseDropDownMenus();
		end
	end
end

do
	if lib and WoWRetail then
		hooksecurefunc("UIDropDownMenu_HandleGlobalMouseEvent", function(button, event)
			lib:UIDropDownMenu_HandleGlobalMouseEvent(button, event)
		end)

	end
end

function lib:UIDropDownMenu_ClearCustomFrames(self)
	if self.customFrames then
		for index, frame in ipairs(self.customFrames) do
			frame:Hide();
		end

		self.customFrames = nil;
	end
end

function lib:UIDropDownMenu_SetWidth(frame, width, padding)
	local frameName = frame:GetName();
	GetChild(frame, frameName, "Middle"):SetWidth(width);
	local defaultPadding = 25;
	if (padding) then
		frame:SetWidth(width + padding);
	else
		frame:SetWidth(width + defaultPadding + defaultPadding);
	end
	if (padding) then
		GetChild(frame, frameName, "Text"):SetWidth(width);
	else
		GetChild(frame, frameName, "Text"):SetWidth(width - defaultPadding);
	end
	frame.noResize = 1;
end

function lib:UIDropDownMenu_SetButtonWidth(frame, width)
	local frameName = frame:GetName();
	if (width == "TEXT") then
		width = GetChild(frame, frameName, "Text"):GetWidth();
	end

	GetChild(frame, frameName, "Button"):SetWidth(width);
	frame.noResize = 1;
end

function lib:UIDropDownMenu_SetText(frame, text)
	local frameName = frame:GetName();
	GetChild(frame, frameName, "Text"):SetText(text);
end

function lib:UIDropDownMenu_GetText(frame)
	local frameName = frame:GetName();
	return GetChild(frame, frameName, "Text"):GetText();
end

function lib:UIDropDownMenu_ClearAll(frame)
	-- Previous code refreshed the menu quite often and was a performance bottleneck
	frame.selectedID = nil;
	frame.selectedName = nil;
	frame.selectedValue = nil;
	lib:UIDropDownMenu_SetText(frame, "");

	local button, checkImage, uncheckImage;
	for i = 1, LSOL_UIDROPDOWNMENU_MAXBUTTONS do
		button = _G["LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i];
		button:UnlockHighlight();

		checkImage = _G["LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i .. "Check"];
		checkImage:Hide();
		uncheckImage = _G["LSOL_DropDownList" .. LSOL_UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i .. "UnCheck"];
		uncheckImage:Hide();
	end
end

function lib:UIDropDownMenu_JustifyText(frame, justification, customXOffset)
	local frameName = frame:GetName();
	local text = GetChild(frame, frameName, "Text");
	text:ClearAllPoints();
	if (justification == "LEFT") then
		text:SetPoint("LEFT", GetChild(frame, frameName, "Left"), "LEFT", customXOffset or 27, 2);
		text:SetJustifyH("LEFT");
	elseif (justification == "RIGHT") then
		text:SetPoint("RIGHT", GetChild(frame, frameName, "Right"), "RIGHT", customXOffset or -43, 2);
		text:SetJustifyH("RIGHT");
	elseif (justification == "CENTER") then
		text:SetPoint("CENTER", GetChild(frame, frameName, "Middle"), "CENTER", customXOffset or -5, 2);
		text:SetJustifyH("CENTER");
	end
end

function lib:UIDropDownMenu_SetAnchor(dropdown, xOffset, yOffset, point, relativeTo, relativePoint)
	dropdown.xOffset = xOffset;
	dropdown.yOffset = yOffset;
	dropdown.point = point;
	dropdown.relativeTo = relativeTo;
	dropdown.relativePoint = relativePoint;
end

function lib:UIDropDownMenu_GetCurrentDropDown()
	if (LSOL_UIDROPDOWNMENU_OPEN_MENU) then
		return LSOL_UIDROPDOWNMENU_OPEN_MENU;
	elseif (LSOL_UIDROPDOWNMENU_INIT_MENU) then
		return LSOL_UIDROPDOWNMENU_INIT_MENU;
	end
end

function lib:UIDropDownMenuButton_GetChecked(self)
	return _G[self:GetName() .. "Check"]:IsShown();
end

function lib:UIDropDownMenuButton_GetName(self)
	return _G[self:GetName() .. "NormalText"]:GetText();
end

function lib:UIDropDownMenu_DisableButton(level, id)
	_G["LSOL_DropDownList" .. level .. "Button" .. id]:Disable();
end

function lib:UIDropDownMenu_EnableButton(level, id)
	_G["LSOL_DropDownList" .. level .. "Button" .. id]:Enable();
end

function lib:UIDropDownMenu_SetButtonText(level, id, text, colorCode)
	local button = _G["LSOL_DropDownList" .. level .. "Button" .. id];
	if (colorCode) then
		button:SetText(colorCode .. text .. "|r");
	else
		button:SetText(text);
	end
end

function lib:UIDropDownMenu_SetButtonNotClickable(level, id)
	_G["LSOL_DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontHighlightSmallLeft);
end

function lib:UIDropDownMenu_SetButtonClickable(level, id)
	_G["LSOL_DropDownList" .. level .. "Button" .. id]:SetDisabledFontObject(GameFontDisableSmallLeft);
end

function lib:UIDropDownMenu_DisableDropDown(dropDown)
	lib:UIDropDownMenu_SetDropDownEnabled(dropDown, false);
end

function lib:UIDropDownMenu_EnableDropDown(dropDown)
	lib:UIDropDownMenu_SetDropDownEnabled(dropDown, true);
end

function lib:UIDropDownMenu_SetDropDownEnabled(dropDown, enabled)
	local dropDownName = dropDown:GetName();
	local label = GetChild(dropDown, dropDownName, "Label");
	if label then
		label:SetVertexColor((enabled and NORMAL_FONT_COLOR or GRAY_FONT_COLOR):GetRGB());
	end

	local icon = GetChild(dropDown, dropDownName, "Icon");
	if icon then
		icon:SetVertexColor((enabled and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR):GetRGB());
	end

	local text = GetChild(dropDown, dropDownName, "Text");
	if text then
		text:SetVertexColor((enabled and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR):GetRGB());
	end

	local button = GetChild(dropDown, dropDownName, "Button");
	if button then
		button:SetEnabled(enabled);
	end

	if enabled then
		dropDown.isDisabled = nil;
	else
		dropDown.isDisabled = 1;
	end
end

function lib:UIDropDownMenu_IsEnabled(dropDown)
	return not dropDown.isDisabled;
end

function lib:UIDropDownMenu_GetValue(id)
	--Only works if the dropdown has just been initialized, lame, I know =(
	local button = _G["LSOL_DropDownList1Button" .. id];
	if (button) then
		return _G["LSOL_DropDownList1Button" .. id].value;
	else
		return nil;
	end
end

lib.DropDownMenuButtonMixin = {}

function lib.DropDownMenuButtonMixin:OnEnter(...)
	ExecuteFrameScript(self:GetParent(), "OnEnter", ...);
end

function lib.DropDownMenuButtonMixin:OnLeave(...)
	ExecuteFrameScript(self:GetParent(), "OnLeave", ...);
end

function lib.DropDownMenuButtonMixin:OnMouseDown(button)
	if self:IsEnabled() then
		lib:ToggleDropDownMenu(nil, nil, self:GetParent());
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
end


local getArgs, doneArgs
do
	local tmp = {}
	function getArgs(...)
		assert(next(tmp) == nil)
		for i = 1, select('#', ...), 2 do
			local k, v = select(i, ...)
			if type(k) ~= "string" then
				error(("Received a bad key, must be a %q, got %q (%s)"):format("string", type(k), tostring(k)), 3)
			elseif tmp[k] ~= nil then
				error(("Received key %q twice"):format(k), 3)
			end
			tmp[k] = v
		end
		return tmp
	end

	function doneArgs(args)
		assert(args == tmp)
		for k in pairs(args) do
			args[k] = nil
		end
		return nil
	end
end

local WotLK = select(4, GetBuildInfo()) < 90000
local ClassicERA = select(4, GetBuildInfo()) < 20000

local panels = {}
LibSimpleOptions.panels = panels
local panelMeta = {}
LibSimpleOptions.panelMeta = panelMeta

for funcName in pairs(panelMeta) do
	for panel in pairs(panels) do
		panel[funcName] = nil
	end
	panelMeta[funcName] = nil
end

do
	local function update(control, ...)

		if (...) ~= control.value then
			control:SetValue(...)
		end
	end

	function panelMeta:Refresh()
		for control in pairs(self.controls) do
			if control.getFunc then
				update(control, control.getFunc())
			end
		end
		if self.refreshFunc then
			self:refreshFunc()
		end
	end

	local function panel_okay(self)
		--GameMenuFrame:Hide()
		for control in pairs(self.controls) do
			control.oldValue = control.value
			if control.okayFunc then
				control.okayFunc()
			end
		end
	end

	local function panel_default(self)
		for control in pairs(self.controls) do
			control:SetValue(control.default)
			if control.defaultFunc then
				control.defaultFunc()
			end
		end
	end

	local function makePanel(name, parentName, controlCreationFunc, panelOpenCmd, ATTversion)
		local panel
		if not parentName then
			panel = CreateFrame("Frame", name .. "_Panel", UIParent , "PortraitFrameTemplate")
		else
			panel = CreateFrame("Frame", parentName .. "_Panel_" .. name, UIParent, "PortraitFrameTemplate")
		end

		tinsert(UISpecialFrames, panel:GetName())
		panel:SetFrameLevel(panel:GetFrameLevel() + 3)
		panel:SetScale(1.5)
		panel:EnableMouse(true)
        panel:SetMovable(true)
		panel:SetClampedToScreen(true)

		panel:SetFrameStrata("DIALOG")
		--panel:SetPortraitTextureRaw("Interface\\AddOns\\ATT\\libs\\icon2")
		--panel:GetPortrait():SetTexture("Interface\\AddOns\\ATT\\libs\\icon2")
		--panel.Bg:SetTexture("")
		panel.Bg:SetAlpha(0.7)
		panel.noBG = panel:CreateTexture("noBG", "BACKGROUND", nil, -8)
        panel.noBG:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")  
		panel.noBG:SetAllPoints()

		local icon = panel:CreateTexture("$parentIcon", "ARTWORK", nil,-7)
		icon:SetSize(60,60)		
	    icon:SetPoint("TOPLEFT",-5,7)
		icon:SetTexture("Interface\\AddOns\\ATT\\libs\\icon2")
		icon:SetTexCoord(0,1,0,1)

		panel.title = _G[name .. "_PanelTitleText"]
		panel.title:SetText("Ability Team Tracker")

		panels[panel] = true
		panel.name = name
		panel.controls = {}
		panel.parent = parentName

		panel:SetWidth(694)
		panel:SetHeight(655)
		panel:SetPoint("CENTER",0,0)
		
		panel.controlCreationFunc = controlCreationFunc
		panel:SetScript("OnShow", function(self) self:ClearAllPoints() self:SetPoint("CENTER"); end)
		--panel:SetScale(1.02)
		local topFrame = CreateFrame("Frame", name .. "_TOPPanel", panel)
		if WotLK then 
		   topFrame:SetSize(panel:GetSize())
		   topFrame:SetPoint(panel:GetPoint())
		   topFrame:SetFrameLevel(panel:GetFrameLevel() + 3)
	   else
		   topFrame:SetSize(panel.NineSlice.TopEdge:GetSize())
		   topFrame:SetPoint(panel.NineSlice.TopEdge:GetPoint())
		   topFrame:SetFrameLevel(panel:GetFrameLevel() + 3)
	   end	

	   topFrame:SetScript("OnMouseDown",
		function(self, button)
			if button == "LeftButton" then
				panel:StartMoving();
			end
		end)
		topFrame:SetScript("OnMouseUp",
		function(self, button)
			if button == "LeftButton"  then
				panel:StopMovingOrSizing();
			end
		end)
	
		for k, v in pairs(panelMeta) do
			panel[k] = v
		end

		local backPanel = CreateFrame("Frame", name .. "_ButtonPanel")
		backPanel.name = name
		backPanel.parent = parentName

		local title = backPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetText(name)
		title:SetJustifyH("LEFT")
		title:SetJustifyV("TOP")
		title:SetPoint("TOPLEFT", 16, -16)

		local subText = backPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		subText:SetText("|cff33ff99Version:|r |cffFF4500v" ..ATTversion .. "|r. "..panelOpenCmd)
		subText:SetNonSpaceWrap(true)
		subText:SetJustifyH("LEFT")
		subText:SetJustifyV("TOP")
		subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
		subText:SetPoint("RIGHT", -32, 0)

		local button = CreateFrame("Button", name, backPanel, "UIPanelButtonTemplate")
		button:SetText("Open Options Panel")
		button:SetSize(140, 40);
		button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -60)
		button:SetScript("OnClick", function(self)
			panel:Show()
		end)

		if InterfaceOptions_AddCategory then
			InterfaceOptions_AddCategory(backPanel)
				else
			local category, layout = Settings.RegisterCanvasLayoutCategory(backPanel, backPanel.name);
			Settings.RegisterAddOnCategory(category);
		end
		
		return panel
	end

	function LibSimpleOptions.AddOptionsPanel(name, controlCreationFunc, panelOpenCmd, ATTversion)
		return makePanel(name, nil, controlCreationFunc, panelOpenCmd, ATTversion)
	end

	function LibSimpleOptions.AddSuboptionsPanel(parentName, name, controlCreationFunc)
		return makePanel(name, parentName, controlCreationFunc)
	end
end

function panelMeta:MakeTitleTextAndSubText(titleText, subTextText)
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetText(titleText)
	title:SetJustifyH("LEFT")
	title:SetJustifyV("TOP")
	title:SetPoint("TOPLEFT", 16, "TOPRIGHT", -16)
	--title:SetPoint("TOP", self, "LEFT", 0, -8)

	local subText = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	subText:SetText(subTextText)
	subText:SetNonSpaceWrap(true)
	subText:SetJustifyH("LEFT")
	subText:SetJustifyV("TOP")
	subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subText:SetPoint("RIGHT", -32, 0)

	return title, subText
end

do
	local backdrop = {
		bgFile = [=[Interface\Buttons\WHITE8X8]=],
		edgeFile = [=[Interface\Tooltips\UI-Tooltip-Border]=],
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	}

	function panelMeta:MakeScrollFrame()
		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_ScrollFrame" .. i
		until not _G[name]
		local scrollFrame = CreateFrame("ScrollFrame", name, self, "UIPanelScrollFrameTemplate")
		scrollFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)
		local bg = CreateFrame("Frame", nil, scrollFrame)
		bg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -3, 3)
		bg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 3, -3)
		bg:SetBackdrop(backdrop)
		bg:SetBackdropColor(0, 0, 0, 0.25)
		local scrollChild = CreateFrame("Frame", name .. "_Child", scrollFrame)
		scrollFrame:SetScrollChild(scrollChild)
		scrollChild:SetWidth(1)
		scrollChild:SetHeight(1)
		return scrollFrame, scrollChild
	end
end

do
	local function slider_OnValueChanged(self)
		self.value = self:GetValue()
		self:SetValue(self.value)
		self.editbox:SetText(self.value)
	end

	local function slider_SetValue(self, value)
		local value = floor(value)
		getmetatable(self).__index.SetValue(self, value)
		self.value = value
		self.changeFunc(value)
		if self.currentText then
			self.currentText:SetText(self.currentTextFunc(value))
		end
	end

	local function sliderBox_SetValue(self)
		local value = floor(self.editbox:GetNumber())
		local minValue, maxValue = self:GetMinMaxValues()
		if value < minValue then value = minValue end
		if value > maxValue then value = maxValue end
		getmetatable(self).__index.SetValue(self, value)
		self.value = value
		self.changeFunc(value)
		if self.currentText then
			self.currentText:SetText(self.currentTextFunc(value))
		end
	end

	function panelMeta:MakeSlider(...)
		local args = getArgs(...)

		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Slider" .. i
		until not _G[name]
		local slider = CreateFrame("Slider", name, args.extra or self, "OptionsSliderTemplate") -- OptionsSliderTemplate

		--if WotLK then _G[slider:GetName()]:SetWidth(135) end
		-- if args.extra then _G[slider:GetName()]:SetWidth(200) else _G[slider:GetName()]:SetWidth(135) end
		self.controls[slider] = true
		slider.tooltipText = args.description
		slider.minValue = args.minText
		
		slider:SetHeight(20)
		slider:SetWidth(140)
        slider:SetPoint("CENTER")
        slider:SetMinMaxValues(args.minValue, args.maxValue)
        slider.High = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -10)
        slider.Low = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -10)
        slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        slider.Text:SetPoint("BOTTOM", slider, "TOP")
        slider.Text:SetText(args.name)
        slider.High:SetText(args.maxText)
        slider.Low:SetText(args.minText)

		local current
		if args.getFunc then
			slider.getFunc = args.getFunc
			current = args.getFunc()
		else
			current = args.current
		end

		if args.currentTextFunc then
			slider.currentTextFunc = args.currentTextFunc
			local currentText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			slider.currentText = currentText
			slider.editbox = CreateFrame("EditBox", name .. "EditBox", slider, "InputBoxTemplate")
			if args.extra then 
		        slider.editbox:SetPoint("LEFT", slider, "RIGHT", 15, 0)
			   --slider.editbox:SetPoint("TOP", slider, "CENTER", 0, -20)
				--_G[slider:GetName()]:SetWidth(160)
			else
				slider.editbox:SetPoint("TOP", slider, "CENTER", 0, -20)
			end
			slider.editbox:SetSize(args.sizeOf or 28, 5)
			--slider.editbox:SetNumeric(true)
			slider.editbox:SetMovable(false);
			slider.editbox:SetAutoFocus(false);
			slider.editbox:SetMultiLine(false);
			slider.editbox:SetText(args.currentTextFunc(current))
			slider.editbox:SetHitRectInsets(0, -10, -10, -10)
		end


		slider.default = args.default
		slider:SetMinMaxValues(args.minValue, args.maxValue)
		if args.step then
			slider:SetValueStep(args.step)
		end

		slider.oldValue = current
		slider.value = current
		slider:SetValue(current)

		slider.changeFunc = args.setFunc
		slider.getCurrent = args.getCurrent
		slider.SetValue = slider_SetValue
		slider.editbox:SetScript("OnEnterPressed", function() sliderBox_SetValue(slider) end)
		slider.editbox:SetScript("OnTextChanged", function(self, userInput) local newText = self:GetText() if userInput and (not tonumber(newText) and newText ~= "-" ) then slider.editbox:SetText(gsub(newText, "[^0-9.-]+", "")) end end)
		slider.editbox:SetScript("OnShow", function(self) self:SetText(self:GetParent().value) end)

		slider:SetScript("OnValueChanged", slider_OnValueChanged)
		slider:SetScript('OnEnter', function() GameTooltip:ClearLines();
			GameTooltip:SetOwner(slider, "ANCHOR_TOP")
			GameTooltip:SetText(slider.tooltipText, nil, nil, nil, nil, 1)
			GameTooltip:Show()
		end)
		slider:SetScript('OnLeave', function() GameTooltip:ClearLines() GameTooltip:Hide() end)

		slider.okayFunc = args.okayFunc
		slider.cancelFunc = args.cancelFunc
		slider.defaultFunc = args.defaultFunc
		args = doneArgs(args)
		return slider
	end
end

local function generic_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
end

local function generic_OnLeave(self)
	GameTooltip:Hide()
end

do
	local function dropDown_SetValue(self, value)
		self.value = value
		lib:UIDropDownMenu_SetSelectedValue(self, value)
		self.changeFunc(value)
	end

	local helper__num, helper__values
	local function helper()
		local value, text = helper__values[helper__num], helper__values[helper__num + 1]
		if value == nil then
			helper__num, helper__values = nil, nil
			return nil
		end
		helper__num = helper__num + 2
		return value, text
	end

	local function get_iter(values)
		if type(values) == "function" then
			return values
		end
		helper__num = 1
		helper__values = values
		return helper
	end

	local SetValue_wrapper
		function SetValue_wrapper(self, ...)
			return dropDown_SetValue(...)
		end

		local function dropDown_menu(self)
		    local info = lib:UIDropDownMenu_CreateInfo()

			for value, text in get_iter(self.values) do
				info.text = text
				info.value = value
				info.checked = self.value == value
				info.func = SetValue_wrapper
				info.arg1 = self
				info.arg2 = value
				info.minWidth = 128
			    lib:UIDropDownMenu_AddButton(info)
			end
		end

	function panelMeta:MakeDropDown(...)
		local args = getArgs(...)
		
		local name
		local i = 0
		repeat
			i = i + 1
			name = "ATT_DropDown" .. i
		until not _G[name]


		--local dropDown = CreateFrame("Frame", name, args.extra or self, BackdropTemplateMixin and "UIDropDownMenuTemplate, BackdropTemplate"  or "UIDropDownMenuTemplate")
	
local dropDown	

if wowtocversion >= 110000 then
    dropDown = CreateFrame("DropdownButton", name, args.extra or self, "WowStyle1DropdownTemplate")
	dropDown:SetDefaultText("Select Value")
	dropDown:SetPoint("CENTER")
	dropDown:SetWidth(150)
	dropDown.values = args.values
	dropDown.hasIcons = args.iconsFunc
	
	if args.getFunc then
		dropDown.current = args.getFunc
	else
		dropDown.current = args.getCurrent
	end

	dropDown.SetValue = args.setFunc
    dropDown.getCurrent = args.getCurrent

	 local function IsSelected(index)  return dropDown.current() == index; end
	 local function SetSelected(index)  dropDown.SetValue(index) end

	local function GeneratorFunction(dropDown, rootDescription)
		for index = 1, #dropDown.values/2 do
			local value = dropDown.values[index*2-1]
			local title = dropDown.values[index*2]
			local icon, isClass 
			if dropDown.hasIcons then icon, isClass = dropDown.hasIcons(value) end

			local radio = rootDescription:CreateRadio(title, IsSelected, SetSelected, value);

		    if icon then
			    radio:AddInitializer(function(button, description, menu)
				local rightTexture = button:AttachTexture();
				rightTexture:SetSize(14, 14);
				rightTexture:SetPoint("RIGHT");
				if isClass then rightTexture:SetAtlas(icon) else rightTexture:SetTexture(icon) end
			    end );
		    end
		end
	end

	dropDown:SetupMenu(GeneratorFunction);

	if args.name ~= "" then
		local label = dropDown:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		label:SetText(args.name)
		--label:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 20, 3)
		label:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 0, 3)
	end

	dropDown.initialize = function()  dropDown.SetValue(dropDown.current()) dropDown:GenerateMenu() end --dropDown.SetValue(dropDown.current()) --dropDown:GenerateMenu()
	dropDown.doRefresh = function() dropDown:GenerateMenu() if dropDown.update then dropDown.SetValue(dropDown.current()) end end

	args = doneArgs(args)
    
else	
        dropDown = lib:Create_UIDropDownMenu(name, args.extra or self)
		dropDown.icons = args.iconsFunc

		--local useColor = color and color or HIGHLIGHT_FONT_COLOR;
		--local title = useColor:WrapTextInColorCode(dropDown.values[index*2])

		self.controls[dropDown] = true
		if args.name ~= "" then
			local label = dropDown:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			label:SetText(args.name)
			--label:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 20, 3)
			label:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 20, 3)
		end
		dropDown.tooltipText = args.description
		dropDown.values = args.values
		lib:UIDropDownMenu_Initialize(dropDown, function()
			dropDown_menu(dropDown)
		end)

		lib:UIDropDownMenu_JustifyText(dropDown, "CENTER")
		lib:UIDropDownMenu_SetWidth(dropDown, 120)


		local current
		if args.getFunc then
			dropDown.getFunc = args.getFunc
			current = args.getFunc()
		else
			current = args.current
		end

		dropDown.doRefresh = function()
			lib:UIDropDownMenu_Initialize(dropDown, function()
				dropDown_menu(dropDown)
				lib:UIDropDownMenu_SetSelectedValue(dropDown, dropDown.getCurrent())
			end)
		end

		dropDown.getCurrent = args.getCurrent
		lib:UIDropDownMenu_SetSelectedValue(dropDown, current)

		dropDown.default = args.default
		dropDown.value = args.current
		dropDown.oldValue = args.current
		dropDown.changeFunc = args.setFunc
		dropDown.SetValue = dropDown_SetValue
		dropDown:EnableMouse(true)
		dropDown:SetScript("OnEnter", generic_OnEnter)
		dropDown:SetScript("OnLeave", generic_OnLeave)
		dropDown.okayFunc = args.okayFunc
		dropDown.cancelFunc = args.cancelFunc
		dropDown.defaultFunc = args.defaultFunc
		args = doneArgs(args)
	end
		return dropDown
		
	end

end

do
	local function donothing() end

	local function button_OnClick(self)
		self.clickFunc()
	end

	function panelMeta:MakeButton(...)
		local args = getArgs(...)

		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Button" .. i
		until not _G[name]

		local button = CreateFrame("Button", name, args.extra or self, "UIPanelButtonTemplate")

		self.controls[button] = true
		button:SetText(args.name)
		button.tooltipText = args.description

		if args.newsize == 1 then
			button:SetSize(80, 30);
			button.Text:SetFont(GameFontHighlight:GetFont(), 10)
		elseif args.newsize == 2 then
			button:SetSize(65, 30);
		elseif args.newsize == 3 then
			button:SetSize(140, 25);
		else 
			button:SetSize(90, 30);
		end
		button.Text:SetPoint("LEFT", 4, 0)
        button.Text:SetPoint("RIGHT", -4, 0)
		button.SetValue = donothing
		button.clickFunc = args.func
		button:SetScript("OnClick", button_OnClick)
		button:SetScript("OnEnter", generic_OnEnter)
		button:SetScript("OnLeave", generic_OnLeave)
		args = doneArgs(args)
		return button
	end
end

do
	local function toggle_SetValue(self, value)
		value = not not value
		self.changeFunc(value)
		self.value = value
		self:SetChecked(value)
	end

	local function toggle_OnClick(self)
		self:SetValue(not not self:GetChecked())
	end

	function panelMeta:MakeToggle(...)
		local args = getArgs(...)

		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Toggle" .. i
		until not _G[name]

		local toggle = CreateFrame("CheckButton", name, args.extra or self, "InterfaceOptionsCheckButtonTemplate")
		self.controls[toggle] = true
		if args.extra and args.extra:GetName() == "Visibility" then
			--_G[toggle:GetName() .. "Text"]:SetText("|T134269:16|t " .. args.name)
			_G[toggle:GetName() .. "Text"]:SetText(args.name)

		else
			_G[toggle:GetName() .. "Text"]:SetText(args.name)
		end
		toggle:SetHitRectInsets(0, -_G[toggle:GetName() .. "Text"]:GetStringWidth() - 1, 0, 0) --GetWidth()
		toggle.Text:SetFont(GameFontNormal:GetFont(), 12)
		toggle.Text:SetHeight(22)
		toggle.Text:SetPoint("LEFT", toggle, "RIGHT", 2, 0)

		toggle.tooltipText = args.description
		toggle.default = args.default
		local current
		if args.getFunc then
			toggle.getFunc = args.getFunc
			current = args.getFunc()
		else
			current = args.current
		end
		toggle.value = current
		toggle.oldValue = current
		toggle.changeFunc = args.setFunc
		toggle.SetValue = toggle_SetValue
		toggle:SetScript("OnClick", toggle_OnClick)

		toggle.getCurrent = args.getCurrent
		toggle:SetChecked(current)
		--toggle:SetScript("OnEnter", generic_OnEnter)
		--toggle:SetScript("OnLeave", generic_OnLeave)
		toggle:SetScript('OnEnter', function() GameTooltip:ClearLines();
			GameTooltip:SetOwner(toggle, "ANCHOR_TOP")
			GameTooltip:SetText(toggle.tooltipText, nil, nil, nil, nil, 1)
			GameTooltip:Show()
		end)
		toggle:SetScript('OnLeave', function() GameTooltip:ClearLines() GameTooltip:Hide() end)
		toggle.okayFunc = args.okayFunc
		toggle.cancelFunc = args.cancelFunc
		toggle.defaultFunc = args.defaultFunc
		args = doneArgs(args)

		return toggle
	end
end

do
	function panelMeta:UpdateSettings()
		local y = 0
		repeat
			y = y + 1
			local toggleName = self:GetName() .. "_Toggle" .. y
			local toggleFrame = _G[toggleName]
			if toggleFrame and toggleFrame:IsShown() and toggleFrame.getCurrent then
				toggleFrame:SetChecked(not not toggleFrame:getCurrent())
			end
		until not _G[toggleName]

		local x = 0
		repeat
			x = x + 1
			local sliderName = self:GetName() .. "_Slider" .. x
			local sliderFrame = _G[sliderName]
			if sliderFrame and sliderFrame:IsShown() and sliderFrame.getCurrent then
				sliderFrame:SetValue(sliderFrame:getCurrent())
				sliderFrame.currentText:SetText(sliderFrame.getCurrent())
			end
		until not _G[sliderName]

		local z = 0
		repeat
			z = z + 1
			local dropdownName = "ATT_DropDown" .. z
			local dropdownFrame = _G[dropdownName]
			if dropdownFrame and dropdownFrame:IsShown() and dropdownFrame.getCurrent then
				dropdownFrame.doRefresh(dropdownFrame)
			end
		until not _G[dropdownName]
	end
end

function LibSimpleOptions.AddSlashCommand(name, ...)

	local num = 0
	local name_upper = name:upper()
	for i = 1, select('#', ...) do
		local cmd = select(i, ...)
		num = num + 1
		_G["SLASH_" .. name_upper .. num] = cmd
		local cmd_lower = cmd:lower()
		if cmd_lower ~= cmd then
			num = num + 1
			_G["SLASH_" .. name_upper .. num] = cmd_lower
		end
	end
	_G.hash_SlashCmdList[name_upper] = nil
	_G.SlashCmdList[name_upper] = function()
		_G[name .. "_Panel"]:Show()
		--InterfaceOptionsFrame_OpenToCategory(name)
		--InterfaceOptionsFrame_OpenToCategory(name)
	end
end

for funcName, func in pairs(panelMeta) do
	LibSimpleOptions[funcName] = func
	for panel in pairs(panels) do
		panel[funcName] = func
	end
end
