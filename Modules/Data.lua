function BGTHPH:updateWeeklyResetTime()
	self.db.global[BGTHPH.realm].weeklyResetTime = GetServerTime() + C_DateAndTime.GetSecondsUntilWeeklyReset();
end

function BGTHPH:clearDataAfterReset()
	for realm, realmData in pairs(BGTHPH.db.global) do
		if (type(realmData) == "table" and realmData ~= "minimapIcon" and realmData ~= "data") then
			if (realmData.myChars) then
				local resetTime = (realmData.weeklyResetTime or 0);
				if (GetServerTime() > resetTime) then
					--resetTime is set after this func is run at logon so it's easy to check if it's first logon after weekly reset.
					--If it's first logon after weekly reset we do things like setting flags that chars need to loot weekly cache etc.
					for char, charData in pairs(realmData.myChars) do
            if (charData.battlegrounds) then
              BGTHPH.db.global[realm].myChars[char].battlegrounds = {};
            end
					end
				end
			end
		end
	end
end