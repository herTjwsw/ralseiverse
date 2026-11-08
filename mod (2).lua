--[[
    mod.lua
    =======
    Entry point for DELTARUNE Chapter 8: THE RALSEIVERSE.

    Everything here runs once when the project is selected, before the
    registry has finished loading -- so this file only sets up globals
    and does cheap bookkeeping. Anything that needs actors, maps or the
    world to exist happens later in Mod:postInit().

    This chapter has no battle content at all: no encounters, no enemies,
    no waves. It is a chapter about meeting people.
]]

--- Every room in the chapter, used for the post-load self check.
local ROOMS = {
    "confluence", "room_cafe", "room_quiet", "room_hug", "room_artist", "room_secret",
    "room_prime", "room_knight", "room_neon", "room_tide",
    "room_bloom", "room_ash", "room_static", "room_margin", "room_draft",
    "room_echo", "room_wish", "room_afterword", "room_field", "room_hedge",
    "room_creek", "room_bells", "room_fireflies", "room_grove", "room_field_festival",
}

local HINT_ROOMS = {
    "confluence", "room_cafe", "room_quiet", "room_hug", "room_prime", "room_knight",
    "room_neon", "room_tide", "room_bloom", "room_ash", "room_static",
}

function Mod:init()
    Mod.logger = Logger("Ralseiverse", ConsoleFormats.CYAN)

    ---------------------------------------------------------------------
    -- Our one custom map event: `ralsei_npc`.
    --
    -- The engine's own `npc` event is `NPC(data.properties["actor"], ...)`
    -- and nothing else -- a `variant` property would be silently thrown
    -- away, and every Ralsei would come out untinted. This does the same
    -- job and then tells the actor which variant it is.
    --
    -- Registered here rather than in postInit because Game.event_registry
    -- is consulted the moment a map's objects are loaded.
    ---------------------------------------------------------------------
    if Game and Game.event_registry then
        Game:registerEvent("ralsei_npc", function(data)
            local actor = Registry.createActor("ralsei_variant")
            actor:setVariant(data.properties["variant"])
            if data.properties["display_name"] then
                actor.name = data.properties["display_name"]
            end
            return NPC(actor, data.center_x, data.center_y, data.properties)
        end)
        Game:registerEvent("field_sprite", function(data)
            local properties = data.properties or {}
            local anchor = Object(data.x, data.y, 1, 1)
            local sprite = Sprite("field/" .. properties["sprite"])
            sprite:setScale(tonumber(properties["scale"]) or 2)
            sprite:setOrigin(0.5, 1)
            anchor:addChild(sprite)
            return anchor
        end)
        Game:registerEvent("artist_board", function(data)
            local properties = data.properties or {}
            local board = Interactable(data.x, data.y, {data.width, data.height}, properties)
            local graphic = Object(0, 0)
            local width, height = data.width, data.height
            function graphic:draw()
                Draw.setColor(0.36, 0.22, 0.13, 1)
                love.graphics.rectangle("fill", 0, 0, width, height)
                Draw.setColor(0.12, 0.25, 0.22, 1)
                love.graphics.rectangle("fill", 5, 5, width - 10, height - 10)
                Draw.setColor(0.84, 0.82, 0.67, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", 7, 7, width - 14, height - 14)
                love.graphics.setFont(Assets.getFont("main", 10))
                love.graphics.printf("DRAW SOMETHING!", 0, height / 2 - 5, width, "center")
                Draw.setColor(1, 1, 1, 1)
            end
            board:addChild(graphic)
            return board
        end)
        Game:registerEvent("egg_hint", function(data)
            if Mod.info.dev or Game:getFlag("ralseiverse.hint_seen", false)
                or Game:getFlag("ralseiverse.hint_room") ~= data.properties["room"] then
                return nil
            end
            local hint = Interactable(data.x, data.y, {data.width, data.height}, {
                cutscene = "hints.eggroom",
                once = true,
            })
            local star = Sprite("kristal/menu_star", data.width / 2, data.height / 2 - 6)
            star:setScale(1.5)
            hint:addChild(star)
            return hint
        end)
    else
        Mod.logger:warn("Game.event_registry is not ready; custom map events will not load.")
    end

    ---------------------------------------------------------------------
    -- Multiverse state
    --
    -- The variant table itself lives in scripts/globals/multiverse.lua,
    -- which the registry turns into the `Multiverse` global. That happens
    -- AFTER this function, so `Multiverse` is only touched from postInit
    -- onwards (or lazily, as below).
    ---------------------------------------------------------------------

    RALSEIVERSE = {}

-------------------------------------------------------------------------
-- The room between rooms
--
-- In the real game you fall into the tree room by walking back and forth
-- between two screens; it is a 1-in-50 chance per crossing. The same trick
-- here, on any doorway that leaves the Confluence, except it is 1-in-8 and
-- it is guaranteed by the sixth crossing -- a secret nobody ever finds is
-- not a secret, it is a waste.
-------------------------------------------------------------------------

RALSEIVERSE.SECRET = {
    room = "room_secret",
    marker = "entry",
    from = { confluence = true },
    chance = 1 / 8,
    guarantee = 6,
}

--- Rolls for the hidden room. Returns true if the transition should be
--- redirected instead of letting the player go where they were going.
function RALSEIVERSE.rollSecret(world, target)
    -- The self-test play-through drives maps through cutscene:loadMap, which
    -- is this same function; a random diversion would fail it. It runs with
    -- dev = true, so the roll simply does not apply there.
    if Mod.info and Mod.info.dev then
        return false
    end

    local cfg = RALSEIVERSE.SECRET
    if type(target) == "table" then
        target = target.name or target.id
    end
    if target == cfg.room then
        return false
    end

    -- Map.name is properties.name, i.e. "confluence"; Map.id is not the room.
    local here = world.map and world.map.name
    if not here or not cfg.from[here] then
        return false
    end

    local tries = (Game:getFlag("ralseiverse.secret_tries", 0) or 0) + 1
    Game:setFlag("ralseiverse.secret_tries", tries)

    if math.random() >= cfg.chance and tries < cfg.guarantee then
        return false
    end

    Game:setFlag("ralseiverse.secret_tries", 0)
    Mod.logger:info("The Confluence gave up its extra room.")
    return true
end


    --- The recolour module (scripts/objects/tint.lua). Registry load order
    --- between `objects` and `data/actors` is not guaranteed, so the
    --- variant actor asks for it through here whenever it needs it.
    ---@return table? RalseiTint
    function RALSEIVERSE.Tint()
        if _G["RalseiTint"] then
            return _G["RalseiTint"]
        end

        -- Fall back to running the script ourselves if the registry
        -- hasn't got to it yet.
        local chunks = Mod.info and Mod.info.script_chunks
        if chunks then
            for path, chunk in pairs(chunks) do
                if path:find("scripts/objects/tint", 1, true) then
                    local ok, result = pcall(chunk)
                    if ok and result then
                        _G["RalseiTint"] = result
                        return result
                    end
                end
            end
        end

        return nil
    end

    --- Makes the real Ralsei shudder as every other version of himself
    --- feels the same thing at once. Used once, in the ending.
    ---
    --- This deliberately uses only stock engine effects (aura, shake,
    --- animation) rather than recolouring him: hooking the engine's own
    --- `ralsei` actor from a project is not possible, because registry
    --- hooks are loaded before `data/` scripts exist to hook.
    ---@param ids string[]|string Variant ids (used for timing), or "all"
    ---@param interval number? Seconds per beat (default 0.09)
    ---@param cycles integer? How many passes to make (default 2)
    function RALSEIVERSE.shudder(ids, interval, cycles)
        if type(ids) == "string" then
            local all = {}
            for _, id in ipairs(Multiverse.ORDER) do
                table.insert(all, id)
            end
            table.insert(all, "null")
            ids = all
        end

        interval = interval or 0.09
        cycles = cycles or 2

        local timer = Game.world and Game.world.timer
        local ralsei = Game.world and Game.world:getCharacter("ralsei")
        if not timer or not ralsei then return end

        timer:script(function(wait)
            if ralsei.sprite then
                ralsei.sprite.aura = true
            end

            for _ = 1, cycles do
                for _ = 1, #ids do
                    ralsei:shake(6, 2)
                    Assets.playSound("sparkle_gem", 0.35, 0.8 + love.math.random() * 0.9)
                    ralsei:setAnimation("battle/act")
                    wait(interval)
                end
            end

            ralsei:stopShake()
            ralsei:resetSprite()
            if ralsei.sprite then
                ralsei.sprite.aura = false
            end
        end)
    end

    Mod.logger:info("Loaded " .. self.info.name)
end

--- The registry is fully loaded at this point, so this is a safe place to
--- prove the project is wired up correctly and say so loudly if not.
function Mod:postInit(new_file)

    ---------------------------------------------------------------------
    -- Fwen-tag transformation. The player borrows the prime Ralsei actor
    -- only while inside the Fwen room; leaving restores the exact actor
    -- they entered with, so the change is cosmetic and room-local.
    ---------------------------------------------------------------------
    function RALSEIVERSE.transformPlayerToFwen(player, fwenNpc)
        if not player or RALSEIVERSE.FWEN_TRANSFORMED then return false end
        RALSEIVERSE.FWEN_ORIGINAL_ACTOR = player.actor
        RALSEIVERSE.FWEN_TRANSFORMED = true
        player:setActor(Registry.createActor("ralsei_variant", "prime"))
        if Game.world then
            Game.world:startCutscene("hugroom", "transformed", fwenNpc)
        end
        return true
    end

    local function restoreFwenPlayer(player)
        if player and RALSEIVERSE.FWEN_TRANSFORMED and RALSEIVERSE.FWEN_ORIGINAL_ACTOR then
            player:setActor(RALSEIVERSE.FWEN_ORIGINAL_ACTOR)
        end
        RALSEIVERSE.FWEN_ORIGINAL_ACTOR = nil
        RALSEIVERSE.FWEN_TRANSFORMED = false
        RALSEIVERSE.FWEN_CHASE_ACTIVE = false
    end

    ---------------------------------------------------------------------
    -- The hidden room. `World:loadMap` is where every door, every event
    -- and every `cutscene:loadMap` ends up, so this is the one place a
    -- transition can be quietly redirected somewhere else.
    ---------------------------------------------------------------------
    HookSystem.hook(World, "loadMap", function(orig, world, map, ...)
        local target = type(map) == "table" and (map.name or map.id) or map
        local here = world.map and world.map.name
        if here == "room_hug" and target ~= "room_hug" then
            restoreFwenPlayer(world.player)
        elseif target == "room_hug" and here ~= "room_hug" then
            RALSEIVERSE.FWEN_CHASE_ACTIVE = false
            RALSEIVERSE.FWEN_TRANSFORMED = false
            RALSEIVERSE.FWEN_ORIGINAL_ACTOR = nil
        end
        if not Mod.info.dev and not Game:getFlag("ralseiverse.hint_room") then
            local room = HINT_ROOMS[love.math.random(#HINT_ROOMS)]
            Game:setFlag("ralseiverse.hint_room", room)
        end
        if RALSEIVERSE.rollSecret(world, map) then
            local cfg = RALSEIVERSE.SECRET
            return orig(world, cfg.room, cfg.marker, "up")
        end
        return orig(world, map, ...)
    end)

    if not RALSEIVERSE.Tint() then
        Mod.logger:warn("RalseiTint could not be loaded; variants will draw untinted.")
    end

    local missing = {}
    for _, id in ipairs(ROOMS) do
        if not Registry.getMap(id) and not Registry.getMapData(id) then
            table.insert(missing, id)
        end
    end

    if #missing > 0 then
        Mod.logger:warn("Missing rooms: " .. table.concat(missing, ", "))
    else
        Mod.logger:info("All " .. #ROOMS .. " rooms registered.")
    end

    -- Every door and interactable in the chapter names a cutscene; make
    -- sure each group resolves.
    local known = {
        confluence = "intro",
        hugroom = "arrive",
        variants = "prime",
        activities = "tea",
        cafe = "counter",
        quietroom = "arrive",
        afterword = "gate",
        hints = "eggroom",
    }
    for group, id in pairs(known) do
        if not Registry.getWorldCutscene(group, id) then
            Mod.logger:warn("Cutscene \"" .. group .. "." .. id .. "\" did not register.")
        end
    end

    if new_file then
        Mod.logger:info("New file: descending into the Confluence.")
    else
        Mod.logger:info("Save loaded with " .. tostring(Multiverse.metCount()) .. "/7 Ralseis met.")
    end

    -- In dev mode the project plays itself: see scripts/objects/selftest.lua.
    -- objects/ scripts become globals named after their own `id` field, so
    -- this is a plain lookup now that the registry has run.
    if Mod.info.dev then
        local driver = Registry.getObject("RalseiverseSelfTest")
        if driver then
            driver.run()
            Mod.logger:warn("dev mode: running the automated play-through.")
        else
            Mod.logger:error("self-test driver is not registered.")
        end
    end
end

--- Only does anything while the dev-mode self-test is running.
function Mod:postUpdate()
    if Mod.step then
        Mod.step()
    end
end

function Mod:save(data)
    data["ralseiverse_met"] = Multiverse.metCount()
    data["ralseiverse_hugs"] = Game:getFlag("ralseiverse.hugs", 0)
end

function Mod:load(data, new_file, index)
    -- Flags are persisted by the engine; this just keeps the log honest.
    if not new_file then
        Mod.logger:info(tostring(Multiverse.metCount()) .. "/7 Ralseis met, "
            .. tostring(Game:getFlag("ralseiverse.activities", 0)) .. " activities done.")
    end
end
