--- fat-rogue.lua
-- random dungeons for sharks
-- @author sebastian jensen

--- @todo pull these from ini/json or use as keys in db, whatever
monsterTypes = {
  "Celestial",
  "Elemental",
  "Construct",
  "Aberration",
  "Fey",
  "Fiend",
  "Beast",
  "Humanoid",
  "Undead",
  "Monstrosity",
  "Giant",
  "Dragon"
}

function dice(num, sides)
  local sum = 0
  for d = 1, num do
    sum = sum + math.random(1, sides)
  end
  return sum
end

function make_entity(map, kind, x, y, param)
    if map.entities == nil then return end -- too paranoid?
    -- clamp to bounds, but maybe we'd rather bail?
    if x < 1 then x = 1 end
    if y < 1 then y = 1 end
    if x > map.width then x = map.width end
    if y > map.height then y = map.height end
    local entity = {
      kind = kind,         -- the kind of object ("player", "monster", "treasure")
      x = x,
      y = y,
      param = param or 0   -- extra data like subtype of kind or amount of coins if kind is treasure for example
    }
    return entity
end

function generate_map(width, height, maxNumRooms, maxRoomWidth, maxRoomHeight)
  local map = {
    width = width or 121,
    height = height or 41,
    data = {},  -- 1d buffer of tiles, just 0 and 1 for now
    entities = {}   
    -- keep separate tables for different types of entities?
    -- depends on what type of collision/interaction checks we want
  }
  
  -- maps must have uneven dimensions because we dont use edges
  if map.width % 2 == 0 then map.width = map.width + 1 end
  if map.height % 2 == 0 then map.height = map.height + 1 end
  
  for y = 1, map.height do
    for x = 1, map.width do
      map.data[y * map.width + x] = 0
    end
  end
  
  --- CORRIDORS: ---
  -- fill the map with a perfect maze basically using "recursive backtracker" but without recursion.
  local toVisit = {}
  table.insert(toVisit, 2 * map.width + 2); -- always start from 2, 2 to help with testing, but we could start anywhere
  map.data[toVisit[#toVisit]] = 1
  while #toVisit > 0 do
    local current = toVisit[#toVisit]
    
    -- my decision to stick to a 1d flat array has made this somewhat ugly
    local currentX = current % map.width
    local currentY = math.floor(current / map.width)
    
    ---@todo: refactor into function that returns the toConsider array?
    local toConsider = {}
    if currentY - 2 > 1 and map.data[current - (map.width * 2)] == 0 then
      table.insert(toConsider, -map.width)
    end
    if currentY + 2 < map.height and map.data[current + (map.width * 2)] == 0 then
      table.insert(toConsider, map.width)
    end
    if currentX + 2 < map.width and map.data[current + 2] == 0 then
      table.insert(toConsider, 1)
    end
    if currentX - 2 > 1 and map.data[current - 2] == 0 then
      table.insert(toConsider, -1)
    end
    
    if #toConsider > 0 then
      local dir = toConsider[math.ceil(math.random(#toConsider))]
      map.data[current + dir] = 1
      map.data[current + (dir * 2)] = 1
      table.insert(toVisit, current + (dir * 2))
    else 
      table.remove(toVisit)
    end
  end
  
  --- PLACE ROOMS: ---
  -- last minute solution. i removed overlap checks for a cheap way to get l-shaped and other irregular rooms.
  -- the original solution confined rooms to a grid, which works great for games like spelunky or binding of isaac
  -- that does not use smooth scrolling. the reason the grided solution was scrapped was because it was difficult
  -- to parameterize in a meaningful way; api user would have to select a grid size that is a factor of the width and
  -- height which is already constrained to be uneven :C ... i should have gone with bsp or brute force and move apart approach.
  local numRooms = math.random(maxNumRooms)
  for i=1, maxNumRooms do
    local roomSizeX = math.random(2, maxRoomWidth)
    local roomSizeY = math.random(2, maxRoomHeight)
    local xOffset = math.random(2, map.width - roomSizeX - 2)
    local yOffset = math.random(2, map.height - roomSizeY - 2)
    for y = yOffset, yOffset + roomSizeY do
      for x = xOffset, xOffset + roomSizeX do
        map.data[y * map.width + x] = 1
      end
    end
  end
  
  --- PLACE ENTITIES: ---
  for y = 1, map.height do
    for x = 1, map.width do
      if map.data[y * map.width + x] == 1 then
        local objectRoll = dice(3, 6)
        if objectRoll == 18 then
          table.insert(map.entities, make_entity(map, "treasure", x, y, math.random(10, 100)))
        elseif objectRoll == 3 then
          local monsterRoll = dice(2, 6)
          -- monster roll is just a numerical value into lookup table
          table.insert(map.entities, make_entity(map, "monster", x, y, monsterRoll))
        end
      end
    end
  end
  
  --- PLACE PLAYER: ---
  -- @todo: this is a quick hack to early exit out of nested loop. refactor out.
  (function ()
    for y = 1, map.height do
      for x = 1, map.width do
        if map.data[y * map.width + x] == 1 then
          table.insert(map.entities, make_entity(map, "player", x, y))
          return
        end
      end
    end
  end)()
    
  return map
end


function pretty_print_to_console(map)
  if map == nil then return end
  for y = 1, map.height do
    for x = 1, map.width do
      -- obviously, if you had graphics you would loop through entities
      -- only once (not once per tile) and draw them in on top of the tile.
      local empty = true;
      for n = 1, #world.entities do
        if world.entities[n].x == x and world.entities[n].y == y then
            -- @fixme: if player and other object are on the same tile, both are drawn
            if world.entities[n].kind == "player" then  -- no switch in lua :C
              io.write("@")
            elseif world.entities[n].kind == "monster" then
              io.write("M") 
            elseif world.entities[n].kind == "treasure" then
              io.write("X")
            end
            empty = false
        end
      end
      if empty then io.write(world.data[y * world.width + x] == 1 and "." or "#") end
    end
    io.write("\n")
  end
end

math.randomseed(os.time())  -- fine for now
world = generate_map(32, 32, 8, 8, 8)
pretty_print_to_console(world)


