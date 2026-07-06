pcounter = 0

function normalize_angle(a)
   while a > math.pi do a = a - 2.0 * math.pi end
   while a < -math.pi do a = a + 2.0 * math.pi end
   return a
end

function pose_inverse(p)
   local c = math.cos(p.yaw)
   local s = math.sin(p.yaw)
   return {
      x = -(c * p.x + s * p.y),
      y = -(-s * p.x + c * p.y),
      yaw = -p.yaw
   }
end

function pose_compose(a, b)
   local c = math.cos(a.yaw)
   local s = math.sin(a.yaw)
   return {
      x = a.x + c * b.x - s * b.y,
      y = a.y + s * b.x + c * b.y,
      yaw = normalize_angle(a.yaw + b.yaw)
   }
end

function shared_tag_peer_pose(my_tag, peer_tag)
   return pose_compose(my_tag, pose_inverse(peer_tag))
end

function init()
   log("crazyflie_apriltag demo initialized")
end

function step()
   for i, tag in ipairs(robot.apriltag) do
      log(string.format("tag[%d] id=%d x=%.3f y=%.3f yaw=%.3f distance=%.3f angle=%.3f",
                        i, tag.id, tag.x, tag.y, tag.yaw, tag.distance, tag.angle))
   end

   -- RAB cooperative fusion belongs here once a RAB actuator/sensor Lua API is enabled.
   -- Message payload shape: sender_id, tag_id, tag_x, tag_y, tag_yaw.
   counter = counter + 1
end

function reset()
   counter = 0
end

function destroy()
end
