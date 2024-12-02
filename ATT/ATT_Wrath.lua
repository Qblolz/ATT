--[[
Name: Ability Team Tracker Wrath
Author: by Qblolz
Contact/support @ curseforge.com/wow/addons/att
Description: Track the cooldowns of your party members
--]]
local _G = _G
local addon, ATTdbs = ...
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local IsInInstance = IsInInstance
local CooldownFrame_Set = CooldownFrame_SetTimer
local GetTalentInfo = GetTalentInfo
local GetSpellInfo = GetSpellInfo
local ClearInspectPlayer = ClearInspectPlayer
local GetInventoryItemLink = GetInventoryItemLink
local UnitIsDead = UnitIsDead
local CanInspect = CanInspect
local UnitIsConnected = UnitIsConnected
local CheckInteractDistance = CheckInteractDistance
local InspectFrame = _G.InspectFrame
local GetActiveTalentGroup = GetActiveTalentGroup
local LGlows = ATTdbs.LibATTButtonGlow
local SO = ATTdbs.LibSimpleOptions
local ChatPrefix = "ATT-Check"
local ATTversion = GetAddOnMetadata("ATT", "Version")
local db
local selectedDB
local dbModif = ATTdbs.dbModif
local constellations = ATTdbs.constellations
local dbModifGlyph = ATTdbs.dbModifGlyph
local dbImport = ATTdbs.dbImport
local ShareCD = ATTdbs.ShareCD
local dbAuraRemoved = ATTdbs.dbAuraRemoved
local dbAuraApplied = ATTdbs.dbAuraApplied
local dbTrinkets = ATTdbs.dbTrinkets
local cooldownResetters = ATTdbs.cooldownResetters
local validPartyUnits = ATTdbs.validPartyUnits
local validRaidUnits = ATTdbs.validRaidUnits
local customframes = ATTdbs.customframes
local itemBonus = ATTdbs.dbItemBonus
local setBonus = ATTdbs.dbSetBonus
local dbModifBonus = ATTdbs.dbModifBonus
local INVSLOTS = ATTdbs.INVSLOTS
local L = ATTdbs.enUS

local ATT = CreateFrame("Frame", "ATT", UIParent)
local ATTIcons = CreateFrame("Frame", nil, UIParent)
local ATTAnchor = CreateFrame("Frame", nil, UIParent)
local ATTOnUpdateFrame = CreateFrame("Frame")

local elapsedTime = 0

local anchors = {}
local activeGUIDS = {}
local activeBUFFS = {}
local syncChache = {}

-- Player Inspect
local inspect_queue = {}
local dbInspect = {}
local dbInspectGear = {}
local isFWW = {} -- workaround fix
local hookedFrames = {}
ATTdbs.UnitIDCache = {}


local PvPTrinketName = GetSpellInfo(42292)

local PlayerGUID = UnitGUID("player")

local function IsInGroup()
	return (GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0)
end

local function IsInRaid()
	return GetNumRaidMembers() > 0
end

local function GetNumSubgroupMembers()
	return GetNumPartyMembers()
end

local function GetNumGroupMembers()
	return GetNumRaidMembers()
end

local function print(...)
    for i = 1, select('#', ...) do
        ChatFrame1:AddMessage("|cff33ff99ATT|r: " .. select(i, ...))
    end
end

local function localeFunc()
    local getLocale = GetLocale()
    if ATTDB.useEnglish then
        L = ATTdbs.enUS
    elseif ATTdbs[getLocale] then
        L = ATTdbs[getLocale]
    else
        L = ATTdbs.enUS
    end

    local function defaultFuncLoc(L, key)
        return key;
       end
    setmetatable(L, {__index=defaultFuncLoc});
end
------

function ATT:UpdateUnitIDCache()
    ATTdbs.UnitIDCache = {}
    local validUnits = ATT.inRaid and validRaidUnits or validPartyUnits
    for k, v in pairs(validUnits) do
        local guid = UnitGUID(k)
        if guid then 
            ATTdbs.UnitIDCache[guid] = {k,v}
            local unitName = GetUnitName(k, true)
            ATTdbs.UnitIDCache[unitName] = k
         end
    end
        --clean old inspects
    for guid, info in pairs(dbInspect) do
       local unitInGroup = ATTdbs.UnitIDCache[guid]
       if not unitInGroup and dbInspect[guid] then
        dbInspect[guid] = nil
        dbInspectGear[guid] = nil
        syncChache[guid] = nil
       end
    end
end

function ATT:GetUnitByGUID(guid)
    if not guid then return end
    local unit = ATTdbs.UnitIDCache[guid] and ATTdbs.UnitIDCache[guid][1]
    return unit
end

function ATT:GetAnchorByUnit(unit)
    if not unit or not (validRaidUnits[unit] or validPartyUnits[unit]) then 
        return 
    end
    
    local guid = UnitGUID(unit)
    local anchor = guid and ATTdbs.UnitIDCache[guid] and ATTdbs.UnitIDCache[guid][2]

    return anchors[anchor]
end

local function getIconCharges(icon)
    local charges = icon.chargesText:GetText() and icon.chargesText:GetText():match("^[0-9]+$")
    if charges then
        return tonumber(charges)
    end
end 

function ATT:ShowGlow(icon, duration)
    if not icon then return end
    icon.glowDuration = duration

    LGlows.ShowOverlayGlow2(icon)
end

function ATT:HideGlow(icon)
    if not icon then return end

    LGlows.HideOverlayGlow2(icon)

    local charges = icon.maxcharges and getIconCharges(icon)

    icon.glowDuration = nil
end

