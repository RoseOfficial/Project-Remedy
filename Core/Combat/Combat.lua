-- Combat
Olympus = Olympus or {}
Olympus.Combat = {
    -- Constants
    HEALING_LOCKOUT = 2.0, -- Time to wait between healing spells
    MIN_SPELL_SPACING = 0.7, -- Minimum time between any spells
    OGCD_WINDOW_START = 0.6, -- When oGCD weaving can begin after a GCD
    OGCD_WINDOW_END = 1.2, -- When oGCD weaving must end before next GCD
    AOE_HEAL_LOCKOUT = 4.0, -- Extra lockout for AoE heals
    
    -- Spell cast tracking
    lastSpellCast = {
        id = 0,
        timestamp = 0,
        category = nil,
        isGCD = false,
        isHealing = false,
        isAoE = false,
        gcdLength = 0,
        targetId = 0
    }
}

---Initialize the Combat module
function Olympus.Combat.Initialize()
    Debug.TrackFunctionStart("Olympus.Combat.Initialize")
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Initializing Combat module...")
    
    -- Initialize spell tracking
    Olympus.Combat.lastSpellCast = {
        id = 0,
        timestamp = 0,
        category = nil,
        isGCD = false,
        isHealing = false,
        isAoE = false,
        gcdLength = 0,
        targetId = 0
    }
    
    Debug.Info(Debug.CATEGORIES.SYSTEM, "Combat module initialized successfully")
    Debug.TrackFunctionEnd("Olympus.Combat.Initialize")
end

---Get current GCD length from base GCD spell (Stone)
---@return number gcdLength The current GCD length in seconds
function Olympus.Combat.GetGCDLength()
    local baseGCD = ActionList:Get(1, 119) -- Stone
    return baseGCD and baseGCD.cdmax or 2.5 -- Fallback to 2.5s
end

---Check if an entity has a specific buff
---@param entity table The entity to check
---@param buffId number The buff ID to check for
---@param ownerId number|nil Optional owner ID to check against
---@return boolean hasBuff Whether the entity has the buff
function Olympus.Combat.HasBuff(entity, buffId, ownerId)
    if not entity or not entity.buffs then return false end
    
    for _, buff in pairs(entity.buffs) do
        if buff.id == buffId then
            if ownerId then
                return buff.ownerid == ownerId
            end
            return true
        end
    end
    
    return false
end

---Get the highest level spell available from a list
---@param spells table Array of spell definitions sorted by descending level
---@return table spell The highest level available spell
function Olympus.Combat.GetHighestLevelSpell(spells)
    for _, spell in ipairs(spells) do
        if Player.level >= spell.level then
            return spell
        end
    end
    return spells[#spells] -- Return lowest level spell as fallback
end

---Check if a spell is ready to be cast
---@param spell table|number The spell object or spell ID to check
---@param spellDef table|nil The spell definition containing instant cast info
---@return boolean ready Whether the spell can be cast
function Olympus.Combat.IsReady(spell, spellDef)
    -- Handle spell ID input
    if type(spell) == "number" then
        spell = ActionList:Get(1, spell)
    end
    
    -- Basic validity checks
    if not table.valid(spell) then return false end
    if spell.cdmax - spell.cd > 0.5 then return false end
    
    -- Movement restriction check
    if Player:IsMoving() then
        if spellDef and spellDef.instant then return true end
        if Olympus.Combat.HasBuff(Player, Olympus.BUFF_IDS.SWIFTCAST) then return true end
        return false
    end
    
    return true
end

---Check if a spell can be cast based on weaving rules
---@param action table The action to check
---@return boolean canCast Whether the spell can be cast under weaving rules
function Olympus.Combat.CanWeaveSpell(action)
    if not action then return false end
    
    -- Special case for Sprint - bypass weaving rules
    if action.id == Olympus.COMMON_SPELLS.SPRINT.id then return true end
    
    local currentTime = os.clock()
    local timeSinceLastCast = currentTime - Olympus.Combat.lastSpellCast.timestamp
    
    -- Check if this is a healing spell
    local isHealing = (action.category == "Healing")
    if isHealing and Olympus.Combat.lastSpellCast.isHealing then
        -- Enforce healing lockout
        if timeSinceLastCast < Olympus.Combat.HEALING_LOCKOUT then return false end
        
        -- Extra lockout for AoE heals
        if action.isAoE and Olympus.Combat.lastSpellCast.isAoE then
            if timeSinceLastCast < Olympus.Combat.AOE_HEAL_LOCKOUT then return false end
        end
        
        -- Check if target already has a heal incoming
        if not action.isAoE and action.targetId and action.targetId == Olympus.Combat.lastSpellCast.targetId then
            if timeSinceLastCast < 3.0 then return false end
        end
    end
    
    -- Check if this is a GCD spell using the explicit isGCD property
    local isGCD = action.isGCD
    
    -- Enforce minimum spell spacing
    if timeSinceLastCast < Olympus.Combat.MIN_SPELL_SPACING then return false end
    
    if isGCD then
        -- For GCD spells, ensure we're not in an oGCD weaving window
        if Olympus.Combat.lastSpellCast.isGCD and timeSinceLastCast < Olympus.Combat.OGCD_WINDOW_END then
            return false
        end
        return true
    else
        -- For oGCDs, check strict weaving window
        if not Olympus.Combat.lastSpellCast.isGCD then return false end
        if timeSinceLastCast < Olympus.Combat.OGCD_WINDOW_START then return false end
        if timeSinceLastCast > Olympus.Combat.OGCD_WINDOW_END then return false end
        return true
    end
end

---Attempt to cast an action on a target
---@param action table The action to cast
---@param targetId number|nil The optional target ID
---@param priority string|nil Priority level ("high", "medium", "low")
---@return boolean success Whether the cast was attempted
function Olympus.Combat.CastAction(action, targetId, priority)
    if not action then return false end
    
    -- Performance checks
    if Olympus.Performance.frameBudgetExceeded and Olympus.Performance.skipLowPriority then
        -- Always allow high priority actions
        if priority ~= "high" then return false end
    end
    
    -- Level and readiness checks
    if Player.level < action.level then return false end
    
    local actionObj = ActionList:Get(1, action.id)
    if not Olympus.Combat.IsReady(actionObj, action) then return false end
    
    -- Weaving system checks (skip for Sprint)
    if action.id ~= Olympus.COMMON_SPELLS.SPRINT.id and not Olympus.Combat.CanWeaveSpell(action) then
        return false
    end
    
    -- Attempt to cast directly
    if actionObj:Cast(targetId) then
        Olympus.Combat.lastSpellCast.id = action.id
        Olympus.Combat.lastSpellCast.timestamp = os.clock()
        Olympus.Combat.lastSpellCast.category = action.category
        Olympus.Combat.lastSpellCast.isGCD = action.isGCD
        Olympus.Combat.lastSpellCast.isHealing = (action.category == "Healing")
        Olympus.Combat.lastSpellCast.isAoE = action.isAoE
        Olympus.Combat.lastSpellCast.targetId = targetId
        if Olympus.Combat.lastSpellCast.isGCD then
            Olympus.Combat.lastSpellCast.gcdLength = Olympus.Combat.GetGCDLength()
        end
        return true
    end
    
    return false
end
