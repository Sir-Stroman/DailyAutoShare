DailyAutoShare = DailyAutoShare or {}
DAS = DailyAutoShare

DAS.name = "Daily Autoshare"
DAS.version = "0.2"
DAS.author = "manavortex"
DAS.settings = {}
DAS.globalSettings = {}
DAS.ui = nil
DAS.columns = nil

DailyAutoShare.shareables   	= {}
DailyAutoShare.single   		= {}
DailyAutoShare.bingo 			= {}
DailyAutoShare.subzones 		= {}
DailyAutoShare.channelTypes 	= {
    [CHAT_CHANNEL_PARTY]    = true, 
    [CHAT_CHANNEL_SAY ]     = false, 
    [CHAT_CHANNEL_YELL]     = false, 
    [CHAT_CHANNEL_ZONE]     = false,
}

DailyAutoShare.locale 			= GetCVar("language.2")
DailyAutoShare.guildInviteText             = nil

local sm = SCENE_MANAGER
local DailyAutoShare = DailyAutoShare


DAS.autoInviting = false

local bingoTable = {}

local characterName = zo_strformat(GetUnitName('player'))

_G["DAS_STATUS_COMPLETE"] 	= 0
_G["DAS_STATUS_OPEN"] 		= 1
_G["DAS_STATUS_ACTIVE"]		= 2
_G["DAS_STATUS_TRACKED"]	= 3

DAS.zoneIds = {
	[823] = "GoldCoast",
	[684] = "Wrothgar",
	[816] = "Hew's Bane",
	[849] = "Vvardenfell",
	[181] = "Cyrodiil",
}

local defaults = {

	["tracked"] = {
		[684] = true,
		[823] = true,
		[849] = true,	-- Vvardenfell
		[181] = false,
	},

	["singleDailies"]               = {},
	["shareableDailies"]            = {},
	["speakStupid"]                 = false,
	["debug"] 		                = false,
	["keepInviteUpOnDegroup"] 		= false,
	
	["DasControl"] = {
		["x"] = 0,
		["y"] = 0,
	},
	["DasButton"] = {
		["x"] = 0,
		["y"] = 0,
	},
	["inactiveZones"]			= {
		["hide"]				= true,
	},
	[849] = {
		["relic"] = {
			["invisible"] = false,
			["active"] = true,
		},
		["hunt"] = {
			["invisible"] = false,
			["active"] = true,
		},
		["delve"] = {
			["invisible"] = false,
			["active"] = true,
		},
		["boss"] = {
			["invisible"] = false,
			["active"] = true,
		},
	},
	
	debugOutput		   			= false,
	currentlyWithQuest 			= false,
	currentQuestIndex 			= nil,
	currentQuestName 			= nil,
	autoTrack 					= false,
	autoAcceptInvite 			= false,
	autoAcceptInviteInterval 	= 5,
	autoAcceptShared 			= true,
	autoDeclineShared 			= false,
	autoAcceptAllDailies 		= false,
	autoInvite 					= false,
	autoLeave 					= true,
	useGlobalSettings 			= true,
	minimised 					= false,
	locked 						= false,
	hidden 						= false,
	fontScale					= 1,
	tooltipRight 				= false,
	upsideDown 					= false,
	autoHide 					= false,
	autoMinimize 				= false,
	autoShare 					= true,
	hideCompleted				= false,
	lastLookingFor 				= "",
	guildInviteNumber 			= 1,
	guildInviteText,
	listenInGuilds,

}

local function p(p1, p2, p3, p4, p5, p6)
	if not DAS.GetDebugMode() or not p1 then return end
    local s = zo_strformat(p1, p2, p3, p4, p5, p6)
    if not p2 then 
        d(p1) 
        return 
    end
end
DAS.debug = p

local cachedDisplayName = GetUnitDisplayName('player')


local lastUnitName = nil
local em = EVENT_MANAGER

local playerName		 	= nil
local playerGroupLeadStatus = false

