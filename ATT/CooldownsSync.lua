local addon, ATTdbs = ...
local unpack = table.unpack or _G.unpack
local isDF = (select(4, GetBuildInfo()) >= 100000)

local function IsInGroup()
	return (GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0)
end

local function IsInRaid()
	return GetNumRaidMembers() > 0
end

local GetSpellInfo = GetSpellInfo or function(spellID)
	local spellInfo = C_Spell.GetSpellInfo(spellID);
	if spellInfo then
		return spellInfo.name, spellInfo.iconID, spellInfo.originalIconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID
	end
end

local GetSpellCooldown = GetSpellCooldown or function(spellID)
	local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
	if spellCooldownInfo then
		return spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate;
	end
end

local GetSpellCharges = GetSpellCharges or function(spellID)
	local spellChargeInfo = C_Spell.GetSpellCharges(spellID)
	if spellChargeInfo then
		return spellChargeInfo.currentCharges, spellChargeInfo.maxCharges, spellChargeInfo.cooldownStartTime, spellChargeInfo.cooldownDuration, spellChargeInfo.chargeModRate;
	end
end

-- default values
ATTdbs.HasATT = {}
ATTdbs.inGroup = false
ATTdbs.CooldownTickers = {}
ATTdbs.PlayerCooldowns = {}
ATTdbs.PlayerCooldownsHash = {}

local CONST_CVAR_TEMPCACHE = "ATTcache"

local function print(...)
    for i = 1, select('#', ...) do
        ChatFrame1:AddMessage("|cff33ff99ATT SYNC|r: " .. select(i, ...))
    end
end

function ATTdbs:GetPlayerSpecId()
    local spec = GetSpecialization()
    if (spec) then
        local specId = GetSpecializationInfo(spec)
        if (specId and specId > 0) then
            return specId
        end
    end
end

local getAuraDuration = function(spellId)
    return 0
end

-- return is a number is almost equal to another within a tolerance range
function ATTdbs:isNearlyEqual(value1, value2, tolerance)
    tolerance = tolerance or 0.01
    return abs(value1 - value2) <= tolerance
end

