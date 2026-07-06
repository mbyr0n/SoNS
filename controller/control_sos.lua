pcall(function() os.setlocale("C", "numeric") end)

-- ==================== CONSTANTS ====================
local K_P = 10.0
local MAX_WHEEL = 20
local BEACON_EVERY = 5
local DISCOVERY_STEPS = 50

-- RAB message layout (10 bytes):
-- [1] = sender_id
-- [2] = msg_type: 0=BEACON, 1=ACCEPT
-- [3] = state (0=SINGLE,1=BRAIN,2=CHILD) or accepted_parent for ACCEPT
-- [4] = sons_root_id
-- [5] = sons_root_rank_lo
-- [6] = sons_root_rank_hi
-- [7] = parent_id (255=none)
-- [8] = my_node_id (255=none)
-- [9] = yaw_byte (heading of sender, 0-255 maps to -π to π)
-- [10] = unused

-- ==================== ROBOT IDENTITY ====================
local id_num = tonumber(robot.id:match("(%d+)$")) or 0
local my_rank = ((id_num + 1) * 7919) % 65536 / 65535

-- ==================== TOPOLOGY ====================
-- Tree: {parent_node, target_x, target_y relative to parent}
local TREE = {
  [0] = {p=nil, x=0.0, y=0.0},
  [1] = {p=0, x=0.6, y=0.4},
  [2] = {p=0, x=0.6, y=-0.4},
  [3] = {p=1, x=0.5, y=0.3},
  [4] = {p=1, x=0.5, y=-0.3},
  [5] = {p=2, x=0.5, y=0.3},
}
local N_NODES = 6
local node_to_id = {}
local id_to_node = {}

-- ==================== STATE ====================
local tick = 0
local state = "SINGLE"
local sons_root_id = id_num
local sons_root_rank = my_rank
local parent_id = nil
local my_node = nil
local known = {}
local last_beacon = 0
local assigned = false

-- ==================== HELPERS ====================
local function normalize_angle(a)
  while a > math.pi do a = a - 2 * math.pi end
  while a < -math.pi do a = a + 2 * math.pi end
  return a
end

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