local function debugOut(p1, p2, p3, p4, p5, p6, p7, p8)
    if (not p2) then 
        d(p1) 
        return
    end
    if p8 then
        d(zo_strformat("<<1>> <<2>> <<3>> <<4>> <<5>> <<6>> <<7>> <<8>>", p1, p2, p3, p4, p5, p6, p7, p8)) 
    elseif p7 then
        d(zo_strformat("<<1>> <<2>> <<3>> <<4>> <<5>> <<6>> <<7>>", p1, p2, p3, p4, p5, p6, p7)) 
    elseif p6 then 
        d(zo_strformat("<<1>> <<2>> <<3>> <<4>> <<5>> <<6>>", p1, p2, p3, p4, p5, p6)) 
    elseif p5 then
        d(zo_strformat("<<1>> <<2>> <<3>> <<4>> <<5>>", p1, p2, p3, p4, p5)) 
    elseif p4 then
        d(zo_strformat("<<1>> <<2>> <<3>> <<4>>", p1, p2, p3, p4))    
    elseif p3 then
        d(zo_strformat("<<1>> <<2>> <<3>>", p1, p2, p3))    
    else
        d(zo_strformat("<<1>> <<2>>", p1, p2))    
    end
end
DAS.DebugOut = debugOut
function DAS.Report(text)
	if DAS.GetShutUp() then return end
	d(text)
end


local function GetBingoMatch(bingoString)
    if not bingoString then return end
    local bingoIndex = bingoTable[bingoString]
    if not bingoIndex then return end
    
    return DAS.GetQuestStatus(DAS.GetQuestNameFromIndex(bingoIndex)) == DAS_STATUS_ACTIVE or 
    bingoString == "any" or bingoString == DAS.guildInviteText
end

--==============================
--======= Event hooks  =========
--==============================

local function OnGroupTypeChanged(eventCode, unitTag)
	if IsUnitGrouped("player") or not DAS.GetStopInviteOnDegroup() then return end
	DAS.SetAutoInvite(false)
end

local function OnQuestAdded(eventCode, journalIndex, questName, objectiveName)
	
	local zoneId = DAS.GetZoneId()
	if not DAS.GetActiveIn(zoneId) 			then return end
	if not GetIsQuestSharable(journalIndex) then return end	
	
	if nil ~= DAS.GetArrayEntry(DAS.shareables[zoneId], questName) or 
	nil ~= DAS.GetArrayEntry(DAS.single[zoneId], questName) then
		DAS.LogQuest(questName, false)
		zo_callLater(function() DAS.RefreshControl(true) end, 700)
	end		
end

local function OnQuestShared(eventCode, questId)
	if not DAS_QUEST_IDS[questId] then return end
	local questName, _, _, displayName = GetOfferedQuestShareInfo(questId)
	local zoneId = DAS.GetZoneId()
	if nil ~= DAS.GetArrayEntry(DAS.shareables[zoneId], questName) then
		AcceptSharedQuest(questId)
		zo_callLater(function() DAS.RefreshControl(true) end, 500)
	elseif nil ~= DAS.GetArrayEntry(DAS.single[zoneId], questName) then
		DAS.Report("DailyAutoShare declined a quest for you. Type /DailyAutoShare disabledecline to stop it from doing so.")
		DeclineSharedQuest(questId)
	end
end

local function onGroupMessage(messageText)
    if 	string.match(messageText, "share") or
			string.match(messageText, "quest") or
			string.match(messageText, "please") then            
			DAS.TryShareActiveDaily()
    elseif string.match(messageText, "stop") and string.match(messageText, "sharing") then          
        DAS.SetAutoShare(false)
    end
end

