package.path = "./controller/phase2/common/?.lua;./controller/phase2/qupa/?.lua;" .. package.path

local kinematics = require("qupa_kinematics")

local function fail(message)
   io.stderr:write("FAIL: " .. message .. "\n")
   os.exit(1)
end

local function assert_close(actual, expected, tolerance, message)
   if math.abs(actual - expected) > tolerance then
      fail(string.format("%s: expected %.12f, got %.12f", message, expected, actual))
   end
end

local params = {
   wheel_base = 0.20,
   max_wheel_speed = 1.0,
   wheel_radius = nil,
   actuator_scale = 1.0,
   k_theta = 2.0,
   max_linear_speed = 0.5,
   max_angular_speed = 2.0,
   stop_heading_error = math.rad(75),
}

local straight = kinematics.differential_drive(0.10, 0.0, params)
assert_close(straight.left, 0.10, 1e-9, "straight left wheel")
assert_close(straight.right, 0.10, 1e-9, "straight right wheel")

local rotate = kinematics.differential_drive(0.0, 0.5, params)
assert_close(rotate.left, -0.05, 1e-9, "rotate left wheel")
assert_close(rotate.right, 0.05, 1e-9, "rotate right wheel")

local circle = kinematics.differential_drive(0.10, 0.25, params)
assert_close(circle.left, 0.075, 1e-9, "circle left wheel")
assert_close(circle.right, 0.125, 1e-9, "circle right wheel")

local saturated = kinematics.differential_drive(2.0, 0.0, params)
assert_close(saturated.left, 1.0, 1e-9, "saturated left wheel")
assert_close(saturated.right, 1.0, 1e-9, "saturated right wheel")
assert_close(saturated.scale, 0.5, 1e-9, "saturation scale")

local lateral = kinematics.virtual_to_unicycle(0.0, 0.10, 0.0, params)
assert_close(lateral.v, 0.0, 1e-9, "lateral command must stop forward motion while heading error is large")
assert_close(lateral.w, 2.0, 1e-9, "lateral command angular speed must saturate")

local forward = kinematics.virtual_to_unicycle(0.10, 0.0, 0.0, params)
assert_close(forward.v, 0.10, 1e-9, "forward virtual command linear speed")
assert_close(forward.w, 0.0, 1e-9, "forward virtual command angular speed")

local applied_left = nil
local applied_right = nil
local robot_ref = {
   wheels = {
      set_velocity = function(left, right)
         applied_left = left
         applied_right = right
      end,
   },
}
kinematics.apply_to_wheels(robot_ref, {left = -0.2, right = 0.3})
assert_close(applied_left, -0.2, 1e-9, "applied left wheel")
assert_close(applied_right, 0.3, 1e-9, "applied right wheel")

print("PASS: Phase 2 Qupa kinematics are valid")
