local AIL = "|HAiLC|h" -- used as hidden text to be able to find our custom line in the tooltip easier
local CACHE = {}

local TIMEOUT = 120

local function getCache(unit)
	local guid = UnitGUID(unit)
	if not CACHE[guid] then
		CACHE[guid] = {}
		CACHE[guid].spec = UnitClass(unit)
		CACHE[guid].ilvl = 0
		CACHE[guid].specThrottle = 0
		CACHE[guid].ilvlThrottle = 0
	end
	return CACHE[guid]
end

local function isCoA()
end


function AILGetCacheTable()
	return CACHE
end



local function updateCache(unit, spec, ilvl, fixIlvl)
	local class, classFile = UnitClass(unit)
	local timeNow = GetTime()
	local data = getCache(unit)
	if spec then
		data.spec = spec
	end
	if ilvl and ilvl > 0 then
		data.ilvl = ilvl
	end

	-- Is Hero --
	if IsHeroClass(unit) then
		-- if seasonal, spec == class so timeout instantly. if not, timeout when spec ~= class
		if C_Realm.IsSeasonal() or data.spec ~= class then
			data.specThrottle = timeNow + TIMEOUT
		end
	-- Is CoA --	
	elseif IsCustomClass(unit) then 
		-- Specialization inspections are not implemented yet by ascension
		data.specThrottle = timeNow + TIMEOUT
	end

	-- timeout if new info is same as old
	if ilvl > 0 and data.ilvl == ilvl then
		data.ilvlThrottle = timeNow + TIMEOUT
	end

end

local function getColoredIlvlString(unit)
	local itemLevel = getCache(unit).ilvl
	local color = WHITE_FONT_COLOR
	local level = UnitLevel(unit)
	local expansionTarget = Enum.Expansion.Vanilla
	if level > 70 then
		expansionTarget = Enum.Expansion.WoTLK
	elseif level > 60 then
		expansionTarget = Enum.Expansion.TBC
	end
	local softCap = GetItemLevelSoftCap(expansionTarget)
	if itemLevel <= softCap then
		color = ColorUtil:Lerp(color, ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic], itemLevel / softCap)
	else
		-- if they have higher than the soft cap, give a special color
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	end
	if itemLevel > 0 then
		local itemLevelText = format("%.02f", itemLevel)
		return "(" .. color:WrapText(itemLevelText) .. ")"
	else
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Poor]
		return "(" .. color:WrapText("?") .. ")"
	end
end

local function IsIlvlThrottled(unit)
	return getCache(unit).ilvlThrottle > GetTime()
end

local function IsSpecThrottled(unit)
	return getCache(unit).specThrottle > GetTime()
end

local function notifyInspections(unit)
	if AscensionInspectFrame and AscensionInspectFrame:IsShown() then
		return
	end
	if CanInspect(unit) and not IsIlvlThrottled(unit) then
		NotifyInspect(unit)
	end
	if C_MysticEnchant.CanInspect(unit) and not IsSpecThrottled(unit) then
		C_MysticEnchant.Inspect(unit, true)
	end
end

local function OnTooltipSetUnitHandler(self)
	local _, unit = self:GetUnit()
	if not unit or not UnitIsPlayer(unit) then
		return
	end
	notifyInspections(unit)
	local spec = getCache(unit).spec
	local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	if spec == UnitClass(unit) or IsCustomClass(unit) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	end
	self:AddDoubleLine(AIL .. color:WrapText(spec), getColoredIlvlString(unit))
end

local function GameTooltipOnEvent(self, event, ...)
	local _, unit = GameTooltip:GetUnit()
	if not unit or not UnitIsPlayer(unit) then
		return
	end
	if event == "INSPECT_TALENT_READY" then --UPDATE ILVL if > 0 and different than cached
		local ilvl = UnitAverageItemLevel(unit)
		updateCache(unit, nil, (ilvl > 0 and getCache(unit).ilvl ~= ilvl ) and ilvl or  getCache(unit).ilvl)
		for i = 1, GameTooltip:NumLines() do
			if string.match(_G["GameTooltipTextLeft" .. i]:GetText(), AIL) then -- looks for our hidden text
				_G["GameTooltipTextRight" .. i]:SetText(getColoredIlvlString(unit))
			end
		end
	elseif event == "MYSTIC_ENCHANT_INSPECT_RESULT" then -- UPDATE SPEC AND ILVL  if > 0 and different than cached
		local ilvl = UnitAverageItemLevel(unit)
		updateCache(unit, UnitSpecAndIcon(unit), (ilvl > 0 and getCache(unit).ilvl ~= ilvl ) and ilvl or  getCache(unit).ilvl)
		for i = 1, GameTooltip:NumLines() do
			if string.match(_G["GameTooltipTextLeft" .. i]:GetText(), AIL) then -- looks for our hidden text
				local spec = getCache(unit).spec
				local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
				if spec == UnitClass(unit) or IsCustomClass(unit) then
					color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
				end
				_G["GameTooltipTextRight" .. i]:SetText(getColoredIlvlString(unit))
				_G["GameTooltipTextLeft" .. i]:SetText(AIL .. color:WrapText(spec))
			end
		end
	end
	GameTooltip:Show()
end

GameTooltip:RegisterEvent("INSPECT_TALENT_READY")
GameTooltip:RegisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
GameTooltip:HookScript("OnEvent", GameTooltipOnEvent)
GameTooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnitHandler)