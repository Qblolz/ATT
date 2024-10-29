local addon, ATTdbs = ...
ATTdbs.LibATTButtonGlow = {}
local lib = ATTdbs.LibATTButtonGlow

local Masque = LibStub("Masque", true)

lib.unusedOverlays2 = lib.unusedOverlays2 or {}
lib.numOverlays2 = lib.numOverlays2 or 0

local tinsert, tremove, tostring = table.insert, table.remove, tostring

local function OverlayGlowAnimOutFinished2(animGroup)
	local overlay = animGroup:GetParent()
	local frame = overlay:GetParent()
	overlay:Hide()
	tinsert(lib.unusedOverlays2, overlay)
	frame.__LBGoverlay2 = nil
end

local function OverlayGlow_OnHide(self)
	if self.animOut:IsPlaying() then
		self.animOut:Stop()
		OverlayGlowAnimOutFinished2(self.animOut)
	end
end

local function OverlayGlow_OnUpdate(self, elapsed)
	AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
	local cooldown = self:GetParent().cooldown
	if self and self:IsShown() and cooldown > 3000 then
		self:SetAlpha(0.5)
	else
		self:SetAlpha(0.9)
	end
end

local function CreateScaleAnim(group, target, order, duration, x, y, delay)
	local scale = group:CreateAnimation("Scale")
	scale:SetOrder(order)
	scale:SetDuration(duration)
	scale:SetScale(x, y)
	if delay then
		scale:SetStartDelay(delay)
	end
end

local function CreateAlphaAnim(group, target, order, duration, fromAlpha, toAlpha, delay)
	local alpha = group:CreateAnimation("Alpha")
	alpha:SetOrder(order)
	alpha:SetDuration(duration)

	if delay then
		alpha:SetStartDelay(delay)
	end
end

local function AnimIn_OnPlay(group)
	local frame = group:GetParent()
	local frameWidth, frameHeight = frame:GetSize()
	frame.innerGlow:SetSize(frameWidth / 1.2, frameHeight / 1.2)
	frame.innerGlow:SetAlpha(1.0)
	frame.innerGlowOver:SetAlpha(1.0)
	frame.outerGlow:SetSize(frameWidth * 1.2, frameHeight * 1.2)
	frame.outerGlow:SetAlpha(1.0)
	frame.outerGlowOver:SetAlpha(1.0)
	frame.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
	frame.ants:SetAlpha(0)
	frame:Show()
end

local function AnimIn_OnFinished(group)
	local frame = group:GetParent()
	local frameWidth, frameHeight = frame:GetSize()
	frame.innerGlow:SetAlpha(0)
	frame.innerGlow:SetSize(frameWidth, frameHeight)
	frame.innerGlowOver:SetAlpha(0.0)
	frame.outerGlow:SetSize(frameWidth, frameHeight)
	frame.outerGlowOver:SetAlpha(0.0)
	frame.outerGlowOver:SetSize(frameWidth, frameHeight)
	frame.ants:SetAlpha(1.0)
end

