local M = {}

function M.clamp(value, minimum, maximum)
   return math.max(minimum, math.min(maximum, value))
end

function M.wrap_angle(angle)
   while angle > math.pi do
      angle = angle - 2.0 * math.pi
   end
   while angle < -math.pi do
      angle = angle + 2.0 * math.pi
   end
   return angle
end

function M.norm2(x, y)
   return math.sqrt(x * x + y * y)
end

function M.deadzone(value, threshold)
   if math.abs(value) < threshold then
      return 0.0
   end
   return value
end

return M
