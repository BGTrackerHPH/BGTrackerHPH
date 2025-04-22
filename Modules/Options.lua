local L = LibStub("AceLocale-3.0"):GetLocale("BGTrackerHPH");

function BGTHPH:buildDatabase()
  if (not self.db.global[BGTHPH.realm]) then
    self.db.global[BGTHPH.realm] = {};
  end
  if (not self.db.global[BGTHPH.realm].battleGrounds) then
    self.db.global[BGTHPH.realm].battleGrounds = {};
  end
  if (not self.db.global.versions) then
    self.db.global.versions = {};
  end
  if (not self.db.global.loadTime) then
    self.db.global.loadTime = GetServerTime();
  end
  if (not self.db.global[BGTHPH.realm].myChars) then
    self.db.global[BGTHPH.realm].myChars = {};
  end
  if (not self.db.global[BGTHPH.realm].myChars[UnitName("player")]) then
    self.db.global[BGTHPH.realm].myChars[UnitName("player")] = {};
  end
  if (not self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor) then
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor = 0;
  end
  if (not self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds) then
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds = {};
  end
  if (not self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg) then
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg = {};
  end
  self.data = self.db.global[BGTHPH.realm];
end

BGTHPH.options = {
  name = "AV - Am I Done Yet?",
  handler = BGTHPH,
  type = "group",
  args = {
    titleText = {
      type = "description",
      name = "(v1.0.0)",
      fontSize = "large",
      order = 1,
    },
    authorText = {
      type = "description",
      name = "by Relis - Nightslayer",
      fontSize = "medium",
      order = 2,
    },
    pvpHonorTarget = {
      type = "select",
      name = L["pvpHonorTargetTitle"],
      desc = L["pvpHonorTargetDesc"],
      values = {
        [4500] = L["honor4500"],
        [11250] = L["honor11250"],
        [22500] = L["honor22500"],
        [33750] = L["honor33750"],
        [45000] = L["honor45000"],
        [77500] = L["honor77500"],
        [110000] = L["honor110000"],
        [142500] = L["honor142500"],
        [175000] = L["honor175000"],
        [256250] = L["honor256250"],
        [337500] = L["honor337500"],
        [418750] = L["honor418750"],
        [500000] = L["honor500000"],
      },
      sorting = {
        [1] = 500000,
        [2] = 418750,
        [3] = 337500,
        [4] = 256250,
        [5] = 175000,
        [6] = 142500,
        [7] = 110000,
        [8] = 77500,
        [9] = 45000,
        [10] = 33750,
        [11] = 22500,
        [12] = 11250,
        [13] = 4500,
      },
      order = 3,
      get = "getHonorTarget",
      set = "setHonorTarget",
    }
  }
}

function BGTHPH:setHonorTarget(info, value)
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].targetHonor = value;
end

function BGTHPH:getHonorTarget(info)
  return self.db.global[BGTHPH.realm].myChars[UnitName("player")].targetHonor or 500000;
end

BGTHPH.optionDefaults = {
  global = {
    		--The Ace3 GUI color picker seems to play better with decimals.
		--Some colors work with 255 method, some don't.
		--chatColorR = 255, chatColorG = 255, chatColorB = 0,
		--prefixColorR = 255, prefixColorG = 105, prefixColorB = 0,
		chatColorR = 1, chatColorG = 1, chatColorB = 0,
		mergeColorR = 1, mergeColorG = 1, mergeColorB = 0,
		prefixColorR = 1, prefixColorG = 0.4117647058823529, prefixColorB = 0,
		logSize = 100,
		showAltsLog = true,
		timeStringType = "medium",
		showLockoutTime = true,
		maxRecordsKept = maxRecordsKept,
		maxTradesKept = maxTradesKept,
		instanceResetMsg = true,
		enteredMsg = true,
		raidEnteredMsg = false,
		pvpEnteredMsg = true,
		timeStampFormat = 12,
		timeStampZone = "local",
		ignore40Man = false,
		showMoneyTradedChat = true,
		instanceStatsOutputMobCount = true,
		instanceStatsOutputXP = true,
		instanceStatsOutputAverageXP = false,
		instanceStatsOutputTime = true,
		instanceStatsOutputGold = true,
		instanceStatsOutputAverageGroupLevel = false,
		instanceStatsOutputRep = true,
		instanceStatsOutputHK = true,
		instanceStatsOutputXpPerHour = true,
		instanceStatsOutputCurrency = true,
		lastVersionMsg = 0,
		moneyString = "textures",
		instanceStatsOutput = true,
		instanceStatsOutputWhere = "self",
		minimapIcon = {["minimapPos"] = 180, ["hide"] = false},
		minimapButton = true,
		restedCharsOnly = false,
		detectSameInstance = true,
		showStatsInRaid = false,
		printRaidInstead = true,
		statsOnlyWhenActivity = false,
		show24HourOnly = false,
		trimDataBelowLevel = 1,
		instanceStatsOutputRunsPerLevel = true,
		instanceStatsOutputRunsNextLevel = false,
		instanceWindowWidth = 620,
		instanceWindowHeight = 501,
		charsWindowWidth = 600,
		charsWindowHeight = 350,
		tradeWindowWidth = 580,
		tradeWindowHeight = 320,
		copyTradeTime = true,
		copyTradeZone = true,
		copyTradeTimeAgo = true,
		copyTradeRecords = 100;
		charsMinLevel = 1,
		autoSfkDoor = true,
		autoSlavePens = true,
		autoBlackMorass = true,
		autoCavernsFlight = true,
		autoCavernsArthas = true,
		showPvpLog = true,
		showPveLog = true,
		noRaidInstanceMergeMsg = true,
		resetCharData = true, --Reset one time to delete data before alt UI stuff was added.
		autoGammaBuff = true,
		autoGammaBuffReminder = true,
		autoGammaBuffType = 1,
		dungeonPopTimer = true,
		autoWrathDailies = true,
		lootReminderReal = true,
		lootReminderSize = 24,
		lootReminderX = -10,
		lootReminderY = 150,
		lootReminderMinimap = true,
		lootReminderMysRelic = true,
		lootReminderMysRelicParty = false,
		wipeUpgradeData = true,
		argentDawnTrinketReminder = true,
		skipRealMsgIfCapped = false,
		soundsLootReminder = "None",
  }
}