function ATT:QueueInspect(guid)
    if guid then
        for i = 1, #inspect_queue do
            if inspect_queue[i] == guid then
                return
            end
        end
        self.insStart = self.insStart or {}
        self.insStart[guid] = GetTime()
        inspect_queue[#inspect_queue + 1] = guid
    end
end

function ATT:DequeueInspectByGUID(guid)
    for i = 1, #inspect_queue do
        if inspect_queue[i] == guid then
            table.remove(inspect_queue, i)
        end
    end
end

function ATT:RequeueInspectByGUID(guid)
    for i = 1, #inspect_queue do
        if inspect_queue[i] == guid then
            table.remove(inspect_queue, i)
            inspect_queue[#inspect_queue + 1] = guid
        end
    end
end

function ATT:ProcessInspect(unit, guid, specInspect, gearInspect)
    -- Talent Check / Inspect
    if unit and specInspect and guid then
        local _, class, classID = UnitClass(unit)
        classID = tonumber(classID)

        dbInspect[guid] = {}
        local isInspect = (guid ~= PlayerGUID) and true --here
        local talentspec = GetActiveTalentGroup(isInspect)

        for i = 1, 4 do
            for j = 1, 31 do
                local Name, _, _, _, rank = GetTalentInfo(i, j, isInspect, false, talentspec)
                if Name and rank then dbInspect[guid][Name] = rank end
            end
        end

        if gearInspect then
            dbInspectGear[guid] = {}
            for k = 13, 14 do
                local itemLink = GetInventoryItemLink(unit, INVSLOTS[k])
                if itemLink then
                    local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4,
                        Suffix, Unique, LinkLvl, Name = string.find(itemLink,
                        "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
                    if itemID then
                        itemID = tonumber(itemID)
                        if ATTdbs.dbTrinketsMerge[itemID] then itemID = ATTdbs.dbTrinketsMerge[itemID] end
                        dbInspect[guid][itemID] = 1
                        dbInspectGear[guid][itemID] = 1
                    end
                end
            end
            for k = 1, 12 do
                local itemLink = GetInventoryItemLink(unit, INVSLOTS[k])
                local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4,
                    Suffix, Unique, LinkLvl, Name = string.find(itemLink,
                    "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
                if itemID then
                    itemID = tonumber(itemID)
                    local hasItemBonus = itemBonus[itemID]
                    if hasItemBonus then
                        dbInspect[guid][hasItemBonus] = 1
                        dbInspectGear[guid][hasItemBonus] = 1
                    end
                    local hasSetBonus = setBonus[itemID]
                    if hasSetBonus then
                        dbInspect[guid][hasSetBonus] = dbInspect[guid][hasSetBonus] and (dbInspect[guid][hasSetBonus] + 1) or 1
                        dbInspectGear[guid][hasSetBonus] = dbInspect[guid][hasSetBonus] and (dbInspect[guid][hasSetBonus] + 1) or 1
                    end
                end
            end
        else
            if dbInspectGear[guid] then
                for itemID, value in pairs (dbInspectGear[guid]) do
                    dbInspect[guid][itemID] = value
                end
            end
        end
        if isInspect then
            for gspellID, gTable in pairs(dbModifGlyph) do
                if gspellID and classID and db.isEnabledSpell[class] and db.isEnabledSpell[class][gspellID] and classID == gTable.class then
                    dbInspect[guid][gTable.mod] = 1
                end
            end
        else
            for i = 1, 6 do
                local enabled, _, glyphSpellID = GetGlyphSocketInfo(i)
                if enabled and glyphSpellID then dbInspect[guid][glyphSpellID] = 1 end
            end
        end

        if not dbInspect[guid]["constellation"] then
        	for key = 1, 40 do
                local _, _, icon, _, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, key, "HARMFUL")
                if spellID ~= nil and constellations[spellID] then
                    dbInspect[guid]["constellation"] = spellID
                end
            end
        end

        dbInspect[guid]["isInspected"] = true
    end

    self:UpdateIcons()

    if syncChache[guid] then
        local anchor = self:GetAnchorByUnit(unit)
        local syncSpells = syncChache[guid]
        if next(syncSpells) and anchor then
            for k, icon in pairs(anchor.icons) do
                if syncSpells[icon.abilityID] then
                    self:ProcessSync(anchor, icon.abilityID, syncSpells[icon.abilityID], unit)
                end
            end
        end
        syncChache[guid] = nil
    end
end


function ATT:InspectPlayer()
    self:UpdateUnitIDCache()
    self:ApplyAnchorSettings()

    local _, instanceType = IsInInstance()
    ATT.inRaid =  (IsInRaid() and instanceType ~= "arena")

    PlayerGUID = UnitGUID("player")
    self:ProcessInspect("player", PlayerGUID, 1, true)
end

local function itemsReadyCheck(unit)
    if not unit then return end
    for k = 13, 14 do
        local itemLink = GetInventoryItemLink(unit, INVSLOTS[k])
        if not itemLink then return end
    end
    return true
 end

function ATT:InspectIsReady(guid, unit)
    local itemsReady = itemsReadyCheck(unit)

    if guid and unit and guid ~= PlayerGUID  then
        if itemsReady then self:DequeueInspectByGUID(guid) else self:RequeueInspectByGUID(guid) end
        self:ProcessInspect(unit, guid, 1, itemsReady)
    end

    ClearInspectPlayer()
end


function ATT:EnqueueInspect(isUpdate)
    if not self.insEnabled then
        self:RegisterEvent("INSPECT_READY")
        self:RegisterEvent("INSPECT_TALENT_READY")
        self.insEnabled = true
    end
    local groupSize = nil

    if (IsInRaid()) then
        groupSize = GetNumGroupMembers() < self.groupSize and GetNumGroupMembers() or self.groupSize
    else
        groupSize = GetNumSubgroupMembers() < self.groupSize and GetNumSubgroupMembers() or self.groupSize
    end

    if groupSize == 0 then
        self.elapsedTime = -0.6

    	return
    end

    for i = 1, groupSize do --inRaidGr
        local unit = (ATT.inRaid and "raid" .. i) or ("party" .. i)
        local guid = UnitGUID(unit)
        if guid and guid ~= PlayerGUID then
            if isUpdate then
                if not dbInspect[guid] or (dbInspect[guid] and not dbInspect[guid]["isInspected"]) then
                    self:QueueInspect(guid)
                end -- here
            else

                self:QueueInspect(guid)
            end
        end
    end
    self.elapsedTime = -0.6
end

function ATT:ProcessInspectQueue()
    if UnitIsDead("player") then return end

    local cTime = GetTime()
    self.insTime = self.insTime or {}
    self.insStart = self.insStart or {}
    for i, guid in pairs(inspect_queue) do
        local unit = self:GetUnitByGUID(guid)

        if not unit or (unit and (not UnitIsConnected(unit) or (self.insStart[guid] and self.insStart[guid] + 120 < cTime))) then --here
            self:DequeueInspectByGUID(guid)
            break
        end

        if
            unit and
            not (InspectFrame and InspectFrame:IsShown()) and
            CheckInteractDistance(unit, 1) and
            CanInspect(unit) and
            (not self.insTime[guid] or self.insTime[guid] + 12 < cTime)
         then
            self.lastIns = guid
            self.insTime[guid] = cTime
            NotifyInspect(unit)
            break
        end
    end
end

function ATT:INSPECT_TALENT_READY()
    if (InspectFrame and InspectFrame:IsShown()) then
        return
    end

    local guid = self.lastIns
    local unit = self:GetUnitByGUID(guid)

    if unit and self.lastIns == guid then
         self.lastIns = nil
         self:InspectIsReady(guid, unit)
    end

    if #inspect_queue == 0 and self.insEnabled then
        self:UnregisterEvent("INSPECT_TALENT_READY")
        self.insEnabled = false
        self.insTime = {}
        self.insStart = {}
    end
end

function ATT:INSPECT_READY(guid)
    if (InspectFrame and InspectFrame:IsShown()) then
        return
    end

    local unit = self:GetUnitByGUID(guid)

    if unit and self.lastIns == guid then
         self.lastIns = nil
         self:InspectIsReady(guid, unit)
    end

    if #inspect_queue == 0 and self.insEnabled then
        self:UnregisterEvent("INSPECT_READY")
        self.insEnabled = false
        self.insTime = {}
        self.insStart = {}
    end
end


function ATT:SavePositions()
    for k, anchor in ipairs(anchors) do
        local scale = anchor:GetEffectiveScale()
        local worldscale = UIParent:GetEffectiveScale()
        local x = anchor:GetLeft() * scale
        local y = (anchor:GetTop() * scale) - (UIParent:GetTop() * worldscale)
        if not db.positions[k] then
            db.positions[k] = {}
        end
        db.positions[k].x = x
        db.positions[k].y = y
    end
end

function ATT:CheckBlizzFrames()
    local compact = C_CVar:GetValue("C_CVAR_USE_COMPACT_SOLO_FRAMES")
    local UseCombinedGroups = CompactRaidFrameManager_GetSetting and CompactRaidFrameManager_GetSetting("KeepGroupsTogether")
    local frametype = nil

    if ATT.inRaid then
        if compact and _G["CompactPartyFrameMember1"] and _G["CompactPartyFrameMember1"]:IsVisible() then
            frametype = "CompactPartyFrameMember%d"
        else
            if not UseCombinedGroups then
                frametype = "CompactRaidFrame%d"
            else
                frametype = "CompactRaidGroup1RGMember%d"
            end
        end
    else
        if compact then
            if _G["CompactPartyFrameMember1"] and _G["CompactPartyFrameMember1"]:IsVisible() then
                frametype = "CompactPartyFrameMember%d"
            else
                if not UseCombinedGroups then
                    frametype = "CompactRaidFrame%d"
                else
                    frametype = "CompactRaidGroup1RGMember%d"
                end
            end
        else
            frametype = "PartyMemberFrame%d"
        end
    end

    return frametype
end

function ATT:FindFrames()
    hookedFrames = {}
    local frametype = nil
    local cunit = nil

    if db.attach == 1 and ATT_DropDown1 and ATT_DropDown1.values[7] then
        frametype = customframes[ATT_DropDown1.values[7]].cframe
        cunit = customframes[ATT_DropDown1.values[7]].cunitid
    else
        if db.attach == 1 or db.attach == 2 then
            frametype = self:CheckBlizzFrames()
        elseif db.attach and db.attach > 2 and customframes[db.attach] then
            frametype = customframes[db.attach].cframe
            cunit = customframes[db.attach].cunitid
        end
    end

    if not frametype then
        return
    end

    local isGrouped = string.find(frametype, "1RG")
    if isGrouped then
        for k = 1, 8 do
            local framename = string.gsub(frametype, "1RG", k)
            for i = 1, 5 do
                local name = format(framename, i)
                local frame = _G[name]
                local unit = frame and (cunit and frame[cunit] or frame['unit'])
                local guid = unit and UnitGUID(unit)
                if guid and frame:IsShown() then
                    hookedFrames[guid] = frame
                end
            end
        end
    else
        if frametype == "CompactPartyFrameMember%d" then
            for i = 1, 5 do
                local name = "CompactPartyFrameMember" .. i
                local frame = _G[name]
                local unit = frame and (cunit and frame[cunit] or frame['unit'])
                local guid = unit and UnitGUID(unit)
                if guid and frame:IsShown() then
                    hookedFrames[guid] = frame
                end
            end
        elseif frametype == "PartyMemberFrame%d" then
            if PlayerGUID and _G["PlayerFrame"] and _G["PlayerFrame"]:IsShown() then hookedFrames[PlayerGUID] = _G["PlayerFrame"] end
            for i = 1, 4 do
                local name = "PartyMemberFrame" .. i
                local frame = _G[name]
                local unit = frame and (cunit and frame[cunit] or frame['unit'])
                local guid = unit and UnitGUID(unit)
                if guid and frame:IsShown() then
                    hookedFrames[guid] = frame
                end
            end
        else
            for i = 1, 40 do
                local name = format(frametype, i)
                local frame = _G[name]
                local unit = frame and (cunit and frame[cunit] or frame['unit'])
                local guid = unit and UnitGUID(unit)
                if guid and frame:IsShown() then
                    hookedFrames[guid] = frame
                end
            end
        end
    end
    if PlayerGUID and _G["PlayerFrame"] and (not hookedFrames[PlayerGUID] or (hookedFrames[PlayerGUID] and not hookedFrames[PlayerGUID]:IsVisible() and GetNumGroupMembers() == 0)) then
        hookedFrames[PlayerGUID] = _G["PlayerFrame"]
    end

    --print(frametype)
end

function ATT:UpdatePositions()
    db.positions = db.positions or {}
    self:FindFrames()

    for k, anchor in ipairs(anchors) do
        anchors[k]:ClearAllPoints()
        anchors[k]:SetScale(db.anchorScale or 1)
        local scale = anchors[k]:GetEffectiveScale()
        local offsetX = db.offsetX / scale
        local offsetY = db.offsetY / scale

        local unit = (ATT.inRaid and "raid" .. k) or ((k == 5 and "player") or (k ~= 5 and "party" .. k))
        local anchorGuid = unit and UnitGUID(unit)
        local raidFrame =  hookedFrames[anchorGuid]

        if anchor.GUID == PlayerGUID and db.selfAttach then raidFrame = nil end

        if raidFrame and db.attach and db.attach ~= 0 then
            if not db.attachPos or db.attachPos == 0  then
                  anchors[k]:SetPoint("BOTTOMLEFT", raidFrame, "TOPLEFT", offsetX, offsetY) --anchorTOPLEFT
            elseif db.attachPos == 1 then
                  anchors[k]:SetPoint("BOTTOMRIGHT", raidFrame, "TOPRIGHT",  offsetX, offsetY) --anchorTOPRIGHT
            elseif db.attachPos == 2 then
                  anchors[k]:SetPoint("TOPLEFT", raidFrame, "BOTTOMLEFT", offsetX, offsetY) --anchorBOTTOMLEFT
            elseif db.attachPos == 3 then
                    anchors[k]:SetPoint("TOPRIGHT", raidFrame, "BOTTOMRIGHT", offsetX, offsetY) --anchorBOTTOMRIGHT
            elseif db.attachPos == 4 then
               anchors[k]:SetPoint("CENTER", raidFrame, "LEFT", offsetX, offsetY) --anchorCENTERLEFT
            elseif db.attachPos == 5 then
               anchors[k]:SetPoint("CENTER", raidFrame, "RIGHT", offsetX, offsetY) --anchorCENTERRIGHT
            else
                anchors[k]:SetPoint("BOTTOMLEFT", raidFrame, "TOPLEFT", offsetX, offsetY) --anchorTOPLEFT
             end
        else
            if db.positions[k] then
                local x = db.positions[k].x / scale
                local y = db.positions[k].y / scale 
                anchors[k]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x  , y )
            else
                anchors[k]:SetPoint("CENTER", UIParent, "CENTER")
            end
        end
    end
end

function ATT:CreateAnchors()
    for i = 1, 40 do
        local anchor = CreateFrame("Frame", "ATTAnchor" .. i, ATTAnchor) --GlowBoxTemplate
        local index = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        anchor:SetSize(24, 22)
        anchor:EnableMouse(true)
        anchor:SetMovable(true)
        anchor.text = anchor:CreateFontString("text", "ARTWORK", "GameFontNormalSmall")
        anchor.text:SetSize(18, 18)
        anchor.text:SetPoint("CENTER")
        anchor.text:SetText(i)
        --anchor:Show()
        anchor.icons = {}
        anchor.freeProcs = {}
        anchor.StopAllIcons = function(flag)
            if anchor.GUID then activeBUFFS[anchor.GUID] = {} ;  activeGUIDS[anchor.GUID] = {} end

            for k, icon in ipairs(anchor.icons) do
                if flag ~= "raidstop" or (flag == "raidstop" and icon.cooldown and icon.cooldown >= 120) then
                    icon.Stop();
                    icon.seen = nil
                end
            end
        end
        anchor.StopAllGlow = function(flag)
            for k, icon in ipairs(anchor.icons) do
               -- LGlows.HideOverlayGlow2(icon)
               ATT:HideGlow(icon)
            end
        end
        anchor:SetScript("OnMouseDown",
            function(self, button)
                if button == "LeftButton" and db.attach == 0 or (anchor.GUID == PlayerGUID and db.selfAttach) then
                    self:StartMoving();
                end
            end)
        anchor:SetScript("OnMouseUp",
            function(self, button)
                if button == "LeftButton" and db.attach == 0 or (anchor.GUID == PlayerGUID and db.selfAttach) then
                    self:StopMovingOrSizing();
                    ATT:SavePositions()
                end
            end)

        anchor:Hide()
        anchors[i] = anchor
    end
end

local function CreateIcon(anchor)
    local icon = CreateFrame("Frame", anchor:GetName() .. "Icon" .. (#anchor.icons + 1), ATTIcons, "ATTButtonTemplateClassic")
    icon:SetSize(40, 40)
    icon:SetAlpha(db.iconAlpha or 1)
    
    local cd = CreateFrame("Cooldown", icon:GetName() .. "Cooldown", icon, "CooldownFrameTemplate")
    icon.cd = cd

    icon.Start = function(sentCD, nextcharge, rate)
       -- if activeBUFFS[guid] and activeBUFFS[guid][icon.abilityID] then return end
       if activeBUFFS[icon.GUID] and activeBUFFS[icon.GUID][icon.abilityID] then return end --freeprocs
       local cTime = GetTime()

        if icon.raterecovery then --and not icon.excluded
            rate = icon.raterecovery
            cTime = cTime * (1 - rate) + cTime * rate
            sentCD = sentCD * rate
            icon.cdrecovery = sentCD
        end
        icon.texture:SetVertexColor(1, 1, 1)

       -- local chargesText = icon.chargesText:GetText() and icon.chargesText:GetText():match("^[0-9]+$")
       -- local charges = chargesText and tonumber(chargesText)
       -- getIconCharges
        local charges = icon.maxcharges and getIconCharges(icon)
        if icon.maxcharges and charges then
            if charges == icon.maxcharges or nextcharge == icon.maxcharges then
                CooldownFrame_Set(cd, cTime, sentCD, true, true, rate)
                icon.starttime = cTime
                charges = charges - 1
                icon.chargesText:SetText(charges)
            elseif charges < icon.maxcharges and nextcharge == 5 then
                CooldownFrame_Set(cd, cTime, sentCD, true, true, rate)
                icon.starttime = cTime
                icon.chargesText:SetText(charges)
            elseif charges > 1 and nextcharge == 1 and icon.starttime < cTime and charges < icon.maxcharges then
                charges = charges - 1
                icon.chargesText:SetText(charges)
            elseif charges == 1 and nextcharge == 1 and icon.starttime < cTime then
                cd:SetDrawEdge(true)
                charges = charges - 1
                icon.chargesText:SetText(charges)
            end
        else
            CooldownFrame_Set(cd, cTime, sentCD, true, false, rate)
            icon.starttime = cTime
        end

        icon:Show()
        icon.active = true;
        icon.flashAnim:Play()


        activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
        activeGUIDS[icon.GUID][icon.abilityID] = activeGUIDS[icon.GUID][icon.abilityID] or {}
        activeGUIDS[icon.GUID][icon.abilityID].chargeleft = charges
        activeGUIDS[icon.GUID][icon.abilityID].starttime = icon.starttime
        activeGUIDS[icon.GUID][icon.abilityID].cooldown = sentCD
        if db.hidden then ATT:ToggleDisplay(anchor, icon.GUID) end
        if icon.ability and icon.abilityID and anchor.spec and nextcharge ~= 5 then
            if db.alertCD[anchor.spec][icon.abilityID] then PlaySound(8959, "Master"); end
            if db.alertCDtext[anchor.spec][icon.abilityID] then
                local playername = select(6, GetPlayerInfoByGUID(icon.GUID))
                if playername then
                    UIErrorsFrame:AddMessage("|T" .. icon.texture:GetTexture() ..":18|t |cffFF4500" .. icon.ability .. "|r  - used by ->>  |cffFF4500" .. playername .. "|r");
                end
            end
        end
    end

    icon.Stop = function()
        if icon.glowDuration then
           -- LGlows.HideOverlayGlow2(icon)
           ATT:HideGlow(icon)
        end
        CooldownFrame_Set(cd, 0, 0, 0);
        icon.starttime = 0

        if icon.inUse and icon.GUID then
            activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
            activeGUIDS[icon.GUID][icon.abilityID] = activeGUIDS[icon.GUID][icon.abilityID] or {}
            activeGUIDS[icon.GUID][icon.abilityID].starttime = icon.starttime
            activeGUIDS[icon.GUID][icon.abilityID].cooldown = icon.cooldown
        end
        if icon.inUse and db.hidden then ATT:ToggleDisplay(anchor, icon.GUID) end

        if icon.inUse and icon.maxcharges and icon.GUID then
            icon.chargesText:SetText(icon.maxcharges) 
            activeGUIDS[icon.GUID][icon.abilityID].chargeleft = icon.maxcharges
        end
    end

    icon.SetTimer = function(starttime, cooldown, rate, isRate, charges, isSync)
       if activeBUFFS[icon.GUID] and activeBUFFS[icon.GUID][icon.abilityID] then return end --freeprocs
        
       local charges = icon.maxcharges and (charges or getIconCharges(icon))

        if icon.raterecovery and icon.inUse and not isRate then
             rate = icon.raterecovery
          if isSync then 
            starttime = GetTime() * (1 - rate) + icon.starttime * rate
          else 
             starttime = icon.starttime - ((icon.starttime - starttime) * rate)
          end
             cooldown = icon.cooldown * rate
             --print(cooldown .. " - " ..(cooldown * rate) .. " - "..icon.cdrecovery )
        end

        if icon.inUse then
            icon.texture:SetVertexColor(1, 1, 1)
            CooldownFrame_Set(cd, starttime, cooldown, true, false, rate)
            icon.active = true
            icon.starttime = starttime
 
            activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
            activeGUIDS[icon.GUID][icon.abilityID] = activeGUIDS[icon.GUID][icon.abilityID] or {}
            activeGUIDS[icon.GUID][icon.abilityID].starttime = icon.starttime
            activeGUIDS[icon.GUID][icon.abilityID].cooldown = cooldown

            if charges then
            icon.chargesText:SetText(charges)
            cd:SetDrawEdge(true)

            activeGUIDS[icon.GUID][icon.abilityID].chargeleft = charges
        end

            if icon.inUse and db.hidden then ATT:ToggleDisplay(anchor, icon.GUID) end
        end
    end

    icon.SetOldTimer = function(starttime, cooldown, rate, isRate, charges)
        if icon.raterecovery or not icon.inUse then
            return
        end
        local charges = icon.maxcharges and (charges or getIconCharges(icon))

        icon.texture:SetVertexColor(1, 1, 1)
        CooldownFrame_Set(cd, starttime, cooldown, true, false, rate)

        if charges then
            icon.chargesText:SetText(charges)
            cd:SetDrawEdge(true)
            activeGUIDS[icon.GUID][icon.abilityID].chargeleft = charges
        end
        icon.active = true
        icon.starttime = starttime
    end

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(true)
    icon.texture = texture

    ATT:ApplyIconTextureBorder(icon)

    icon.chargesText = icon:CreateFontString(nil, "OVERLAY", "DialogButtonHighlightText")
    icon.chargesText:SetTextColor(1, 1, 1)
    icon.chargesText:SetText("")
    icon.chargesText:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
    icon.chargesText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 3)

    -- tooltip:
    if not db.showTooltip then
        icon:EnableMouse(false)
    end

    icon:SetScript('OnEnter', function()
        if db.showTooltip and icon.abilityID then
            local tooltip = Spell:CreateFromSpellID(icon.abilityID)
            tooltip:ContinueOnSpellLoad(function()
                GameTooltip:ClearLines();
                GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
                GameTooltip:SetSpellByID(icon.abilityID)
                GameTooltip:AddLine("Spell ID: " .. icon.abilityID .. " - iCD: " .. icon.cooldown .. " sec", 1, 1, 1)
                GameTooltip:SetPadding(16, 0)
                -- GameTooltip:SetAlpha(db.iconAlpha or 1)
                GameTooltip:Show()
            end)
            icon:EnableMouse(true)
        end
    end)

    icon:SetScript('OnLeave', function()
        if db.showTooltip and icon.abilityID then
            GameTooltip:ClearLines()
            GameTooltip:Hide()
            icon:EnableMouse(true)
        end
    end)

    local Masque, MSQ_Version = LibStub("Masque", true)
    if Masque and MSQ_Version then
        icon.MasqueGroup = Masque:Group("Ability Team Tracker")
        icon.MasqueGroup:AddButton(icon, {
            FloatingBG = false,
            Icon = icon.texture,
            Cooldown = icon.cd,
        })
    end

    return icon
end

-- adds a new icon
function ATT:AddIcon(icons, anchor)
    local newicon = CreateIcon(anchor)
    icons[#icons + 1] = newicon
    return newicon
end

function ATT:ApplyIconTextureBorder(icon)
    icon:SetAlpha(db.iconAlpha or 1)
    icon.texture:SetVertexColor(1, 1, 1)
    if db.showIconBorders then
        icon.texture:SetTexCoord(0, 1, 0, 1)
    else
        icon.texture:SetTexCoord(0.07, 0.9, 0.07, 0.90)
    end
end

function ATT:UpdateAnchorGUID(anchor, unit, guid)
    local _, class = UnitClass(unit)
    anchor.GUID = guid
    anchor.class = class
    local icons = anchor.icons
    local numIcons = 1
    local dbInspected = dbInspect[guid]
    local constellationID = nil
    if dbInspected then
        constellationID = dbInspected["constellation"]
    end

    if dbInspected and dbInspect[guid]["isInspected"] and class and dbImport[class] and type(db.isEnabledSpell[class] == "table") then
    --if class and dbImport[class] and type(db.isEnabledSpell[class] == "table") then
        -- Trinkets
        for abilityIndex, abilityTable in pairs(self:MergeTable(class, "trinkets")) do
            local name, id, trinketId, cooldown, texture, spellTName = abilityTable.name, abilityTable.ability, abilityTable.trinketId, abilityTable.cooldown, abilityTable.texture , abilityTable.spellTName
            if
                name and
                id and
                trinketId and
                dbInspected and
                db.isEnabledSpell[class][trinketId] and
                dbInspected[trinketId]
            then
                local icon = icons[numIcons] or self:AddIcon(icons, anchor)
                icon.texture:SetTexture(texture or self:FindAbilityIcon(name, id))
                icon.GUID = anchor.GUID
                icon.ability = spellTName and spellTName or name
                icon.abilityID = id
                icon.cooldown = cooldown
                icon.maxcharges = nil
                icon.chargesText:SetText()
                icon.inUse = true
                icon.excluded = true
                icon.race = nil

                ATT:ApplyIconTextureBorder(icon)
                activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
                if activeGUIDS[icon.GUID][id] then
                    icon.SetOldTimer(activeGUIDS[icon.GUID][id].starttime, activeGUIDS[icon.GUID][id].cooldown, nil , nil, activeGUIDS[icon.GUID][id].chargeleft )
                else
                    icon.Stop()
                end
                numIcons = numIcons + 1
            end
        end

        -- Constellations
        for abilityIndex, abilityTable in pairs(self:MergeTable(class, "racials")) do
            local constellation, id, cooldown, cdshare, texture, name = abilityTable.constellation, abilityTable.ability,
                abilityTable.cooldown, abilityTable.cdshare, abilityTable.texture, abilityTable.name

            if name and id and db.isEnabledSpell[class][id] and constellationID == constellation then
                local icon = icons[numIcons] or self:AddIcon(icons, anchor)
                icon.texture:SetTexture(texture or self:FindAbilityIcon(name, id))
                icon.GUID = anchor.GUID
                icon.ability = name
                icon.abilityID = id
                icon.cooldown = cooldown
                icon.maxcharges = nil
                icon.chargesText:SetText()
                icon.inUse = true
                icon.race = constellation
                icon.excluded = true
                icon.racecdshare = cdshare

                ATT:ApplyIconTextureBorder(icon)
                activeGUIDS[icon.GUID] = activeGUIDS[icon.GUID] or {}
                if activeGUIDS[icon.GUID][id] then
                    icon.SetOldTimer(activeGUIDS[icon.GUID][id].starttime, activeGUIDS[icon.GUID][id].cooldown, nil , nil, activeGUIDS[icon.GUID][id].chargeleft )
                else
                    icon.Stop()
                end
                numIcons = numIcons + 1
            end
        end

        -- Abilities:
        if not db.bgMode then
            for abilityIndex, abilityTable in pairs(self:MergeTable(class, "abilities", true)) do
                local name, id, cooldown, charges, custom, spellrace, texture = abilityTable.name, abilityTable.ability,
                    abilityTable.cooldown, abilityTable.charges, abilityTable.custom, abilityTable.race,
                    abilityTable.texture
                local modif = dbModif[id]
                local glyphModif = dbModifGlyph[id]
                local bonusModif = dbModifBonus[id]

                if name and spellrace and (raceID ~= spellrace[1] and raceID ~= spellrace[2] and raceID ~= spellrace[3]) then name = nil end
                if name and (custom and not db.isEnabledSpell[class][id .. "custom"]) or (not custom and not db.isEnabledSpell[class][id]) or (dbInspected and dbInspected[name] == 0) then name = nil end

                if name and modif and dbInspected and dbInspected[modif.mod] and dbInspected[modif.mod] > 0 then
                    local newcd = dbInspected[modif.mod]
                    cooldown = cooldown - (modif.rank[newcd] or modif.rank[1])
                end

                if name and glyphModif and dbInspected and dbInspected[glyphModif.mod] then cooldown = cooldown - glyphModif.cd end

                if name and bonusModif and dbInspected and dbInspected[bonusModif.mod] and dbInspected[bonusModif.mod] >= bonusModif.rank then
                    cooldown = cooldown - bonusModif.cd
                end

                if name and bonusModif then
                    for index, bonusmod in pairs(bonusModif.mod) do
                        if dbInspected and dbInspected[bonusmod] and bonusModif.rank[index] and (dbInspected[bonusmod] >= bonusModif.rank[index]) then
                            cooldown = cooldown - bonusModif.cd[index]
                        end
                    end
                end

                if name and id then
                    local icon = icons[numIcons] or self:AddIcon(icons, anchor)
                    icon.texture:SetTexture(texture or self:FindAbilityIcon(name, id))
                    icon.GUID = anchor.GUID
                    icon.ability = name
                    icon.abilityID = id
                    icon.cooldown = cooldown
                    icon.maxcharges = nil
                    icon.chargesText:SetText()
                    icon.inUse = true
                    icon.race = nil

                    ATT:ApplyIconTextureBorder(icon)
                    if not activeGUIDS[icon.GUID] and icon.GUID then
                        activeGUIDS[icon.GUID] = {}
                    end
                    if activeGUIDS[icon.GUID] and activeGUIDS[icon.GUID][id] then
                        icon.SetOldTimer(activeGUIDS[icon.GUID][id].starttime, activeGUIDS[icon.GUID][id].cooldown, nil , nil, activeGUIDS[icon.GUID][id].chargeleft )
                    else
                        icon.Stop()
                    end
                    numIcons = numIcons + 1
                end
            end
        end
    end

    -- clean leftover icons
    for j = numIcons, #icons do
        icons[j].ability = nil
        icons[j].abilityID = nil
        icons[j].class = nil
        icons[j].seen = nil
        icons[j].active = nil
        icons[j].inUse = nil
        icons[j].showing = nil
    end
    self:ToggleDisplay(anchor, guid)
end

function ATT:ToggleDisplay(anchor, unitGuid, isUpdate)
    local icons = anchor.icons
    local lastActiveIndex = 0
    local oldActiveIndex = 0
    local count = 0
    -- if isUpdate then anchor.SyncCDs = {} end

    for k, icon in pairs(icons) do
        -- if isUpdate and icon.inUse and icon.abilityID then table.insert(anchor.SyncCDs, icon.abilityID) end
        if icon.active and icon.cooldown then
            icon.timeleft = icon.starttime + icon.cooldown - GetTime()
            if icon.timeleft <= 0 or not icon.timeleft then
                if activeGUIDS[icon.GUID] and activeGUIDS[icon.GUID][icon.abilityID] then
                    activeGUIDS[icon.GUID][icon.abilityID] = nil
                end
                icon.active = nil
            end
        end
        ATT:ApplyIconTextureBorder(icon)
        if db.showTooltip then
            icon:EnableMouse(true)
        else
            icon:EnableMouse(false)
        end -- click-through
        if icon and icon.abilityID and icon.inUse and unitGuid and unitGuid == anchor.GUID and icon.GUID == unitGuid then
            icon.showing = (activeGUIDS[icon.GUID] and activeGUIDS[icon.GUID][icon.abilityID] and icon.active) or
                (not db.hidden)
        end
        icon:ClearAllPoints()
        icon:Hide()
    end

    local attachPos = (db.attachPos or 0) % 2 == 0
    for k, icon in pairs(icons) do
        if icon and icon.abilityID and icon.showing and icon.inUse and unitGuid and unitGuid == anchor.GUID and
            icon.GUID == unitGuid then
            if db.reverseIcons then
                if db.IconRows > 1 then
                    if lastActiveIndex == 0 then
                         icon:SetPoint(attachPos and "TOPLEFT" or "TOPRIGHT", anchor, attachPos and "BOTTOMRIGHT" or "BOTTOMLEFT")
                    elseif (count >= db.IconRows and count % db.IconRows == 0) then
                        icon:SetPoint(attachPos and "LEFT" or "RIGHT", icons[oldActiveIndex],attachPos and "RIGHT" or "LEFT", attachPos and 1 * db.iconOffsetY or -1 * db.iconOffsetY, 0)
                    else
                        if db.growUP then
                            icon:SetPoint(attachPos and "BOTTOM" or "BOTTOM", icons[lastActiveIndex],attachPos and "TOP" or "TOP", 0, 1 * db.iconOffsetX)
                        else
                            icon:SetPoint(attachPos and "TOP" or "TOP", icons[lastActiveIndex], attachPos and "BOTTOM" or "BOTTOM", 0, -1 * db.iconOffsetX)

                        end
                    end
                else
                    if lastActiveIndex == 0 then
                        icon:SetPoint(attachPos and "TOPLEFT" or "TOPRIGHT", anchor, attachPos and "BOTTOMRIGHT" or "BOTTOMLEFT", attachPos and 1 * db.iconOffsetY or -1 * db.iconOffsetY, 0)
                    else
                        icon:SetPoint(attachPos and "LEFT" or "RIGHT", icons[lastActiveIndex],attachPos and "RIGHT" or "LEFT", attachPos and 1 * db.iconOffsetY or -1 * db.iconOffsetY, 0)
                    end
                end
            else
                if db.IconRows > 1 then
                    if lastActiveIndex == 0 then
                       icon:SetPoint(attachPos and "TOPRIGHT" or "TOPLEFT", anchor,attachPos and "BOTTOMLEFT" or "BOTTOMRIGHT")
                    elseif (count >= db.IconRows and count % db.IconRows == 0) then
                        icon:SetPoint(attachPos and "RIGHT" or "LEFT", icons[oldActiveIndex],attachPos and "LEFT" or "RIGHT", attachPos and -1 * db.iconOffsetY or db.iconOffsetY, 0)
                    else
                        if db.growUP then
                            icon:SetPoint(attachPos and "BOTTOM" or "BOTTOM", icons[lastActiveIndex],attachPos and "TOP" or "TOP", 0, 1 * db.iconOffsetX)
                        else
                             icon:SetPoint(attachPos and "TOP" or "TOP", icons[lastActiveIndex],attachPos and "BOTTOM" or "BOTTOM", 0, -1 * db.iconOffsetX)
                        end
                    end
                else
                    if lastActiveIndex == 0 then
                        icon:SetPoint(attachPos and "TOPRIGHT" or "TOPLEFT", anchor,attachPos and "BOTTOMLEFT" or "BOTTOMRIGHT", attachPos and -1 * db.iconOffsetY or db.iconOffsetY, 0)
                    else
                        icon:SetPoint(attachPos and "RIGHT" or "LEFT", icons[lastActiveIndex],attachPos and "LEFT" or "RIGHT", attachPos and -1 * db.iconOffsetY or db.iconOffsetY, 0)
                    end
                end
            end

            lastActiveIndex = k
            if (count == 0 or (count >= db.IconRows and count % db.IconRows == 0)) then
                oldActiveIndex = count == 0 and k or lastActiveIndex
            end
            count = count + 1
            icon:Show()
        end
    end
end

function ATT:UpdateIcons()
    for k, anchor in ipairs(anchors) do
        local unit = (ATT.inRaid and "raid" .. k) or ((k == 5 and "player") or (k ~= 5 and "party" .. k))
        local guid = unit and UnitGUID(unit)

        if db.lock or not guid then anchor:Hide() else anchor:Show() end

        if guid and guid == PlayerGUID and (self.hideSelf) then
            anchor:Hide()
            anchor.GUID = nil
            anchor.class = nil
            guid = nil
        end

        if guid and guid ~= PlayerGUID and (self.groupSize < k or self.groupSize == 0) then
            anchor:Hide()
            anchor.GUID = nil
            anchor.class = nil
            guid = nil
        end

        if not guid then
            anchor:Hide()
            if anchor.GUID then activeBUFFS[anchor.GUID] = {} end
            anchor.GUID = nil
            anchor.class = nil
            guid = nil
        end

        self:UpdateAnchorGUID(anchor, unit, guid)
    end
end

function ATT:ApplyAnchorSettings()
    local _, type = IsInInstance()
    ATT.inRaid = (IsInRaid() and type ~= "arena")
    ATTIcons:SetScale(db.scale or 1)
    self.groupSize = self.groupSize or 5

    if (type == "arena") then
        self.groupSize = db.visArena or 5
        self.hideSelf = db.visArenaSelf
        ATTIcons:Show();
        self:Show();
    elseif (type == "party") then
        self.groupSize = db.visDungeon or 5
        self.hideSelf = db.visDungeonSelf
        ATTIcons:Show();
        self:Show();
    elseif (type == "scenario") then
        self.groupSize = db.visScenario or 5
        self.hideSelf = db.visScenarioSelf
        ATTIcons:Show();
        self:Show();
    elseif (type == "raid") then
        self.groupSize = db.visInraid or 5
        self.hideSelf = db.visInraidSelf
        ATTIcons:Show();
        self:Show();
    elseif (type == "pvp") then
        self.groupSize = db.visInbg or 5
        self.hideSelf = db.visInbgSelf
        ATTIcons:Show();
        self:Show();
    elseif (type == "none") then
        self.groupSize = db.visOutside or 5
        self.hideSelf = db.visOutsideSelf
        if self.groupSize < 5 then
            self.groupSize = 0
            self.hideSelf = true
            ATTIcons:Hide();
            self:Hide();
        else
            ATTIcons:Show();
            self:Show();
        end
    else
        self.groupSize = 0
        self.hideSelf = true
        ATTIcons:Hide();
        self:Hide();
    end

   if self.groupSize == 0 and self.hideSelf then
      ATTIcons:Hide();
      self:Hide();
   end

    if not db.lock and ATTIcons:IsShown() then
        ATTAnchor:Show()
    else
        ATTAnchor:Hide()
    end

    self:UpdatePositions();
    self:UpdateIcons();
end

function ATT:UNIT_AURA(unit)
    if not ATTIcons:IsShown() then return end
    local anchor = self:GetAnchorByUnit(unit)
    if not anchor then return end
    -- Feign Death workaround fix
    local guid = UnitGUID(unit)
    local fd = select(1, AuraUtil.FindAuraByName(GetSpellInfo(5384), unit))
    if not fd and isFWW["fd" .. guid] == guid then
        C_Timer:After(0.12,
            function()
                self:StartCooldown(GetSpellInfo(5384), unit, 5384);
                isFWW["fd" .. guid] = nil;
            end)
    end
end

function ATT:PLAYER_ENTERING_WORLD()
    self:UpdateUnitIDCache()
    self:CheckProfile()

    C_Timer:After(1, function()
        local _, instanceType = IsInInstance()
        self:InspectPlayer()
        self:StopAllGlow()
        self:UpdateGroup()
        if instanceType == "arena" then
            self:StopAllIcons();
        end
        self:SendUpdate()
    end)
end

function ATT:PARTY_MEMBERS_CHANGED()
    if (not ATTIcons:IsShown()) then
        return
    end

    self:UpdateUnitIDCache()
    self:ApplyAnchorSettings()
    --self:EnqueueInspect(true)


    C_Timer:After(0.05, function()
        self:UpdateUnitIDCache()
        self:ApplyAnchorSettings()
        self:EnqueueInspect(true)
    end)
end

function ATT:UpdateGroup()
    self:ApplyAnchorSettings();
    self:EnqueueInspect()
end

function ATT:GROUP_JOINED()
    self:UpdateUnitIDCache()
    self:ApplyAnchorSettings()
    self:EnqueueInspect()
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        self:StopAllIcons();
    end
end

function ATT:FindAbilityByName(abilities, name)
    if abilities then
        for i, v in pairs(abilities) do
            if v and v.ability and v.ability == name then return v, i end
        end
    end
end

function ATT:StartCooldown(spellName, unit, SentID, flag)
    local anchor = self:GetAnchorByUnit(unit)
    if not unit or not anchor then return end
    local guid = anchor.GUID

    if not anchor or not guid then return end
    self:TrackCooldown(anchor, spellName, SentID, unit, guid, flag)

    -- trinket to constellation
    if spellName == PvPTrinketName then
        for k, icon in ipairs(anchor.icons) do
            local constellationCD = ATTdbs.constellationsShare[icon.abilityID]
            if constellationCD and icon.abilityID then
                local duration = 0
                if icon.starttime then
                    duration = icon.starttime + icon.cooldown - GetTime()
                end

                if duration and duration < constellationCD then
                    local starttime = GetTime() - icon.cooldown + constellationCD
                    icon.SetTimer(starttime, icon.cooldown)
                end
            end
        end
    end

    -- constellation to trinket
    if ATTdbs.constellationsShare[SentID] then
        local cooldown = ATTdbs.constellationsShare[SentID]
        for k, icon in ipairs(anchor.icons) do
            if icon.inUse and icon.ability == PvPTrinketName then
                local duration = 0
                if icon.starttime then
                    duration = icon.starttime + icon.cooldown - GetTime()
                end

                if duration and duration < cooldown then
                    local starttime = GetTime() - icon.cooldown + cooldown
                    icon.SetTimer(starttime, icon.cooldown)
                end
            end
        end
    end
end

function ATT:TrackCooldown(anchor, ability, SentID, unit, guid, flag) --TODO per ID
    local rate = nil
    for k, icon in ipairs(anchor.icons) do
        if icon.cooldown and icon.inUse then
            -- Direct cooldown
            if
                (icon.ability and icon.ability == ability)
                or
                (
                    icon.race and
                    ATTdbs.constellations[icon.race] and
                    ATTdbs.constellations[icon.race]['alt'] and
                    ATTdbs.constellations[icon.race]['alt'][SentID]
                )
            then --here
                if flag and icon.cd then
                    icon.cd:Hide()
                    icon.texture:SetVertexColor(0.4, 0.4, 0.4)
                    break
                end
                icon.seen = true
                icon.Start(icon.cooldown, 1, rate)
            end
        end
        -- Cooldown Share
        if ShareCD[ability] and ShareCD[ability][icon.abilityID] and icon.inUse then icon.Start(icon.cooldown, 1, rate) end

        -- Cooldown reset
        if cooldownResetters[ability] then
            if type(cooldownResetters[ability]) == "table" and (cooldownResetters[ability][icon.abilityID] or cooldownResetters[ability]["ALL"]) and not icon.excluded and icon.inUse then
                icon.Stop()
            end
        end
    end
end

function ATT:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, srcFlags, destGUID, destName, flags, SentID, spellName, spellSchool, auraType, ...)
    if not ATTIcons:IsShown() then return end

    local unit = self:GetUnitByGUID(sourceGUID)
    local unitDest = self:GetUnitByGUID(destGUID)

    if unit and (event == "SPELL_CAST_SUCCESS") and not ATTdbs.dbBannedIds[SentID] then
        self:StartCooldown(spellName, unit, SentID, dbAuraRemoved[spellName] and "AuraOn")
    end
    if unit and (event == "SPELL_AURA_APPLIED") and (auraType == "BUFF") then
        if dbAuraApplied[spellName] then self:StartCooldown(spellName, unit, SentID, dbAuraApplied and "AuraOn") end
    end
    if unit and (event == "SPELL_AURA_REMOVED") and (auraType == "BUFF") then
        if dbAuraRemoved[spellName] then self:StartCooldown(spellName, unit, SentID) end
    end

    if db.glow and unit and ((event == "SPELL_AURA_APPLIED") or (event == "SPELL_AURA_REMOVED")) and (auraType == "BUFF") then
        local dest = (unitDest and unitDest) or unit
        C_Timer:After(0.05, function() self:IconGlow(unit, spellName, event, dest, SentID) end)
    end
end

function ATT:IconGlow(unit, spellName, event, unitDest, SentID)
    if not unit then
        return
    end
    local anchor = self:GetAnchorByUnit(unit)
    if not anchor then
        return
    end

    for k, icon in ipairs(anchor.icons) do
        if icon.inUse and event == "SPELL_AURA_APPLIED" and (SentID == icon.abilityID) and not icon.race then --spellName == icon.ability
            local duration = select(6, AuraUtil.FindAuraByName(spellName, unitDest))
            if icon.showing and icon.cooldown and duration and tonumber(duration) > 1 and tonumber(icon.cooldown) > tonumber(duration) then -- here (icon.active or dbAuraRemoved[SentID])
                self:ShowGlow(icon, duration)
                --LGlows.ShowOverlayGlow2(icon)
                C_Timer:After(duration + 0.5, function()
                    local isActive = select(1, AuraUtil.FindAuraByName(spellName, unitDest));
                    if not isActive then
                        --LGlows.HideOverlayGlow2(icon)
                        ATT:HideGlow(icon)
                    end
                end)
            end
        end
        if event == "SPELL_AURA_REMOVED" and SentID == icon.abilityID and icon.glowDuration then
            --LGlows.HideOverlayGlow2(icon)
            ATT:HideGlow(icon)
        end
    end
end

function ATT:UNIT_SPELLCAST_SUCCEEDED(unit, ability)
    local anchor = self:GetAnchorByUnit(unit)
    if not anchor then return end
    local guid = UnitGUID(unit)

    local abilityData = self:FindAbilityByName(anchor.icons, ability)
    if not abilityData then
    	return
    end

    local SentID = abilityData.abilityID

    if SentID == 20594 and unit and guid then self:StartCooldown(GetSpellInfo(20594), unit, SentID) end
    if SentID == 42292 and unit and guid then
        self:StartCooldown(GetSpellInfo(42292), unit, SentID, dbAuraRemoved[GetSpellInfo(SentID)] and "AuraOn")
    end
    if SentID == 5384 and unit and guid then
        self:StartCooldown(GetSpellInfo(5384), unit, 5384, "Aura51514n");
        isFWW["fd" .. guid] = guid
    end
    if SentID == 51514 and unit and guid then
    	self:StartCooldown(GetSpellInfo(51514), unit, SentID)
    end
    if SentID == 17928 and unit and guid then
        self:StartCooldown(GetSpellInfo(17928), unit, SentID)
    end
    if SentID == 320552 and unit and guid then
        self:StartCooldown(GetSpellInfo(320552), unit, SentID)
    end
end

-- resets all icons
function ATT:StopAllIcons(flag)
    for k, anchor in ipairs(anchors) do
        anchor:StopAllIcons(flag)
    end
    wipe(activeGUIDS)
end

function ATT:StopAllGlow()
    for k, anchor in ipairs(anchors) do
        anchor:StopAllGlow()
    end
end

function ATT:SendUpdate()
    if self.useCrossAddonCommunication and IsInGroup() then
        local joinedString = strjoin(",", "Version", PlayerGUID, ATTversion)
        SendAddonMessage(ChatPrefix, joinedString, IsInRaid() and "RAID" or "PARTY")
    end
end

function ATT:ProcessSync(anchor, spellId, cooldownInfo)
     local isReady, normalizedPercent, timeLeft, charges, minValue, maxValue, currentValue = ATTdbs:GetCooldownInfo(cooldownInfo)
     local spellName = GetSpellInfo(spellId)
 
         for k, icon in ipairs(anchor.icons) do
             if (not isReady) and timeLeft and  timeLeft > 0 and icon.inUse and icon.ability == spellName then
                 local start = currentValue - icon.cooldown + timeLeft --processing time
                 local iconCharges = icon.maxcharges and getIconCharges(icon)

                if not icon.starttime or ((ceil(icon.starttime) ~= ceil(start))) or (iconCharges and (iconCharges ~= charges)) then
                  icon.SetTimer(start, icon.cooldown, nil, nil, icon.maxcharges and charges)
                end
            elseif isReady and icon.inUse and icon.starttime and icon.active and icon.ability == spellName then
                --and not ATTdbs.dbReplace[icon.abilityID]
                 icon.Stop()
           end
        end
 end
 
 function ATTdbs:OnReceiveCooldownUpdate(unitId, spellId, cooldownInfo)
    local anchor = ATT:GetAnchorByUnit(unitId)
    if not anchor or not spellId or not cooldownInfo then return end
    local guid = UnitGUID(unitId)

    if not dbInspect[guid] and syncChache[guid] then 
        syncChache[guid][spellId] = cooldownInfo
    end

     ATT:ProcessSync(anchor, spellId, cooldownInfo)
end

function ATTdbs:OnReceiveCooldownListUpdate(unitId, unitCooldows)
    local anchor = ATT:GetAnchorByUnit(unitId)
    if not anchor or not unitCooldows then return end
    local guid = UnitGUID(unitId)

    if not dbInspect[guid] then 
        syncChache[guid] = unitCooldows
    end

    for spellId, cooldownInfo in pairs(unitCooldows) do
        ATT:ProcessSync(anchor, spellId, cooldownInfo)
    end
end

function ATT:CHAT_MSG_ADDON(prefix, message, dist, sender)
    if prefix == ChatPrefix and message then
        local msgtype, guid, infos = strmatch(message, "(.-),(.-),(.+)")

        if not msgtype or not guid or not infos then return end

        if msgtype == "Version" then
            if infos and tonumber(infos) and tonumber(infos) > tonumber(ATTversion) and not self.VersionChecked then
                self.VersionChecked = tonumber(infos)
                print(L["NEWVERSION"].." [|cffFF4500v" .. infos .. "|r]")
            end
        end
    end
end

function ATT:PLAYER_EQUIPMENT_CHANGED(item)
    if not item then
        return
    end
    self:InspectPlayer()
    self:ApplyAnchorSettings()
end

function ATT:CVAR_UPDATE(cvar)
    if cvar == "C_CVAR_USE_COMPACT_PARTY_FRAMES" then
        C_Timer:After(0.1, function() self:ApplyAnchorSettings(); end)
    end
end

function ATT:CHAT_MSG_BG_SYSTEM_NEUTRAL(text)
    if not ATTIcons:IsShown() or not text then return end
    local _, instanceType = IsInInstance()
    if (instanceType == "arena" or instanceType == "pvp") and (string.find(text, "!$")) then
        C_Timer:After(1, function()
            ATT:InspectPlayer()
            ATT:UpdateGroup()
        end)
    end
end

function ATT:PLAYER_TALENT_UPDATE()
    self:InspectPlayer()
    self:ApplyAnchorSettings()
end

function ATT:CheckProfile()
    local _, instanceType = IsInInstance()
    selectedDB.ProfileSelected = selectedDB.ProfileSelected or "DEFAULT"

    if selectedDB.autoselectBG then
        if instanceType == "pvp" and selectedDB.ProfileSelected ~= "BG"  and instanceType ~= "pvp" then
            ATTDB.lastProfile = selectedDB.ProfileSelected
            selectedDB.ProfileSelected = "BG"
        elseif selectedDB.ProfileSelected == "BG" and ATTDB.lastProfile then
            selectedDB.ProfileSelected = ATTDB.lastProfile
            ATTDB.lastProfile = nil
        end
    end

    db = selectedDB[selectedDB.ProfileSelected]
    db.classSelected = "WARRIOR";
    db.category = "abilities";
    ATT.inRaid = type ~= "arena"
end

function ATT:LoadProfiles()
    local profiles = { "DEFAULT", "TANK", "HEALER", "DAMAGER", "BG", "Extra1", "Extra2" }
    local oldDB = ATTDB                                    --getting old main profiles
    oldDB.Profiles = nil                                   --remove old profiles

    if ATTDB["isEnabledSpell"] then ATTDB = {} end         --cleaning DB
    if ATTCharDB["isEnabledSpell"] then ATTCharDB = {} end --cleaning Char DB

    if ATTDB.profilebychar then selectedDB = ATTCharDB else selectedDB = ATTDB end
    local dbProfiles = {}

    for i = 1, #profiles do
        if not selectedDB[profiles[i]] then
            dbProfiles[profiles[i]] = {}
            for a, b in pairs(profiles[i] == "DEFAULT" and oldDB["isEnabledSpell"] and oldDB or ATTdbs.Defaults) do
                if type(b) ~= "table" then
                    dbProfiles[profiles[i]][a] = b
                else
                    dbProfiles[profiles[i]][a] = {}
                    for c, d in pairs(b) do
                        if type(d) ~= "table" then
                            dbProfiles[profiles[i]][a][c] = d
                        else
                            dbProfiles[profiles[i]][a][c] = {}
                            for e, f in pairs(d) do dbProfiles[profiles[i]][a][c][e] = f end
                        end
                    end
                end
            end
            selectedDB[profiles[i]] = dbProfiles[profiles[i]]
        end
    end
end

function ATT:ACTIVE_TALENT_GROUP_CHANGED()
    self:InspectPlayer()
    self:ApplyAnchorSettings()
end

local function On_Update(self, elapsed)
    if #inspect_queue == 0 then return end

    if (#inspect_queue > 0) then
        ATT.elapsedTime = (ATT.elapsedTime or 0) + elapsed
        if ATT.elapsedTime > 0.6 then
            ATT.elapsedTime = 0
            ATT:ProcessInspectQueue()
        end
    end
end

local function ATT_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    self.useCrossAddonCommunication = true
    if self.useCrossAddonCommunication then self:RegisterEvent("CHAT_MSG_ADDON") end
    self:SetScript("OnEvent", function(self, event, ...) if self[event] then self[event](self, ...) end end);
    ATTDB = ATTDB or {}
    ATTCharDB = ATTCharDB or {}
    localeFunc()

    for _, v in pairs(dbTrinkets) do
        local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(v.trinketId)
        v.name = itemName
        v.spellTName = GetSpellInfo(v.ability)
        v.texture = itemTexture
    end

    self:UpdateUnitIDCache()
    self:LoadProfiles()
    self:CheckProfile()
    self:CreateAnchors()
    self:CreateOptions()
    self:UpdateScrollBar()
    self:FindFrameType();
    self:ApplyAnchorSettings()

    ATTOnUpdateFrame:SetScript("OnUpdate", On_Update)

    if C_CVar:GetValue("C_CVAR_USE_COMPACT_PARTY_FRAMES") then
        hooksecurefunc("CompactUnitFrameProfiles_ActivateRaidProfile", function() ATT:ApplyAnchorSettings(); end)
        hooksecurefunc("CompactRaidFrameManager_UpdateShown", function() ATT:ApplyAnchorSettings(); end)
    end
 
    C_Timer:After(3, function() self:UpdateUnitIDCache() self:CheckProfile() self:FindFrameType(); self:ApplyAnchorSettings(); end)

    local panelOpenCmd = ATTDB.useAtrack and L["attopen2"] or L["attopen"]
    print("|cff33ff99A|rbility |cff33ff99T|ream |cff33ff99T|rracker |cffFF4500[v" ..ATTversion .. "]|r loaded. "..panelOpenCmd)
end

function ATT:FindAbilityIcon(ability, id)
    if not id then
        return ""
    end
    local icon;
    if id then
        _, _, icon = GetSpellInfo(id)
    else
        _, _, icon = GetSpellInfo(ability)
    end

    return icon or ""
end

function ATT:MergeTable(class, category, isAnchor)
    local newdbSpells = {}

    if not db.alertCDtext then db.alertCDtext = {} end --updade fix
    if type(db.isEnabledSpell[class]) ~= "table" then db.isEnabledSpell[class] = {} end
    if type(db.customSpells[class]) ~= "table" then db.customSpells[class] = {} end
    if type(db.iconOrder[class]) ~= "table" then db.iconOrder[class] = {} end
    if type(db.alertCD[class]) ~= "table" then db.alertCD[class] = {} end
    if type(db.alertCDtext[class]) ~= "table" then db.alertCDtext[class] = {} end

    local dbSpells = dbImport[class]
    local dbiconOrder = db.iconOrder[class]
    local dbcustomSpells = db.customSpells[class]

    if category == "abilities" then
        if dbSpells then
            for _, v in pairs(dbSpells) do
                if not v.name then v.name = GetSpellInfo(v.ability) end --if not v.name
                if v.name then table.insert(newdbSpells, v) end
            end
        end

        if dbcustomSpells then
            for _, v in pairs(dbcustomSpells) do
                if not v.name then v.name = GetSpellInfo(v.ability) end
                if v.name then table.insert(newdbSpells, v) end
            end
        end

        for _, v in pairs(newdbSpells) do
            if dbiconOrder[v.ability] then
                v.order = dbiconOrder[v.ability] or 20
            else
                v.order = 20
            end
        end

        table.sort(newdbSpells, function(a, b)
            if isAnchor then
                if (a.order) == (b.order) then
                    return (a.name) < (b.name)
                else
                    return (a.order) < (b.order)
                end
            else
                return (a.name) < (b.name)
            end
        end)
    elseif category == "trinkets" then
        if dbTrinkets then
            for _, v in pairs(dbTrinkets) do
                if v.name then table.insert(newdbSpells, v) end
            end
            table.sort(newdbSpells, function(a, b)
                if (a.isPvPtrinket and not b.isPvPtrinket) then
                    return (1) < (2)
                elseif (not a.isPvPtrinket and b.isPvPtrinket) then
                    return (1) > (2)
                else
                    return (a.name) < (b.name)
                end
            end)
        end
    elseif category == "racials" then
        if constellations then
            for _, v in pairs(constellations) do
                if not v.name then v.name = GetSpellInfo(v.ability) end
                if v.name then table.insert(newdbSpells, v) end
            end
            table.sort(newdbSpells, function(a, b) return (a.name) < (b.name) end)
        end
    elseif category == "glyphs" then
        if ATTdbs.dbModifGlyph then
            for glyphId, v in pairs(ATTdbs.dbModifGlyph) do
                if not v.name then
                    v.name = GetSpellInfo(v.mod)
                    v.ability = v.mod
                    v.texture = "Interface\\Icons\\INV_Inscription_MajorGlyph00"
                end
                local gClass = select(2, GetClassInfo(v.class))
                if v.name and gClass == class then table.insert(newdbSpells, v) end
            end
        end
    end

    return newdbSpells
end

-- Panel
-------------------------------------------------------------

local function CreatePopUpFrame(panel, name)
    local popUpFrame = CreateFrame("Frame", name, panel, "UIPanelDialogTemplate"); --InsetFrameTemplate2
    popUpFrame:SetFrameLevel(popUpFrame:GetFrameLevel() + 3)
    popUpFrame:SetSize(320, 290);
    popUpFrame:SetPoint('LEFT', 150, -110);
   -- popUpFrame:SetFrameStrata("WORLD")
   -- popUpFrame.Title:SetText(name)
    popUpFrame:EnableMouse(true)
    popUpFrame:SetToplevel(true)

    popUpFrame.Close = _G[name.."Close"]
    popUpFrame.Close:SetPoint("TOPRIGHT", 2, 1)
    popUpFrame.Close:SetScript("OnClick", function(self)  panel.popUP = false self:GetParent():Hide() end)
    popUpFrame:Hide()

    return popUpFrame
end

local function CreateListButton(parent, index, panel)
    local button = CreateFrame("CheckButton", parent:GetName() .. index, parent, "InterfaceOptionsCheckButtonTemplate")
    button.orderbtn = CreateFrame("button", parent:GetName() .. index .. "orderbtn", button, "UIPanelScrollUpButtonTemplate")
    button.orderbtn:SetNormalTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Up")
    button.orderbtn:SetPushedTexture("Interface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Disabled")

    return button
end

local function CreateEditBox(name, parent, width, height)
    local editbox = CreateFrame("EditBox", parent:GetName() .. name, parent, "InputBoxTemplate")
    editbox:SetHeight(height)
    editbox:SetWidth(width)
    editbox:SetAutoFocus(false)
    editbox:SetNumeric(true)
    editbox:SetMaxLetters(8)
    local label = editbox:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    label:SetText(name)
    label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT", -3, 0)
    return editbox
end

local function EnableGlobalSpell(id, isenabled, alertcd, alertcdtext)
    for i = 1, GetNumClasses() do
        local className, classTag, classID = GetClassInfo(i)
        if classTag then
                if not db.isEnabledSpell[classTag] then db.isEnabledSpell[classTag] = {} end
                if not db.alertCD[classTag] then db.alertCD[classTag] = {} end
                if not db.alertCDtext[classTag] then db.alertCDtext[classTag] = {} end

                db.isEnabledSpell[classTag][id] = isenabled
                db.alertCD[classTag][id] = alertcd
                db.alertCDtext[classTag][id] = alertcdtext
        end
    end
end

function ATT:FindFrameType()
    local hookFrames = { 0, L["DoNotAttach"], 1, L["AutoattachUI"], 2, L["Blizzard UI"] }
    for x, v in pairs(customframes) do
        local checkframe = format(string.gsub(v.cframe, "1RG", 1), 1)
        if (_G[checkframe] or IsAddOnLoaded(v.cname)) then
            tinsert(hookFrames, x);
            tinsert(hookFrames, v.ctype);
        end
    end

    if ATT_DropDown1 then
        ATT_DropDown1.values = hookFrames
        ATT_DropDown1.doRefresh()
    end
end

function ATT:CreateOptions()
    local panelOpenCmd = ATTDB.useAtrack and L["attopen2"] or L["attopen"]
    local panel = SO.AddOptionsPanel("Ability Team Tracker", function() end, panelOpenCmd, ATTversion)
    self.panel = panel
    SO.AddSlashCommand("Ability Team Tracker", ATTDB.useAtrack and "/atrack" or "/att")

    local attach = panel:MakeDropDown('name', L["attach"], 'description', L["attachToolTip"],
        'values', { 0, L["DoNotAttach"], 1, L["AutoattachUI"], 2, L["Blizzard UI"] }, 'default', 0, 'getFunc', function()
            return db.attach or 0
        end, 'getCurrent', function()
            return db.attach or 0
        end, 'setFunc', function(value)
            db.attach = tonumber(value);
            self:ApplyAnchorSettings();
        end)
    attach:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -80)

    local attachPos = panel:MakeDropDown('name', L["attachPos"], 'description', L["attachPosToolTip"],
    'values', { 0, L["TOPLEFT"], 1, L["TOPRIGHT"], 2, L["BOTTOMLEFT"], 3, L["BOTTOMRIGHT"], 4, L["CENTERLEFT"], 5, L["CENTERRIGHT"] }, 'default', 0, 'getFunc', function()
        return  db.attachPos or 0
    end, 'getCurrent', function()
        return  db.attachPos or 0
    end, 'setFunc', function(value)
        db.attachPos = tonumber(value);
        self:ApplyAnchorSettings();
    end)
    attachPos:SetPoint("TOPLEFT", attach, "TOPLEFT", 0, -50)

    local growUP = panel:MakeToggle('name', L["growUP"], 'description', L["growUPToolTip"], 'default'
   , false, 'getFunc', function()
       return db.growUP
   end, 'getCurrent', function()
       return db.growUP
   end, 'setFunc', function(value)
       db.growUP = value;
       self:ApplyAnchorSettings();
   end)
   growUP:SetPoint("TOP", panel, "TOP", -120, -70)

   local reverseIcons = panel:MakeToggle('name', L["reverseIcons"], 'description', L["reverseIconsToolTip"],
   'default', false, 'getFunc', function()
       return db.reverseIcons
   end, 'getCurrent', function()
       return db.reverseIcons
   end, 'setFunc', function(value)
       db.reverseIcons = value;
       self:ApplyAnchorSettings()
   end)
reverseIcons:SetPoint("TOP", growUP, "BOTTOM", 0, -5)

   local selfAttach = panel:MakeToggle(
    'name', L["selfAttach"],
    'description', L["selfAttachToolTip"],
    'default', false,
    'getFunc', function() return db.selfAttach end,
    'getCurrent', function() return db.selfAttach end,
    'setFunc', function(value)
        db.selfAttach = value;
        self:ApplyAnchorSettings()
    end)
selfAttach:SetPoint("TOP", reverseIcons, "BOTTOM", 0, -5)

    local scale = panel:MakeSlider('name', L["scale"], 'description', L["scaleToolTip"], 'minText', '1',
        'maxText', '200', 'minValue', 1, 'maxValue', 200, 'step', 1, 'default', 100, 'current',
        db.scale and tonumber(db.scale * 100) or 1, 'getCurrent',
        function()
            return db.scale and tonumber(db.scale * 100) or 100
        end, 'setFunc', function(value)
            if (tonumber(value) / 100) ~= db.scale then
                db.scale = tonumber(string.format("%.2f", value)) / 100;
                ATTIcons:SetScale(db.scale or 1)
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.2f", value))
        end,'sizeOf', '56')
    scale:SetPoint("TOPLEFT", attach, "TOPLEFT", 20, -110)

    local anchorScale = panel:MakeSlider('name', L["anchorScale"], 'description', L["anchorScaleToolTip"], 'minText', '1',
        'maxText', '200', 'minValue', 1, 'maxValue', 200, 'step', 1, 'default', 100, 'current',
        db.anchorScale and tonumber(db.anchorScale * 100) or 1, 'getCurrent',
        function()
            return db.anchorScale and tonumber(db.anchorScale * 100) or 100
        end, 'setFunc', function(value)
            if (tonumber(value) / 100) ~= db.anchorScale then
                db.anchorScale = tonumber(string.format("%.2f", value)) / 100;
                self:UpdatePositions()
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.2f", value))
        end,'sizeOf', '56')
    anchorScale:SetPoint("LEFT", scale, "RIGHT", 15, 0) 

    local iconRows = panel:MakeSlider('name', L["iconRows"], 'description', L["iconRowsToolTip"], 'minText',
        '1', 'maxText', '5', 'minValue', 1, 'maxValue', 5, 'step', 1, 'default', 2, 'current',
        tonumber(db.IconRows) or 1
        , 'getCurrent',
        function()
            return tonumber(db.IconRows) or 1
        end, 'setFunc', function(value)
            if value ~= db.IconRows then
                db.IconRows = tonumber(string.format("%.1d", value));
                self:UpdateIcons();
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.1d", value));
        end,
        'sizeOf', '56')
    iconRows:SetPoint("LEFT", anchorScale, "RIGHT", 15, 0)

    local iconAlpha = panel:MakeSlider('name', L["iconAlpha"], 'description',  L["iconAlphaToolTip"], 'minText',
        'Hide', 'maxText', '10', 'minValue', 0, 'maxValue', 10, 'step', 1, 'default', 0, 'current',
        db.iconAlpha and tonumber(db.iconAlpha * 10) or 10,
        'getCurrent', function()
            return db.iconAlpha and tonumber(db.iconAlpha * 10) or 10
        end, 'setFunc', function(value)
            if value ~= db.iconAlpha then
                db.iconAlpha = value / 10;
                self:UpdateIcons();
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.1d", value));
        end,'sizeOf', '56')
    iconAlpha:SetPoint("LEFT", iconRows, "RIGHT", 15, 0)

    local offsetX = panel:MakeSlider('name', L["offsetX"], 'description', L["offsetXTooltip"], 'minText',
        'Left', 'maxText', 'Right', 'minValue', -200, 'maxValue', 200, 'step', 1, 'default', 0, 'current',
        tonumber(db.offsetX) or 0,
        'getCurrent', function()
            return tonumber(db.offsetX) or 0
        end, 'setFunc', function(value)
            if value ~= db.offsetX then
                db.offsetX = tonumber(value);
                self:UpdatePositions()
            end
        end, 'currentTextFunc', function(value)
            return tonumber(value);
        end,'sizeOf', '56')
    offsetX:SetPoint("TOPLEFT", attach, "TOPLEFT", 20, -175)

    local offsetY = panel:MakeSlider('name', L["offsetY"], 'description',  L["offsetYTooltip"], 'minText',
        'Down', 'maxText', 'Up', 'minValue', -200, 'maxValue', 200, 'step', 1, 'default', 0, 'current',
        tonumber(db.offsetY) or 0,
        'getCurrent', function()
            return tonumber(db.offsetY) or 0
        end, 'setFunc', function(value)
            if value ~= db.offsetY then
                db.offsetY = tonumber(value);
                self:UpdatePositions()
            end
        end, 'currentTextFunc', function(value)
            return tonumber(value);
        end,'sizeOf', '56')
    offsetY:SetPoint("LEFT", offsetX, "RIGHT", 15, 0)

    local iconOffsetX = panel:MakeSlider('name', L["iconOffsetX"], 'description', L["iconOffsetXToolTip"], 'minText',
        '0', 'maxText', '100', 'minValue', 0, 'maxValue', 100, 'step', 1, 'default', 5, 'current',
        tonumber(db.iconOffsetX) or 5,
        'getCurrent', function()
            return tonumber(db.iconOffsetX) or 5
        end, 'setFunc', function(value)
            if value ~= db.iconOffsetX then
                db.iconOffsetX = tonumber(string.format("%.1d", value));
                self:UpdateIcons();
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.1d", value));
        end,'sizeOf', '56')
    iconOffsetX:SetPoint("LEFT", offsetY, "RIGHT", 15, 0)

    local iconOffsetY = panel:MakeSlider('name', L["iconOffsetY"], 'description', L["iconOffsetYToolTip"], 'minText',
        '0', 'maxText', '100', 'minValue', 0, 'maxValue', 100, 'step', 1, 'default', 2, 'current',
        tonumber(db.iconOffsetY) or 2,
        'getCurrent', function()
            return tonumber(db.iconOffsetY) or 2
        end, 'setFunc', function(value)
            if value ~= db.iconOffsetY then
                db.iconOffsetY = tonumber(string.format("%.1d", value));
                self:UpdateIcons();
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.1d", value));
        end,'sizeOf', '56')
    iconOffsetY:SetPoint("LEFT", iconOffsetX, "RIGHT", 15, 0)

    local lock = panel:MakeToggle('name', L["lock"], 'description', L["lockToolTip"], 'default', false, 'getFunc'
    , function()
        return db.lock
    end, 'getCurrent', function()
        return db.lock
    end, 'setFunc', function(value)
        db.lock = value;
        self:ApplyAnchorSettings()
    end)
    lock:SetPoint("TOP", panel, "TOP", 40, -70)

    local glow = panel:MakeToggle('name', L["glow"], 'description',
    L["glowToolTip"], 'default', true, 'getFunc', function()
            return db.glow
        end, 'getCurrent', function()
            return db.glow
        end, 'setFunc', function(value)
            db.glow = false;
            self:UpdateIcons();
        end)
    glow:SetPoint("TOP", lock, "BOTTOM", 0, -5)

    local showIconBorders = panel:MakeToggle('name', L["showIconBorders"], 'description', L["showIconBordersToolTip"],
        'default', true, 'getFunc', function()
            return db.showIconBorders
        end, 'getCurrent', function()
            return db.showIconBorders
        end, 'setFunc', function(value)
            db.showIconBorders = value;
            self:UpdateIcons();
        end)
    showIconBorders:SetPoint("TOP", glow, "BOTTOM", 0, -5)

    local simpleMode = panel:MakeToggle('name', L["simpleMode"], 'description',
    L["simpleModeTooltip"],  'default', false, 'getFunc',
    function()
        return db.bgMode
    end, 'getCurrent', function()
        return db.bgMode
    end, 'setFunc', function(value)
        db.bgMode = value;
        ATT:ApplyAnchorSettings();
    end)
    simpleMode:SetPoint("LEFT", lock, "RIGHT", 120, 0)

    local hidden = panel:MakeToggle('name', L["hidden"], 'description', L["hiddenTooltip"],
        'default', false, 'getFunc', function()
            return db.hidden
        end, 'getCurrent', function()
            return db.hidden
        end, 'setFunc', function(value)
            db.hidden = value;
            self:UpdateIcons();
        end)
    hidden:SetPoint("TOP", simpleMode, "BOTTOM", 0, -5)

    local info = CreateFrame("Frame", "ATTFrame", panel, BackdropTemplateMixin and "BackdropTemplate")
    info:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -240, -625)
    info:SetSize(50, 50)

    local version = info:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    version:SetText("|cffffff00ATT|r |cff33ff99for " .. "Sirus".. "|r by |cffffff00Qblolz|r")
    version:SetPoint("TOPLEFT", info, "TOPLEFT", 145, 0)


    self:CreateTabs()
    self:UpdateScrollBar()
    self:CreateAbilityOptionsFrame()
end

function ATT:CreateVisibilityFrame(visibility)
    local panel = self.panel

    local arenaGroupSize = panel:MakeSlider('name',  L["arenaGroupSize"], 'description',
    L["arenaGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visArena) or 5,
    'getCurrent', function()
        return tonumber(db.visArena) or 5
    end, 'setFunc', function(value)
        if value ~= db.visArena then
            db.visArena = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
   -- arenaGroupSize:SetPoint("TOP", visibility, "TOP", -60, -30)
    arenaGroupSize:SetPoint("TOPLEFT", visibility, "TOPLEFT", 40 , -100)

    local arenaSelf = panel:MakeToggle('name', L["arenaSelf"], 'description', L["arenaSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visArenaSelf
    end, 'getCurrent', function()
        return db.visArenaSelf
    end, 'setFunc', function(value)
        db.visArenaSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    arenaSelf:SetPoint("LEFT", arenaGroupSize, "RIGHT", 55, 0)

    local dungeonGroupSize = panel:MakeSlider('name', L["dungeonGroupSize"], 'description',
    L["dungeonGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visDungeon) or 5,
    'getCurrent', function()
        return tonumber(db.visDungeon) or 5
    end, 'setFunc', function(value)
        if value ~= db.visDungeon then
            db.visDungeon = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
   -- dungeonGroupSize:SetPoint("TOP", arenaGroupSize, "TOP", 0, -40)
   dungeonGroupSize:SetPoint("LEFT", arenaGroupSize, "RIGHT", 160, 0)


    local dungeonSelf = panel:MakeToggle('name', L["dungeonSelf"], 'description', L["dungeonSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visDungeonSelf
    end, 'getCurrent', function()
        return db.visDungeonSelf
    end, 'setFunc', function(value)
        db.visDungeonSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    dungeonSelf:SetPoint("LEFT", dungeonGroupSize, "RIGHT", 55, 0)

    local scenarioGroupSize = panel:MakeSlider('name', L["scenarioGroupSize"], 'description',
    L["scenarioGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visScenario) or 5,
    'getCurrent', function()
        return tonumber(db.visScenario) or 5
    end, 'setFunc', function(value)
        if value ~= db.visScenario then
            db.visScenario = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
    scenarioGroupSize:SetPoint("TOP", arenaGroupSize, "TOP", 0, -60)

    local scenarioSelf = panel:MakeToggle('name', L["scenarioSelf"], 'description', L["scenarioSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visScenarioSelf
    end, 'getCurrent', function()
        return db.visScenarioSelf
    end, 'setFunc', function(value)
        db.visScenarioSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    scenarioSelf:SetPoint("LEFT", scenarioGroupSize, "RIGHT", 55, 0)

    local inbgGroupSize = panel:MakeSlider('name', L["inbgGroupSize"], 'description',
    L["inbgGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visInbg) or 5,
    'getCurrent', function()
        return tonumber(db.visInbg) or 5
    end, 'setFunc', function(value)
        if value ~= db.visInbg then
            db.visInbg = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
    inbgGroupSize:SetPoint("TOP", dungeonGroupSize, "TOP", 0, -60)

    local inbgSelf = panel:MakeToggle('name', L["inbgSelf"], 'description', L["inbgSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visInbgSelf
    end, 'getCurrent', function()
        return db.visInbgSelf
    end, 'setFunc', function(value)
        db.visInbgSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    inbgSelf:SetPoint("LEFT", inbgGroupSize, "RIGHT", 55, 0)

    local inraidGroupSize = panel:MakeSlider('name', L["inraidGroupSize"], 'description',
    L["inraidGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visInraid) or 5,
    'getCurrent', function()
        return tonumber(db.visInraid) or 5
    end, 'setFunc', function(value)
        if value ~= db.visInraid then
            db.visInraid = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
    inraidGroupSize:SetPoint("TOP", scenarioGroupSize, "TOP", 0, -60)

    local inraidSelf = panel:MakeToggle('name', L["inraidSelf"], 'description', L["inraidSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visInraidSelf
    end, 'getCurrent', function()
        return db.visInraidSelf
    end, 'setFunc', function(value)
        db.visInraidSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    inraidSelf:SetPoint("LEFT", inraidGroupSize, "RIGHT", 55, 0)

    local outsideGroupSize = panel:MakeSlider('name', L["outsideGroupSize"], 'description',
    L["outsideGroupSizeToolTip"], 'minText', 'Hide', 'maxText', '40', 'minValue', 0,
    'maxValue', 40, 'step', 1, 'default', 0, 'extra', visibility, 'current', tonumber(db.visOutside) or 5,
    'getCurrent', function()
        return tonumber(db.visOutside) or 5
    end, 'setFunc', function(value)
        if value ~= db.visOutside then
            db.visOutside = tonumber(string.format("%.1d", value));
            ATT:EnqueueInspect(true)
            ATT:ApplyAnchorSettings();
        end
    end, 'currentTextFunc', function(value)
        return tonumber(string.format("%.1d", value));
    end,'sizeOf', '28')
    outsideGroupSize:SetPoint("TOP", inbgGroupSize, "TOP", 0, -60)

    local outsideSelf = panel:MakeToggle('name', L["outsideSelf"], 'description', L["outsideSelfToolTip"], 'extra', visibility, 'default', false,
    'getFunc', function()
        return db.visOutsideSelf
    end, 'getCurrent', function()
        return db.visOutsideSelf
    end, 'setFunc', function(value)
        db.visOutsideSelf = value;
        ATT:ApplyAnchorSettings();
    end)
    outsideSelf:SetPoint("LEFT", outsideGroupSize, "RIGHT", 55, 0)

end

function ATT:CreateProfilesFrame(profiles)
    local panel = self.panel

    local selectProfile = panel:MakeDropDown('name', L["selectProfile"], 'description', L["selectProfileToolTip"], 'extra',
        profiles, 'values',
        { "DEFAULT", L["Main"], "TANK", L["Tank"], "HEALER", L["Healer"], "DAMAGER", L["DPS"], "BG", L["BattleGround"], "Extra1",
        L["ExtraProfie1"], "Extra2", L["ExtraProfie2"] }, 'default', "DEFAULT", 'getFunc', function()
            return selectedDB.ProfileSelected
        end, 'getCurrent', function()
            return selectedDB.ProfileSelected
        end, 'setFunc', function(value)
            local _, instanceType = IsInInstance()
            if selectedDB.autoselectprofile then
                print(L["selectProfileASenabled"])
                panel:UpdateSettings()
                return --TODO
            elseif (selectedDB.autoselectBG and instanceType == "pvp") then
                print(L["selectProfileBGenabled"])
                panel:UpdateSettings()
                return
            end
            selectedDB.ProfileSelected = value;
            self:CheckProfile();
            self:UpdateScrollBar();
            self:ApplyAnchorSettings();
            panel:UpdateSettings()
        end) -- here
    selectProfile:SetPoint("TOP", profiles, "TOP", -30, -80)

    local copyProfile = panel:MakeButton('name', L["copyProfile"], 'description',
    L["copyProfileToolTip"], 'extra', profiles, 'newsize', 2, 'func',
        function()
            if selectedDB.ProfileSelected ~= "DEFAULT" then
                StaticPopup_Show("ATT_COPYPROFILES")
            else
                print(L["copyProfileMain"])
            end
        end)
    copyProfile:SetPoint("LEFT", selectProfile, "RIGHT", -5, 3)

    StaticPopupDialogs["ATT_COPYPROFILES"] = {
        text = L["copyProfilePopUp"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            if selectedDB.ProfileSelected ~= "DEFAULT" then
                selectedDB[selectedDB.ProfileSelected] = selectedDB["DEFAULT"]
                self:CheckProfile();
                self:UpdateScrollBar();
                self:ApplyAnchorSettings();
                panel:UpdateSettings()
                print(L["copyProfileUpdated"])
            end
        end,
        exclusive = true,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local autoselectBG = panel:MakeToggle('name', L["autoselectBG"], 'description',
    L["autoselectBGToolTip"], 'extra', profiles, 'default', false, 'getFunc',
        function()
            return selectedDB.autoselectBG
        end, 'setFunc', function(value)
            selectedDB.autoselectBG = value;
            ATT:CheckProfile();
            ATT:UpdateScrollBar();
            ATT:ApplyAnchorSettings();
            panel:UpdateSettings()
        end)
    autoselectBG:SetPoint("TOP", profiles, "TOP", -90, -120)

    local profilebychar = panel:MakeToggle('name', L["profilebychar"], 'description',
    L["profilebycharToolTip"], 'extra', profiles, 'default', false,
        'getFunc', function()
            return ATTDB.profilebychar
        end, 'setFunc', function(value)
            StaticPopup_Show("ATT_CHARDB")
        end)
    profilebychar:SetPoint("TOP", autoselectBG, "TOP", 0, -30)

    StaticPopupDialogs["ATT_CHARDB"] = {
        text = L["profilebycharPopUp"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            --ATTCharDB = {}; ---HERE TODO TESTING
            ATTDB.profilebychar = (not ATTDB.profilebychar);
            ATT:CheckProfile();
            ATT:UpdateScrollBar();
            ATT:ApplyAnchorSettings();
            panel:UpdateSettings()
            ReloadUI();
        end,
        OnCancel = function()
            profilebychar:SetChecked(not not ATTDB.profilebychar)
        end,
        OnHide = function()
            profilebychar:SetChecked(not not ATTDB.profilebychar)
        end,
        exclusive = true,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local reset = panel:MakeButton('name', L["reset"], 'description', L["resetToolTip"], 'extra',
    profiles, 'newsize', false, 'func', function()
        StaticPopup_Show("ATT_RESET")
    end)
    reset:SetPoint("TOP", profiles, "TOP", 0, -240)

StaticPopupDialogs["ATT_RESET"] = {
    text = L["resetPopUp"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        ATTDB = {};
        ATTCharDB = {};
        ReloadUI();
    end,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

    profiles:SetScript("OnHide",
        function(self)
            StaticPopup_Hide("ATT_RESET")
            StaticPopup_Hide("ATT_COPYPROFILES")
            StaticPopup_Hide("ATT_CHARDB")
            StaticPopup_Hide("ATT_USEENGLISH")
        end)

end

function ATT:CreateOptionsFrame(options)
    local panel = self.panel

    local useAtrack = panel:MakeToggle('name', L["useAtrack"], 'description',
    L["useAtrackToolTip"], 'extra', options, 'default', false, 'getFunc',
        function()
            return ATTDB.useAtrack
        end, 'setFunc', function(value)
            StaticPopup_Show("ATT_useAtrack")
        end)
    useAtrack:SetPoint("TOPLEFT", options, "TOPLEFT", 40 , -80)

    StaticPopupDialogs["ATT_useAtrack"] = {
        text = L["useAtrackPopUp"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            ATTDB.useAtrack = (not ATTDB.useAtrack);
            useAtrack:SetChecked(not not ATTDB.useAtrack)
            ReloadUI();
        end,
        OnCancel = function()
            useAtrack:SetChecked(not not ATTDB.useAtrack)
        end,
        OnHide = function()
            useAtrack:SetChecked(not not ATTDB.useAtrack)
        end,
        exclusive = true,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local disableSync = panel:MakeToggle('name', L["disableSync"], 'description',L["disableSyncToolTip"], 'extra', options, 'default', false, 'newsize', false,
    'getFunc', function()
        return ATTDB.disableSync
    end, 'setFunc', function(value)
        StaticPopup_Show("ATT_disableSync")
    end)
    disableSync:SetPoint("TOP", useAtrack, "TOP", 0, -35) 

StaticPopupDialogs["ATT_disableSync"] = {
    text = L["disableSyncPopUp"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        ATTDB.disableSync = (not ATTDB.disableSync);
        disableSync:SetChecked(not not ATTDB.disableSync)
    end,
    OnCancel = function()
        disableSync:SetChecked(not not ATTDB.disableSync)
    end,
    OnHide = function()
        disableSync:SetChecked(not not ATTDB.disableSync)
    end,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local useEnglishLang = panel:MakeToggle('name', L["useEnglishLang"], 'description',
L["useEnglishLangToolTip"], 'extra', options, 'default', false,
    'getFunc', function()
        return ATTDB.useEnglish
    end, 'setFunc', function(value)
        StaticPopup_Show("ATT_USEENGLISH")
    end)
useEnglishLang:SetPoint("TOP", disableSync, "TOP", 0, -35)
useEnglishLang:SetScript("OnShow", function(self) if GetLocale() == "enUS" then useEnglishLang:Hide() else useEnglishLang:Show() end end)

StaticPopupDialogs["ATT_USEENGLISH"] = {
    text = L["useEnglishLangPopUp"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        ATTDB.useEnglish = (not ATTDB.useEnglish);
        ReloadUI();
    end,
    OnCancel = function()
        useEnglishLang:SetChecked(not not ATTDB.useEnglish)
    end,
    OnHide = function()
        useEnglishLang:SetChecked(not not ATTDB.useEnglish)
    end,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local legendFrame = CreateFrame("Frame", nil, options)
legendFrame:SetSize(220, 150)
legendFrame:SetPoint("TOPLEFT", 400, -70)

local abilityTexture = "Interface\\GossipFrame\\DailyActiveQuestIcon"  -- NPE Exclamation Point texture

local legend = legendFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
legend:SetText("|T" .. abilityTexture .. ":16|t " .. L["Legend"])
legend:SetPoint("TOP", legendFrame, "TOP", 0, -10)

local redSpell = legendFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
redSpell:SetText(L["redSpell"])
redSpell:SetPoint("TOPLEFT", legendFrame, "TOPLEFT", 10, -40)

local customSpell = legendFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
customSpell:SetText(L["customSpell"])
customSpell:SetPoint("TOPLEFT", legendFrame, "TOPLEFT", 10, -65)

local greenSpell = legendFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
greenSpell:SetText(L["greenSpell"])
greenSpell:SetPoint("TOPLEFT", legendFrame, "TOPLEFT", 10, -90)

local arrowIcon = legendFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
arrowIcon:SetText("|TInterface\\MainMenuBar\\UI-MainMenu-ScrollUpButton-Up:32|t- "..L["arrowIcon"])
arrowIcon:SetPoint("TOPLEFT", legendFrame, "TOPLEFT", 5, -110)


local contact = options:CreateFontString(nil, "ARTWORK", "GameFontDisable")
contact:SetText("[ Support: curseforge.com/wow/addons/att ]")
contact:SetPoint("BOTTOMRIGHT", options, "BOTTOMRIGHT", -10, 15)


options:SetScript("OnHide",
        function(self)
            StaticPopup_Hide("ATT_useAtrack")
            StaticPopup_Hide("ATT_disableSync")
            StaticPopup_Hide("ATT_USEENGLISH")
        end)
end

function ATT:CreateAbilityOptionsFrame()
    local panel = self.panel
    local popUpFrame = CreatePopUpFrame(panel, L["AbilityOptions"])
    self.OrderPopUpFrame = popUpFrame
    popUpFrame.id = nil
    popUpFrame:SetSize(250, 180);
    --popUpFrame:SetPoint('LEFT', 210, -65);
    popUpFrame.Close:SetScript("OnClick", function(self)  panel.popUP = false self:GetParent():Hide() ATT:UpdateIcons() end)

    local order = panel:MakeSlider('name', L["order"], 'extra', popUpFrame, 'description', L["orderToolTip"]
        , 'minText', '1', 'maxText', '20', 'minValue', 1, 'maxValue', 20, 'step', 1, 'default', 1, 'current',
        tonumber(db.iconOrder[db.classSelected][popUpFrame.id]) or 20, 'setFunc', function(value)
            if value ~= db.iconOrder[db.classSelected][popUpFrame.id] then
                db.iconOrder[db.classSelected][popUpFrame.id] = tonumber(string.format("%.1d", value))
                ATT:UpdateIcons()
            end
        end, 'currentTextFunc', function(value)
            return tonumber(string.format("%.1d", value))
        end,'sizeOf', '56')
    order:SetPoint("TOP", popUpFrame, "TOP", -20, -60)

    local notorder = popUpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    notorder:SetText(L["notoder"])
    notorder:SetPoint("TOP", popUpFrame, "TOP", 0, -60)

    local alertCD = panel:MakeToggle('name', L["alertCD"], 'extra', popUpFrame, 'description',
    L["alertCDTooTtip"], 'default', false, 'getFunc', function()
            return db.alertCD[db.classSelected][popUpFrame.id]
        end,
        'setFunc', function(value)
                db.alertCD[db.classSelected][popUpFrame.id] = value;
        end)
    alertCD:SetPoint("TOP", order, "BOTTOM", -70, -25)

    local alertCDtext = panel:MakeToggle('name', L["alertCDtext"], 'extra', popUpFrame, 'description',
    L["alertCDtextToolTip"], 'default', false, 'getFunc', function()
            return db.alertCDtext[db.classSelected][popUpFrame.id]
        end, 'setFunc', function(value)
                db.alertCDtext[db.classSelected][popUpFrame.id] = value;
        end)
    alertCDtext:SetPoint("LEFT", alertCD, "RIGHT", 100, 0)

    local removebutton = panel:MakeButton('name', L["removebutton"], 'newsize', 3, 'description', L["removebuttonToolTip"], 'extra', popUpFrame, 'func',
    function()
        local id = popUpFrame.id
        local class = db.classSelected
        local ability = GetSpellInfo(id) or id

        local _ability, _index = ATT:FindAbilityByName(db.customSpells[class], tonumber(id))
        if _ability and _index then
            table.remove(db.customSpells[class], _index)
            panel.popUP = false 
            popUpFrame:Hide()
            ATT:UpdateScrollBar();
            ATT:UpdateIcons()
            print(L["removebuttonRemoved"]..": |cffFF4500" .. ability .. "|r ID: |cffFF4500" .. id .. "|r")
        else
            print(L["removebuttonInvalid"])
        end
    end)
    removebutton:SetPoint("TOP", order, "CENTER", 20, -65)

    popUpFrame:SetScript("OnShow", function(self)
        alertCD:SetChecked(not not db.alertCD[db.classSelected][popUpFrame.id])
        alertCDtext:SetChecked(not not db.alertCDtext[db.classSelected][popUpFrame.id])
        if ATT:FindAbilityByName(db.customSpells[db.classSelected], tonumber(popUpFrame.id)) then
            removebutton:Show()
           else
            removebutton:Hide()
        end

        if (db.category == "abilities") then
            order:SetValue(tonumber(db.iconOrder[db.classSelected][popUpFrame.id]) or 20)
            order.currentText:SetText(tonumber(db.iconOrder[db.classSelected][popUpFrame.id]) or 20)
            order:Show();
            notorder:Hide();
        else
            order:Hide();
            notorder:Show();
        end
    end)
end

function ATT:UpdateScrollBar()
    local panel, scrollframe, btns = self.panel, self.scrollframe, self.btns
    local OrderPopUpFrame = self.OrderPopUpFrame
    local line = 1

    for abilityIndex, abilityTable in pairs(self:MergeTable(db.classSelected, db.category)) do
        local name, id, cooldown, maxcharges, custom, texture, trinketId, isPvPtrinket = abilityTable.name,
            abilityTable.ability, abilityTable.cooldown, abilityTable.maxcharges, abilityTable.custom,
            abilityTable.texture, abilityTable.trinketId, abilityTable.isPvPtrinket
        local button = btns[line]
        local abilitytexture = texture or self:FindAbilityIcon(name, id)

        if line == 1 then
            button:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 2, 0)
        end

        if custom then
            button.Text:SetText("|T" .. abilitytexture .. ":20|t |cff808080" .. name .. "|r")
            button:SetChecked(db.isEnabledSpell[db.classSelected][id .. "custom"])
            button:SetScript("OnClick", function(self)
                db.isEnabledSpell[db.classSelected][id .. "custom"] = button:GetChecked() or false;
                ATT:UpdateIcons();
            end)
        else
            if isPvPtrinket then
                button.Text:SetText("|T" .. abilitytexture .. ":20|t |cffFF4500" .. name .. "|r")
            else
                button.Text:SetText("|T" .. abilitytexture .. ":20|t " .. name)
            end
            button:SetChecked(db.isEnabledSpell[db.classSelected][trinketId and trinketId or id])
            button:SetScript("OnClick", function(self)
                db.isEnabledSpell[db.classSelected][trinketId and trinketId or id] = button:GetChecked() or false;
                ATT:UpdateIcons();
            end)
        end
        button.Text:SetSize(160, 22)
        button.Text:SetJustifyH("LEFT")
        button:SetHitRectInsets(0, -160, 0, 0)
        button.Text:SetFont(GameFontNormal:GetFont(), 12)


        button:SetScript('OnEnter', function()
            if trinketId then
                GameTooltip:ClearLines();
                GameTooltip:SetOwner(button, "ANCHOR_TOP")
                if isPvPtrinket then
                    GameTooltip:SetSpellByID(id)
                    GameTooltip:AddLine("|cffFF4500[PvP]|r Spell ID:" .. id, 1, 1, 1)
                else
                    GameTooltip:AddLine("Spell ID: " .. id, 1, 1, 1)
                end
                GameTooltip:SetPadding(16, 0)
                GameTooltip:Show()
            else
                GameTooltip:ClearLines();
                GameTooltip:SetOwner(button, "ANCHOR_TOP")
                GameTooltip:SetSpellByID(id)
                if custom then
                    GameTooltip:AddLine("|cff808080[CUSTOM]|r Spell ID: " .. id .. " - CD: " .. cooldown, 1, 1, 1)
                else
                    if db.category == "glyphs" then
                        GameTooltip:AddLine("Glyph ID: " .. id .. "\n|cffFF4500"..L["GlyphsInfo"].."|r", 1, 1, 1)
                    else
                        GameTooltip:AddLine("Spell ID: " .. id, 1, 1, 1)
                    end
                end
                GameTooltip:SetPadding(16, 0)
                GameTooltip:Show()
            end
        end)

        button:SetScript('OnLeave', function()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end)

        local orderbtn = button.orderbtn
        orderbtn:SetPoint("LEFT", button, "RIGHT", 160, 0)
        orderbtn:SetText("Order")
        orderbtn:SetScript("OnClick", function(self)
            if (db.category == "glyphs") then
                print(L["GlyphsNoInfo"].."|cffFF4500glyphs|r.")
                return
            end
            --OrderPopUpFrame.Title:SetText(("|T" .. abilitytexture .. ":15|t " .. name:sub(1, 30)))
            OrderPopUpFrame.id = id
            if panel.popUP then
                panel.popUP:Hide()
                panel.popUP = false
            else
                OrderPopUpFrame:Show()
                panel.popUP = OrderPopUpFrame
            end
        end)

        button:Show()
        line = line + 1
    end

    for i = line, 50 do
        btns[i]:Hide();
    end
end

function ATT:CreateAbilityEditor(frame)
    local panel = self.panel
    panel:Hide()
    local btns = {}
    self.btns = btns
    
    --local cpanel = CreateFrame("Frame", "ATTFrame", panel, BackdropTemplateMixin and "BackdropTemplate, InsetFrameTemplate")
    --cpanel:SetSize(640, 290)
    --cpanel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20 , -290)
    
    local scrollframe = CreateFrame("ScrollFrame", "ATTScrollFrame", frame, "UIPanelScrollFrameTemplate")
    local child = CreateFrame("Frame", "ATTScrollFrameChild", scrollframe)
    child:SetSize(1, 1)
    scrollframe:SetScrollChild(child)
    self.scrollframe = child
    scrollframe:SetSize(440, 262)
    --scrollframe:SetPoint('LEFT', 25, -110)
    scrollframe:SetPoint("TOPLEFT", frame, "TOPLEFT", 15 , -15)


    for i = 1, 50 do
        local button = CreateListButton(child, tostring(i), frame)
        if (i % 2 == 0) then
            button:SetPoint("LEFT", btns[#btns], "RIGHT", 195, 0)
        else
            button:SetPoint("TOPLEFT",
                btns[#btns - 1], "BOTTOMLEFT", 0, 0)
        end
        btns[#btns + 1] = button
    end

    scrollframe:SetScript("OnShow",
        function(self)
            ATT:FindFrameType();
            if panel.popUP then
                panel.popUP:Hide()
                panel.popUP = false
            end
            child.dropdownClass.initialize()
            child.dropdownClass:SetValue(db.classSelected or "WARRIOR")
            panel:UpdateSettings()
        end)

        local function classColor(class, color) 
            local colorClass = WrapTextInColorCode(class, color)
            return colorClass or class
        end

    local dropdownClass = panel:MakeDropDown('name', L["dropdownClass"], 'description', L["dropdownClassToolTip"], 'extra', frame, 'values',
        {
            "WARRIOR", classColor(LOCALIZED_CLASS_NAMES_MALE.WARRIOR, "ffC69B6D"),
            "PALADIN", classColor(LOCALIZED_CLASS_NAMES_MALE.PALADIN, "ffF48CBA"),
            "PRIEST", classColor(LOCALIZED_CLASS_NAMES_MALE.PRIEST, "ffFFFFFF"),
            "SHAMAN", classColor(LOCALIZED_CLASS_NAMES_MALE.SHAMAN, "ff0070DD"),
            "DRUID", classColor(LOCALIZED_CLASS_NAMES_MALE.DRUID, "ffFF7C0A"),
            "ROGUE", classColor(LOCALIZED_CLASS_NAMES_MALE.ROGUE, "ffFFF468"),
            "MAGE", classColor(LOCALIZED_CLASS_NAMES_MALE.MAGE, "ff3FC7EB"),
            "WARLOCK", classColor(LOCALIZED_CLASS_NAMES_MALE.WARLOCK, "ff8788EE"),
            "HUNTER", classColor(LOCALIZED_CLASS_NAMES_MALE.HUNTER, "ffAAD372"),
            "DEATHKNIGHT", classColor(LOCALIZED_CLASS_NAMES_MALE.DEATHKNIGHT, "ffC41E3A"),
        },
        'default', 'WARRIOR',
        'getFunc', function() return db.classSelected end,
        'getCurrent', function() return db.classSelected end,
        'setFunc', function(value)
            db.classSelected = value;
            db.category = "abilities"
            child.dropdownCateg.initialize()
            child.dropdownCateg:SetValue(db.category)
        end)
    dropdownClass:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 25, -10)
    child.dropdownClass = dropdownClass

    local dropdownCateg = panel:MakeDropDown('name', L["dropdownCateg"], 'description', L["dropdownCategToolTip"], 'extra', frame, 'values',
    { "abilities", L["Abilities"], "trinkets", L["Trinkets"], "racials", L["Racials"] , "glyphs", L["Glyphs"] }, 'default',
        "abilities", 'current', "abilities", 'getCurrent', function()
            return db.category
        end, 'setFunc', function(value)
            if panel.popUP then
                panel.popUP:Hide()
                panel.popUP = false
            end
            db.category = value;
            ATT:UpdateScrollBar()
            if value == "abilities" then self.globalSelections:Hide() self.editor:Show() else self.editor:Hide() self.globalSelections:Show() end 
            if value == "glyphs" then self.globalSelections:Hide() self.editor:Hide() end 
        end)
    dropdownCateg:SetPoint("TOPLEFT", dropdownClass, "BOTTOMLEFT", 0, -20)
    child.dropdownCateg = dropdownCateg

    local globalSelections = panel:MakeButton('name', L["globalSelections"], 'newsize', 3, 'description', L["globalSelectionsToolTip"],'extra', frame, 'func',
    function()
    local class = dropdownClass.value
    local categ = dropdownCateg.value
      if categ ~= "trinkets" and categ ~= "racials" then print("|cffFF4500" ..categ .. "|r - "..L["globalSelectionsInvalid"]) return end
      for abilityIndex, abilityTable in pairs(self:MergeTable(class, categ)) do
        local name, id, trinketId = abilityTable.name, abilityTable.ability, abilityTable.trinketId
            local isenabled = db.isEnabledSpell[class] and db.isEnabledSpell[class][trinketId and trinketId or id]
            local alertcd = db.alertCD[class] and db.alertCD[class][id]
            local alertcdtext = db.alertCDtext[class] and db.alertCDtext[class][id]
            EnableGlobalSpell(trinketId and trinketId or id, isenabled, alertcd, alertcdtext) --global selections
      end
           ATT:UpdateScrollBar();
           ATT:UpdateIcons()
           print("|cffFF4500"..categ.."|r "..L["globalSelectionsDone"])
   end)
   globalSelections:SetPoint("CENTER", dropdownCateg, "TOP", 1, -75)
   self.globalSelections = globalSelections

    local editor = CreateFrame("Frame", "ATTFrame", frame, BackdropTemplateMixin and "BackdropTemplate, InsetFrameTemplate")
    editor:SetSize(150, 110)
    editor:SetPoint("TOPLEFT", dropdownCateg, "BOTTOMLEFT", 10, -50)
    self.editor = editor
    local editorTitle = editor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    editorTitle:SetPoint("CENTER", editor, "TOP", 0, -13)
    editorTitle:SetText("Ability Editor")

    local ideditbox = CreateEditBox(L["AbilityID"], editor, 75, 30)
    ideditbox:SetPoint("TOPLEFT", dropdownCateg, "BOTTOMLEFT", 25, -90)

    local cdeditbox = CreateEditBox(L["AbilityCD"], editor, 35, 30)
    cdeditbox:SetPoint("LEFT", ideditbox, "RIGHT", 15, 0)

    local addbutton = panel:MakeButton('name', L["addbutton"], 'newsize', 3, 'description', L["addbuttonToolTip"], 'extra', editor, 'func',
        function()
            local id = ideditbox:GetText():match("^[0-9]+$")
            local class = dropdownClass.value
            local ability = GetSpellInfo(id)
            local cdtext = cdeditbox:GetText():match("^[0-9]+$")

            if ability and cdtext and id and db.customSpells[class] then
                local abilities = db.customSpells[class]
                local _ability, _index = ATT:FindAbilityByName(db.customSpells[class], tonumber(ideditbox:GetText()))
                if _ability and _index then
                    abilities[_index] = {
                        ability = tonumber(id),
                        cooldown = tonumber(cdtext),
                        order = _ability.order or 20,
                        custom = true
                    }
                    ideditbox:SetText("");
                    cdeditbox:SetText("");
                    print(L["addbuttonUpdate"]..": |cffFF4500" ..ability .. "|r id: |cffFF4500" .. id .. "|r cd: |cffFF4500" .. cdtext .. "|r")
                else
                    table.insert(abilities, { ability = tonumber(id), cooldown = tonumber(cdtext), order = 20, custom = true })
                    ideditbox:SetText("");
                    cdeditbox:SetText("");
                    print(L["addbuttonAdded"]..": |cffFF4500" ..ability .. "|r id: |cffFF4500" .. id .. "|r cd: |cffFF4500" .. cdtext .. "|r")
                end
                ATT:UpdateScrollBar();
                ATT:UpdateIcons()
            else
                print(L["addbuttonInvalid"])
            end
        end)
    addbutton:SetPoint("TOPLEFT", ideditbox, "BOTTOMLEFT", -8, -5)

end
function ATT:CreateTabs()
    local panel = self.panel
 
     local ATTTabs = CreateFrame("Frame", "ATTTabsFrame", panel, "InsetFrameTemplate")
     ATTTabs:SetSize(650, 290)
     ATTTabs:SetPoint("TOPLEFT", panel, "TOPLEFT", 20 , -310)
     ATTTabs:EnableMouse(true)
 
   
     -- Create tabs
     local tabs = {}
     local tabHeaders = {L["editorTitle"], L["showVisibility"] , L["Profiles"], L["Options"] }
 
     for i = 1, #tabHeaders do
         local tab = CreateFrame("Button", ATTTabs:GetName().."Tab"..i, ATTTabs, "FriendsFrameTabTemplate")
         tab:SetID(i)
         tab:SetText(tabHeaders[i])
         tab:SetScript("OnClick", function()
            if panel.popUP then panel.popUP:Hide() panel.popUP = false end
             _G.PanelTemplates_SetTab(ATTTabs, i)
             ATTTabs:ShowTab(i)
         end) 
     
         if i == 1 then
             tab:SetPoint("TOPLEFT", ATTTabs, "BOTTOMLEFT", 5, 0)
         else
             tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", -16, 0)
         end
     
         tabs[i] = tab
     end
 
     _G.PanelTemplates_SetNumTabs(ATTTabs, #tabs)
     _G.PanelTemplates_SetTab(ATTTabs, 1)
     -- Create content frames
     local tabContents = {}
     
     
     local function CreateTabContent(parent, tabName)
         local frame = CreateFrame("Frame", nil, parent)
         frame:SetSize(650, 290)
         frame:SetPoint("TOP", 0, 0)
         frame:Hide()
 
         if tabName == 1 then self:CreateAbilityEditor(frame) end
 
         if tabName == 2 then  
             local headerFrame = CreateFrame("Frame", nil, frame)
             headerFrame:SetSize(250, 54)  -- Smaller width and height
             headerFrame:SetPoint("TOP", 0, 0)
 
             local headerTexture = headerFrame:CreateTexture(nil, "BACKGROUND")
             headerTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")

             headerTexture:SetAllPoints(headerFrame)
 
             -- Create the header text
             local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
             headerText:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)
             headerText:SetText(L["showVisibility"])

             local font, _, flags = headerText:GetFont()
             headerText:SetFont(font, 14, flags) 

             self:CreateVisibilityFrame(frame) 
         end

         if tabName == 3 then 
            local headerFrame = CreateFrame("Frame", nil, frame)
            headerFrame:SetSize(250, 54)  
            headerFrame:SetPoint("TOP", 0, 0)

            local headerTexture = headerFrame:CreateTexture(nil, "BACKGROUND")
            headerTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")

            headerTexture:SetAllPoints(headerFrame)

            -- Create the header text
            local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            headerText:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)
            headerText:SetText(L["Profiles"])
 
            local font, _, flags = headerText:GetFont()
            headerText:SetFont(font, 14, flags) 

             self:CreateProfilesFrame(frame) 
         end
 
         if tabName == 4 then 
            local headerFrame = CreateFrame("Frame", nil, frame)
            headerFrame:SetSize(250, 54)  
            headerFrame:SetPoint("TOP", 0, 0)

            local headerTexture = headerFrame:CreateTexture(nil, "BACKGROUND")
            headerTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")

            headerTexture:SetAllPoints(headerFrame)

            -- Create the header text
            local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            headerText:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)
            headerText:SetText(L["Options"])
 
            local font, _, flags = headerText:GetFont()
            headerText:SetFont(font, 14, flags) 

             self:CreateOptionsFrame(frame) 
         end

         return frame
     end
 
       tabContents[1] = CreateTabContent(ATTTabs, 1)
       tabContents[2] = CreateTabContent(ATTTabs, 2) 
       tabContents[3] = CreateTabContent(ATTTabs, 3)  
       tabContents[4] = CreateTabContent(ATTTabs, 4)  

 -- Function to show the correct tab content
 function ATTTabs:ShowTab(tabIndex)
     for i, frame in ipairs(tabContents) do
         if i == tabIndex then
             frame:Show()
         else
             frame:Hide()
         end
     end
 end
     
     ATTTabs:ShowTab(1)
 end


ATT:RegisterEvent("ADDON_LOADED")
ATT:SetScript("OnEvent", ATT_OnLoad)