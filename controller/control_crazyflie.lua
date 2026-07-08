pcall(function() os.setlocale("C", "numeric") end)

local counter = 0
local NO_DETECTION_LOG_PERIOD = 10

local QUPA_TAG_IDS = {
   [101] = true,
   [102] = true,
   [103] = true,
   [104] = true,
   [105] = true,
   [106] = true,
   [107] = true,
   [108] = true,
}

function is_qupa_tag(tag_id)
   return QUPA_TAG_IDS[tag_id] == true
end

function init()
   counter = 0
   robot.quadrotor.set_linear_velocity(0.0, 0.0, 0.0)
   robot.quadrotor.set_rotational_speed(0.0)
   log("Crazyflie started in hover and tag detection test")
end

function step()
   counter = counter + 1

   robot.quadrotor.set_linear_velocity(0.0, 0.0, 0.0)
   robot.quadrotor.set_rotational_speed(0.0)

   if counter % NO_DETECTION_LOG_PERIOD == 0 then
      local p = robot.positioning.position
      log(string.format(
         "Crazyflie position x=%.3f y=%.3f z=%.3f",
         p.x, p.y, p.z
      ))

      local qupa_detections = 0
      for i, tag in ipairs(robot.apriltag) do
         if is_qupa_tag(tag.id) then
            qupa_detections = qupa_detections + 1
            log(string.format(
               "QUPA tag detected id=%d x=%.3f y=%.3f yaw=%.3f distance=%.3f angle=%.3f",
               tag.id,
               tag.x,
               tag.y,
               tag.yaw,
               tag.distance,
               tag.angle
            ))
         else
            log(string.format(
               "non-QUPA tag ignored id=%d x=%.3f y=%.3f yaw=%.3f distance=%.3f angle=%.3f",
               tag.id,
               tag.x,
               tag.y,
               tag.yaw,
               tag.distance,
               tag.angle
            ))
         end
      end

      if qupa_detections == 0 then
         log("no QUPA tags detected")
      end
   end
end

function reset()
   counter = 0
end

function destroy()
   robot.quadrotor.set_linear_velocity(0.0, 0.0, 0.0)
   robot.quadrotor.set_rotational_speed(0.0)
end
