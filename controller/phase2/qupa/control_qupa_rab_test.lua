pcall(function() os.setlocale("C", "numeric") end)

package.path = "./controller/phase2/common/?.lua;" .. package.path

local constants = require("constants")
local protocol = require("protocol")
local neighbor_table = require("neighbor_table")

local LOG_PERIOD = 10

local tick = 0
local uid = 0
local sequence = 0
local neighbors = nil

local function uid_from_robot_id(robot_id)
   return tonumber(robot_id:match("(%d+)$")) or 0
end

local function role_for_uid(robot_uid)
   if robot_uid == 101 then
      return constants.ROLE.LEADER
   end
   return constants.ROLE.FOLLOWER
end

local function stop_wheels()
   if robot.wheels then
      robot.wheels.set_velocity(0, 0)
   end
end

local function send_heartbeat()
   sequence = (sequence + 1) % 256
   local packet = protocol.build_packet({
      sender_uid = uid,
      message_type = protocol.MESSAGE_TYPE.HEARTBEAT,
      robot_type = constants.ROBOT_TYPE.QUPA,
      role = role_for_uid(uid),
      state = constants.STATE.OK,
      sequence = sequence,
   })
   robot.range_and_bearing.set_data(packet)
end

local function update_neighbors()
   local rab = robot.range_and_bearing
   if not rab then
      return
   end

   for _, packet in ipairs(rab) do
      local decoded = protocol.decode_packet(packet.data)
      neighbor_table.update_from_packet(neighbors, decoded, packet, tick)
   end
   neighbor_table.mark_stale(neighbors, tick, constants.NEIGHBOR_TIMEOUT_TICKS)
end

local function log_neighbors()
   local active_ids = neighbor_table.active_ids(neighbors)
   local id_text = table.concat(active_ids, ",")
   if id_text == "" then
      id_text = "none"
   end
   log(string.format("RAB_TEST robot=%s uid=%d tick=%d NEIGHBORS=%s", robot.id, uid, tick, id_text))
end

function init()
   tick = 0
   sequence = 0
   uid = uid_from_robot_id(robot.id)
   neighbors = neighbor_table.new(uid)
   stop_wheels()
   log(string.format("RAB_TEST init robot=%s uid=%d", robot.id, uid))
end

function step()
   tick = tick + 1
   stop_wheels()
   send_heartbeat()
   update_neighbors()

   if tick % LOG_PERIOD == 0 then
      log_neighbors()
   end
end

function reset()
   tick = 0
   sequence = 0
   neighbors = neighbor_table.new(uid)
   stop_wheels()
end

function destroy()
   stop_wheels()
end
