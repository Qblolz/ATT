local addon, ATTdbs = ...

ATTdbs.validPartyUnits = { 
    ["player"] = 5, ["party1"] = 1, ["party2"] = 2, ["party3"] = 3, ["party4"] = 4,	["pet"] = 5, ["partypet1"] = 1, ["partypet2"] = 2, ["partypet3"] = 3, ["partypet4"] = 4,
}

ATTdbs.validRaidUnits = {
    ["raid1"] = 1, ["raid2"] = 2, ["raid3"] = 3, ["raid4"] = 4, ["raid5"] = 5, ["raid6"] = 6, ["raid7"] = 7, ["raid8"] = 8, ["raid9"] = 9,["raid10"] = 10,
    ["raid11"] = 11, ["raid12"] = 12, ["raid13"] = 13, ["raid14"] = 14, ["raid15"] = 15, ["raid16"] = 16, ["raid17"] = 17, ["raid18"] = 18, ["raid19"] = 19,["raid20"] = 20,
    ["raid21"] = 21, ["raid22"] = 22, ["raid23"] = 23, ["raid24"] = 24, ["raid25"] = 25, ["raid26"] = 26, ["raid27"] = 27, ["raid28"] = 28, ["raid29"] = 29,["raid30"] = 30,
    ["raid31"] = 31, ["raid32"] = 32, ["raid33"] = 33, ["raid34"] = 34, ["raid35"] = 35, ["raid36"] = 36, ["raid37"] = 37, ["raid38"] = 38, ["raid39"] = 39,["raid40"] = 40,

	["raidpet1"] = 1, ["raidpet2"] = 2, ["raidpet3"] = 3, ["raidpet4"] = 4, ["raidpet5"] = 5, ["raidpet6"] = 6, ["raidpet7"] = 7, ["raidpet8"] = 8,["raidpet9"] = 9,["raidpet10"] = 10,
	["raidpet11"] = 11, ["raidpet12"] = 12, ["raidpet13"] = 13, ["raidpet14"] = 14, ["raidpet15"] = 15, ["raidpet16"] = 16, ["raidpet17"] = 17, ["raidpet18"] = 18, ["raidpet19"] = 19,["raidpet20"] = 20,
    ["raidpet21"] = 21, ["raidpet22"] = 22, ["raidpet23"] = 23, ["raidpet24"] = 24, ["raidpet25"] = 25, ["raidpet26"] = 26, ["raidpet27"] = 27, ["raidpet28"] = 28, ["raidpet29"] = 29,["raidpet30"] = 30,
    ["raidpet31"] = 31, ["raidpet32"] = 32, ["raidpet33"] = 33, ["raidpet34"] = 34, ["raidpet35"] = 35, ["raidpet36"] = 36, ["raidpet37"] = 37, ["raidpet38"] = 38, ["raidpet39"] = 39,["raidpet40"] = 40,
}

