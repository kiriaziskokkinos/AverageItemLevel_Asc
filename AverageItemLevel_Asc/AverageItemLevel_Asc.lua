AverageItemLevel_Asc = select(2, ...)
local _print = print
local AIL = "|HAiLC|h" -- used as hidden text to be able to find our custom line in the tooltip easier
local CACHE = {}
local TIMEOUT = 60
local debug = false
local MAX_INSPECTIONS_TILL_TIMEOUT = 5
local function print(...)
	if debug then
	_print(...)
	end
end

function AverageItemLevel_Asc.toggleDebug()
	debug = not debug
	_print(debug and "Debug turned on." or "Debug turned off.")
end


local function getCacheForUnit(unit)
	if not unit then return end
	local guid = UnitGUID(unit)
	if not CACHE[guid] then
		CACHE[guid] = {}
		CACHE[guid].spec = UnitClass(unit)
		CACHE[guid].ilvl = 0
		CACHE[guid].specExpirationTime = 0
		CACHE[guid].ilvlExpirationTime = 0
		CACHE[guid].inspections = 0
	end
	return CACHE[guid]
end

function AverageItemLevel_Asc.GetCache()
	return CACHE
end

local function resetExpirations()
	for _,data in pairs(CACHE) do
		data.specExpirationTime = 0
		data.ilvlExpirationTime = 0
	end
end 

function AverageItemLevel_Asc.SetInspectTimeout(newTimeout)
	TIMEOUT = newTimeout > 0 and newTimeout or 1
	resetExpirations()
end




local function IsIlvlThrottled(unit)
	return getCacheForUnit(unit).ilvlExpirationTime > GetTime()
end

local function IsSpecThrottled(unit)
	return getCacheForUnit(unit).specExpirationTime > GetTime()
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

local function updateCache(unit, spec, ilvl)
	local class, classFile = UnitClass(unit)
	local timeNow = GetTime()
	local data = getCacheForUnit(unit)
	data.spec = spec or data.spec or class or "?"
	-- Is Hero --
	if IsHeroClass(unit) then
		-- if seasonal, spec == class so timeout instantly. if not, timeout when spec ~= class
		if C_Realm.IsSeasonal() or data.spec ~= class then
			data.specExpirationTime = timeNow + TIMEOUT
		end
	-- Is CoA --	
	elseif IsCustomClass(unit) then 
		-- Specialization inspections are not implemented yet by ascension
		data.specExpirationTime = timeNow + TIMEOUT
	end


	if ilvl == nil then return end
	if ilvl > 0 and data.ilvl == ilvl then
		print("Inspect result for",UnitName(unit),":",data.ilvl,"-->",ilvl,",saving.")
		data.ilvlExpirationTime = timeNow + TIMEOUT
	elseif data.ilvl ~= ilvl or ilvl == 0  then

		if data.inspections >= MAX_INSPECTIONS_TILL_TIMEOUT then 
			print("Reached inspection limit for",UnitName(unit),",stopping.")
			data.ilvlExpirationTime = timeNow + TIMEOUT
			data.inspections = 0
			return
		end

		print("Inspect result for",UnitName(unit),":",data.ilvl,"-->",ilvl, ",repeating...")
		data.ilvlExpirationTime = 0
		data.ilvl = ilvl
		-- scaling reporting wrong ilvl workaround
		notifyInspections(unit)
		data.inspections = data.inspections + 1
	end
end




local function getColoredIlvlString(unit)
	local itemLevel = getCacheForUnit(unit).ilvl
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





local function OnTooltipSetUnitHandler(self)
	local _, unit = self:GetUnit()
	if not unit or not UnitIsPlayer(unit) then
		return
	end
	notifyInspections(unit)
	local spec = getCacheForUnit(unit).spec
	local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	if spec == UnitClass(unit) or IsCustomClass(unit) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	end
	self:AddDoubleLine(AIL .. color:WrapText(spec), getColoredIlvlString(unit))
end

local function GameTooltipOnEvent(self, event, ...)
	local _, unit = self:GetUnit()
	if not unit or not UnitIsPlayer(unit) then
		return
	end
	if event == "INSPECT_TALENT_READY" then --UPDATE ILVL if > 0 and different than cached
		local ilvl = UnitAverageItemLevel(unit)
		updateCache(unit, nil, ilvl)
		for i = 1, self:NumLines() do
			if string.match(_G["GameTooltipTextLeft" .. i]:GetText(), AIL) then -- looks for our hidden text
				_G["GameTooltipTextRight" .. i]:SetText(getColoredIlvlString(unit))
			end
		end
	elseif event == "MYSTIC_ENCHANT_INSPECT_RESULT" then -- UPDATE SPEC AND ILVL  if > 0 and different than cached
		-- local ilvl = UnitAverageItemLevel(unit)
		local spec,_ = UnitSpecAndIcon(unit)
		updateCache(unit, spec)
		for i = 1, self:NumLines() do
			if string.match(_G["GameTooltipTextLeft" .. i]:GetText(), AIL) then -- looks for our hidden text
				local spec = getCacheForUnit(unit).spec
				local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
				if spec == UnitClass(unit) or IsCustomClass(unit) then
					color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
				end
				-- _G["GameTooltipTextRight" .. i]:SetText(getColoredIlvlString(unit))
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