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
