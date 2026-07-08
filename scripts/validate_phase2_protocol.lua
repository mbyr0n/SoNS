package.path = "./controller/phase2/common/?.lua;" .. package.path

local constants = require("constants")
local protocol = require("protocol")

local function fail(message)
   io.stderr:write("FAIL: " .. message .. "\n")
   os.exit(1)
end

local function assert_equal(actual, expected, message)
   if actual ~= expected then
      fail(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
   end
end

local packet = protocol.build_packet({
   sender_uid = 101,
   message_type = protocol.MESSAGE_TYPE.HEARTBEAT,
   robot_type = constants.ROBOT_TYPE.QUPA,
   role = constants.ROLE.LEADER,
   state = constants.STATE.OK,
   sequence = 7,
   data_a = protocol.encode_signed(0.5, 1.0),
   data_b = protocol.encode_signed(-0.5, 1.0),
})

assert_equal(#packet, 10, "build_packet must produce 10 bytes")
assert_equal(packet[protocol.BYTE.VERSION], protocol.VERSION, "packet version")
assert_equal(packet[protocol.BYTE.SENDER_UID], 101, "packet sender_uid")
assert_equal(packet[protocol.BYTE.SEQUENCE], 7, "packet sequence")

local decoded = protocol.decode_packet(packet)
if not protocol.is_valid_packet(decoded) then
   fail("decoded packet must be valid")
end

assert_equal(decoded.sender_uid, 101, "decoded sender_uid")
assert_equal(decoded.message_type, protocol.MESSAGE_TYPE.HEARTBEAT, "decoded message_type")
assert_equal(decoded.robot_type, constants.ROBOT_TYPE.QUPA, "decoded robot_type")
assert_equal(decoded.role, constants.ROLE.LEADER, "decoded role")
assert_equal(decoded.state, constants.STATE.OK, "decoded state")
assert_equal(decoded.sequence, 7, "decoded sequence")

local bad_version = protocol.decode_packet({99, 101, 1, 1, 1, 0, 1, 0, 0, 0})
if protocol.is_valid_packet(bad_version) then
   fail("wrong protocol version must be invalid")
end

local short_packet = protocol.decode_packet({protocol.VERSION, 101})
if protocol.is_valid_packet(short_packet) then
   fail("short packet must be invalid")
end

local bad_message = protocol.decode_packet({protocol.VERSION, 101, 99, 1, 1, 0, 1, 0, 0, 0})
if protocol.is_valid_packet(bad_message) then
   fail("unknown message type must be invalid")
end

local bad_uid = protocol.decode_packet({protocol.VERSION, 0, 1, 1, 1, 0, 1, 0, 0, 0})
if protocol.is_valid_packet(bad_uid) then
   fail("sender_uid 0 must be invalid")
end

print("PASS: Phase 2 RAB protocol is valid")
