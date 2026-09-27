
local MAJOR_VERSION = "LibATTSimpleOptions"
local MINOR_VERSION = 90005

if not LibStub then error(MAJOR_VERSION .. " requires LibStub") end
-- #AUTODOC_NAMESPACE LibSimpleOptions

local LibSimpleOptions, oldLib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not LibSimpleOptions then
	return
end
if oldLib then
	oldLib = {}
	for k, v in pairs(LibSimpleOptions) do
		LibSimpleOptions[k] = nil
		oldLib[k] = v
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

local WotLK = not not ToggleAchievementFrame

local panels
if oldLib then
	panels = oldLib.panels or {}
else
	panels = {}
end
LibSimpleOptions.panels = panels

local panelMeta
if oldLib then
	panelMeta = oldLib.panelMeta or {}
else
	panelMeta = {}
end

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

	local function makePanel(name, parentName, controlCreationFunc)
		local panel
		if not parentName then
			panel = CreateFrame("Frame", name .. "_Panel")
		else
			panel = CreateFrame("Frame", parentName .. "_Panel_" .. name)
		end
		panels[panel] = true

		panel.name = name
		panel.controls = {}
		panel.parent = parentName

		panel.okay = panel_okay
		panel.cancel = panel_cancel
		panel.default = panel_default

		InterfaceOptions_AddCategory(panel)

		panel.controlCreationFunc = controlCreationFunc
		panel:SetScript("OnShow", panel_OnShow)
		for k, v in pairs(panelMeta) do
			panel[k] = v
		end
		
		return panel
	end

	function LibSimpleOptions.AddOptionsPanel(name, controlCreationFunc)
		return makePanel(name, nil, controlCreationFunc)
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
	title:SetPoint("TOPLEFT", 16, -16)
	
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
		self:SetValue(self:GetValue())
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
	
	local function slider_SetValueLow(self, value)
	local value = tonumber(string.format("%.2f",value))
		getmetatable(self).__index.SetValue(self, value)
		self.value = value
		self.changeFunc(value)
		if self.currentText then
			self.currentText:SetText(self.currentTextFunc(value))
		end
	end

	function panelMeta:MakeSlider(...)
		local args = getArgs(...)
		if type(args.name) ~= "string" then
			error(("name must be %q, got %q (%s)"):format("string", type(args.name), tostring(args.name)), 2)
		elseif type(args.description) ~= "string" then
			error(("description must be %q, got %q (%s)"):format("string", type(args.description), tostring(args.description)), 2)
		elseif type(args.minText) ~= "string" then
			error(("minText must be %q, got %q (%s)"):format("string", type(args.minText), tostring(args.minText)), 2)
		elseif type(args.maxText) ~= "string" then
			error(("maxText must be %q, got %q (%s)"):format("string", type(args.maxText), tostring(args.maxText)), 2)
		elseif type(args.minValue) ~= "number" then
			error(("minValue must be %q, got %q (%s)"):format("number", type(args.minValue), tostring(args.minValue)), 2)
		elseif type(args.maxValue) ~= "number" then
			error(("maxValue must be %q, got %q (%s)"):format("number", type(args.maxValue), tostring(args.maxValue)), 2)
		elseif args.step and type(args.step) ~= "number" then
			error(("step must be %q or %q, got %q (%s)"):format("nil", "number", type(args.step), tostring(args.step)), 2)
		elseif type(args.default) ~= "number" then
			error(("default must be %q, got %q (%s)"):format("number", type(args.default), tostring(args.default)), 2)
		elseif args.default < args.minValue or args.default > args.maxValue then
			error(("default must be [%s, %s], got %s"):format(args.minValue, args.maxValue, tostring(args.default)), 2)
		elseif not args.current == not args.getFunc then
			error(("either current or getFunc must be supplied, but not both"), 2)
		elseif args.current and type(args.current) ~= "number" then
			error(("current must be %q, got %q (%s)"):format("number", type(args.current), tostring(args.current)), 2)
		elseif args.getFunc and type(args.getFunc) ~= "function" then
			error(("getFunc must be %q, got %q (%s)"):format("function", type(args.getFunc), tostring(args.getFunc)), 2)
		elseif type(args.setFunc) ~= "function" then
			error(("setFunc must be %q, got %q (%s)"):format("function", type(args.setFunc), tostring(args.setFunc)), 2)
		elseif args.currentTextFunc and type(args.currentTextFunc) ~= "function" then
			error(("currentTextFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.currentTextFunc), tostring(args.currentTextFunc)), 2)
		elseif args.okayFunc and type(args.okayFunc) ~= "function" then
			error(("okayFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.okayFunc), tostring(args.okayFunc)), 2)
		elseif args.cancelFunc and type(args.cancelFunc) ~= "function" then
			error(("cancelFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.cancelFunc), tostring(args.cancelFunc)), 2)
		elseif args.defaultFunc and type(args.defaultFunc) ~= "function" then
			error(("defaultFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.defaultFunc), tostring(args.defaultFunc)), 2)
		end
		
		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Slider" .. i
		until not _G[name]
		local slider = CreateFrame("Slider", name, args.extra or self, "OptionsSliderTemplate") 

	    if args.extra then _G[slider:GetName()]:SetWidth(200) else _G[slider:GetName()]:SetWidth(135) end
		self.controls[slider] = true
		slider.tooltipText = args.description

		_G[slider:GetName() .. "Text"]:SetText(args.name)
		_G[slider:GetName() .. "Text"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		_G[slider:GetName() .. "Low"]:SetText(args.minText)
		_G[slider:GetName() .. "Low"]:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		_G[slider:GetName() .. "High"]:SetText(args.maxText)
		_G[slider:GetName() .. "High"]:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)

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
			currentText:SetPoint("TOP", slider, "CENTER", 0, -8)
			currentText:SetText(args.currentTextFunc(current))
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
        slider.SetValue = (args.step and args.step >= 1 and slider_SetValue) or slider_SetValueLow
		slider:SetScript("OnValueChanged",slider_OnValueChanged)
		slider:SetScript('OnEnter', function() GameTooltip:ClearLines(); GameTooltip:SetOwner(slider, "ANCHOR_TOP")
		GameTooltip:SetText(slider.tooltipText, nil, nil, nil, nil, 1) GameTooltip:Show() end)
        slider:SetScript('OnLeave', function() GameTooltip:ClearLines()  GameTooltip:Hide()end)	
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
		MSA_DropDownMenu_SetSelectedValue(self, value)
		self.changeFunc(value)
	end
	local helper__num, helper__values
	local function helper()
		local value, text = helper__values[helper__num], helper__values[helper__num+1]
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
	if WotLK then
		function SetValue_wrapper(self, ...)
			return dropDown_SetValue(...)
		end
	else
		SetValue_wrapper = dropDown_SetValue
	end
	local function dropDown_menu(self)
		for value, text in get_iter(self.values) do
			local info = MSA_DropDownMenu_CreateInfo()
			info.text = text
			info.value = value
			info.checked = self.value == value
			info.func = SetValue_wrapper
			info.arg1 = self
			info.arg2 = value
			info.minWidth = 125
			MSA_DropDownMenu_AddButton(info)
		end
	end
	
	local tmp = {}
	function panelMeta:MakeDropDown(...)
		local args = getArgs(...)
		if type(args.name) ~= "string" then
			error(("name must be %q, got %q (%s)"):format("string", type(args.name), tostring(args.name)), 2)
		elseif type(args.description) ~= "string" then
			error(("description must be %q, got %q (%s)"):format("string", type(args.description), tostring(args.description)), 2)
		elseif type(args.values) ~= "function" then
			if type(args.values) ~= "table" then
				error(("values must be %q, got %q (%s)"):format("table", type(args.values), tostring(args.values)), 2)
			elseif #args.values%2 ~= 0 then
				error(("values must have an even number of items, got %d"):format(#args.values), 2)
			end
			for i = 1, #args.values, 2 do
				local k, v = args.values[i], args.values[2]
				if type(k) ~= "string" and type(k) ~= "number" then
					error(("values' keys must be %q or %q, got %q (%s)"):format("string", "number", type(k), tostring(k)))
				elseif type(v) ~= "string" then
					error(("values' values must be %q, got %q (%s)"):format("string", type(v), tostring(v)))
				end
				tmp[k] = v
			end
		end
		if type(args.default) ~= "number" and type(args.default) ~= "string" then
			error(("default must be %q or %q, got %q (%s)"):format("number", "string", type(args.default), tostring(args.default)), 2)
		elseif type(args.values) ~= "function" and not tmp[args.default] then
			error(("default must be in values, %s is not"):format(tostring(args.default)), 2)
		elseif not args.current == not args.getFunc then
			error(("either current or getFunc must be supplied, but not both"), 2)
		elseif args.current and type(args.current) ~= "string" and type(args.current) ~= "number" then
			error(("current must be %q or %q, got %q (%s)"):format("string", "number", type(args.current), tostring(args.current)), 2)
		elseif type(args.values) ~= "function" and args.current and not tmp[args.current] then
			error(("current must be in values, %s is not"):format(tostring(args.current)), 2)
		elseif args.getFunc and type(args.getFunc) ~= "function" then
			error(("getFunc must be %q, got %q (%s)"):format("function", type(args.getFunc), tostring(args.getFunc)), 2)
		elseif type(args.setFunc) ~= "function" then
			error(("setFunc must be %q, got %q (%s)"):format("function", type(args.setFunc), tostring(args.setFunc)), 2)
		elseif args.okayFunc and type(args.okayFunc) ~= "function" then
			error(("okayFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.okayFunc), tostring(args.okayFunc)), 2)
		elseif args.cancelFunc and type(args.cancelFunc) ~= "function" then
			error(("cancelFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.cancelFunc), tostring(args.cancelFunc)), 2)
		elseif args.defaultFunc and type(args.defaultFunc) ~= "function" then
			error(("defaultFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.defaultFunc), tostring(args.defaultFunc)), 2)
		end
		for k in pairs(tmp) do
			tmp[k] = nil
		end
		local name
		local i = 0
		repeat
			i = i + 1
			name = "ATT_DropDown" .. i
		until not _G[name]
		local dropDown = MSA_DropDownMenu_Create(name, args.extra or self)
		self.controls[dropDown] = true
		if args.name ~= "" then
			local label = dropDown:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			label:SetText(args.name)
			label:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 16, 3)
		end
		dropDown.tooltipText = args.description
		dropDown.values = args.values
		dropDown.initialize = function() MSA_DropDownMenu_Initialize(dropDown, function(self, level, menuList)
			dropDown_menu(dropDown)
		end) end
		dropDown.initialize()

		if WotLK then
		    MSA_DropDownMenu_JustifyText(dropDown, "CENTER")
		    MSA_DropDownMenu_SetWidth(dropDown, 120)			
		else
			MSA_DropDownMenu_JustifyText(dropDown, "CENTER")
			MSA_DropDownMenu_SetWidth(120, dropDown)			
		end
	
		local current
		if args.getFunc then
			dropDown.getFunc = args.getFunc
			current = args.getFunc()
		else
			current = args.current
		end

        dropDown.doRefresh = function() MSA_DropDownMenu_Initialize(dropDown, function(self, level, menuList)
			dropDown_menu(dropDown)
            MSA_DropDownMenu_Refresh(dropDown)
		end) end

        
		MSA_DropDownMenu_SetSelectedValue(dropDown, current)
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
		if type(args.name) ~= "string" then
			error(("name must be %q, got %q (%s)"):format("string", type(args.name), tostring(args.name)), 2)
		elseif type(args.description) ~= "string" then
			error(("description must be %q, got %q (%s)"):format("string", type(args.description), tostring(args.description)), 2)
		elseif type(args.func) ~= "function" then
			error(("description must be %q, got %q (%s)"):format("function", type(args.func), tostring(args.func)), 2)
		end
		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Button" .. i
		until not _G[name]
	
		local button = CreateFrame("Button", name, self, "UIPanelButtonTemplate")
		self.controls[button] = true
		button:SetText(args.name)
		button.tooltipText = args.description
		if args.extra then button:SetWidth(100); button:SetHeight(30); 
		else button:SetNormalFontObject(GameFontNormalSmall)  button:SetWidth(80); button:SetHeight(30) 

		end
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
		if type(args.name) ~= "string" then
			error(("name must be %q, got %q (%s)"):format("string", type(args.name), tostring(args.name)), 2)
		elseif type(args.description) ~= "string" then
			error(("description must be %q, got %q (%s)"):format("string", type(args.description), tostring(args.description)), 2)
		elseif type(args.default) ~= "boolean" then
			error(("default must be %q, got %q (%s)"):format("boolean", type(args.default), tostring(args.default)), 2)
		elseif (args.current == nil) == not args.getFunc then
			error(("either current or getFunc must be supplied, but not both"), 2)
		elseif args.current and type(args.current) ~= "boolean" then
			error(("current must be %q, got %q (%s)"):format("boolean", type(args.current), tostring(args.current)), 2)
		elseif args.getFunc and type(args.getFunc) ~= "function" then
			error(("getFunc must be %q, got %q (%s)"):format("function", type(args.getFunc), tostring(args.getFunc)), 2)
		elseif type(args.setFunc) ~= "function" then
			error(("setFunc must be %q, got %q (%s)"):format("function", type(args.setFunc), tostring(args.setFunc)), 2)
		elseif args.okayFunc and type(args.okayFunc) ~= "function" then
			error(("okayFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.okayFunc), tostring(args.okayFunc)), 2)
		elseif args.cancelFunc and type(args.cancelFunc) ~= "function" then
			error(("cancelFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.cancelFunc), tostring(args.cancelFunc)), 2)
		elseif args.defaultFunc and type(args.defaultFunc) ~= "function" then
			error(("defaultFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.defaultFunc), tostring(args.defaultFunc)), 2)
		end
		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_Toggle" .. i
		until not _G[name]
	
		local toggle = CreateFrame("CheckButton", name, args.extra or self, "InterfaceOptionsCheckButtonTemplate")
		self.controls[toggle] = true
		_G[toggle:GetName() .. "Text"]:SetText(args.name)
	    toggle:SetHitRectInsets(0, -_G[toggle:GetName() .. "Text"]:GetStringWidth() - 1, 0, 0) --GetWidth()

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
		toggle:SetChecked(current)
	    --toggle:SetScript("OnEnter", generic_OnEnter)
	    --toggle:SetScript("OnLeave", generic_OnLeave)
		toggle:SetScript('OnEnter', function() GameTooltip:ClearLines(); GameTooltip:SetOwner(toggle, "ANCHOR_CURSOR")
		GameTooltip:SetText(toggle.tooltipText, nil, nil, nil, nil, 1) GameTooltip:Show() end)
        toggle:SetScript('OnLeave', function() GameTooltip:ClearLines()  GameTooltip:Hide()end)	
		toggle.okayFunc = args.okayFunc
		toggle.cancelFunc = args.cancelFunc
		toggle.defaultFunc = args.defaultFunc
		args = doneArgs(args)
		
		return toggle
	end
end

do
	local function update(self, r, g, b, a)
		if not self.hasAlpha then
			a = 1
		end
		self.info.r = r
		self.info.g = g
		self.info.b = b
		if self.hasAlpha then
			self.info.opacity = a
		end
		self.color:SetTexture(r, g, b, a)
		if self.value == self.oldValue then
			self.value = {}
		end
		self.value[1] = r
		self.value[2] = g
		self.value[3] = b
		if self.hasAlpha then
			self.value[4] = a
		end
		self.info.r = r
		self.info.g = g
		self.info.b = b
		if self.hasAlpha then
			self.info.opacity = 1 - a
		end
		if self.hasAlpha then
			self.changeFunc(r, g, b, a)
		else
			self.changeFunc(r, g, b)
		end
	end	
	local function button_SetValue(self, ...)
		if select('#', ...) == 1 and type((...)) == "table" then
			return button_SetValue(self, unpack(value))
		end
		update(self, ...)
	end
	local function button_OnClick(self)
		OpenColorPicker(self.info)
	end	
	local function swatchFunc(self)
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local opacity = 1 - OpacitySliderFrame:GetValue()
	
		update(self, r, g, b, opacity)
	end
	local function cancelFunc(self)
		local previousValues = ColorPickerFrame.previousValues
		local r, g, b, opacity = previousValues.r, previousValues.g, previousValues.b, hasAlpha and 1 - previousValues.opacity or 1
	
		update(self, r, g, b, opacity)
	end
	function panelMeta:MakeColorPicker(...)
		local args = getArgs(...)
		if type(args.name) ~= "string" then
			error(("name must be %q, got %q (%s)"):format("string", type(args.name), tostring(args.name)), 2)
		elseif type(args.description) ~= "string" then
			error(("description must be %q, got %q (%s)"):format("string", type(args.description), tostring(args.description)), 2)
		elseif type(args.hasAlpha) ~= "boolean" then
			error(("hasAlpha must be %q, got %q (%s)"):format("boolean", type(args.hasAlpha), tostring(args.hasAlpha)), 2)
		elseif type(args.defaultR) ~= "number" then
			error(("defaultR must be %q, got %q (%s)"):format("number", type(args.defaultR), tostring(args.defaultR)), 2)
		elseif args.defaultR < 0 or args.defaultR > 1 then
			error(("defaultR must be [0, 1], got %s"):format(tostring(args.defaultR)), 2)
		elseif type(args.defaultG) ~= "number" then
			error(("defaultG must be %q, got %q (%s)"):format("number", type(args.defaultG), tostring(args.defaultG)), 2)
		elseif args.defaultG < 0 or args.defaultG > 1 then
			error(("defaultG must be [0, 1], got %s"):format(tostring(args.defaultG)), 2)
		elseif type(args.defaultB) ~= "number" then
			error(("defaultB must be %q, got %q (%s)"):format("number", type(args.defaultB), tostring(args.defaultB)), 2)
		elseif args.defaultB < 0 or args.defaultB > 1 then
			error(("defaultB must be [0, 1], got %s"):format(tostring(args.defaultB)), 2)
		elseif args.hasAlpha and type(args.defaultA) ~= "number" then
			error(("defaultA must be %q, got %q (%s)"):format("number", type(args.defaultA), tostring(args.defaultA)), 2)
		elseif args.hasAlpha and (args.defaultA < 0 or args.defaultA > 1) then
			error(("defaultA must be [0, 1], got %s"):format(tostring(args.defaultA)), 2)
		elseif not args.currentR == not args.getFunc then
			error(("either currentR or getFunc must be supplied, but not both"), 2)
		elseif args.currentR and (not args.currentG or not args.currentB or (args.hasAlpha and not args.currentA)) then
			error(("if you supply currentR, you must supply currentG and currentB (and currentA if hasAlpha)"), 2)
		elseif args.currentR and type(args.currentR) ~= "number" then
			error(("current must be %q, got %q (%s)"):format("number", type(args.currentR), tostring(args.currentR)), 2)
		elseif args.currentG and type(args.currentG) ~= "number" then
			error(("current must be %q, got %q (%s)"):format("number", type(args.currentG), tostring(args.currentG)), 2)
		elseif args.currentB and type(args.currentB) ~= "number" then
			error(("current must be %q, got %q (%s)"):format("number", type(args.currentB), tostring(args.currentB)), 2)
		elseif args.currentA and type(args.currentA) ~= "number" then
			error(("current must be %q, got %q (%s)"):format("number", type(args.currentA), tostring(args.currentA)), 2)
		elseif args.getFunc and type(args.getFunc) ~= "function" then
			error(("getFunc must be %q, got %q (%s)"):format("function", type(args.getFunc), tostring(args.getFunc)), 2)
		elseif type(args.setFunc) ~= "function" then
			error(("setFunc must be %q, got %q (%s)"):format("function", type(args.setFunc), tostring(args.setFunc)), 2)
		elseif args.okayFunc and type(args.okayFunc) ~= "function" then
			error(("okayFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.okayFunc), tostring(args.okayFunc)), 2)
		elseif args.cancelFunc and type(args.cancelFunc) ~= "function" then
			error(("cancelFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.cancelFunc), tostring(args.cancelFunc)), 2)
		elseif args.defaultFunc and type(args.defaultFunc) ~= "function" then
			error(("defaultFunc must be %q or %q, got %q (%s)"):format("nil", "function", type(args.defaultFunc), tostring(args.defaultFunc)), 2)
		end
		
		local name
		local i = 0
		repeat
			i = i + 1
			name = self:GetName() .. "_ColorPicker" .. i
		until not _G[name]
	
		if not args.hasAlpha then
			args.defaultA = 1
		end
		
		local button = CreateFrame("Button", name, self)
		self.controls[button] = true
		
		
		local currentR, currentG, currentB, currentA
		if args.getFunc then
			button.getFunc = args.getFunc
			currentR, currentG, currentB, currentA = button.getFunc()
			if not args.hasAlpha then
				currentA = 1
			end
		else
			currentR = args.currentR
			currentG = args.currentG
			currentB = args.currentB
			if not args.hasAlpha then
				currentA = 1
			else
				currentR = args.currentA
			end
		end
		
		button.tooltipText = args.description
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		text:SetText(args.name)
		text:SetPoint("LEFT", button, "RIGHT", 0, 1)
		button:SetHitRectInsets(0, -text:GetStringWidth() - 1, 0, 0)
		local color = button:CreateTexture(nil, "ARTWORK")
		button.color = color
		color:SetTexture(currentR, currentG, currentB, currentA)
		local background = button:CreateTexture(nil, "BORDER")
		background:SetTexture([=[Tileset\Generic\Checkers]=])
		background:SetTexCoord(0, 0.5, 0, 0.5)
		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetTexture([=[Interface\ChatFrame\ChatFrameColorSwatch]=])
		button:SetWidth(26)
		button:SetHeight(26)
		background:SetPoint("CENTER")
		background:SetWidth(14)
		background:SetHeight(14)
		color:SetPoint("CENTER")
		color:SetWidth(14)
		color:SetHeight(14)
		border:SetAllPoints(button)
		button.default = { args.defaultR, args.defaultG, args.defaultB }
		button.oldValue = { currentR, currentG, currentB }
		if hasAlpha then
			button.default[4] = args.defaultA
			button.oldValue[4] = currentA
		end
		button.value = button.oldValue
		button.hasAlpha = args.hasAlpha
		button.changeFunc = args.setFunc
		button.SetValue = button_SetValue
		local function swatchFunc_wrapper()
			swatchFunc(button)
		end
		local function cancelFunc_wrapper()
			cancelFunc(button)
		end
		button.info = {
			swatchFunc = swatchFunc_wrapper,
			hasOpacity = args.hasAlpha,
			opacityFunc = args.hasAlpha and swatchFunc_wrapper or nil,
			r = currentR,
			g = currentB,
			b = currentG,
			opacity = args.hasAlpha and 1 - currentA or nil,
			cancelFunc = cancelFunc_wrapper,
		}
		button:SetScript("OnClick", button_OnClick)
		button:SetScript("OnEnter", generic_OnEnter)
		button:SetScript("OnLeave", generic_OnLeave)
		button:RegisterForClicks("LeftButtonUp")
		button.okayFunc = args.okayFunc
		button.cancelFunc = args.cancelFunc
		button.defaultFunc = args.defaultFunc
		args = doneArgs(args)
		return button
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
		InterfaceOptionsFrame_OpenToCategory(name)
		InterfaceOptionsFrame_OpenToCategory(name)
	end
end

for funcName, func in pairs(panelMeta) do
	LibSimpleOptions[funcName] = func
	for panel in pairs(panels) do
		panel[funcName] = func
	end
end