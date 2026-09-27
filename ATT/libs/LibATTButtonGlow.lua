local MAJOR_VERSION = "LibATTButtonGlow"
local MINOR_VERSION = 8

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

--[[
	Glow for ATT icons, 5.4.8.

	Reuses Blizzard's proc-glow frame template "ActionBarButtonSpellActivationAlert"
	(same one ActionButton uses) so the XML animations actually work; Lua-created
	Scale/Alpha animations do nothing on 5.4.8 (no SetFromAlpha/SetToAlpha).

	Two template scripts are overridden for ATT:
	  * OnUpdate - Blizzard's ActionButton_OverlayGlowOnUpdate reads
	    parent.cooldown as a frame, but ATT stores the cooldown *number* in
	    icon.cooldown (the frame is icon.cd) -> "attempt to index local
	    'cooldown' (a number value)". Use icon.cd instead.
	  * OnHide - Blizzard's cleanup clears button.overlay, not our
	    button.__ATTGlowOverlay, leaving a stale reference.
--]]

local tinsert, tremove = table.insert, table.remove

lib.unusedOverlays = lib.unusedOverlays or {}
lib.numOverlays = lib.numOverlays or 0

local function AnimOutFinished(animGroup)
	local overlay = animGroup:GetParent()
	if overlay.__pooled then return end
	overlay.__pooled = true
	local button = overlay:GetParent()
	overlay:Hide()
	tinsert(lib.unusedOverlays, overlay)
	if button then button.__ATTGlowOverlay = nil end
end

local function OverlayOnUpdate(self, elapsed)
	AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
	local parent = self:GetParent()
	local cd = parent and parent.cd
	if cd and cd.IsShown and cd:IsShown() and cd.GetCooldownDuration and cd:GetCooldownDuration() > 3000 then
		self:SetAlpha(0.5)
	else
		self:SetAlpha(1.0)
	end
end

local function OverlayOnHide(self)
	if self.animOut:IsPlaying() then
		self.animOut:Stop()
	end
	AnimOutFinished(self.animOut)
end

local function GetOverlay()
	local overlay = tremove(lib.unusedOverlays)
	if not overlay then
		lib.numOverlays = lib.numOverlays + 1
		overlay = CreateFrame("Frame", "ATTButtonGlowOverlay"..lib.numOverlays, UIParent, "ActionBarButtonSpellActivationAlert")
		overlay.animOut:SetScript("OnFinished", AnimOutFinished)
		overlay:SetScript("OnUpdate", OverlayOnUpdate)
		overlay:SetScript("OnHide", OverlayOnHide)
	end
	overlay.__pooled = false
	return overlay
end

function lib.ShowOverlayGlow2(frame)
	if not frame then return end
	local overlay = frame.__ATTGlowOverlay
	if overlay and overlay:IsShown() then
		if overlay.animOut:IsPlaying() then
			overlay.animOut:Stop()
			overlay.animIn:Play()
		end
		return
	end
	frame.__ATTGlowOverlay = nil

	overlay = GetOverlay()
	local frameWidth, frameHeight = frame:GetSize()
	overlay:SetParent(frame)
	overlay:ClearAllPoints()
	-- Make the height/width available before the next frame:
	overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
	overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
	overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
	overlay.animIn:Play()
	frame.__ATTGlowOverlay = overlay
end

function lib.HideOverlayGlow2(frame)
	if not frame then return end
	local overlay = frame.__ATTGlowOverlay
	if overlay then
		-- Already fading out: don't restart animOut every call (it may be called
		-- from a per-frame OnUpdate), or it would never finish.
		if overlay.animOut:IsPlaying() then return end
		if overlay.animIn:IsPlaying() then
			overlay.animIn:Stop()
		end
		if frame:IsVisible() then
			overlay.animOut:Play()
		else
			AnimOutFinished(overlay.animOut)
		end
	end
end
