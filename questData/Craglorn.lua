local zoneId	= 888
-- have two local tables. The first is for quest names, the second is for the corresponding bingo codes.
local tbl   = {}
local tbl2  = {}
--[[
  set up the tables. Order of quests in the UI depends on the order you add them here.
  Important: You have to use GetString(YOUR_QUEST_NAME_CONSTANT) here, or localization won't work.
  Localization strings are defined in ../locale/<lang>.lua
--]]

-- Quest Giver
-- Quest name

--------------------
-- lower Craglorn

-- Sara Benele
-- "Critical Mass"
table.insert(tbl, GetString(DAS_CRAG_SARA))
table.insert(tbl2, {[1] = "sara", [2] = "mass"})
-- Greban
-- "The Fallen City of Shada"
table.insert(tbl, GetString(DAS_CRAG_SHADA))
table.insert(tbl2, {[1] = "shada", [2] = "city"})
-- Nhalan
-- "The Reason We Fight"
table.insert(tbl, GetString(DAS_CRAG_NEDE))
table.insert(tbl2, {[1] = "reason", [2] = "nede"})
-- Ralai
-- "Waters Run Foul"
table.insert(tbl, GetString(DAS_CRAG_NEREID))
table.insert(tbl2, {[1] = "nereid", [2] = "foul", [3] = "water"})
-- Ibrula
-- "The Seeker's Archive"
table.insert(tbl, GetString(DAS_CRAG_HERMY))
table.insert(tbl2, {[1] = "Seeker", [2] = "hermy"})
-- Fights-With-Tail
-- "Supreme Power"
table.insert(tbl, GetString(DAS_CRAG_ELINHIR))
table.insert(tbl2, {[1] = "power", [2] = "elihir"})
-- Fada at-Glina
-- "The Trials of Rahni'Za"
table.insert(tbl, GetString(DAS_CRAG_TUWHACCA))
table.insert(tbl2, {[1] = "rahni"})

--------------------
-- upper Craglorn

-- Nendirume
-- "The Blood of Nirn"
table.insert(tbl, GetString(DAS_CRAG_NIRNCRUX))
table.insert(tbl2, {[1] = "nirn"})
-- Book in Dragonstar
-- "The Gray Passage"
table.insert(tbl, GetString(DAS_CRAG_WORLDTRIP))
table.insert(tbl2, {[1] = "trip"})
-- Lashburr Tooth-Breaker
-- "Iron and Scales"
table.insert(tbl, GetString(DAS_CRAG_SCALES))
table.insert(tbl2, {[1] = "scales", [2] = "iron"})
-- Crusader Dalamar
-- "Souls of the Betrayed"
table.insert(tbl, GetString(DAS_CRAG_NECRO))
table.insert(tbl2, {[1] = "necro", [2] = "souls"})
-- Scattered-Leaves
-- "Taken Alive"
table.insert(tbl, GetString(DAS_CRAG_KIDNAP))
table.insert(tbl2, {[1] = "kidnap", [2] = "alive"})
-- Safa al-Satakalaam
-- "The Truer Fangs"
table.insert(tbl, GetString(DAS_CRAG_HITMAN))
table.insert(tbl2, {[1] = "hitman", [2] = "fang", [3] = "fangs"})
-- Mederic Vyger
-- "Uncaged"
table.insert(tbl, GetString(DAS_CRAG_DUNGEON))
table.insert(tbl2, {[1] = "dungeon", [2] = "uncage", [3] = "cage"})

-- ...
-- now set the table with the quest names for the zone
DAS.shareables[zoneId]      = tbl
-- call the func to make the bingo table.
DAS.makeBingoTable(zoneId, tbl2)
--[[ you now have two maps:
  --        {questName -> questId}
  --        {bingoCode -> questId}
  -- to save performance, the quest ID is stored in the control, on top of that there's a table somewhere in the DAS table that holds
  -- the active quest IDs. There's a lot of redundancy in this AddOn, since I've dropped dead, feel free to optimize.
-- ]]
-- If there are subzones, you register them like this:
-- DAS.subzones[zoneId+1] = zoneId
-- DAS.subzones[zoneId+2] = zoneId
-- DAS.subzones[zoneId+3] = zoneId
-- Quest lookup happens via
local zoneId = DAS.GetZoneId()
local quests = DAS.shareables[zoneId] or DAS.shareables[DAS.subzones[zoneId]] or {}
--[[
  That way, if you're in a zone's subzone, it will show the zone's parent quests, unless
  you feel like setting up extra tables for those that only show the current (delve) quest.
  See Morrowind.lua for examples of that.
-- ]]
-- set up auto quest accept:
--[[
DAS.questStarter[zoneId] = {
  [GetString(DAS_QUEST_SE_BOSS)]    = true,  -- Senchal/WB/Bruccius Baenius
  [GetString(DAS_QUEST_SE_DELVE)]    = true,  -- Senchal/Delve/Guybert Flaubert
  [GetString(DAS_QUEST_SE_DRAGONS)]    = true,  -- Dragon island/Dragons
  [GetString(DAS_QUEST_SE_DELVE2)]    = true,  -- Dragon island/Delve relic
}
-- set up auto quest turnin:
DAS.questFinisher[zoneId] = {
  [GetString(DAS_QUEST_SE_BOSS)]    = true,  -- Senchal/WB/Bruccius Baenius
  [GetString(DAS_QUEST_SE_DELVE)]    = true,  -- Senchal/Delve/Guybert Flaubert
  [GetString(DAS_QUEST_SE_DRAGONS)]    = true,  -- Dragon island/Dragons
  [GetString(DAS_QUEST_SE_DELVE2)]    = true,  -- Dragon island/Delve relic
}
]]
--[[
  I'm matching against the quest IDs for auto accepting quest shares.
  Reason: Comparing numbers is a tonne cheaper than comparing strings.
  Make sure you register the quest IDs. Unfortunately, you can only see them
  when you get a quest shared OR via iteration after yu have completed those.
-- ]]
-- Set up like below (Morrowind example):
--[[
DAS.questIds[zoneId] = {
 -- upper
[5767]  = true, -- "The Blood of Nirn"
[5777]  = true, -- "The Gray Passage",
[5766]  = true, -- "Iron and Scales",
[5770]  = true, -- "Souls of the Betrayed",
[5765]  = true, -- "Taken Alive",
[5764]  = true, -- "The Truer Fangs",
[5772]  = true, -- "Uncaged",

}
]]
-- or by loop (Summerset example)
--[[DAS.questIds[zoneId] = {}
for i=6082, 6087 do
  DAS.questIds[zoneId][i] = true
  DAS_QUEST_IDS[i] = true
end
]]
-- now hook up additiona subzone IDs (like Clockwork City - Brass Citadel has its own ID
--DAS.zoneHasAdditionalId(zoneId2, zoneId)
--[[
  Don't forget to register the zone ID in the options. If the AddOn isn't detecting active in the settings
  for its zone ID, it won't show.
  ..\00_startup
  defaults.tracked[zoneId]
  You also need to register a menu setting so users can toggle it on and off
  ..\DASMenu.lua
  Hook up your new quest data file in the AddOn's manifest file:
  ..\DailyAutoShare.txt
  ... and you're good to go.
]]