local channelTypes = DAS.channelTypes
local function OnChatMessage(eventCode, channelType, fromName, messageText, _, fromDisplayName)
	    
        -- react to the group asking for shares
	if (channelType == CHAT_CHANNEL_PARTY) then
		return onGroupMessage(messageText)
	end        
    
    if not messageText:find("%+") then return end
    
    local bingoCode = string.match(messageText, "%+%s?(%S+)")
    if not bingoCode then return end
    
    -- we're not listening in the chat channel.
    if not channelTypes[channelType] then
        -- it's not the zone chat
        if not channelType == CHAT_CHANNEL_ZONE then return end
        -- it'snot a player message
        if not cachedDisplayName:find(fromDisplayName) then return end
        if IsUnitGrouped('player') then 
            if DAS.GetGroupLeaveOnNewSearch() then
                GroupLeave()
                return
            end
        else
            DAS.TryTriggerAutoAcceptInvite()
        end
    end
    
    if not DAS.autoInviting then return end
    
    local bingoCode = string.match(messageText, "%+%s?(%S+)")
    if not bingoCode then return end
        
	if not GetBingoMatch(bingoCode:lower()) then return end

	-- try invite if we are group lead
	if IsUnitSoloOrGroupLeader('player') then 
        GroupInviteByName(fromDisplayName)
    end
end

function DAS.SetChatListenerStatus(status)

    DAS.channelTypes[CHAT_CHANNEL_SAY ]     = status
    DAS.channelTypes[CHAT_CHANNEL_YELL]     = status
    DAS.channelTypes[CHAT_CHANNEL_ZONE]     = status
	if status then
		em:RegisterForEvent("DailyAutoShare", EVENT_CHAT_MESSAGE_CHANNEL,  OnChatMessage)
	else
		em:UnregisterForEvent("DailyAutoShare", EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessage)
	end	
end

-- EVENT_MANAGER:RegisterForEvent("DASPlayerMessage", EVENT_CHAT_MESSAGE_CHANNEL, 
	-- function(eventCode, channelType, fromName, messageText, _, fromDisplayName)
        -- if fromDisplayName == cachedDisplayName then return end
        -- if not channelType == CHAT_CHANNEL_ZONE then return end
        -- local bingoCode = string.match(messageText, "%+(%S+)")
        -- if not bingoCode then return end
        -- if IsUnitGrouped('player') and DAS.GetAutoLeave() then GroupLeave()	end
        -- DAS.TryTriggerAutoAcceptInvite()
	-- end
-- )
-- EVENT_MANAGER:AddFilterForEvent("DASPlayerMessage", EVENT_CHAT_MESSAGE_CHANNEL, REGISTER_FILTER_UNIT_TAG, "player")

DAS.bingoFallback = {}
function DAS.makeBingoTable(zoneId, tbl) 
	DAS.bingo[zoneId] = {}    
    DAS.bingoFallback[zoneId] = {}
	for key, value in pairs(tbl) do
        if type(value) == "table" then 
            local best = value[0]
            for _, actualValue in pairs(value) do
                DAS.bingo[zoneId][actualValue] = key
                DAS.bingoFallback[zoneId][actualValue] = best
            end
        else
            DAS.bingo[zoneId][value] = key
        end
	end
	return DAS.bingo[zoneId]
end

function DAS.getBingoTable(zoneId)
    zoneId = zoneId or DAS.GetZoneId() or 0
    return DAS.bingo[zoneId] or {} 
end

local function OnPlayerActivated(eventCode)
	local active 		= DAS.GetActiveIn()	
	DAS.SetHidden(not active)
	DAS.SetChatListenerStatus(active)
	DAS.RefreshControl(true)
	bingoTable = (active and DAS.getBingoTable()) or {}
    DAS.autoInviting = DAS.GetAutoInvite()
    DAS.guildInviteText = DAS.GetGuildInviteText() or ""
    if #DAS.guildInviteText  == 0 then DAS.guildInviteText = nil end
end

local function OnGroupMemberAdded(eventCode, memberName)
	DAS.TryShareActiveDaily()
end

local function OnUnitCreated(eventCode, unitTag)
    local unitZone = GetZoneId(GetUnitZoneIndex(unitTag))
    if not DAS.GetActiveIn(unitZone) then return end
    if GetUnitDisplayName(unitTag) == cachedDisplayName then return end
    DAS.TryShareActiveDaily(unitZone)
