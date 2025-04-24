print("BGTrackerHPH successfully loaded!")
BGTHPH = LibStub("AceAddon-3.0"):NewAddon("BGTrackerHPH", "AceComm-3.0");
local _, _, _, tocVersion = GetBuildInfo();
BGTHPH.expansionNum = 1;
if (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
  BGTHPH.isClassic = true;
end
BGTHPH.hasAddon = {};
BGTHPH.realm = GetRealmName();
BGTHPH.faction = UnitFactionGroup("player")
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddonMetadata or GetAddOnMetadata;
local version = GetAddOnMetadata("BGTrackerHPH", "Version") or 9999;
BGTHPH.version = tonumber(version)
local L = LibStub("AceLocale-3.0"):GetLocale("BGTrackerHPH");
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
BGTHPH.LDBIcon = LibStub("LibDBIcon-1.0")
BGTHPH.loadTime = GetServerTime()

function BGTHPH:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("BGTrackerHPHDB", BGTHPH.optionDefaults, "DEFAULT") 
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BGTrackerHPH", BGTHPH.options);
  self.BGTHPHOptions = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BGTrackerHPH", "BG Tracker HPH");
  self:buildDatabase();
  self:setCurrentHonor();
  self:setSessionStartHonor();
  self:clearSessionHonor()
  self:createBroker();
  self:removeStaleActiveBg();
  self:clearDataAfterReset();
  self:updateWeeklyResetTime();
end

function BGTHPH:openConfig()
	Settings.OpenToCategory("BG Tracker HPH");
end

local BGTHPHLDB, doUpdateMinimapButton;
function BGTHPH:createBroker()
  local data = {
    type = "data source",
    label = "BGTHPH",
    text = "Ready",
    icon = "Interface\\AddOns\\BGTrackerHPH\\Media\\portal3",
    OnClick = function(self, button)
      if (button == "LeftButton" and IsShiftKeyDown()) then
      elseif (button == "LeftButton" and IsControlKeyDown()) then
      elseif (button == "LeftButton") then
        if (InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown()) then
					InterfaceOptionsFrame:Hide();
				elseif (SettingsPanel and SettingsPanel:IsShown()) then
					SettingsPanel:Hide();
				else
					BGTHPH:openConfig();
				end
      elseif (button == "RightButton" and IsShiftKeyDown()) then
      elseif (button == "RightButton") then
      elseif (button == "MiddleButton") then
      end
    end,
    OnEnter = function(self, button)
      GameTooltip:SetOwner(self, "ANCHOR_NONE")
      GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
      doUpdateMinimapButton = true;
      BGTHPH:updateMinimapButton(GameTooltip, self);
      GameTooltip:Show()
    end,
    OnLeave = function(self, button)
			GameTooltip:Hide()
			if (GameTooltip.BGTHPHSeparator) then
				GameTooltip.BGTHPHSeparator:Hide();
			end
			if (GameTooltip.BGTHPHSeparator2) then
				GameTooltip.BGTHPHSeparator2:Hide();
			end
		end,
  };
  BGTHPHLDB = LDB:NewDataObject("BGTHPH", data);
  BGTHPH.LDBIcon:Register("BGTrackerHPH", BGTHPHLDB, BGTHPH.db.global.minimapIcon);
  local frame = BGTHPH.LDBIcon:GetMinimapButton("BGTrackerHPH");
  if (frame) then
    frame:SetFrameLevel(9)
  end
end

function BGTHPH:updateMinimapButton(tooltip, frame)
  tooltip = tooltip or GameTooltip;
  if (not tooltip:IsOwned(frame)) then
    if (tooltip.BGTHPHSeparator) then
      tooltip.BGTHPHSeparator:Hide();
    end
    for i = 2, 10 do
      if (tooltip["BGTHPHSeparator" .. i]) then
        tooltip["BGTHPHSeparator" .. i]:Hide();
      end
    end
    return;
  end
  tooltip:ClearLines()
  tooltip:AddLine("BG Tracker HPH")
  if (tooltip.BGTHPHSeparator) then
    tooltip.BGTHPHSeparator:Hide();
    tooltip.BGTHPHSeparator2:Hide();
  end
  if (BGTHPH.perCharOnly) then
    tooltip:AddLine("|cFF9CD6DE(" .. L["thisChar"] .. ")|r");
  end
  tooltip:AddLine(BGTHPH:getMinimapButtonData());
  tooltip:AddLine("|cFF9CD6DE" .. L["Left-Click"] .. "|r " .. L["openBattleGroundData"]);
end

function BGTHPH:getMinimapButtonData()
  self:setCurrentHonor();
  session, hour = self:getHPHCalc();
  numGamesLast10, numGamesLast50, averageLast10, averageLast50 = self:calcRemainingGames();
  return "Current Honor: " .. self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor .. "\n"
    .. "Honor/Hour (past hour): " .. hour .. "\n"
    .. "Honor/Session: " .. session .. "\n"
    .. "Remaining Games (last 10 avg): " .. numGamesLast10 .. "\n"
    .. "Last 10 Games Average: " .. averageLast10 .. "\n"
    .. "Remaining Games (last 50 avg): " .. numGamesLast50 .. "\n"
    .. "Last 50 Games Average: " .. averageLast50
  ;
end

function BGTHPH:playerEnteredBattleground()
  self:enterBattleground();
end

function BGTHPH:exitBattleground()
  self:exitBattleGroundUpdate()
end

function BGTHPH:receivedBattlegroundUpdate()
  self:updateBattlegroundInfo();
end

function BGTHPH:clear()
  self:clearBattleGrounds();
end

function BGTHPH:debug()
  self:recordEndBattlegroundDataDebug();
end

function BGTHPH:bgReport()
  print(self:getBattleGroundsCount());
end

function BGTHPH:findBgByLastActiveStart(startTime)
  start = GetServerTime();
  if (startTime) then
    start = startTime;
  end
  bgs = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
  print(self:findBGByStartTime(bgs, start));
end

function BGTHPH:enterBg()
  self:enterBattleground();
end

function BGTHPH:addBg(arg)
  self:recordEndBattlegroundData(0)
end

function BGTHPH:removeLastBg(arg)
  self:removeLastBattlegroundEntry(arg);
end

SLASH_BGTHPHCMD1, SLASH_BGTHPHCMD2 = '/BGTHPH', '/amidoneyet';
function SlashCmdList.BGTHPHCMD(msg, editBox)
  local cmd, arg, extra;
  if (msg) then
    msg = string.lower(msg);
    cmd, arg, extra = strsplit(" ", msg, 3);
  end
  if (cmd == "debugLastBg") then
    BGTHPH:debug();
  elseif (cmd == "clear") then
    BGTHPH:clear();
  elseif (cmd == "bgreport") then
    BGTHPH:bgReport();
  elseif (cmd == "last") then
    BGTHPH:findBgByLastActiveStart(arg);
  elseif (cmd == "addbg") then
    BGTHPH:addBg();
  elseif (cmd == "enterbg") then
    BGTHPH:enterBg();
  elseif (cmd == "version") then
    print(self.version)
  elseif (cmd == "rmlastbg") then
    BGTHPH:removeLastBg(arg);
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
f:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event, ...)
  if (string.match(event, "PLAYER_ENTERING_BATTLEGROUND")) then
    BGTHPH:playerEnteredBattleground();
  elseif (string.match(event, "UPDATE_BATTLEFIELD_SCORE")) then
    C_Timer.After(3, function() BGTHPH:receivedBattlegroundUpdate() end);
  elseif (string.match(event, "ZONE_CHANGED") or string.match(event, "PLAYER_ENTERING_WORLD")) then
    C_Timer.After(3, function() BGTHPH:exitBattleground() end);
  end
end)

