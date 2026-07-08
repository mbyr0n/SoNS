pcall(function() os.setlocale("C", "numeric") end)

package.path = "./controller/phase2/common/?.lua;./controller/phase2/qupa/?.lua;" .. package.path

local kinematics = require("qupa_kinematics")

local tick = 0

local params = {
   wheel_base = 0.20,
   max_wheel_speed = 10.0,
   wheel_radius = nil,
   actuator_scale = 100.0,
   k_theta = 2.0,
   max_linear_speed = 0.20,
   max_angular_speed = 1.5,
   stop_heading_error = math.rad(75),
}

local function command_for_tick(current_tick)
   if current_tick <= 40 then
      return kinematics.differential_drive(0.10, 0.0, params), "straight"
   elseif current_tick <= 80 then
      return kinematics.differential_drive(0.0, 0.5, params), "rotate"
   elseif current_tick <= 120 then
      return kinematics.differential_drive(0.10, 0.25, params), "circle"
   elseif current_tick <= 160 then
      local unicycle = kinematics.virtual_to_unicycle(0.0, 0.10, 0.0, params)
      return kinematics.differential_drive(unicycle.v, unicycle.w, params), "lateral_virtual"
   end
   return kinematics.differential_drive(0.0, 0.0, params), "stop"
end

local function apply_stop()
   if robot.wheels then
      robot.wheels.set_velocity(0, 0)
   end
end

function init()
   tick = 0
   apply_stop()
   log("KINEMATICS_TEST init robot=" .. robot.id)
end

function step()
   tick = tick + 1
   local command, mode = command_for_tick(tick)
   kinematics.apply_to_wheels(robot, command)

   if tick % 10 == 0 then
      log(string.format(
         "KINEMATICS_TEST tick=%d mode=%s left=%.3f right=%.3f scale=%.3f",
         tick,
         mode,
         command.left,
         command.right,
         command.scale or 1.0
      ))
   end
end

function reset()
   tick = 0
   apply_stop()
end

function destroy()
   apply_stop()
end