ATTdbs.customframes = {
    [3] = { ctype = "ShadowUFRaidGR", cname = "ShadowedUnitFrames" , cframe = "SUFHeaderraid1RGUnitButton%d", },
    [4] = { ctype = "ShadowedUF", cname = "ShadowedUnitFrames" , cframe = "SUFHeaderpartyUnitButton%d", },
    [5] = { ctype = "ShadowUFRaid", cname = "ShadowedUnitFrames" , cframe = "SUFHeaderraidUnitButton%d",},
    [6] = { ctype = "Grid2", cname = "Grid2" , cframe = "Grid2LayoutHeader1UnitButton%d",},
    [7] = { ctype = "Nug", cname = "Nug" , cframe = "NugRaid1RGUnitButton%d",},
    [8] = { ctype = "HealBot", cname = "HealBot" , cframe = "HealBot_Action_HealUnit%d",},
    [9] = { ctype = "InvenRaidFrames3", cname = "InvenRaidFrames3" , cframe = "InvenRaidFrames3Group0UnitButton%d", },
    [10] = { ctype = "Plexus", cname = "Plexus" , cframe = "PlexusLayoutHeader1UnitButton%d", },
    [11] = { ctype = "ZPerl", cname = "ZPerl" , cframe = "XPerl_party%d", cunitid = "partyid" },
    [12] = { ctype = "ZPerl_RaidGR", cname = "ZPerl" , cframe = "XPerl_Raid_Grp1RGUnitButton%d", cunitid = "partyid",},
    [13] = { ctype = "ElvUI", cname = "ElvUI" , cframe = "ElvUF_PartyGroup1UnitButton%d", },
    [14] = { ctype = "ElvUIRaidGR", cname = "ElvUI" , cframe = "ElvUF_RaidGroup1RGUnitButton%d",},
    [15] = { ctype = "VuhDo", cname = "VuhDo" , cframe = "Vd1H%d", cunitid = "raidid"},
    [16] = { ctype = "Tukui", cname = "Tukui" , cframe = "TukuiPartyUnitButton%d",},
    [17] = { ctype = "Duf", cname = "Duf" , cframe = "DUF_PartyFrame%d",},
    [18] = { ctype = "PitBull4", cname = "PitBull4" , cframe = "PitBull4_Groups_PartyUnitButton%d",},
    [19] = { ctype = "ShestakUI_DPS", cname = "ShestakUIDPS" , cframe = "oUF_PartyDPSUnitButton%d",},
    [20] = { ctype = "ShestakUI",cname = "ShestakUI" , cframe = "oUF_PartyUnitButton%d", },
    [21] = { ctype = "KkthnxUI", cname = "KkthnxUI" , cframe = "oUF_PartyUnitButton%d",},
    [22] = { ctype = "NDui", cname = "NDui" , cframe = "oUF_PartyUnitButton%d",},
    [23] = { ctype = "RUF", cname = "RUF" , cframe = "oUF_RUF_PartyUnitButton%d",},
    [24] = { ctype = "GwRaid", cname = "Gw" , cframe = "GwRaidGridDisplay%d",},
    [25] = { ctype = "Gw", cname = "Gw" , cframe = "GwCompactparty%d", },
    [26] = { ctype = "Lime_Party", cname = "Lime" , cframe = "LimeGroup0UnitButton%d",},
    [27] = { ctype = "Cell", cname = "Cell" , cframe = "CellPartyFrameMember%d", cunitid = "unitid",},
    [28] = { ctype = "CellRaid", cname = "Cell" , cframe = "CellRaidFrameMember%d", cunitid = "unitid",},
    [29] = { ctype = "Grid2_Group", cname = "Cell" , cframe = "Grid2LayoutHeader1RGUnitButton%d",},
    [30] = { ctype = "AshToAsh", cname = "AshToAsh" , cframe = "AshToAshUnit1RGUnit%d",},
    [31] = { ctype = "NDui-RaidGR", cname = "NDui" , cframe = "oUF_Raid1GRUnitButton%d",},
    [32] = { ctype = "AltzUI", cname = "AltzUI" , cframe = "Altz_PartyUnitButton%d",},
    [33] = { ctype = "AltzUI-Healer", cname = "AltzUI" , cframe = "Altz_HealerRaidUnitButton%d",},
    [34] = { ctype = "AltzUI-DPS", cname = "AltzUI" , cframe = "Altz_DpsRaidUnitButton%d",},
    [35] = { ctype = "ShestakUI_Heal", cname = "ShestakUI" , cframe = "oUF_RaidHeal1RGUnitButton%d",},
    [36] = { ctype = "GW2", cname = "GW2_UI" , cframe = "GwCompactPartyFrame%d",},
    [37] = { ctype = "Gw2_Raid", cname = "GW2_UI" , cframe = "GwCompactRaidFrame%d", },
    [38] = { ctype = "Gw2_Party", cname = "GW2_UI" , cframe = "GwPartyFrame%d", },
}  

ATTdbs.INVSLOTS = {
	INVSLOT_HEAD, --1
	INVSLOT_NECK, -- 2
	INVSLOT_SHOULDER, -- 3
	INVSLOT_CHEST, -- 4
	INVSLOT_WAIST, -- 5
	INVSLOT_LEGS, -- 6
	INVSLOT_FEET, -- 7
	INVSLOT_WRIST, -- 8
	INVSLOT_HAND, -- 9
	INVSLOT_FINGER1, -- 10
	INVSLOT_FINGER2, -- 11
	INVSLOT_BACK, --12
	INVSLOT_TRINKET1, --13
	INVSLOT_TRINKET2, --14
	INVSLOT_MAINHAND, --15
}