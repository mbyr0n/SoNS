# Phase 2 Controller Base

This directory contains the shared conventions for Phase 2 controllers.

## IDs

- Crazyflie UID: `200`
- Qupa UIDs: `101`, `102`, `103`, `104`, `105`, `106`

Use the same UID for logs, neighbor-table keys, RAB sender IDs, and visual tag IDs whenever possible.

## Timing

Phase 2 assumes `ticks_per_second = 10`, so `DT = 0.1` seconds.

The initial neighbor timeout is 10 ticks, equal to 1 second at 10 Hz.

## RAB Protocol

The Phase 2 RAB packet has 10 bytes:

| Byte | Meaning |
|---:|---|
| 1 | Protocol version |
| 2 | Sender UID |
| 3 | Message type |
| 4 | Robot type |
| 5 | Role |
| 6 | State |
| 7 | Sequence |
| 8 | Signed data A |
| 9 | Signed data B |
| 10 | Reserved |

This protocol is intentionally limited to Phase 2 heartbeat, state, and command messages. Phase 3 concepts such as recruitment, dynamic tree assignment, split, merge, and brain replacement are out of scope here.

`common/protocol.lua` provides pure Lua helpers to build and decode packets:

- `build_packet(fields)` creates a 10-byte RAB payload.
- `decode_packet(data)` converts a RAB data table into named fields.
- `is_valid_packet(decoded)` rejects incomplete packets, wrong protocol versions, invalid sender IDs, and unknown message types.

## Neighbor Table

`common/neighbor_table.lua` stores fresh local neighbors by UID.

Each entry stores `uid`, `robot_type`, `role`, `state`, `range`, `bearing`, `vertical_bearing`, `last_seen`, `sequence`, and `active`.

The table ignores packets from the local robot and marks entries inactive after the configured timeout. It does not reconstruct a global adjacency matrix; that remains a logging or loop-function responsibility.

## Shared Math

`common/math_utils.lua` provides small reusable helpers for controllers:

- `clamp(value, minimum, maximum)`
- `wrap_angle(angle)`
- `norm2(x, y)`
- `deadzone(value, threshold)`

## Qupa Kinematics

`qupa/qupa_kinematics.lua` converts Phase 2 motion commands into differential wheel commands.

- `differential_drive(v_cmd, w_cmd, params)` maps linear/angular velocity to left/right wheel speeds and preserves curvature during saturation.
- `virtual_to_unicycle(vx, vy, yaw_rate, params)` maps a virtual planar command to unicycle motion for the differential Qupa.
- `apply_to_wheels(robot_ref, command)` sends a computed command to `robot.wheels.set_velocity`.
