local next, ipairs, pairs = next, ipairs, pairs
local floor, tinsert = floor, tinsert

local GetTime = GetTime
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local FONT_SIZE = 20 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 1.5 --the minimum duration to show cooldown text fo
local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for calculating aura time text
local DAYISH, HOURISH, MINUTEISH = HOUR * 23.5, MINUTE * 59.5, 59.5 --used for caclculating aura time at transition points
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY / 2 + 0.5, HOUR / 2 + 0.5, MINUTE / 2 + 0.5 --used for calculating next update times
local TimeFormats = { -- short / indicator color
[0] = {"%dd", "%d%sd|r"},
[1] = {"%dh", "%d%sh|r"},
[2] = {"%dm", "%d%sm|r"},
[3] = {"%ds", "%d%ss|r"},
[4] = {"%.1fs", "%.1f%ss|r"},
[5] = {"%d:%02d", "%d%s:|r%02d"}, --mmss
[6] = {"%d:%02d", "%d%s:|r%02d"}, --hhmm
}

for _, x in pairs(TimeFormats) do
	x[3] = gsub(x[1], "s$", "") -- 1 without seconds
	x[4] = gsub(x[2], "%%ss", "%%s") -- 2 without seconds
end

local TimeColors = { --aura time colors
	[0] = "|cffeeeeee", --days
	[1] = "|cffeeeeee", --hours
	[2] = "|cffeeeeee", --minutes
	[3] = "|cffeeeeee", --seconds
	[4] = "|cfffe0000", --expire (fade timer)
	[5] = "|cff909090", --mmss
	[6] = "|cff707070", --hhmm
}