local function CreateOverlayGlow()
	lib.numOverlays2 = lib.numOverlays2 + 1

	-- create frame and textures
	local name = "ButtonGlowOverlay2" .. tostring(lib.numOverlays2)
	local overlay = CreateFrame("Frame", name, UIParent)

	-- inner glow
	overlay.innerGlow = overlay:CreateTexture(name .. "InnerGlow", "ARTWORK")
	overlay.innerGlow:SetPoint("CENTER")
	overlay.innerGlow:SetAlpha(0)
	overlay.innerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	-- inner glow over
	overlay.innerGlowOver = overlay:CreateTexture(name .. "InnerGlowOver", "ARTWORK")
	overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
	overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
	overlay.innerGlowOver:SetAlpha(0)
	overlay.innerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	-- outer glow
	overlay.outerGlow = overlay:CreateTexture(name .. "OuterGlow", "ARTWORK")
	overlay.outerGlow:SetPoint("CENTER")
	overlay.outerGlow:SetAlpha(0)
	overlay.outerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	-- outer glow over
	overlay.outerGlowOver = overlay:CreateTexture(name .. "OuterGlowOver", "ARTWORK")
	overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
	overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
	overlay.outerGlowOver:SetAlpha(0)
	overlay.outerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	-- ants
	overlay.ants = overlay:CreateTexture(name .. "Ants", "OVERLAY")
	overlay.ants:SetPoint("CENTER")
	overlay.ants:SetAlpha(0)
	overlay.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]])

	-- setup antimations
	overlay.animIn = overlay:CreateAnimationGroup()
	CreateScaleAnim(overlay.animIn, overlay.innerGlow,      1, 0.1, 1.2, 1.2)
	CreateScaleAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.1, 1.2, 1.2)
	CreateAlphaAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 1, 0)
	CreateScaleAnim(overlay.animIn, overlay.outerGlow,      1, 0.3, 0.8, 0.8)
	CreateScaleAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 0.8, 0.8)
	CreateAlphaAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 1, 0)
	CreateAlphaAnim(overlay.animIn, overlay.innerGlow,      1, 0.2, 1, 0, 0.3)
	CreateAlphaAnim(overlay.animIn, overlay.ants,           1, 0.2, 0, 1, 0.3)
	overlay.animIn:SetScript("OnPlay", AnimIn_OnPlay)
	overlay.animIn:SetScript("OnFinished", AnimIn_OnFinished)

	overlay.animOut = overlay:CreateAnimationGroup()
	CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 1, 0.2, 0, 1)
	CreateAlphaAnim(overlay.animOut, overlay.ants,          1, 0.2, 1, 0)
	CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 2, 0.2, 1, 0)
	CreateAlphaAnim(overlay.animOut, overlay.outerGlow,     2, 0.2, 1, 0)

	overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished2)

	-- scripts
	overlay:SetScript("OnUpdate", OverlayGlow_OnUpdate)
	overlay:SetScript("OnHide", OverlayGlow_OnHide)

	overlay.__LBGVersion = MINOR_VERSION

	return overlay
end

local function GetOverlayGlow()
	local overlay = tremove(lib.unusedOverlays2)
	if not overlay then
		overlay = CreateOverlayGlow()
	end
	return overlay
end

function lib.ShowOverlayGlow2(frame)
	if frame.__LBGoverlay2 then
		if frame.__LBGoverlay2.animOut:IsPlaying() or frame.__LBGoverlay2.animIn:IsPlaying() then
			frame.__LBGoverlay2.animOut:Stop()
			frame.__LBGoverlay2.animIn:Stop()
			frame.__LBGoverlay2.animIn:Play()
		end
	else
		local overlay = GetOverlayGlow()
		local frameWidth, frameHeight = frame:GetSize()
		overlay:SetParent(frame)
		overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
		overlay:ClearAllPoints()
		--Make the height/width available before the next frame:
		overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		overlay.animIn:Play()
		frame.__LBGoverlay2 = overlay

		if Masque and Masque.UpdateSpellAlert and (not frame.overlay or not issecurevariable(frame, "overlay")) then
			local old_overlay = frame.overlay
			frame.overlay = overlay
			Masque:UpdateSpellAlert(frame)

			frame.overlay = old_overlay
		end
	end
end

function lib.HideOverlayGlow2(frame)
	frame.glowDuration = nil
	--frame.cd:SetSwipeColor(1,1,1,1)
    local chargetxt = tonumber(frame.chargesText:GetText())
	if frame.__LBGoverlay2 then
		if frame.__LBGoverlay2.animIn:IsPlaying() then
			frame.__LBGoverlay2.animIn:Stop()
		end
		if frame:IsVisible() then
			frame.__LBGoverlay2.animOut:Play()
		else
			OverlayGlowAnimOutFinished2(frame.__LBGoverlay2.animOut)
		end
	end
end