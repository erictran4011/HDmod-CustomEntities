local celib = require "custom_entities"

--spikeball is offset by 3 tiles from its source block.
--the spawn function will create the spikeball itself,, then the source block over it .

--todo: 
--improve the formula for knockback on the spikeball
--draw chains,, probably by using chain entities
--send the spikeballs absolutely flying when the anchor tile is destroyed
--texture everything
--tweak the speed the spikeballs can move at
--figure out what should be able to get hit by these

local spikeball_texture_id
do
    local spikeball_texture_def = TextureDefinition.new()
    spikeball_texture_def.width = 128
    spikeball_texture_def.height = 128
    spikeball_texture_def.tile_width = 128
    spikeball_texture_def.tile_height = 128

    spikeball_texture_def.texture_path = 'spikeball.png'
    spikeball_texture_id = define_texture(spikeball_texture_def)
end
local function spikeball_trap_set(uid)
    local ent = get_entity(uid)
    local x, y, l = get_position(uid)

    ent:set_texture(spikeball_texture_id)

    ent.flags = set_flag(ent.flags, ENT_FLAG.NO_GRAVITY)
    ent.flags = clr_flag(ent.flags, ENT_FLAG.COLLIDES_WALLS)
    ent.flags = clr_flag(ent.flags, ENT_FLAG.INTERACT_WITH_SEMISOLIDS)
    ent.flags = clr_flag(ent.flags, ENT_FLAG.INTERACT_WITH_WATER)
    ent.flags = clr_flag(ent.flags, ENT_FLAG.INTERACT_WITH_WEBS)

    ent:set_draw_depth(7)

    ent.width = 1
    ent.height = 1
    --spawn the "source" tile, if this is destroyed the custom entity should just turn into a regular old unchained spikeball
    ent.owner_uid = spawn_grid_entity(ENT_TYPE.ACTIVEFLOOR_CHAINEDPUSHBLOCK, x, y, l)
    --move_state determines the direction the ball will spin in
    ent.move_state = 1
    if math.random(2) == 1 then
        ent.move_state = 2 --we cant set move_state to -1 because its an unsigned int,, just check the exact number later
    end
    --health determines the speed of the ball
    ent.health = math.random(25, 45)
end

local function spikeball_trap_update(ent)
    ent.velocityx = 0
    ent.velocityy = 0

    ent.animation_frame = 208

    --move from a fixed position based on the source block
    local source_block = get_entity(ent.owner_uid)
    local sx, sy, sl = get_position(ent.owner_uid)
    local x, y, l = get_position(ent.uid)
    local move_dir = 1
    if ent.move_state == 2 then
        move_dir = -1
    end
    local angle = move_dir*ent.stand_counter/ent.health

    if source_block == nil then
        local spikeball = spawn(ENT_TYPE.ACTIVEFLOOR_UNCHAINED_SPIKEBALL, x, y, l, math.random(-1, 1), 1)
        kill_entity(ent.uid)
    else
        ent.x = sx + source_block.velocityx + (3*math.cos(angle))
        ent.y = sy + source_block.velocityy + (3*math.sin(angle))

        ent.angle = angle
    end
    --damage entities on contact
    for _, v in ipairs(get_entities_by(0, MASK.PLAYER, l)) do
        local other_ent = get_entity(v)
        if ent:overlaps_with(other_ent) and other_ent.invincibility_frames_timer == 0 then
            local ex, ey, el = get_position(v)
            local kbdir = 1
            if (ex-x) < 0 then kbdir = -1 end
            other_ent:damage(
                ent.uid,
                2,
                80,
                (kbdir)*ent.health/250,
                math.sin(ey-y)/2,
                10
            )
        end
    end
end

register_option_button("spawn_spikeball_trap", "spawn_spikeball_trap", 'spike_spikeball_trap', function ()
    local x, y, l = get_position(players[1].uid)
    local uid = spawn(ENT_TYPE.ITEM_ROCK, x+3, y, l, 0, 0)
    spikeball_trap_set(uid)
    set_post_statemachine(uid, spikeball_trap_update)
end)