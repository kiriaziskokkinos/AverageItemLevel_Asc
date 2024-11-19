AiL = select(2, ...)
local CACHE = {}
local TIMEOUT = 60
local MAX_INSPECTIONS_TILL_TIMEOUT = 5
local _print = print
AiL.Options = AiL.Options or {}
AiL.Options.ShowIcon = true -- CHANGE THIS TO false TO DISABLE ICON
AiL.Options.Debug = true
AiL.specListLookup = {
    -- PYROMANCER
    [706859] = "Flameweaving Pyromancer",
    [680961] = "Incineration Pyromancer",
    [500173] = "Draconic Pyromancer",
    -- CULTIST
    [805120] = "Influence Cultist",
    [805606] = "Corruption Cultist",
    [520226] = "Dreadnaught Cultist",
    [805605] = "Godblade Cultist",
    -- VENOMANCER
    [500231] = "Fortitude Venomancer",
    [800889] = "Stalking Venomancer",
    [681101] = "Rotweaver Venomancer",
    [800912] = "Vizier Venomancer",
    -- WITCH HUNTER
    [680489] = "Black Knight Witch Hunter",
    [680234] = "Darkness Witch Hunter",
    [705492] = "Boltslinger Witch Hunter",
    [802020] = "Inquisition Witch Hunter",
    -- REAPER
    [500283] = "Harvest Reaper",
    [560427] = "Domination Reaper",
    [500284] = "Soul Reaper",
    -- TEMPLAR
    [520007] = "Crusader Templar",
    [803147] = "Oathkeeper Templar",
    [5000008] = "Zealot Templar",
    -- WITCH DOCTOR
    [804620] = "Shadowhunting Witch Doctor",
    [560967] = "Brewing Witch Doctor",
    [500052] = "Voodoo Witch Doctor",
    -- FELSWORN
    [500067] = "Tyranny Felsworn",
    [705132] = "Slaying Felsworn",
    [500066] = "Infernal Felsworn",
    -- BARBARIAN
    [500061] = "Ancestry Barbarian",
    [706432] = "Headhuntung Barbarian",
    [500059] = "Brutality Barbarian",
    -- PRIMALIST
    [500298] = "Life Primalist",
    [805943] = "Wildwalker Primalist",
    [805945] = "Wildwalker Primalist",
    [680440] = "Geomancy Primalist",
    [803975] = "Mountain King Primalist",
    -- SUN CLERIC
    [680627] = "Valkyrie Sun Cleric",
    [500207] = "Piety Sun Cleric",
    [800586] = "Seraphim Sun Cleric",
    [500209] = "Blessing Sun Cleric",
    -- RANGER
    [500022] = "Archery Ranger",
    [806345] = "Farstrider Ranger",
    [500024] = "Brigand Ranger",
    -- BLOODMAGE
    [804204] = "Eternal Bloodmage",
    [680688] = "Fleshweaver Bloodmage",
    [500107] = "Sanguine Bloodmage",
    [500108] = "Accursed Bloodmage",
    -- RUNEMASTER
    [800741] = "Displacement Runemaster",
    [500309] = "Spellslinger Runemaster",
    [500314] = "Riftblade Runemaster",
    -- TINKER
    [503562] = "Mechanics Tinker",
    [500215] = "Invention Tinker",
    [805313] = "Demolition Tinker",
    -- STORMBRINGER
    [804019] = "Wind Stormbringer",
    [500005] = "Maelstrom Stormbringer",
    [500068] = "Lightning Stormbringer",
    -- KNIGHT OF XOROTH
    [704993] = "Hellfire Knight of Xoroth",
    [706935] = "Defiance Knight of Xoroth",
    [804284] = "War Knight of Xoroth",
    -- GUARDIAN
    [500049] = "Vanguard Guardian",
    [500051] = "Inspiration Guardian",
    [500050] = "Gladiator Guardian",
    -- NECROMANCER
    [500117] = "Death Necromancer",
    [500165] = "Animation Necromancer",
    [801760] = "Rime Necromancer",
    -- CHRONOMANCER
    [524965] = "Artificer Chronomancer",
    [518352] = "Duality Chronomancer",
    [503811] = "Duality Chronomancer",
    [801270] = "Displacement Chronomancer",
    -- STARCALLER
    [801128] = "Warden Starcaller",
    [804287] = "Moon Guard Starcaller",
    [805356] = "Sentinel Starcaller",
    [801973] = "Moon Priest Starcaller"
}
--- DEBUG STUFF ---
function AiL.print(...)
    if AiL.Options.Debug then
        _print(...)
    end
end

function AiL.toggleDebug()
    AiL.Options.Debug = not AiL.Options.Debug
    _print(AiL.Options.Debug and "Debug turned on." or "Debug turned off.")
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
		-- INITIAL DATA BEFORE CACHE
		
        local spec, icon = UnitSpecAndIcon(unit)
		AiL.print("No cache found for ",UnitName(unit),". Initializing to",spec)
        if IsCustomClass(unit) then
            spec = (spec == UnitClass(unit)) and spec or (spec .. " " .. UnitClass(unit))
        end
        icon = " |T" .. icon .. ".blp:32:32:0:0|t "
        CACHE[guid] = {
            spec = spec,
            icon = icon,
            ilvl = 0,
            true_ilvl = 0,
            specExpirationTime = 0,
            ilvlExpirationTime = 0,
            inspections = 0
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
            data.icon = newIcon
            data.specExpirationTime = timeNow + TIMEOUT
            return
        end
        AiL.print("No specialization was reported by UnitSpecAndIcon(unit). Inspecting Build.")

        ---------------- COA TEST ---------------
        local activeSpec = C_CharacterAdvancement.GetInspectInfo(unit) or 1
        if not activeSpec then
			AiL.print("active spec of ",UnitName(unit)," is null.")
            return
        end

        local entries = C_CharacterAdvancement.GetInspectedBuild(unit, activeSpec)
        if not entries then
            AiL.print("GetInspectedBuild did not return entries for spec ",activeSpec," of",UnitName(unit))
            return
        end

        for i, entry in ipairs(entries) do
            local rank = entry.Rank
            local internalID = entry.EntryId

            local entry = C_CharacterAdvancement.GetEntryByInternalID(entry.EntryId)
            if entry then
                local spellID = entry.Spells[rank]
                if AiL.specListLookup[spellID] then
                    data.spec = AiL.specListLookup[spellID]
					AiL.print("Inspecting CoA class spec ", UnitName(unit), "is now", data.spec)
                    data.icon = select(3, GetSpellInfo(spellID))
                    data.icon = " |T" .. data.icon .. ".blp:32:32:0:0|t "
                    local color = AiL.getColorforUnitSpec(unit, data.spec)
					data.specExpirationTime = timeNow + TIMEOUT
                    return
                end
            end
        end

		AiL.print(UnitName(unit), "no spec info found for ActiveSpec=",activeSpec)
    end
end

function AiL.notifyInspections(unit)
    if AscensionInspectFrame and AscensionInspectFrame:IsShown() then
        return
    end

    if CanInspect(unit) and not IsIlvlThrottled(unit) then
        NotifyInspect(unit)

    end
    if IsCustomClass(unit) and not IsSpecThrottled(unit) then
        C_CharacterAdvancement.InspectUnit(unit)
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
		GameTooltip:GetScript("OnEvent")(GameTooltip,"AIL_FINAL_INSPECT_REACHED")
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
