package.path = "./controller/phase2/common/?.lua;" .. package.path

local math_utils = require("math_utils")

local function fail(message)
   io.stderr:write("FAIL: " .. message .. "\n")
   os.exit(1)
end

local function assert_close(actual, expected, tolerance, message)
   if math.abs(actual - expected) > tolerance then
      fail(string.format("%s: expected %.12f, got %.12f", message, expected, actual))
   end
end

if math_utils.clamp(4, -2, 2) ~= 2 then
   fail("clamp must cap values above maximum")
end

if math_utils.clamp(-4, -2, 2) ~= -2 then
   fail("clamp must cap values below minimum")
end

if math_utils.clamp(1, -2, 2) ~= 1 then
   fail("clamp must preserve values inside range")
end

assert_close(math_utils.wrap_angle(3 * math.pi), math.pi, 1e-9, "wrap_angle(3*pi)")
assert_close(math_utils.wrap_angle(-3 * math.pi), -math.pi, 1e-9, "wrap_angle(-3*pi)")
assert_close(math_utils.norm2(3, 4), 5, 1e-9, "norm2(3,4)")

if math_utils.deadzone(0.01, 0.03) ~= 0.0 then
   fail("deadzone must zero values inside threshold")
end

if math_utils.deadzone(-0.01, 0.03) ~= 0.0 then
   fail("deadzone must zero negative values inside threshold")
end

if math_utils.deadzone(0.05, 0.03) ~= 0.05 then
   fail("deadzone must preserve values outside threshold")
end

print("PASS: Phase 2 math utilities are valid")
