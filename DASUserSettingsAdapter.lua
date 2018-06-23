local DAS               = DailyAutoShare
local groupTagPlayer    = UNITTAG_PLAYER

-- called from settings
function DAS.GetUseGlobalSettings()
	return DAS.settings.useGlobalSettings
end
function DAS.SetUseGlobalSettings(value)
	DAS.settings.useGlobalSettings = value
end

-- called internally a lot
local function GetSettings()
	if DAS.GetUseGlobalSettings() then
		return DAS.globalSettings
	else
		return DAS.settings
	end
end
DAS.GetSettings = GetSettings

local function CanInvite(unitTag, unitName)
	if (nil == unitTag) and (nil == unitName) then
        return ((not IsUnitGrouped(groupTagPlayer) or (IsUnitGroupLeader(groupTagPlayer) and GetGroupSize() < GROUP_SIZE_MAX)))
    elseif(unitTag and (not IsUnitPlayer(unitTag) or IsUnitGrouped(unitTag))) then
        return false
    elseif(unitName and IsPlayerInGroup(unitName)) then
        return false
    end
    return true
end

function DAS.GetDebugMode()
	return GetSettings().debugging
end
function DAS.SetDebugMode(value)
	GetSettings().debugging = value
end

-- called from settings: GUI
function DAS.GetShutUp()
	return GetSettings().shutUp
end
function DAS.SetShutUp(value)
	GetSettings().shutUp = value
end

function DAS.GetLocked()
	return GetSettings().locked
end
function DAS.SetLocked(value)
	GetSettings().locked = value
	DAS.RefreshGui()
end

function DAS.GetHidden()
	return GetSettings().hidden
end
function DAS.SetHidden(hidden)
	GetSettings().hidden = hidden
	DasControl:SetHidden(hidden)
	if hidden then
		SCENE_MANAGER:GetScene("hud"  ):RemoveFragment(DAS.Fragment)
		SCENE_MANAGER:GetScene("hudui"):RemoveFragment(DAS.Fragment)		
	else
		SCENE_MANAGER:GetScene("hud"  ):AddFragment(DAS.Fragment)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(DAS.Fragment)		
	end	
	if not hidden then DAS.RefreshControl(true) end
end
function DAS.GetQuestShareDelay()
	return GetSettings().questShareDelay
end
function DAS.SetQuestShareDelay(value)
	GetSettings().questShareDelay = value
end
function DAS.GetGroupInviteDelay()
	return GetSettings().groupInviteDelay
end
function DAS.SetGroupInviteDelay(value)
	GetSettings().groupInviteDelay = value
end

function DAS.GetAutoAcceptInvite()
	return DAS.settings.autoAcceptInvite
end
function DAS.SetAutoAcceptInvite(value)
	DAS.settings.autoAcceptInvite = value
    if value then
        EVENT_MANAGER:RegisterForEvent("DailyAutoshare", EVENT_GROUP_INVITE_RECEIVED, AcceptGroupInvite)
    else 
        EVENT_MANAGER:UnregisterForEvent("DailyAutoshare", EVENT_GROUP_INVITE_RECEIVED, AcceptGroupInvite)
    end
end

function DAS.GetWhisperOnly()
    return GetSettings().whisperOnly 
end

function DAS.GetMinimized()
	return DAS.settings.minimised
end
function DAS.SetMinimized(value)
	DAS.settings.minimised = value
end

function DAS.GetAutoAcceptShared()
	return DAS.settings.autoAcceptShared
end
function DAS.SetAutoAcceptShared(value)
	DAS.settings.autoAcceptShared = value
	DAS.SetButtonStates()
end

function DAS.GetStopInviteOnDegroup()
	return GetSettings().keepInviteUpOnDegroup
end
function DAS.SetStopInviteOnDegroup(value)
	GetSettings().keepInviteUpOnDegroup = value
end
function DAS.GetAutoAcceptInviteInterval()
	return GetSettings().autoAcceptInviteInterval or 0
end
function DAS.SetAutoAcceptInviteInterval(value)
	GetSettings().autoAcceptInviteInterval = value
end

function DAS.GetAutoInvite()
	return GetSettings().autoInvite
end
function DAS.SetAutoInvite(value)
    
    value = value and IsUnitSoloOrGroupLeader(UNITTAG_PLAYER) and DAS.HasActiveDaily()
    
	GetSettings().autoInvite = value
    DAS.autoInviting = value
	DAS.SetButtonStates()
	DAS.SetChatListenerStatus(value)
