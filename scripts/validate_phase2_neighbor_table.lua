package.path = "./controller/phase2/common/?.lua;" .. package.path

local constants = require("constants")
local protocol = require("protocol")
local neighbor_table = require("neighbor_table")

local function fail(message)
   io.stderr:write("FAIL: " .. message .. "\n")
   os.exit(1)
end

local function assert_equal(actual, expected, message)
   if actual ~= expected then
      fail(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
   end
end

local table_state = neighbor_table.new(101)

local self_packet = protocol.decode_packet(protocol.build_packet({
   sender_uid = 101,
   message_type = protocol.MESSAGE_TYPE.HEARTBEAT,
   robot_type = constants.ROBOT_TYPE.QUPA,
   role = constants.ROLE.LEADER,
   state = constants.STATE.OK,
   sequence = 1,
}))

neighbor_table.update_from_packet(table_state, self_packet, {range = 10, horizontal_bearing = 0.1}, 1)
if neighbor_table.get(table_state, 101) ~= nil then
   fail("neighbor table must ignore self packets")
end

local decoded = protocol.decode_packet(protocol.build_packet({
   sender_uid = 102,
   message_type = protocol.MESSAGE_TYPE.HEARTBEAT,
   robot_type = constants.ROBOT_TYPE.QUPA,
   role = constants.ROLE.FOLLOWER,
   state = constants.STATE.OK,
   sequence = 9,
}))

neighbor_table.update_from_packet(table_state, decoded, {
   range = 123,
   horizontal_bearing = 0.25,
   vertical_bearing = -0.1,
}, 5)

local neighbor = neighbor_table.get(table_state, 102)
if not neighbor then
   fail("neighbor 102 must be stored")
end

assert_equal(neighbor.uid, 102, "stored uid")
assert_equal(neighbor.robot_type, constants.ROBOT_TYPE.QUPA, "stored robot_type")
assert_equal(neighbor.role, constants.ROLE.FOLLOWER, "stored role")
assert_equal(neighbor.state, constants.STATE.OK, "stored state")
assert_equal(neighbor.range, 123, "stored range")
assert_equal(neighbor.bearing, 0.25, "stored bearing")
assert_equal(neighbor.vertical_bearing, -0.1, "stored vertical bearing")
assert_equal(neighbor.last_seen, 5, "stored last_seen")
assert_equal(neighbor.sequence, 9, "stored sequence")
assert_equal(neighbor.active, true, "stored active flag")

local ids = neighbor_table.active_ids(table_state)
assert_equal(#ids, 1, "one active neighbor")
assert_equal(ids[1], 102, "active neighbor id")

neighbor_table.mark_stale(table_state, 16, constants.NEIGHBOR_TIMEOUT_TICKS)
assert_equal(neighbor_table.get(table_state, 102).active, false, "stale neighbor must be inactive")
assert_equal(#neighbor_table.active_ids(table_state), 0, "no active neighbors after timeout")

neighbor_table.update_from_packet(table_state, decoded, {range = 100, horizontal_bearing = 0.0}, 17)
assert_equal(neighbor_table.get(table_state, 102).active, true, "fresh packet must reactivate neighbor")

print("PASS: Phase 2 neighbor table is valid")
