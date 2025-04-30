function BGTHPH:setCurrentHonor()
  hk, hp = GetPVPThisWeekStats();
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor = hp;
end

function BGTHPH:setSessionStartHonor()
  hk, hp = GetPVPThisWeekStats();
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionStartHonor = hp;
end

function BGTHPH:removeLastBattlegroundEntry(index)
  rmIndex = index or 1;
  battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
  if (battleGrounds) then
    newBattleGrounds = {};
    for i=1, #battleGrounds do
      if (i ~= tonumber(rmIndex)) then
        table.insert(newBattleGrounds, battleGrounds[i]);
      end
    end
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds = newBattleGrounds
  end
end

function BGTHPH:formatDuration(duration)
  local hours = math.floor(duration/3600);
  local minutes =  math.floor((duration % 3600)/60);
  local seconds =  duration % 60;
  return format("%dh:%dm:%ds", hours, minutes, seconds);
end

function BGTHPH:averageLastNGames(games)
  local totalGames = 0;
  local totalHonor = 0;
  local totalDuration = 0;
  if (games) then
    for k, v in pairs(games) do
      totalGames = totalGames + 1;
      totalHonor = totalHonor + v.honorGain;
      totalDuration = totalDuration + v.duration;
    end
  end

  if (totalGames == 0) then
    return 0, 0;
  end

  return (totalHonor/totalGames), self:formatDuration(totalDuration/totalGames) ;
end

function BGTHPH:last(arr, num)
  local collector = {};
  for i=1, num do
    table.insert(collector, arr[i]);
  end
  return collector;
end

function BGTHPH:calcRemainingGames()
  target = self.db.global[BGTHPH.realm].myChars[UnitName("player")].targetHonor;
  current = self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor;
  remaining = target-current;
  
  battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;

  last10Games = {};
  last50Games = {};

  if (battleGrounds) then
    if #battleGrounds < 10 then
      last10Games = self:last(battleGrounds, #battleGrounds);
    end
    if #battleGrounds >= 10 then
      last10Games = self:last(battleGrounds, 10);
    end
    if #battleGrounds >= 50 then
      last50Games = self:last(battleGrounds, 50);
    end
  end 

  numGamesLast10, last10AvgDuration = self:averageLastNGames(last10Games);
  numGamesLast50, last50AvgDuration = self:averageLastNGames(last50Games);

  return math.ceil(remaining/numGamesLast10), math.ceil(remaining/numGamesLast50), math.floor(numGamesLast10), last10AvgDuration, math.floor(numGamesLast50), last50AvgDuration;
end

function BGTHPH:getHPHCalc()
  sessionStartHonor = self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionStartHonor;
  sessionHonor = self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionHonor;

  sessionStart = BGTHPH.loadTime;
  timeSinceSessionStart = GetServerTime() - BGTHPH.loadTime;
  oneHourAgo = GetServerTime() - math.min(timeSinceSessionStart, 3600);
  local hourlyHonor = 0;
  honorRecords = self.db.global[BGTHPH.realm].myChars[UnitName("player")].honorRecords;
  if honorRecords then
    for k, v in pairs(honorRecords) do
      hourlyHonor = hourlyHonor + v.honorGained;
    end
  end
  return math.floor((sessionHonor/timeSinceSessionStart)*3600), math.floor((hourlyHonor/min(timeSinceSessionStart, 3600))*3600);
end

function BGTHPH:removeStaleActiveBg()
  if not UnitInBattleground("player") then
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg = {};
  end
end

function BGTHPH:enterBattleground()
  self:setCurrentHonor();
  local b = {
    startTime = GetServerTime(),
    startHonor = self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor;
    instance = GetZoneText();
  }
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg = b;
end

function BGTHPH:getBattleGroundsCount()
  battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
  return #battleGrounds;
end

function BGTHPH:exitBattleGroundUpdate()
  currentZone = GetZoneText();
  activeBg = self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg;
  if (activeBg.startTime) then
    battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
    previousZone = activeBg.instance;
    if (currentZone ~= previousZone) then
      existingRecord = BGTHPH:findBGByStartTime(battleGrounds, activeBg.startTime);
      if (existingRecord) then
        currentTime = GetServerTime();
        local t = {
          startTime = activeBg.startTime,
          startHonor = activeBg.startHonor,
          winner = battleGrounds[existingRecord].winner,
          endHonor = hp,
          endTime = currentTime,
          duration = currentTime - activeBg.startTime,
          honorGain = hp - activeBg.startHonor; 
        }
        self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds[existingRecord] = t;
      end
    end
  end
end

function BGTHPH:findBGByStartTime(battleGrounds, startTime)
  if #battleGrounds == 0 then
    return false;
  end
  if battleGrounds then
    for k, v in pairs(battleGrounds) do
      if (v.startTime == startTime) then
        return k
      end
    end
  end
  return nil
end

function BGTHPH:recordEndBattlegroundData(winner)
  activeBg = self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg;
  if (activeBg and activeBg.startTime) then
    hk, hp = GetPVPThisWeekStats();
    local currentTime = GetServerTime();
    battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds or {};
    if battleGrounds then
      matchingBg = self:findBGByStartTime(battleGrounds, activeBg.startTime);
      local t = {
        startTime = activeBg.startTime,
        startHonor = activeBg.startHonor,
        winner = winner,
        endHonor = hp,
        endTime = currentTime,
        duration = currentTime - activeBg.startTime,
        honorGain = hp - activeBg.startHonor;
      }
      if (matchingBg) then
        self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds[matchingBg] = t;
      else 
        table.insert(battleGrounds, 1, t);
        -- self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg = {};
        self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds = battleGrounds;
      end
    end
  end
end

function BGTHPH:recordEndBattlegroundDataDebug()
  activeBg = self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg;
  if (activeBg and activeBg.startTime) then
    hk, hp = GetPVPThisWeekStats();
    local currentTime = GetServerTime();
    battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
    if battleGrounds then
      matchingBg = self:findBGByStartTime(activeBg.startTime);
      if (matchingBg) then
        print("Matching BG Found: " .. matchingBg);
      else 
        print("No Matching BG");
      end
    end
  end
end

function BGTHPH:updateBattlegroundInfo()
  self:setCurrentHonor()
  if (GetBattlefieldWinner()) then
    winner = GetBattlefieldWinner();
    if (winner) then
      self:recordEndBattlegroundData(winner);
    end
  end
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].activeBg.instance = GetZoneText();
end

