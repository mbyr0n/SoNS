local M = {}

M.VERSION = 2
M.PACKET_SIZE = 10

M.BYTE = {
   VERSION = 1,
   SENDER_UID = 2,
   MESSAGE_TYPE = 3,
   ROBOT_TYPE = 4,
   ROLE = 5,
   STATE = 6,
   SEQUENCE = 7,
   DATA_A = 8,
   DATA_B = 9,
   RESERVED = 10,
}

M.MESSAGE_TYPE = {
   HEARTBEAT = 1,
   STATE = 2,
   COMMAND = 3,
}

function M.encode_signed(value, max_abs)
   value = math.max(-max_abs, math.min(max_abs, value))
   return math.floor(((value / max_abs) + 1.0) * 127.5 + 0.5)
end

function M.decode_signed(byte, max_abs)
   return ((byte / 127.5) - 1.0) * max_abs
end

function M.empty_packet()
   return {M.VERSION, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

return M
