#!/usr/bin/env python3
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
CONSTANTS = ROOT / "controller" / "phase2" / "common" / "constants.lua"
PROTOCOL = ROOT / "controller" / "phase2" / "common" / "protocol.lua"
MATH_UTILS = ROOT / "controller" / "phase2" / "common" / "math_utils.lua"
README = ROOT / "controller" / "phase2" / "README.md"


def fail(message):
    print(f"FAIL: {message}")
    return 1


def read_required(path):
    if not path.exists():
        raise FileNotFoundError(path)
    return path.read_text(encoding="utf-8")


def require(pattern, text, message):
    if not re.search(pattern, text):
        return fail(message)
    return 0


def validate_constants():
    try:
        text = read_required(CONSTANTS)
    except FileNotFoundError:
        return fail(f"missing {CONSTANTS.relative_to(ROOT)}")

    checks = [
        (r"CRAZYFLIE_UID\s*=\s*200\b", "Crazyflie UID must be 200"),
        (r"QUPA_UIDS\s*=\s*\{\s*101\s*,\s*102\s*,\s*103\s*,\s*104\s*,\s*105\s*,\s*106\s*,?\s*\}", "Qupa UIDs must be 101 through 106"),
        (r"DT\s*=\s*0\.1\b", "DT must be 0.1 seconds"),
        (r"NEIGHBOR_TIMEOUT_TICKS\s*=\s*10\b", "neighbor timeout must start at 10 ticks"),
        (r"QUPA\s*=\s*1\b", "robot type QUPA must be 1"),
        (r"CRAZYFLIE\s*=\s*2\b", "robot type CRAZYFLIE must be 2"),
        (r"LEADER\s*=\s*1\b", "role LEADER must be 1"),
        (r"FOLLOWER\s*=\s*2\b", "role FOLLOWER must be 2"),
    ]
    for pattern, message in checks:
        result = require(pattern, text, message)
        if result:
            return result
    return 0


def validate_protocol():
    try:
        text = read_required(PROTOCOL)
    except FileNotFoundError:
        return fail(f"missing {PROTOCOL.relative_to(ROOT)}")

    checks = [
        (r"PACKET_SIZE\s*=\s*10\b", "RAB packet size must be 10 bytes"),
        (r"VERSION\s*=\s*2\b", "protocol version must be 2"),
        (r"VERSION\s*=\s*1\b", "byte 1 must be VERSION"),
        (r"SENDER_UID\s*=\s*2\b", "byte 2 must be SENDER_UID"),
        (r"MESSAGE_TYPE\s*=\s*3\b", "byte 3 must be MESSAGE_TYPE"),
        (r"ROBOT_TYPE\s*=\s*4\b", "byte 4 must be ROBOT_TYPE"),
        (r"ROLE\s*=\s*5\b", "byte 5 must be ROLE"),
        (r"STATE\s*=\s*6\b", "byte 6 must be STATE"),
        (r"SEQUENCE\s*=\s*7\b", "byte 7 must be SEQUENCE"),
        (r"DATA_A\s*=\s*8\b", "byte 8 must be DATA_A"),
        (r"DATA_B\s*=\s*9\b", "byte 9 must be DATA_B"),
        (r"RESERVED\s*=\s*10\b", "byte 10 must be RESERVED"),
        (r"function\s+M\.encode_signed\(value, max_abs\)", "encode_signed(value, max_abs) must exist"),
        (r"function\s+M\.decode_signed\(byte, max_abs\)", "decode_signed(byte, max_abs) must exist"),
    ]
    for pattern, message in checks:
        result = require(pattern, text, message)
        if result:
            return result

    forbidden = ["RECRUIT", "ACCEPT", "SPLIT", "MERGE", "BRAIN_REPLACE"]
    for name in forbidden:
        if name in text:
            return fail(f"Phase 3 protocol name {name} must not appear in Phase 2 protocol")
    return 0


def validate_math_utils():
    try:
        text = read_required(MATH_UTILS)
    except FileNotFoundError:
        return fail(f"missing {MATH_UTILS.relative_to(ROOT)}")

    checks = [
        (r"function\s+M\.clamp\(value, minimum, maximum\)", "clamp(value, minimum, maximum) must exist"),
        (r"function\s+M\.wrap_angle\(angle\)", "wrap_angle(angle) must exist"),
        (r"function\s+M\.norm2\(x, y\)", "norm2(x, y) must exist"),
        (r"function\s+M\.deadzone\(value, threshold\)", "deadzone(value, threshold) must exist"),
    ]
    for pattern, message in checks:
        result = require(pattern, text, message)
        if result:
            return result
    return 0


def validate_readme():
    try:
        text = read_required(README)
    except FileNotFoundError:
        return fail(f"missing {README.relative_to(ROOT)}")

    for snippet in ("UID", "DT = 0.1", "10 bytes", "Phase 3", "math_utils.lua"):
        if snippet not in text:
            return fail(f"Phase 2 README must mention {snippet!r}")
    return 0


def main():
    for validator in (validate_constants, validate_protocol, validate_math_utils, validate_readme):
        result = validator()
        if result != 0:
            return result
    print("PASS: Phase 2 conventions are valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