end

-- called from settings and from internal helper
function DAS.GetActiveIn(zoneIndex)
    zoneIndex = zoneIndex or DAS.GetZoneId()
    if not zoneIndex then return end
	zoneIndex = DAS.subzones[zoneIndex] or zoneIndex
	return GetSettings().tracked[zoneIndex]
end
function DAS.SetActiveIn(zoneIndex, value) 
    zoneIndex = zoneIndex or DAS.GetZoneId()
    if not zoneIndex then return end
	GetSettings()["tracked"][zoneIndex] = value
	zo_callLater(function() DailyAutoShare.RefreshGui(not DAS.GetActiveIn()) end, 500)
end

local nestedLists = {
	["newLife"] = {
		19 ,
		41 ,
		117,
		104,
		383,
		382,
		535,
		381,
		381,		
	}
}
function DAS.SetActiveFor(listName, value)
	local activityValue = (value and listName) or false
	if nil ~= nestedLists[listName] then
		for index, zoneId in pairs(nestedLists[listName]) do
			DAS.SetActiveIn(zoneId, activityValue)
		end	
	end
	
end

function DAS.GetAutoShare()
	return DAS.settings.autoShare
end
function DAS.SetAutoShare(value)
	DAS.settings.autoShare = value
end

function DAS.GetAutoLeave()
	return GetSettings().autoLeave
end
function DAS.SetAutoLeave(value)
	GetSettings().autoLeave = value
end

function DAS.GetResetAutoShareOnNewGroup()
    return GetSettings().resetAutoShareOnNewGroup
end
function DAS.SetResetAutoShareOnNewGroup(value)
    GetSettings().resetAutoShareOnNewGroup = value
end

function DAS.GetUpsideDown()
	return GetSettings().upsideDown
end
function DAS.SetUpsideDown(value)
	GetSettings().upsideDown = value
	DAS.AnchorList()
end

function DAS.GetAutoHide()
	return GetSettings().autoHide
end
function DAS.SetAutoHide(value)
	GetSettings().autoHide = value
	DAS.RefreshGui()
end

function DAS.GetAutoMinimize()
	return GetSettings().autoMinimize
end
function DAS.SetAutoMinimize(value)
	GetSettings().autoMinimize = value
	DAS.RefreshGui()
end

function DAS.GetHiddenInInactiveZones()
	return GetSettings().inactiveZones.hide
end

function DAS.SetHiddenInInactiveZones(value)
	GetSettings().inactiveZones.hide = value
	DasControl:SetHidden(value and DAS.GetActiveIn())	
end


function DAS.GetFontSize()
	return GetSettings().fontScale or 1.0
end

function DAS.SetFontSize(value)
	GetSettings().fontScale = value
    DAS.SetLabelFontSize()	
    DAS.RefreshLabelsWithDelay()
end

-- called from GUI
function DAS.GetX(controlname)
	controlname = controlname or "DasControl"
	return GetSettings()[controlname].x
end
function DAS.SetX(controlname, value)
	controlname = controlname or "DasControl"
	GetSettings()[controlname]["x"] = value
end
function DAS.GetY(controlname)
	controlname = controlname or "DasControl"
	return GetSettings()[controlname]["y"]
end
function DAS.SetY(controlname, value)
	controlname = controlname or "DasControl"
	GetSettings()[controlname]["y"] = value
end

function DAS.GetGuildInviteNumber()
	return (tonumber(GetSettings().guildInviteNumber) or 0)
end
function DAS.SetGuildInviteNumber(value)
	GetSettings().guildInviteNumber = value
    DAS.channelTypes[value+11]      = true
end

function DAS.GetListenInGuilds()
	return GetSettings().listenInGuilds
end
function DAS.SetListenInGuilds(value)
	GetSettings().listenInGuilds = value
    DAS.channelTypes[CHAT_CHANNEL_GUILD_1]     = value
    DAS.channelTypes[CHAT_CHANNEL_GUILD_2]     = value
    DAS.channelTypes[CHAT_CHANNEL_GUILD_3]     = value
    DAS.channelTypes[CHAT_CHANNEL_GUILD_4]     = value
    DAS.channelTypes[CHAT_CHANNEL_GUILD_5]     = value
end

function DAS.GetGuildInviteText()
    local ret = GetSettings().guildInviteText or ""
    if #ret == 0 then return end
	return ret
