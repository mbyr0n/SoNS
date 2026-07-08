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

function M.build_packet(fields)
   local packet = M.empty_packet()
   packet[M.BYTE.SENDER_UID] = fields.sender_uid or 0
   packet[M.BYTE.MESSAGE_TYPE] = fields.message_type or 0
   packet[M.BYTE.ROBOT_TYPE] = fields.robot_type or 0
   packet[M.BYTE.ROLE] = fields.role or 0
   packet[M.BYTE.STATE] = fields.state or 0
   packet[M.BYTE.SEQUENCE] = fields.sequence or 0
   packet[M.BYTE.DATA_A] = fields.data_a or 0
   packet[M.BYTE.DATA_B] = fields.data_b or 0
   packet[M.BYTE.RESERVED] = fields.reserved or 0
   return packet
end

local function message_type_exists(value)
   for _, message_type in pairs(M.MESSAGE_TYPE) do
      if value == message_type then
         return true
      end
   end
   return false
end

function M.decode_packet(data)
   if type(data) ~= "table" or #data < M.PACKET_SIZE then
      return {valid = false, error = "packet too short"}
   end

   local decoded = {
      version = data[M.BYTE.VERSION],
      sender_uid = data[M.BYTE.SENDER_UID],
      message_type = data[M.BYTE.MESSAGE_TYPE],
      robot_type = data[M.BYTE.ROBOT_TYPE],
      role = data[M.BYTE.ROLE],
      state = data[M.BYTE.STATE],
      sequence = data[M.BYTE.SEQUENCE],
      data_a = data[M.BYTE.DATA_A],
      data_b = data[M.BYTE.DATA_B],
      reserved = data[M.BYTE.RESERVED],
      valid = true,
   }

   if decoded.version ~= M.VERSION then
      decoded.valid = false
      decoded.error = "wrong protocol version"
   elseif decoded.sender_uid == nil or decoded.sender_uid <= 0 then
      decoded.valid = false
      decoded.error = "invalid sender uid"
   elseif not message_type_exists(decoded.message_type) then
      decoded.valid = false
      decoded.error = "unknown message type"
   end

   return decoded
end

function M.is_valid_packet(decoded)
   return type(decoded) == "table" and decoded.valid == true
end

return M