local selectIndexes = function(table, startIndex, amountIndexes, zeroIfNil)
    local values = {}
    for i = startIndex, startIndex + amountIndexes do
        values[#values + 1] = tonumber(table[i]) or (zeroIfNil and 0) or table[i]
    end
    return values
end

local function packCooldowns(table)
    local tableSize = #table
    local newString = "" .. tableSize .. ","
    for i = 1, tableSize do
        newString = newString .. table[i] .. ","
    end

    newString = newString:gsub(",$", "")
    return newString
end

local function unpackCooldowns(table)
    local result = {}
    local reservedIndexes = table[1]

    if (not reservedIndexes) then
        return result
    end

    for i = 2, reservedIndexes + 1, 6 do
        local key = tonumber(table[i])
        local values = selectIndexes(table, i + 1, 4, true)
        result[key] = values
    end
    return result
end

function ATTdbs:GetCooldownInfo(cooldownInfo)
    local timeLeft, charges, timeOffset, duration, updateTime, auraDuration = unpack(cooldownInfo)
    if (not timeOffset or not updateTime) then
        return false, 0, 0, 0, 0, 0, 0, 0
    end

    timeOffset = abs(timeOffset)
    local minValue = updateTime - timeOffset -- start
    local maxValue = minValue + duration -- end
    local currentValue = GetTime() -- now
    local percent = min((currentValue - minValue) / max((maxValue - minValue), 0.0000001), 1)
    local timeLeft = max(maxValue - currentValue, 0)

    -- lag compensation
    if (timeLeft <= 2) then
        timeLeft = 0
        if (charges == 0) then
            charges = 1
        end
        minValue = currentValue
        maxValue = 1
        currentValue = 1
    end

    local bIsReady = timeLeft <= 2
    return bIsReady, percent, timeLeft, charges, minValue, maxValue, min(currentValue, maxValue), duration
end

local function tableByLibVersion(data)
    local dataAsTable = {strsplit(",", data)}
    if dataAsTable[#dataAsTable - 1] == "Q" then
        local serverTimeReceived = dataAsTable[#dataAsTable]
        table.removemulti(dataAsTable, #dataAsTable - 1, 2)
        return dataAsTable, serverTimeReceived
    else
        return dataAsTable
    end
end

-- ~comms
function ATTdbs:OnReceiveComm(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)

    if prefix == "LRSATT" then
        ATTdbs.HasATT[sender] = true
    end

    if (prefix == "LRSATT" or (prefix == "LRS" and not ATTdbs.HasATT[sender])) then

        local unit = ATTdbs.UnitIDCache[sender]
        local playerName = UnitName("player")

        if (channel == "GUILD") or (not unit) or (sender == playerName) then 
            return
        end

        local data = text
        local LibDeflate = LibStub:GetLibrary("LibDeflate")
        local dataCompressed = LibDeflate:DecodeForWoWAddonChannel(data)
        data = LibDeflate:DecompressDeflate(dataCompressed)

        if (not unit) or (not data) or (type(data) ~= "string") then
            return
        end
        local dataTypePrefix = data:match("^.")

        if (dataTypePrefix == "U" or dataTypePrefix == "C") then
            -- convert to table
            local dataAsTable = {strsplit(",", data)}
            -- local dataAsTable = tableByLibVersion(data)

            -- remove the first index (prefix)
            tremove(dataAsTable, 1)

            -- trigger callbacks
            ATTdbs:CooldownUpdate(dataTypePrefix, unit, dataAsTable)
        end

        if (dataTypePrefix == "F") then
            -- trigger callbacks
            ATTdbs:AllDataRequested()
            --
        end
    end
end

function ATTdbs:CooldownUpdate(dataTypePrefix, unit, data)

    if (dataTypePrefix == "U") then

        local dataAsArray = data
        local spellId = tonumber(dataAsArray[1])
        local timeLeft = tonumber(dataAsArray[2])
        local charges = tonumber(dataAsArray[3])
        local startTimeOffset = tonumber(dataAsArray[4])
        local duration = tonumber(dataAsArray[5])
        local auraDuration = tonumber(dataAsArray[6])

        if (not spellId or spellId == 0) or (not timeLeft) or (not charges) or (not startTimeOffset) or (not duration) or (not auraDuration) then
            return
        end

        ATTdbs:OnReceiveCooldownUpdate(unit, spellId, {timeLeft,charges,startTimeOffset,duration,GetTime(),auraDuration})
    end

    if (dataTypePrefix == "C") then
        --if ATTdbs.syncFixDelayed and ATTdbs.syncFixDelayed + 10 > GetTime() then return end --openraidlib delay fix

        local cooldownsTable = unpackCooldowns(data)

        if (not cooldownsTable) then
            return
        end

        local now = GetTime()
        for spellId, cooldownTable in pairs(cooldownsTable) do
            cooldownTable[5] = now
        end

        ATTdbs:OnReceiveCooldownListUpdate(unit, cooldownsTable)
    end

end

function ATTdbs:GetPlayerCooldownStatus(spellId)
    -- check if is a charge spell
    local buffDuration = getAuraDuration(spellId)
    local chargesAvailable, chargesTotal, start, duration = GetSpellCharges(spellId)

    if chargesAvailable then
        if (chargesAvailable == chargesTotal) then
            return 0, chargesTotal, 0, 0, 0 -- all charges are ready to use
        else
            -- return the time to the next charge
            local timeLeft = start + duration - GetTime()
            local startTimeOffset = start - GetTime()
            return ceil(timeLeft), chargesAvailable, startTimeOffset, duration, buffDuration
        end
    else
        local start, duration = GetSpellCooldown(spellId)
        if (start == 0) then -- cooldown is ready
            return 0, 1, 0, 0, 0 -- time left, charges, startTime
        elseif start then
            local timeLeft = start + duration - GetTime()
            local startTimeOffset = start - GetTime()

            return ceil(timeLeft), 0, ceil(startTimeOffset), duration, buffDuration -- time left, charges, startTime, duration, buffDuration
        end
    end
end

local function UpdatePlayerCooldownList()
    -- update the list of cooldowns the player has available

    ATTdbs.PlayerCooldowns = {}
    ATTdbs.PlayerCooldownsHash = {}
    local _, playerClass = UnitClass("player")
    local specid = isDF and ATTdbs:GetPlayerSpecId()
    if not playerClass or (isDF and not specid) then
        return
    end

    local locPlayerRace, playerRace, playerRaceId = UnitRace("player")
    -- local spellBookSpellList = getSpellListAsHashTableFromSpellBook()
    local timeNow = GetTime()

    -- build a list of all spells assigned as cooldowns for the player class

    for abilityIndex, abilityTable in pairs(ATTdbs.constellations) do
        -- if spellBookSpellList[abilityTable.ability] then
        local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(abilityTable.ability)
        ATTdbs.PlayerCooldowns[abilityTable.ability] = {timeLeft, charges, startTimeOffset, duration, timeNow, auraDuration}
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = abilityTable.ability
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = timeLeft
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = charges
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = startTimeOffset
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = duration
        ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = auraDuration
        -- end
    end

    local specSpells
    if isDF then specSpells = ATTdbs.dbImport[playerClass][tostring(specid)] else specSpells = (ATTdbs.dbImport[playerClass]) end

    if specSpells then
        for abilityIndex, abilityTable in pairs(specSpells) do
            -- if spellBookSpellList[abilityTable.ability] then
            local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(abilityTable.ability)
            ATTdbs.PlayerCooldowns[abilityTable.ability] = {timeLeft, charges, startTimeOffset, duration, timeNow, auraDuration}
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = abilityTable.ability
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = timeLeft
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = charges
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = startTimeOffset
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = duration
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = auraDuration
        end
    end

    for abilityIndex, abilityTable in pairs(ATTdbs.ShareCD) do
        if isDF then -- and spellBookSpellList[abilityIndex]
            local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(abilityIndex)
            ATTdbs.PlayerCooldowns[abilityIndex] = {timeLeft, charges, startTimeOffset, duration, timeNow, auraDuration}
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = abilityIndex
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = timeLeft
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = charges
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = startTimeOffset
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = duration
            ATTdbs.PlayerCooldownsHash[#ATTdbs.PlayerCooldownsHash + 1] = auraDuration
        end
    end

end

local function SendPlayerCooldown(spellId, timeLeft, charges, startTimeOffset, duration, auraDuration)
     if ATTDB.disableSync then return end

    -- update the player cooldowns locally
     ATTdbs:OnReceiveCooldownUpdate("player", spellId, {timeLeft,charges,startTimeOffset,duration,GetTime(),auraDuration})

    if IsInGroup() then
        local dataToSend = "U," .. spellId .. "," .. timeLeft .. "," .. charges .. "," .. startTimeOffset .. "," .. duration .. "," .. auraDuration
        -- send the data
        ATTdbs:SendCommData(dataToSend)
    end
end

local function SendAllPlayerCooldowns()
    -- get the full cooldown list
    UpdatePlayerCooldownList()
    -- update the player cooldowns locally
    if ATTDB.disableSync then return end
     ATTdbs:OnReceiveCooldownListUpdate("player", ATTdbs.PlayerCooldowns)

    if IsInGroup() then
        -- pack
        local playerCooldownString = packCooldowns(ATTdbs.PlayerCooldownsHash)
        local dataToSend = "C," .. playerCooldownString
        -- send the data
        ATTdbs:SendCommData(dataToSend)
    end
end

local function SendFullData()
    SendAllPlayerCooldowns()
end

function ATTdbs:RequestAllData()
    -- the the player isn't in group, don't send the request
    if (not IsInGroup()) then
        return
    end

    ATTdbs.requestAllInfoCooldown = ATTdbs.requestAllInfoCooldown or 0

    -- check if the player can sent another request
    if (ATTdbs.requestAllInfoCooldown > GetTime()) then
        return
    end

    ATTdbs:SendCommData("F")

    ATTdbs.requestAllInfoCooldown = GetTime() + 30
end

function ATTdbs:AllDataRequested()
    ATTdbs.sendRequestedAllInfoCooldown = ATTdbs.sendRequestedAllInfoCooldown or 0

    if (ATTdbs.sendRequestedAllInfoCooldown > GetTime()) then
        -- reschedule the function call
        ATTdbs:NewUniqueTimer(ATTdbs.sendRequestedAllInfoCooldown - GetTime(), SendFullData, "CommHandler", "sendFullData_Schedule")
        return
    end

    ATTdbs:NewUniqueTimer(math.random(1, 6), SendFullData, "CommHandler", "sendFullData_Schedule")

    -- set the delay for the next request
    ATTdbs.sendRequestedAllInfoCooldown = GetTime() + 30
end
-- ]]
-- @flags
-- 0x1: to party
-- 0x2: to raid
-- 0x4: to guild
local sendData = function(dataEncoded, channel)
    local aceComm = LibStub:GetLibrary("AceComm-3.0", true)
    local dataEncoded = dataEncoded
    if (aceComm) then
        aceComm:SendCommMessage("LRSATT", dataEncoded, channel, nil, "ALERT")
    else
        SendAddonMessage("LRSATT", dataEncoded, channel)
    end
end

local sendDataLR = function(dataEncoded, channel)
    local aceComm = LibStub:GetLibrary("AceComm-3.0", true)

    if (aceComm) then
        aceComm:SendCommMessage("LRS", dataEncoded, channel, nil, "ALERT")
    else
        SendAddonMessage("LRS", dataEncoded, channel)
    end
end

function ATTdbs:SendCommData(data, flags)
    -- local serverTime = GetServerTime()
    -- local data = data .. ",Q," .. serverTime
    if ATTDB.disableSync then return end

    local hasLOR = LibStub("LibOpenRaid-1.0", true)
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local dataCompressed = LibDeflate:CompressDeflate(data, {
        level = 9
    })
    local dataEncoded = LibDeflate:EncodeForWoWAddonChannel(dataCompressed)

    if (flags) then
        if (bit.band(flags, "0x1")) then -- send to party
            if (IsInGroup() and not IsInRaid()) then
                sendData(dataEncoded, IsInGroup() and "PARTY" or "PARTY")
                if data == "F" and not hasLOR then
                    sendDataLR(dataEncoded, IsInGroup() and "PARTY" or "PARTY")
                end
            end
        end

        if (bit.band(flags, "0x2")) then -- send to raid
            if (IsInRaid()) then
                sendData(dataEncoded, IsInRaid() and "RAID" or "RAID")
                if data == "F" and not hasLOR then
                    sendDataLR(dataEncoded, IsInRaid() and "RAID" or "RAID")
                end
            end
        end

        --  if (bit.band(flags, "0x4")) then --send to guild
        --     if (IsInGuild()) then
        --        sendData(dataEncoded, "GUILD")
        --   end
        --  end
    else
        if (IsInGroup() and not IsInRaid()) then -- in party only
            sendData(dataEncoded, IsInGroup() and "PARTY" or "PARTY")
            if data == "F" and not hasLOR then
                sendDataLR(dataEncoded, IsInGroup() and "PARTY" or "PARTY")
            end

        elseif (IsInRaid()) then
            sendData(dataEncoded, IsInRaid() and "RAID" or "RAID")
            if data == "F" and not hasLOR then
                sendDataLR(dataEncoded, IsInRaid() and "RAID" or "RAID")
            end
        end
    end
end

-- ~schedule ~timers

ATTdbs.registeredUniqueTimers = {}

-- run a scheduled function with its payload
local triggerScheduledTick = function(tickerObject)
    local payload = tickerObject.payload
    local callback = tickerObject.callback

    if (tickerObject.isUnique) then
        local namespace = tickerObject.namespace
        local scheduleName = tickerObject.scheduleName
        ATTdbs:CancelUniqueTimer(namespace, scheduleName)
    end

    local result, errortext = xpcall(callback, geterrorhandler(), unpack(payload))
    if (not result) then
       -- print("ERROR on scheduler:", tickerObject.scheduleName, tickerObject.stack, errortext)
    end

    return result
end

-- create a new schedule
function ATTdbs:NewTimer(time, callback, ...)
    local payload = {...}
    local newTimer = C_Timer:NewTimer(time, triggerScheduledTick)
    newTimer.payload = payload
    newTimer.callback = callback
    newTimer.stack = debugstack()
    return newTimer
end

-- create an unique schedule
-- if a schedule already exists, cancels it and make a new
function ATTdbs:NewUniqueTimer(time, callback, namespace, scheduleName, ...)
    ATTdbs:CancelUniqueTimer(namespace, scheduleName)

    -- TODO
    --local newTimer = ATTdbs:NewTimer(time, callback, ...)
    --newTimer.namespace = namespace
    --newTimer.scheduleName = scheduleName
    --newTimer.stack = debugstack()
    --newTimer.isUnique = true

    local registeredUniqueTimers = ATTdbs.registeredUniqueTimers
    registeredUniqueTimers[namespace] = registeredUniqueTimers[namespace] or {}
    registeredUniqueTimers[namespace][scheduleName] = newTimer
end

-- cancel an unique schedule
function ATTdbs:CancelUniqueTimer(namespace, scheduleName)
    local registeredUniqueTimers = ATTdbs.registeredUniqueTimers
    local currentSchedule = registeredUniqueTimers[namespace] and registeredUniqueTimers[namespace][scheduleName]
    if (currentSchedule) then
        if (not currentSchedule:IsCancelled()) then
            currentSchedule:Cancel()
        end
        registeredUniqueTimers[namespace][scheduleName] = nil
    end
end

-- cancel all unique timers
function ATTdbs:CancelAllUniqueTimers()
    local registeredUniqueTimers = ATTdbs.registeredUniqueTimers
    for namespace, schedulesTable in pairs(registeredUniqueTimers) do
        for scheduleName, timerObject in pairs(schedulesTable) do
            if (timerObject and not timerObject:IsCancelled()) then
                timerObject:Cancel()
            end
        end
    end
    table.wipe(registeredUniqueTimers)
end

local cooldownTimeLeftCheck_Ticker = function(tickerObject)
    local spellId = tickerObject.spellId

    -- if the spell does not exists anymore in the player table, cancel the ticker
    if (not ATTdbs.PlayerCooldowns[spellId]) then
        tickerObject:Cancel()
        return
    end

    tickerObject.cooldownTimeLeft = tickerObject.cooldownTimeLeft - 1
    local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(spellId)

    -- is the spell ready to use?
    if (timeLeft == 0) then
        -- it's ready

        SendPlayerCooldown(spellId, 0, charges, 0, 0, 0)
        ATTdbs.CooldownTickers[spellId] = nil
        tickerObject:Cancel()
    else
        -- check if the time left has changed, this check if the cooldown got its time reduced and if the cooldown time has been slow down by modRate
        if (not ATTdbs:isNearlyEqual(tickerObject.cooldownTimeLeft, timeLeft, 1)) then

            -- there's a deviation, send a comm to communicate the change in the time left
            SendPlayerCooldown(spellId, timeLeft, charges, startTimeOffset, duration, auraDuration)
            tickerObject.cooldownTimeLeft = timeLeft
        end
    end

end

local cooldownStartTicker = function(spellId, cooldownTimeLeft)
    local existingTicker = ATTdbs.CooldownTickers[spellId]

    if (existingTicker) then
        -- if a ticker already exists, might be the cooldown of a charge
        -- if the ticker isn't about to expire, just keep the timer
        -- when the ticker finishes it'll check again for charges
        if (existingTicker.startTime + existingTicker.cooldownTimeLeft - GetTime() > 2) then
            return
        end

        -- cancel the existing ticker
        if (not existingTicker:IsCancelled()) then
            existingTicker:Cancel()
        end
    end

    -- create a new ticker
    local maxTicks = ceil(cooldownTimeLeft / 1)
    local newTicker = C_Timer:NewTicker(1, cooldownTimeLeftCheck_Ticker, maxTicks)

    -- store the ticker
    ATTdbs.CooldownTickers[spellId] = newTicker
    newTicker.spellId = spellId
    newTicker.cooldownTimeLeft = cooldownTimeLeft
    newTicker.startTime = GetTime()
    newTicker.endTime = GetTime() + cooldownTimeLeft
end

function ATTdbs:CleanupCooldownTickers()
    for spellId, tickerObject in pairs(ATTdbs.CooldownTickers) do
        local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(spellId)
        if (timeLeft == 0) then
            tickerObject:Cancel()
            ATTdbs.CooldownTickers[spellId] = nil
        end
    end
end

function ATTdbs:OnPlayerCast(event, spellId, isPlayerPet) -- ~cast
    -- player casted a spell, check if the spell is registered as cooldown
    -- issue: pet spells isn't in this table yet, might mess with pet interrupts
    if (ATTdbs.PlayerCooldowns[spellId]) then -- check if the casted spell is a cooldown the player has available
        -- get the cooldown time for this spell
        local timeLeft, charges, startTimeOffset, duration, auraDuration = ATTdbs:GetPlayerCooldownStatus(spellId) -- return 5 values

        SendPlayerCooldown(spellId, timeLeft, charges, startTimeOffset, duration, auraDuration) -- CooldownUpdate

        -- create a timer to monitor the time of this cooldown
        -- as there's just a few of them to monitor, there's no issue on creating one timer per spell
         cooldownStartTicker(spellId, timeLeft)
    end
end

local function delayedTalentChange()
    ATTdbs:NewUniqueTimer(math.random(3, 6), UpdatePlayerCooldownList, "TalentChangeEventGroup", "talentChangedCallback_Schedule")
end

local eventFrame = CreateFrame("Frame")

local eventFunctions = {
    -- check if the player joined a group
    ["GROUP_ROSTER_UPDATE"] = function()
        local bEventTriggered = false
        if (IsInGroup()) then
            if (not ATTdbs.inGroup) then
                ATTdbs.inGroup = true
                ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
                bEventTriggered = true
            end
        else
            if (ATTdbs.inGroup) then
                ATTdbs.inGroup = false
                ---EraseData()
                ATTdbs:CleanupCooldownTickers()
                ATTdbs:CancelAllUniqueTimers()
                bEventTriggered = true
            end
        end

        if (not bEventTriggered and IsInGroup()) then -- the player didn't left or enter a group
            -- the group has changed, trigger a long timer to send full data
            -- as the timer is unique, a new change to the group will replace and refresh the time
            -- using random time, players won't trigger all at the same time
            local randomTime = 5 + math.random() + math.random(1, 5)
            ATTdbs:NewUniqueTimer(randomTime, SendFullData, "mainControl", "sendFullData_Schedule")
        end
    end,
    ["GROUP_JOINED"] = function(...)
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            -- EraseData()
            --ATTdbs.syncFixDelayed = GetTime()
            ATTdbs:CleanupCooldownTickers()
            ATTdbs:CancelAllUniqueTimers()
            ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
        end
    end,

    ["UNIT_SPELLCAST_SUCCEEDED"] = function(...)
        local unit, spellName, _, rank = select(1, ...)

        --TODO
        if true then
        	return
        end

        if unitId ~= "player" or unitId ~= "pet" then
             return
        end
        C_Timer:After(0.1, function()
            -- some spells has many different spellIds, get the default
            -- trigger internal callbacks
            -- TriggerEvent("playerCast", spellId, UnitIsUnit(unitId, "pet"))
            ATTdbs:OnPlayerCast("playerCast", spellId, UnitIsUnit(unitId, "pet"))
        end)
    end,

    ["PLAYER_ENTERING_WORLD"] = function(...)
        -- has the selected character just loaded?
        if (not ATTdbs.bHasEnteredWorld) then
            ATTdbs:RegisterSyncEvents()
            ATTdbs:RequestAllData()
            ATTdbs.bHasEnteredWorld = true
        end
        ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
    end,

    ["PLAYER_SPECIALIZATION_CHANGED"] = function(...)
        delayedTalentChange()
    end,
    ["PLAYER_TALENT_UPDATE"] = function(...)
        delayedTalentChange()
    end,
    ["TRAIT_CONFIG_UPDATED"] = function(...)
        delayedTalentChange()
    end,
    ["TRAIT_TREE_CURRENCY_INFO_UPDATED"] = function(...)
        delayedTalentChange()
    end,

    -- SPELLS_CHANGED

    ["PLAYER_PVP_TALENT_UPDATE"] = function(...)
        -- TriggerEvent("pvpTalentUpdate")
    end,

    ["PLAYER_DEAD"] = function(...)
        --  UpdatePlayerAliveStatus()
    end,
    ["PLAYER_ALIVE"] = function(...)
        --  UpdatePlayerAliveStatus()
    end,
    ["PLAYER_UNGHOST"] = function(...)
        --  UpdatePlayerAliveStatus()
    end,

    ["PLAYER_REGEN_ENABLED"] = function(...)
        ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
    end,

    ["ENCOUNTER_END"] = function()
        if (IsInRaid()) then
            ATTdbs:CleanupCooldownTickers()
            ATTdbs:NewUniqueTimer(1 + math.random(1, 4), SendFullData, "mainControl", "sendFullData_Schedule") -- sendAllPlayerCooldowns_Schedule
        end
    end,

    ["CHALLENGE_MODE_START"] = function()
        ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
    end,

    ["CHALLENGE_MODE_COMPLETED"] = function()
        ATTdbs:NewUniqueTimer(1.0, SendFullData, "mainControl", "sendFullData_Schedule")
    end,

    ["PLAYER_LOGOUT"] = function()
        --  tempCache.SaveData()
    end,

    ["CHAT_MSG_ADDON"] = function(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
        ATTdbs:OnReceiveComm(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
    end
}

local eventFrame = CreateFrame("frame", "ORLATT", UIParent)
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local eventCallbackFunc = eventFunctions[event]
    eventCallbackFunc(...)
end)

function ATTdbs:RegisterSyncEvents()
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("GROUP_JOINED")
    -- eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    -- eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    -- eventFrame:RegisterEvent("UNIT_PET")
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("PLAYER_ALIVE")
    eventFrame:RegisterEvent("PLAYER_UNGHOST")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")

    if (isDF) then
        eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        eventFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE")
        eventFrame:RegisterEvent("ENCOUNTER_END")
        eventFrame:RegisterEvent("CHALLENGE_MODE_START")
        eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
        eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        eventFrame:RegisterEvent("TRAIT_TREE_CURRENCY_INFO_UPDATED")
        eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    end

end

