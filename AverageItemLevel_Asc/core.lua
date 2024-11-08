AiL = select(2, ...)
local CACHE = {}
local TIMEOUT = 60
local MAX_INSPECTIONS_TILL_TIMEOUT = 5
local _print = print
AiL.Options = AiL.Options or {}
AiL.Options.ShowIcon = true
AiL.Options.Debug = false
--- DEBUG STUFF ---
function AiL.print(...)
	if AiL.Options.Debug then
		_print(...)
	end
end

function AiL.toggleDebug()
	AiL.Options.Debug = not AiL.Options.Debug
	_print(debug and "Debug turned on." or "Debug turned off.")
end
------ CACHE ------
local function GetCache()
	return CACHE
end

function AiL.getCacheForUnit(unit)
	if not unit then
		return
	end
	local guid = UnitGUID(unit)
	if not CACHE[guid] then
		local spec, icon = UnitSpecAndIcon(unit)

		if IsCustomClass(unit) then
			spec = (spec == UnitClass(unit)) and spec or (spec .. " " .. UnitClass(unit))
			-- icon = "Interface\\Icons\\classicon_" .. UnitClass(unit):lower()
		end
		-- local spec,icon = UnitSpecAndIcon(unit)
		-- spec = (spec == UnitClass(unit)) and spec
		-- 		or (spec .. " " .. UnitClass(unit))

		icon = " |T" .. icon .. ".blp:32:32:0:0|t "
		CACHE[guid] = {
			spec = spec,
			icon = icon,
			ilvl = 0,
			true_ilvl = 0,
			specExpirationTime = 0,
			ilvlExpirationTime = 0,
			inspections = 0,
		}
	end
	return CACHE[guid]
end

function AiL.ClearCache()
	CACHE = {}
end

function AiL.resetAllExpirations()
	for _, data in pairs(CACHE) do
		data.specExpirationTime = 0
		data.ilvlExpirationTime = 0
	end
end

function AiL.SetInspectTimeout(newTimeout)
	TIMEOUT = newTimeout > 0 and newTimeout or 1
	AiL.resetAllExpirations()
end

local function IsIlvlThrottled(unit)
	return AiL.getCacheForUnit(unit).ilvlExpirationTime > GetTime()
end

local function IsSpecThrottled(unit)
	return AiL.getCacheForUnit(unit).specExpirationTime > GetTime()
end

function AiL.updateCacheSpec(unit)
	if IsSpecThrottled(unit) then
		return
	end
	local timeNow = GetTime()
	local class, classFile = UnitClass(unit)
	local newSpec, newIcon = UnitSpecAndIcon(unit)
	newIcon = " |T" .. newIcon .. ".blp:32:32:0:0|t "
	local data = AiL.getCacheForUnit(unit)
	-- Is Hero --
	if IsHeroClass(unit) then
		-- if seasonal, spec == class so timeout instantly. if not, timeout when spec ~= class
		data.spec = newSpec or data.spec or class or "?"
		data.icon = newIcon
		if C_Realm.IsSeasonal() or data.spec ~= class then
			data.specExpirationTime = timeNow + TIMEOUT
		end

	-- Is CoA --
	elseif IsCustomClass(unit) then
		data.spec = newSpec

		if newSpec ~= UnitClass(unit) then -- UnitSpecAndIcon returned Specialization so we need to append the class
			data.spec = newSpec .. " " .. UnitClass(unit)
		end
		-- Specialization inspections are not implemented yet by ascension
		data.specExpirationTime = timeNow + TIMEOUT
	end
end

function AiL.notifyInspections(unit)
	if AscensionInspectFrame and AscensionInspectFrame:IsShown() then
		return
	end

	if CanInspect(unit) and not IsIlvlThrottled(unit) then
		NotifyInspect(unit)
	end
	if IsHeroClass(unit) then
		if C_MysticEnchant.CanInspect(unit) and not IsSpecThrottled(unit) then
			C_MysticEnchant.Inspect(unit, true)
		end
	end
end

function AiL.updateCacheIlvl(unit)
	if IsIlvlThrottled(unit) then
		return
	end
	local ilvl = UnitAverageItemLevel(unit)
	if ilvl == nil then
		return
	end
	local data = AiL.getCacheForUnit(unit)
	local timeNow = GetTime()
	if ilvl > 0 and data.ilvl == ilvl then
		AiL.print("Inspect result for", UnitName(unit), ":", data.ilvl, "-->", ilvl, ",saving.")
		data.ilvlExpirationTime = timeNow + TIMEOUT
		data.inspections = 0
		data.true_ilvl = ilvl
		C_Hook:SendBlizzardEvent("AIL_FINAL_INSPECT_REACHED")
	elseif data.ilvl ~= ilvl or ilvl == 0 then
		if data.inspections >= MAX_INSPECTIONS_TILL_TIMEOUT then
			AiL.print("Reached inspection limit for", UnitName(unit), ",stopping.")
			data.ilvlExpirationTime = timeNow + TIMEOUT
			data.inspections = 0
			return
		end
		AiL.print("Inspect result for", UnitName(unit), ":", data.ilvl, "-->", ilvl, ",repeating...")
		data.ilvlExpirationTime = 0
		data.ilvl = ilvl
		-- scaling reporting wrong ilvl workaround
		AiL.notifyInspections(unit)
		data.inspections = data.inspections + 1
	end
end

function AiL.getColorforUnitSpec(unit, spec)
	local color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	if spec == UnitClass(unit) or IsCustomClass(unit) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	end
	return color
end

function AiL.getColoredIlvlString(unitLevel, itemLevel)
	local color = WHITE_FONT_COLOR
	local expansionTarget = Enum.Expansion.Vanilla

	if unitLevel > 70 then
		expansionTarget = Enum.Expansion.WoTLK
	elseif unitLevel > 60 then
		expansionTarget = Enum.Expansion.TBC
	end

	local softCap = GetItemLevelSoftCap(expansionTarget)
	if itemLevel <= softCap then
		color = ColorUtil:Lerp(color, ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic], itemLevel / softCap)
	else
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]
	end

	if itemLevel > 0 then
		return "(" .. color:WrapText(format("%.02f", itemLevel)) .. ")"
	else
		color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Poor]
		return "(" .. color:WrapText("?") .. ")"
	end
end