function BGTHPH:clearBattleGrounds()
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds = {};
  print("Battlegrounds cleared");
end

function BGTHPH:clearStale(honorRecords)
  if honorRecords then
    local oneHourAgo = GetServerTime() - 3600;
    local cleared = {};
    for k, v in pairs(honorRecords) do
      if (v.timestamp > oneHourAgo) then
        table.insert(cleared, self.db.global[BGTHPH.realm].myChars[UnitName("player")].honorRecords[k]);
      end
    end
    self.db.global[BGTHPH.realm].myChars[UnitName("player")].honorRecords = cleared;
  end
end

function BGTHPH:clearSessionHonor()
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionHonor = 0;
end

function BGTHPH:recordHonorGain(...)
  local text = ...;
  local honorGained;

  honorGained = string.match(text, "%d+");
  if (not honorGained) then
    BGTHPH:debug("Honor error:", text);
    return;
  end

  local h = {
    honorGained = honorGained,
    timestamp = GetServerTime(),
  }

  honorRecords = self.db.global[BGTHPH.realm].myChars[UnitName("player")].honorRecords

  table.insert(honorRecords, h);
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].honorRecords = honorRecords;
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionHonor = self.db.global[BGTHPH.realm].myChars[UnitName("player")].sessionHonor + honorGained;
  self:clearStale(honorRecords);
end

local f = CreateFrame("Frame");
if (BGTHPH.expansionNum < 4) then
  f:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN");
end
f:SetScript("OnEvent", function(self, event, ...)
  if (event == "CHAT_MSG_COMBAT_HONOR_GAIN") then
    BGTHPH:recordHonorGain(...)
  end
end)