-- ==================== RAB SEND ====================
local function make_msg()
  return {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

function send_beacon()
  if tick - last_beacon < BEACON_EVERY then return end
  last_beacon = tick
  local m = make_msg()
  m[1] = id_num
  m[2] = 0
  if state == "SINGLE" then m[3] = 0
  elseif state == "BRAIN" then m[3] = 1
  else m[3] = 2 end
  m[4] = sons_root_id
  local re = math.floor(sons_root_rank * 65535)
  m[5] = re % 256
  m[6] = math.floor(re / 256)
  m[7] = parent_id or 255
  m[8] = my_node or 255
  local yaw = 0
  if robot.positioning then
    local o = robot.positioning.orientation
    yaw = math.atan2(2*(o.w*o.z + o.x*o.y), 1 - 2*(o.y*o.y + o.z*o.z))
  end
  m[9] = math.floor((yaw / (2*math.pi) + 0.5) * 255 + 0.5) % 256
  robot.range_and_bearing.set_data(m)
end

-- ==================== RAB RECEIVE ====================
function process_rab()
  local rab = robot.range_and_bearing
  if not rab then return end

  for _, pkt in ipairs(rab) do
    local d = pkt.data
    local sender = d[1]
    local mtype = d[2]
    local st = d[3]
    local sri = d[4]
    local srr = (d[6] * 256 + d[5]) / 65535
    local pid = d[7]
    local nid = d[8]

    if sender == id_num then goto continue end

    if pid == 255 then pid = nil end
    if nid == 255 then nid = nil end

    local yaw_byte = d[9]
    local yaw = (yaw_byte / 255 - 0.5) * 2 * math.pi

    if not known[sender] or known[sender].rank < srr then
      known[sender] = {rank = srr, state = st, sons_root = sri, parent = pid, node = nid, yaw = yaw, time = tick}
    end

    ::continue::
  end
end

-- ==================== NODE ASSIGNMENT ====================
function assign_nodes()
  -- Ranks are deterministic: ((id+1)*7919) % 65536 / 65535
  -- Each robot independently computes the same ranking.
  -- Highest rank → node 0 (brain), next → node 1, etc.
  local function rank_of(id)
    return ((id + 1) * 7919) % 65536 / 65535
  end

  local sorted = {}
  for i = 0, N_NODES - 1 do
    table.insert(sorted, {id = i, rank = rank_of(i)})
  end
  table.sort(sorted, function(a, b) return a.rank > b.rank end)

  node_to_id = {}
  id_to_node = {}
  for i, entry in ipairs(sorted) do
    local nid = i - 1
    node_to_id[nid] = entry.id
    id_to_node[entry.id] = nid
  end

  my_node = id_to_node[id_num]
  local t = TREE[my_node]
  if t.p ~= nil then
    local parent_node = t.p
    parent_id = node_to_id[parent_node]
    state = "CHILD"
    sons_root_id = node_to_id[0]
    sons_root_rank = rank_of(sons_root_id)
  else
    state = "BRAIN"
    parent_id = nil
    sons_root_id = id_num
    sons_root_rank = my_rank
  end

  log(string.format("%s: ASSIGNED node=%d state=%s", robot.id, my_node, state))
  if state == "CHILD" then
    log(string.format("%s: following q%d target=(%.2f,%.2f)", robot.id, parent_id, t.x, t.y))
  end
  assigned = true
end

-- ==================== YAW FROM QUATERNION ====================
function get_yaw(o)
  return math.atan2(2*(o.w*o.z + o.x*o.y), 1 - 2*(o.y*o.y + o.z*o.z))
end

-- ==================== MOTION CONTROL ====================
function move_to_parent()
  if my_node == nil or parent_id == nil then
    robot.wheels.set_velocity(0, 0)
    return
  end

  local rab = robot.range_and_bearing
  if not rab then
    robot.wheels.set_velocity(2, 2)
    return
  end

  local p_range, p_bearing = nil, nil
  for _, pkt in ipairs(rab) do
    if pkt.data[1] == parent_id then
      p_range = pkt.range
      p_bearing = pkt.horizontal_bearing
    end
  end

  if not p_range then
    robot.wheels.set_velocity(2, 2)
    return
  end

  local pos = robot.positioning.position
  local child_yaw = get_yaw(robot.positioning.orientation)

  local range_m = p_range / 100.0

  -- Parent's world position from RAB + child's pose
  local parent_x = pos.x + range_m * math.cos(p_bearing + child_yaw)
  local parent_y = pos.y + range_m * math.sin(p_bearing + child_yaw)

  -- Parent's yaw from beacon
  local parent_info = known[parent_id]
  local parent_yaw = parent_info and parent_info.yaw or 0

  -- Target in world: (tx,ty) rotated by parent yaw, offset from parent
  local tx = TREE[my_node].x
  local ty = TREE[my_node].y
  local c = math.cos(parent_yaw)
  local s = math.sin(parent_yaw)
  local target_x = parent_x + tx * c - ty * s
  local target_y = parent_y + tx * s + ty * c

  -- Error in world frame
  local ex = target_x - pos.x
  local ey = target_y - pos.y

  if math.sqrt(ex * ex + ey * ey) < 0.05 then
    robot.wheels.set_velocity(0, 0)
    return
  end

  -- Rotate error to robot's frame
  local cc = math.cos(-child_yaw)
  local ss = math.sin(-child_yaw)
  local rx = ex * cc - ey * ss
  local ry = ex * ss + ey * cc

  -- Continuous blended control (no turn-in-place)
  local forward = clamp(rx * K_P * 0.5, -MAX_WHEEL, MAX_WHEEL)
  local turn = -ry * 3
  local vl = clamp(forward + turn, -MAX_WHEEL, MAX_WHEEL)
  local vr = clamp(forward - turn, -MAX_WHEEL, MAX_WHEEL)
  robot.wheels.set_velocity(vl, vr)
end

function brain_behavior()
  robot.wheels.set_velocity(0, 0)
  robot.leds.set_all_colors(255, 0, 0)
end

function child_behavior()
  robot.leds.set_all_colors(0, 255, 0)
  move_to_parent()
end

function single_behavior()
  robot.wheels.set_velocity(0, 0)
  robot.leds.set_all_colors(0, 0, 255)
end

-- ==================== MAIN LOOP ====================
function init()
  tick = 0
  known = {}
end

function step()
  tick = tick + 1
  send_beacon()
  process_rab()

  if tick == DISCOVERY_STEPS then
    assign_nodes()
  end

  if assigned then
    if tick == 100 or tick == 1000 or tick == 10000 then
      local pos = robot.positioning.position
      local my_yaw = get_yaw(robot.positioning.orientation)
      local rab = robot.range_and_bearing
      local parent_range = -1
      if rab then
        for _, pkt in ipairs(rab) do
          if pkt.data[1] == parent_id then
            parent_range = pkt.range
          end
        end
      end
      local target_dist = -1
      if my_node ~= nil then
        local t = TREE[my_node]
        target_dist = math.sqrt(t.x*t.x + t.y*t.y)
      end
      if state == "BRAIN" then
        log(string.format("%s: t=%d BRAIN pos=(%.2f,%.2f)", robot.id, tick, pos.x, pos.y))
      elseif state == "CHILD" then
        log(string.format("%s: t=%d CHILD p=q%d pos=(%.2f,%.2f) range=%.1f tgt=%.1f err=%.1f", robot.id, tick, parent_id or -1, pos.x, pos.y, parent_range, target_dist*100, math.abs(parent_range - target_dist*100)))
      end
    end
    if state == "BRAIN" then
      brain_behavior()
    elseif state == "CHILD" then
      child_behavior()
    else
      single_behavior()
    end
  else
    single_behavior()
  end
end

function reset()
  tick = 0
  state = "SINGLE"
  parent_id = nil
  my_node = nil
  known = {}
  assigned = false
  robot.wheels.set_velocity(0, 0)
end

function destroy()
  robot.wheels.set_velocity(0, 0)
end
