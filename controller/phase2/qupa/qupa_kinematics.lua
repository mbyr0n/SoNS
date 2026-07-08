local math_utils = require("math_utils")

local M = {}

local function actuator_units(wheel_linear_speed, params)
   if params.wheel_radius then
      return wheel_linear_speed / params.wheel_radius
   end
   return wheel_linear_speed * (params.actuator_scale or 1.0)
end

function M.differential_drive(v_cmd, w_cmd, params)
   local wheel_base = params.wheel_base
   local left = v_cmd - 0.5 * wheel_base * w_cmd
   local right = v_cmd + 0.5 * wheel_base * w_cmd

   left = actuator_units(left, params)
   right = actuator_units(right, params)

   local scale = 1.0
   local maximum = math.max(math.abs(left), math.abs(right))
   if maximum > params.max_wheel_speed then
      scale = params.max_wheel_speed / maximum
      left = left * scale
      right = right * scale
   end

   return {
      left = left,
      right = right,
      scale = scale,
   }
end

function M.virtual_to_unicycle(vx, vy, yaw_rate, params)
   local heading_error = math.atan2(vy, vx)
   local speed = math_utils.norm2(vx, vy)
   local v_cmd = speed * math.cos(heading_error)
   local w_cmd = params.k_theta * heading_error + yaw_rate

   if math.abs(heading_error) > params.stop_heading_error then
      v_cmd = 0.0
   end

   v_cmd = math_utils.clamp(v_cmd, -params.max_linear_speed, params.max_linear_speed)
   w_cmd = math_utils.clamp(w_cmd, -params.max_angular_speed, params.max_angular_speed)

   return {
      v = v_cmd,
      w = w_cmd,
      heading_error = heading_error,
   }
end

function M.apply_to_wheels(robot_ref, command)
   robot_ref.wheels.set_velocity(command.left, command.right)
end

return M