function CooldownFrame_GetTimeInfo(s, threshhold, hhmm, mmss)
	if s < MINUTE then
		if s >= threshhold then
			return floor(s), 3, 0.51
		else
			return s, 4, 0.051
		end
	elseif s < HOUR then
		-- 60-119s: plain seconds ("80") instead of mm:ss; >=2m: "Nm" ("2m").
		if s < 2 * MINUTE then
			return floor(s), 3, 0.51
		end
		local minutes = floor((s / MINUTE) + 0.5)
		return ceil(s / MINUTE), 2, minutes > 1 and (s - (minutes * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
	elseif s < DAY then
		if mmss and s < mmss then
			return s / MINUTE, 5, 0.51, s%MINUTE
		elseif hhmm and s < (hhmm * MINUTE) then
			local minutes = floor((s / MINUTE) + 0.5)
			return s / HOUR, 6, minutes > 1 and (s - (minutes * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH), minutes%MINUTE
		else
			local hours = floor((s / HOUR) + 0.5)
			return ceil(s / HOUR), 1, hours > 1 and (s - (hours * HOUR - HALFHOURISH)) or (s - HOURISH)
		end
	else
		local days = floor((s / DAY)+.5)
		return ceil(s / DAY), 0, days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

--Cooldown.lua
function CooldownFrame_Cooldown_OnUpdate(self, elapsed)
	local forced = elapsed == -1
	if forced then
		self.nextUpdate = 0
	elseif self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	local now = GetTime()
	if self.endCooldown and now >= self.endCooldown then
		CooldownFrame_StopTimer(self)
	elseif self.endTime then
		local value, id, nextUpdate, remainder = CooldownFrame_GetTimeInfo(self.endTime - now, 3, -1, 600)
		if not forced then
			self.nextUpdate = nextUpdate
		end
		local style = TimeFormats[id]
		if style then
			local which = (self.textColors and 2 or 1) + (self.showSeconds and 0 or 2)
			self.text:SetFormattedText(style[which], value, remainder)
		end
		self.text:SetTextColor(.86, .86, .86)
	end
end



function CooldownFrame_CreateCooldownTimer(parent)
	local timer = CreateFrame("Frame", nil, parent)
	timer:Hide()
	timer:SetAllPoints()
	timer.parent = parent
	parent.timer = timer

	local text = timer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("CENTER", 1, 1)
	text:SetJustifyH("CENTER")
	text:SetFont([[Interface\Addons\ATT\media\fonts\Expressway.ttf]], (floor(parent:GetWidth() * 0.55)), "OUTLINE")
	timer.text = text

	-- keep this after Cooldown_OnSizeChanged
	timer:SetScript("OnUpdate", CooldownFrame_Cooldown_OnUpdate)

	return timer
end

function CooldownFrame_Cooldown_ForceUpdate(cd)
	CooldownFrame_Cooldown_OnUpdate(cd, -1)
	cd:Show()
end

function CooldownFrame_StopTimer(cd)
	cd:Hide()
end

function CooldownFrame_OnSetCooldown(self, start, duration)
	if (start and duration) and (duration > MIN_DURATION) then
		local timer = self.timer or CooldownFrame_CreateCooldownTimer(self)
		timer.start = start
		timer.duration = duration
		timer.endTime = start + duration
		timer.endCooldown = timer.endTime - 0.05
		CooldownFrame_Cooldown_ForceUpdate(timer)
	elseif self.timer then
		CooldownFrame_StopTimer(self.timer)
	end
end


function CooldownFrame_Set(self, start, duration, enable, forceShowDrawEdge, modRate)
	if enable and enable ~= 0 and start > 0 and duration > 0 then
		--self:SetDrawEdge(forceShowDrawEdge);
        CooldownFrame_OnSetCooldown(self, start, duration)
		self:SetCooldown(start, duration, modRate);
	else
		CooldownFrame_Clear(self);
	end
end

function CooldownFrame_Clear(self)
	self:SetCooldown(0, 0, 0);
end

function CooldownFrame_SetDisplayAsPercentage(self, percentage)
	local seconds = 100;	-- any number, really
	self:Pause();
	self:SetCooldown(GetTime() - seconds * percentage, seconds);
end

--C_Timer

if not C_Timer then
	local setmetatable = setmetatable
	local type = type
	local tinsert = table.insert
	local tremove = table.remove

	C_Timer = C_Timer or {}
	C_Timer._version = 2

	local TickerPrototype = {}
	local TickerMetatable = {
		__index = TickerPrototype,
		__metatable = true
	}

	local waitTable = {}
	local waitFrame = CreateFrame("Frame", "ATTTimerFrame", UIParent)
	waitFrame:SetScript("OnUpdate", function(self, elapsed)
		if type(elapsed) ~= "number" then elapsed = 0 end
		local total = #waitTable
		local i = 1

		while i <= total do
			local ticker = waitTable[i]

			if ticker._cancelled then
				tremove(waitTable, i)
				total = total - 1
			elseif type(ticker._delay) == "number" and ticker._delay > elapsed then
				ticker._delay = ticker._delay - elapsed
				i = i + 1
			else
				if type(ticker._callback) == "function" then
					ticker._callback(ticker)
				end

				if ticker._remainingIterations == -1 then
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._remainingIterations > 1 then
					ticker._remainingIterations = ticker._remainingIterations - 1
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._remainingIterations == 1 then
					tremove(waitTable, i)
					total = total - 1
				end
			end
		end

		if #waitTable == 0 then
			self:Hide()
		end
	end)

	local function AddDelayedCall(ticker, oldTicker)
		if oldTicker and type(oldTicker) == "table" then
			ticker = oldTicker
		end

		tinsert(waitTable, ticker)
		waitFrame:Show()
	end

	_G.AddDelayedCall = _G.AddDelayedCall or AddDelayedCall

	local function CreateTicker(duration, callback, iterations)
		local ticker = setmetatable({}, TickerMetatable)
		ticker._remainingIterations = iterations or -1
		ticker._duration = duration
		ticker._delay = duration
		ticker._callback = callback

		AddDelayedCall(ticker)

		return ticker
	end

	local function isSelf(a)
		return a == C_Timer
	end

	function C_Timer.After(a, b, c)
		local duration, callback = a, b
		if isSelf(a) then duration, callback = b, c end
		AddDelayedCall({
			_remainingIterations = 1,
			_delay = duration,
			_callback = callback
		})
	end

	function C_Timer.NewTimer(a, b, c)
		if isSelf(a) then return CreateTicker(b, c, 1) end
		return CreateTicker(a, b, 1)
	end

	function C_Timer.NewTicker(a, b, c, d)
		if isSelf(a) then return CreateTicker(b, c, d) end
		return CreateTicker(a, b, c)
	end

	function TickerPrototype:Cancel()
		self._cancelled = true
	end
end



--AuraUtil
AuraUtil = AuraUtil or {};

local function FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, ...)
	if ... == nil then
		return nil; -- Not found
	end
	if predicate(predicateArg1, predicateArg2, predicateArg3, ...) then
		return ...;
	end
	auraIndex = auraIndex + 1;
	return FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, UnitAura(unit, auraIndex, filter));
end

-- Find an aura by any predicate, you can pass in up to 3 predicate specific parameters
-- The predicate will also receive all aura params, if the aura data matches return true
function AuraUtil.FindAura(predicate, unit, filter, predicateArg1, predicateArg2, predicateArg3)
	local auraIndex = 1;
	return FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, UnitAura(unit, auraIndex, filter));
end

do
	local function NamePredicate(auraNameToFind, _, _, auraName)
		return auraNameToFind == auraName;
	end

	-- Finds the first aura that matches the name
	-- Notes:
	--		aura names are not unique!
	--		aura names are localized, what works in one locale might not work in another
	--			consider that in English two auras might have different names, but once localized they have the same name, so even using the localized aura name in a search it could result in different behavior
	--		the unit could have multiple auras with the same name, this will only find the first
	function AuraUtil.FindAuraByName(auraName, unit, filter)
		return AuraUtil.FindAura(NamePredicate, unit, filter, auraName);
	end
end

do
	function AuraUtil.ForEachAura(unit, filter, maxCount, func, usePackedAura)
		if maxCount and maxCount <= 0 then
			return;
		end
		local n = 0
		for i = 1, 255 do
			local name, rank, icon, count, dispelName, duration, expirationTime, source, isStealable, _, spellId, auraType = UnitAura(unit, i, filter)
			if not name then break end
			local stop
			if usePackedAura then
				stop = func({
					name = name,
					icon = icon,
					applications = count,
					dispelName = dispelName,
					duration = duration,
					expirationTime = expirationTime,
					sourceUnit = source,
					isStealable = isStealable,
					spellId = spellId,
					auraType = auraType,
					auraInstanceID = i,
				})
			else
				stop = func(name, icon, count, dispelName, duration, expirationTime, source, isStealable, nil, spellId)
			end
			if stop then break end
			n = n + 1
			if maxCount and n >= maxCount then break end
		end
	end
end