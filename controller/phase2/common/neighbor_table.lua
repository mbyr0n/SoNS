local protocol = require("protocol")

local M = {}

function M.new(self_uid)
   return {
      self_uid = self_uid,
      neighbors = {},
   }
end

function M.update_from_packet(table_state, decoded, rab_packet, tick)
   if not protocol.is_valid_packet(decoded) then
      return false
   end

   if decoded.sender_uid == table_state.self_uid then
      return false
   end

   table_state.neighbors[decoded.sender_uid] = {
      uid = decoded.sender_uid,
      robot_type = decoded.robot_type,
      role = decoded.role,
      state = decoded.state,
      range = rab_packet and rab_packet.range or nil,
      bearing = rab_packet and rab_packet.horizontal_bearing or nil,
      vertical_bearing = rab_packet and rab_packet.vertical_bearing or nil,
      last_seen = tick,
      sequence = decoded.sequence,
      active = true,
   }

   return true
end

function M.mark_stale(table_state, tick, timeout_ticks)
   for _, neighbor in pairs(table_state.neighbors) do
      if tick - neighbor.last_seen > timeout_ticks then
         neighbor.active = false
      end
   end
end

function M.get(table_state, uid)
   return table_state.neighbors[uid]
end

function M.active_ids(table_state)
   local ids = {}
   for uid, neighbor in pairs(table_state.neighbors) do
      if neighbor.active then
         table.insert(ids, uid)
      end
   end
   table.sort(ids)
   return ids
end

return M
