pcall(function() os.setlocale("C", "numeric") end)

local step_count = 0

function init()
   step_count = 0
   if robot.colored_blob_omnidirectional_camera then
      robot.colored_blob_omnidirectional_camera.enable()
   end
end

function reset()
   step_count = 0
end

function step()
   step_count = step_count + 1
   if robot.wheels then
      robot.wheels.set_velocity(0, 0)
   end
end

function destroy()
   if robot.wheels then
      robot.wheels.set_velocity(0, 0)
   end
end