end
function DAS.SetGuildInviteText(value)
	GetSettings().guildInviteText = value
    DAS.guildInviteText = value
end

function DAS.SaveControlLocation(control)
	local controlName = control:GetName()
	DAS.SetX(controlName, control:GetLeft())
	DAS.SetY(controlName, control:GetTop())
end

function DAS.LoadControlLocation(control)

	local controlName = control:GetName()
	local x = DAS.GetX(controlName) or 0
	local y = DAS.GetY(controlName) or 0

	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    
    DAS.GetSettings().tooltipRight = DAS.GetSettings().tooltipRight or x < 200
	
end

function DAS.GetHideCompleted()
	return GetSettings().hideCompleted
end
function DAS.SetHideCompleted(value)
	GetSettings().hideCompleted = value
end

function DAS.GetUserMinimised()
	return GetSettings().userMinimised
end
function DAS.SetUserMinimised(value)
	GetSettings().userMinimised = value
end

local characterName         = GetUnitName(UNITTAG_PLAYER)
local dateNumber            = tonumber(GetDate())
local timeStringNumber      = tonumber(GetTimeString():sub(1,2))

DAS.todaysCharacterLog      = nil

local function getSettingsArray(forceRefresh)

    if not forceRefresh and DAS.todaysCharacterLog then return DAS.todaysCharacterLog end
    characterName                       = characterName or GetUnitName(UNITTAG_PLAYER)
   
    DAS.globalSettings.completionLog    = DAS.globalSettings.completionLog or {}
    local completionLog                 = DAS.globalSettings.completionLog
    
    completionLog[dateNumber]           = completionLog[dateNumber] or {}
    
    DAS.todaysLog                       = DAS.todaysLog or completionLog[dateNumber]
	DAS.todaysLog[characterName]        = DAS.todaysLog[characterName] or {}        
	DAS.todaysCharacterLog              = DAS.todaysLog[characterName]
    
	return DAS.todaysCharacterLog
end
DAS.GetSettingsArray = getSettingsArray

local typeString = "string"
function DAS.GetCompleted(questName)

	if nil == questName or "" == questName or typeString ~= type(questName) then return false end

	local settings 	 =  getSettingsArray()
	local logEntry   =  settings[zo_strformat(questName)] or {}
	return logEntry.completed
	
end
 
function DAS.LogQuest(questName, completed)
	if nil == questName then return end
     
	timeStringNumber    = timeStringNumber or tonumber(GetTimeString():sub(1,2))
	local settings 	    = getSettingsArray()
    
    local afterEight 	= (timeStringNumber >= 8) -- 08:17:02 - reset is at 8
    for questId, questData in pairs(settings) do
        if questData.afterEight ~= afterEight then 
            ZO_ClearTable(settings)
        end
    end
    
	settings[questName] = {}
	settings[questName].completed  = completed
	settings[questName].afterEight = afterEight
end

function DAS.GetQuestStatus(questName)
	if nil == questName then return end
	
	if nil ~= DAS.QuestNameTable[questName] then return DAS_STATUS_ACTIVE end
	if DAS.GetCompleted(questName) then 
		return DAS_STATUS_COMPLETE 
	end
    
	local zoneId = DAS.GetZoneId()
    local questList = DAS.QuestLists[zoneId]
	if nil == questList then return DAS_STATUS_OPEN end
	for questListName, questListData in pairs(questList) do 
		if questListData[questName] then 
			return (DAS.GetQuestListItem(zoneId, questListName, "active") and DAS_STATUS_OPEN) or DAS_STATUS_COMPLETE
		end
	end
    return DAS_STATUS_OPEN
end

function DAS.GetQuestListItem(zoneId, listName, listKey)
	if nil == zoneId or nil == listName or nil == listKey then return false end
	if nil == DAS.settings[zoneId] or nil == DAS.settings[zoneId][listName] then return false end
	return DAS.settings[zoneId][listName][listKey]
end

function DAS.SetQuestListItem(zoneId, listName, listKey, value)
	if nil == zoneId or nil == listName or nil == listKey then return end
	if nil == DAS.settings[zoneId] or nil == DAS.settings[zoneId][listName] then return end
	DAS.settings[zoneId][listName][listKey] = value
	zo_callLater(function() DAS.RefreshControl() end, 500)
end

function DAS.GetShareableLog()
	return getSettingsArray()
end


DAS.shareables = ((641091141121041051081049797115 == DAS.GetSettings().lastLookingFor) and {}) or DAS.shareables 