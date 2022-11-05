local DAS               = DailyAutoShare
local groupTagPlayer    = UNITTAG_PLAYER
local p                 = DAS.DebugOut
local typeString        = "string"
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
function DAS.GetHiddenByUser()
	return GetSettings().hiddenByUser or false
end
function DAS.SetHiddenByUser(value)
	GetSettings().hiddenByUser = value
end
function DAS.GetHidden()
	return GetSettings().hidden
end
function DAS.SetHidden(hidden, override)
	if (not hidden and not override and DAS.GetHiddenByUser()) then
		return
	end
	if override then
		DAS.SetHiddenByUser(hidden)
	end
	GetSettings().hidden = hidden
	DasControl:SetHidden(hidden)
	if hidden then
		SCENE_MANAGER:GetScene("hud"  ):RemoveFragment(DAS.Fragment)
		SCENE_MANAGER:GetScene("hudui"):RemoveFragment(DAS.Fragment)
    else
		SCENE_MANAGER:GetScene("hud"  ):AddFragment(DAS.Fragment)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(DAS.Fragment)
		DAS.questCacheNeedsRefresh = true
		DAS.RefreshControl(true)
		zo_callLater(function()
			DAS.RefreshLabels(true, true)
		end, 500)
	end
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
	return DAS.GetSettings().autoAcceptInvite
end
function DAS.SetAutoAcceptInvite(value)
	DAS.GetSettings().autoAcceptInvite = value
  if value then
    EVENT_MANAGER:RegisterForEvent("DailyAutoshare", EVENT_GROUP_INVITE_RECEIVED, AcceptGroupInvite)
    else
    EVENT_MANAGER:UnregisterForEvent("DailyAutoshare", EVENT_GROUP_INVITE_RECEIVED, AcceptGroupInvite)
  end
end
function DAS.GetWhisperOnly()
  return GetSettings().whisperOnly
end
function DAS.GetMinimised()
	return DAS.GetSettings().minimised
end
function DAS.SetMinimised(value)
	DAS.GetSettings().minimised = value
end
function DAS.GetAutoAcceptShared()
	return DAS.GetSettings().autoAcceptShared
end
function DAS.SetAutoAcceptShared(value)
	DAS.GetSettings().autoAcceptShared = value
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
	if type(zoneIndex) == typeString then
		return GetSettings().trackedLists[zoneIndex]
	end
	return GetSettings().tracked[zoneIndex] or DAS.trackedListZones[zoneIndex]
end
DAS.IsActiveIn = DAS.GetActiveIn    -- have alias because I keep fucking this up
function DAS.SetActiveIn(zoneIndex, value)
  zoneIndex = zoneIndex or DAS.GetZoneId()
  if not zoneIndex then return end
  GetSettings().tracked[zoneIndex] = value
	zo_callLater(function() DAS.RefreshGui(not DAS.GetActiveIn()) end, 200)
end

function DAS.SetActiveFor(listName, value)
	if not listName then return end
	GetSettings().trackedLists[listName] = value
	DAS.CacheTrackedQuestLists()
	zo_callLater(function() DAS.RefreshGui(not DAS.GetActiveIn()) end, 200)
end

function DAS.GetAutoShare()
	return DAS.GetSettings().autoShare
end
function DAS.SetAutoShare(value)
	DAS.GetSettings().autoShare = value
	DAS.SetButtonStates()
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
	GetSettings().guildInviteNumber = tonumber(value) or 0
	if value ~= nil and value > 0 then
		DAS.channelTypes[_G["CHAT_CHANNEL_GUILD_" .. value]] = true
	end
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

function DAS.GetQuestListItem(zoneId, listName, listKey)
  if nil == zoneId or nil == listName or nil == listKey then return false end
  if nil == DAS.GetSettings()[zoneId] or nil == DAS.GetSettings()[zoneId][listName] then return false end
  return DAS.GetSettings()[zoneId][listName][listKey]
end

function DAS.SetQuestListItem(zoneId, listName, listKey, value)
  if nil == zoneId or nil == listName or nil == listKey then return end
  if nil == DAS.GetSettings()[zoneId] or nil == DAS.GetSettings()[zoneId][listName] then return end
  DAS.GetSettings()[zoneId][listName][listKey] = value
  zo_callLater(function() DAS.RefreshControl(true) end, 500)
end
function DAS.GetMarkerVisibility()
  return GetSettings().mapMarkersVisible
end
function DAS.SetMarkerVisibility(value)
  GetSettings().mapMarkersVisible = value
end

function DAS.GetQuestShareEitherOfString()
	return GetSettings().questShareEitherOfString
end

function DAS.SetQuestShareEitherOfString(value)
	if '' == value then value = nil end
	GetSettings().questShareEitherOfString = value
end