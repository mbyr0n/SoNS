#!/usr/bin/env python3
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ARGOS_FILE = ROOT / "experiments" / "phase2" / "p2_01_qupa_kinematics.argos"
CONTROLLER = ROOT / "controller" / "phase2" / "qupa" / "control_qupa_kinematics_test.lua"


def fail(message):
    print(f"FAIL: {message}")
    return 1


def validate_controller():
    if not CONTROLLER.exists():
        return fail(f"missing {CONTROLLER.relative_to(ROOT)}")

    text = CONTROLLER.read_text(encoding="utf-8")
    required = [
        'require("qupa_kinematics")',
        'kinematics.differential_drive',
        'kinematics.virtual_to_unicycle',
        'kinematics.apply_to_wheels',
        'KINEMATICS_TEST',
        'robot.wheels.set_velocity',
    ]
    for snippet in required:
        if snippet not in text:
            return fail(f"controller missing {snippet!r}")

    if not re.search(r"wheel_base\s*=\s*0\.20", text):
        return fail("controller must define wheel_base = 0.20")
    return 0


def validate_argos():
    if not ARGOS_FILE.exists():
        return fail(f"missing {ARGOS_FILE.relative_to(ROOT)}")

    tree = ET.parse(ARGOS_FILE)
    root = tree.getroot()

    experiment = root.find("./framework/experiment")
    if experiment is None or experiment.attrib.get("ticks_per_second") != "10":
        return fail("experiment must run at ticks_per_second='10'")

    controller = root.find(".//lua_controller[@id='qupa_phase2_kinematics_lua']")
    if controller is None:
        return fail("missing qupa_phase2_kinematics_lua controller")

    script = controller.find("./params")
    if script is None or script.attrib.get("script") != "controller/phase2/qupa/control_qupa_kinematics_test.lua":
        return fail("Qupa controller must use phase2 kinematics test script")

    if controller.find("./actuators/differential_steering") is None:
        return fail("Qupa controller missing differential_steering actuator")
    if controller.find("./sensors/positioning") is None:
        return fail("Qupa controller missing positioning sensor")

    qupa = root.find("./arena/qupa[@id='q101']")
    if qupa is None:
        return fail("missing q101 entity")
    controller_ref = qupa.find("./controller")
    if controller_ref is None or controller_ref.attrib.get("config") != "qupa_phase2_kinematics_lua":
        return fail("q101 must use qupa_phase2_kinematics_lua")
    return 0


def main():
    for validator in (validate_controller, validate_argos):
        result = validator()
        if result != 0:
            return result
    print("PASS: Phase 2 Qupa kinematics ARGoS experiment is valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
