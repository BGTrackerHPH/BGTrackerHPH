function BGTHPH:setCurrentHonor()
  hk, hp = GetPVPThisWeekStats();
  self.db.global[BGTHPH.realm].myChars[UnitName("player")].currentWeekHonor = hp;
end

function BGTHPH:averageLastNGames(games)
  local totalGames = 0;
  local totalHonor = 0;
  if (games) then
    for k, v in pairs(games) do
      totalGames = totalGames + 1;
      totalHonor = totalHonor + v.honorGain;
    end
  end

  if (totalGames == 0) then
    return 0;
  end

  return totalHonor/totalGames;
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

  numGamesLast10 = self:averageLastNGames(last10Games);
  numGamesLast50 = self:averageLastNGames(last50Games);

  return math.ceil(remaining/numGamesLast10), math.ceil(remaining/numGamesLast50), math.floor(numGamesLast10), math.floor(numGamesLast50);
end

function BGTHPH:getHPHCalc()
  sessionStart = BGTHPH.loadTime;
  oneHourAgo = GetServerTime() - 3600;
  local hourlyHonor = 0;
  local sessionHonor = 0;
  battleGrounds = self.db.global[BGTHPH.realm].myChars[UnitName("player")].battlegrounds;
  if battleGrounds then
    for k, v in pairs(battleGrounds) do
      if (v.startTime > oneHourAgo) then
        hourlyHonor = hourlyHonor + v.honorGain;
      end
      if (v.startTime > sessionStart) then
        sessionHonor = sessionHonor + v.honorGain;
      end
    end
  end
  return sessionHonor, hourlyHonor;
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