end
local function OnGroupInvite(eventCode, inviterCharacterName, inviterDisplayName)
	if DAS.GetAutoAcceptInvite() then AcceptGroupInvite() end
end

local function OnQuestToolUpdate()
	DAS.RefreshControl(true)
end

local function OnQuestRemoved(eventCode, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questID)	
	if not DAS.GetActiveIn() then return end
	
	DAS.LogQuest(questName, isCompleted)
	if not DAS.HasActiveDaily() then 
		DAS.SetAutoInvite(false)
	end
	
	DAS.RefreshControl(true)
end

local function deleteYesterdaysLog()
	-- kill yesterday's log, we don't need it	
	local currentDate = tonumber(GetDate())
	if (nil ~= DAS.globalSettings and nil ~= DAS.globalSettings.lastLogDate) and (DAS.globalSettings.lastLogDate < currentDate) then 
	if nil == DAS.Log then DAS.Log = {} end
		DAS.Log[DAS.globalSettings.lastLogDate] = nil
		DAS.globalSettings.lastLogDate = currentDate
	end
end

local function hookQuestTracker()
	local function refreshLabels()
		DAS.RefreshLabels(false, true)
	end
	-- SetMapToQuestZone
	ZO_PreHook(QUEST_TRACKER, "ForceAssist", refreshLabels)
end

--==============================
--= DailyAutoShare_Initialize ==
--==============================

local function RegisterEventHooks()

	DailyAutoShare.Fragment 	= ZO_HUDFadeSceneFragment:New(DasControl) 
	
	SCENE_MANAGER:GetScene("hud"  ):AddFragment(DailyAutoShare.Fragment)
	SCENE_MANAGER:GetScene("hudui"):AddFragment(DailyAutoShare.Fragment)
	hookQuestTracker()
	
	em:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, 		OnPlayerActivated)
	
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, 				OnQuestToolUpdate)
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, 			OnQuestRemoved)
	em:RegisterForEvent(ADDON_NAME, EVENT_TRACKING_UPDATE, 			OnQuestToolUpdate)	
	
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, 				OnQuestAdded)
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, 			OnQuestRemoved)
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, 			OnQuestRemoved)
	em:RegisterForEvent(ADDON_NAME, EVENT_QUEST_SHARED, 			OnQuestShared)
	
	
	em:RegisterForEvent(ADDON_NAME, EVENT_GROUP_INVITE_RECEIVED,	OnGroupInvite)
	em:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED,		OnGroupMemberAdded)
	em:RegisterForEvent(ADDON_NAME, EVENT_UNIT_CREATED,	 			OnUnitCreated)
	em:RegisterForEvent(ADDON_NAME, EVENT_UNIT_DESTROYED, 			OnGroupTypeChanged)

	-- DasControl:OnMoveStop
	-- DailyAutoShare.SaveControlLocation(self)
end

--==============================
--===== Rise, my minion!  ======
--==============================

function DailyAutoShare_Initialize(eventCode, addonName)

	if addonName ~="DailyAutoShare" then return end

	DailyAutoShare.settings = ZO_SavedVars:New("DAS_Settings", 0.2, nil, defaults)
	DailyAutoShare.globalSettings = ZO_SavedVars:NewAccountWide("DAS_Globals", 0.2, "DAS_Global", defaults)

	RegisterEventHooks()
	-- deleteYesterdaysLog()
	
	DailyAutoShare.CreateMenu(DailyAutoShare.settings, defaults)
	DAS.CreateGui()

	EVENT_MANAGER:UnregisterForEvent("DailyAutoShare", EVENT_ADD_ON_LOADED)

end


ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DAS_GUI",  GetString(DAS_SI_TOGGLE))
ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DAS_LIST", GetString(DAS_SI_MINIMISE))
EVENT_MANAGER:RegisterForEvent("DailyAutoShare", EVENT_ADD_ON_LOADED, DailyAutoShare_Initialize)
