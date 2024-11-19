AiL = select(2, ...)
local CACHE = {}
local TIMEOUT = 60
local MAX_INSPECTIONS_TILL_TIMEOUT = 5
local _print = print
AiL.Options = AiL.Options or {}
AiL.Options.ShowIcon = true -- CHANGE THIS TO false TO DISABLE ICON
AiL.Options.Debug = false
AiL.specListLookup = {
    -- PYROMANCER
    [706859] = {'Flameweaving Pyromancer','Ability_Mage_FieryPayback'},
    [680961] = {'Incineration Pyromancer','Ability_Warlock_Backdraft'},
    [500173] = {'Draconic Pyromancer','INV_Weapon_Hand_06'},
    -- CULTIST
    [805120] = {'Influence Cultist','spell_shadow_rune'},
    [805606] = {'Corruption Cultist','Achievement_Boss_CThun'},
    [520226] = {'Dreadnought Cultist','inv_shield_grimbatolraid_d_02'},
    [805605] = {'Godblade Cultist','INV_Sword_61'},
    -- VENOMANCER
    [500231] = {'Fortitude Venomancer','ability_mount_hordescorpionamber'},
    [800889] = {'Stalking Venomancer','inv_pet_spiderdemon'},
    [681101] = {'Rotweaver Venomancer','_LiquidStone_Poison'},
    [800912] = {'Vizier Venomancer','rogue_paralytic_poison'},
    -- WITCH HUNTER
    [680489] = {'Black Knight Witch Hunter','inv_helmet_23'},
    [680234] = {'Darkness Witch Hunter','Ability_Warlock_ImprovedSoulLeech'},
    [705492] = {'Boltslinger Witch Hunter','_d3preparation'},
    [802020] = {'Inquisition Witch Hunter','Ability_Rogue_StayofExecution'},
    -- REAPER
    [500283] = {'Harvest Reaper','ability_rogue_sealfate'},
    [560427] = {'Domination Reaper','ability_touchofanimus'},
    [500284] = {'Soul Reaper','inv_artifact_thalkielsdiscord'},
    -- TEMPLAR
    [520007] = {'Crusader Monk','Ability_Paladin_BlessedHands'},
    [803147] = {'Oathkeeper Monk','_D3blindingflash'},
    [5000008] = {'Zealot Monk','_D3deadlyreach'},
    -- WITCH DOCTOR
    [804620] = {'Shadowhunting Witch Doctor','Ability_Hunter_SurvivalInstincts'},
    [560967] = {'Brewing Witch Doctor','INV_Misc_Cauldron_Nature'},
    [500052] = {'Voodoo Witch Doctor','INV_Misc_Idol_02'},
    -- FELSWORN
    [500067] = {'Tyrant Felsworn','Ability_Warlock_DemonicPower'},
    [705132] = {'Slaying Felsworn','INV_Weapon_Glave_01'},
    [500066] = {'Infernal Felsworn','Spell_Shadow_FingerOfDeath'},
    -- BARBARIAN
    [500061] = {'Ancestry Barbarian','Achievement_Dungeon_UtgardeKeep_Normal'},
    [706432] = {'Headhunting Barbarian','5_axe_(3)_Border'},
    [500059] = {'Brutality Barbarian','Ability_Warrior_BloodFrenzy'},
    -- PRIMALIST
    [500298] = {'Life Primalist','Spell_Shaman_BlessingOfEternals'},
    [805943] = {'Wildwalker Primalist','_BearAttack_BrownFire'},
    [805945] = {'Wildwalker Primalist','_BearAttack_BrownFire'},
    [680440] = {'Geomancy Primalist','item_earthenmight'},
    [803975] = {'Mountain King Primalist','inv_elementalearth2'},
    -- SUN CLERIC
    [680627] = {'Valkyrie Sun Cleric','inv_valkiergoldpet'},
    [500207] = {'Piety Sun Cleric','ability_racial_finalverdict'},
    [800586] = {'Seraphim Sun Cleric','Spell_Holy_Crusade'},
    [500209] = {'Blessings Sun Cleric','Ability_Paladin_SacredCleansing'},
    -- RANGER
    [500022] = {'Archery Ranger','Ability_Hunter_LongShots'},
    [806345] ={'Farstrider Ranger','INV_Misc_Map02'},
    [500024] = {'Brigand Ranger','ability_rogue_rollthebones02'},
    -- BLOODMAGE
    [804204] = {'Eternal Bloodmage','achievement_dungeon_jeshowlis'},
    [680688] = {'Fleshweaver Bloodmage','custom_t_handsofblood_border'},
    [500107] = {'Sanguine Bloodmage','Spell_Shadow_LifeDrain'},
    [500108] = {'Accursed Bloodmage','Spell_DeathKnight_Gnaw_Ghoul'},
    -- RUNEMASTER
    [800741] = {'Conjuration Runemaster','70_inscription_vantus_rune_azure'},
    [500309] = {'Spellslinger Runemaster','_D3arcanetorrent'},
    [500314] = {'Riftblade Spiritmage','INV_Weapon_Shortblade_79'},
    -- TINKER
    [503562] = {'Mechanics Tinker','INV_Misc_EngGizmos_06'},
    [500215] = {'Invention Tinker','INV_Gizmo_RocketBootExtreme'},
    [805313] = {'Demolition Tinker','INV_Musket_04'},
    -- STORMBRINGER
    [804019] = {'Wind Stormbringer','Spell_Nature_InvisibilityTotem'},
    [500005] ={'Maelstrom Stormbringer','Achievement_Boss_Thorim'},
    [500068] = {'Lightning Stormbringer','ability_vehicle_electrocharge'},
    -- KNIGHT OF XOROTH
    [704993] = {'Hellfire Knight of Xoroth','Spell_Shadow_ShadowandFlame'},
    [706935] = {'Defiance Knight of Xoroth','INV_Belt_18'},
    [804284] = {'War Knight of Xoroth','INV_MISC_HOOK_01'},
    -- GUARDIAN
    [500049] = {'Vanguard Guardian','Ability_Warrior_SwordandBoard'},
    [500051] = {'Inspiration Guardian','Achievement_BG_winWSG_3-0'},
    [500050] = {'Gladiator Guardian','Achievement_BG_KillFlagCarriers_grabFlag_CapIt'},
    -- NECROMANCER
    [500117] = {'Death Necromancer','achievement_dungeon_naxxramas_25man'},
    [500165] = {'Animation Necromancer','_D3wallofzombies'},
    [801760] = {'Rime Necromancer','Achievement_Boss_Amnennar_the_Coldbringer'},
    -- CHRONOMANCER
    [524965] = {'Artificer Chronomancer','inv_wand_1h_pvp400_c_01'},
    [518352] = {'Duality Chronomancer','inv_enchant_philostone_lv2'},
    [503811] = {'Duality Chronomancer','inv_enchant_philostone_lv2'},
    [801270] = {'Displacement Chronomancer','_AuraCloak_Ice'},
    -- STARCALLER
    [801128] = {'Warden Starcaller','_liquidstone_water'},
    [804287] = {'Moon Guard Starcaller','ability_hunter_carve'},
    [805356] = {'Sentinel Starcaller','_Diablo3_ArrowRain_Mage'},
    [801973] = {'Moon Priest Starcaller','Spell_Frost_ManaRecharge'},
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
                    data.spec = AiL.specListLookup[spellID][1]
					AiL.print("Inspecting CoA class spec ", UnitName(unit), "is now", data.spec)
                    data.icon = "Interface\\Icons\\"..AiL.specListLookup[spellID][2]
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
