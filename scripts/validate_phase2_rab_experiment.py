#!/usr/bin/env python3
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ARGOS_FILE = ROOT / "experiments" / "phase2" / "p2_03_neighbor_communication.argos"
QUPA_CONTROLLER = ROOT / "controller" / "phase2" / "qupa" / "control_qupa_rab_test.lua"
CRAZYFLIE_CONTROLLER = ROOT / "controller" / "phase2" / "crazyflie" / "control_crazyflie_rab_test.lua"
EXPECTED_QUPAS = {"q101", "q102", "q103", "q104"}
EXPECTED_MARKERS = {"101", "102", "103", "104"}


def fail(message):
    print(f"FAIL: {message}")
    return 1


def validate_qupa_controller():
    if not QUPA_CONTROLLER.exists():
        return fail(f"missing {QUPA_CONTROLLER.relative_to(ROOT)}")

    text = QUPA_CONTROLLER.read_text(encoding="utf-8")
    required = [
        'require("constants")',
        'require("protocol")',
        'require("neighbor_table")',
        'protocol.build_packet',
        'protocol.decode_packet',
        'neighbor_table.update_from_packet',
        'neighbor_table.mark_stale',
        'robot.range_and_bearing.set_data',
        'NEIGHBORS',
    ]
    for snippet in required:
        if snippet not in text:
            return fail(f"controller missing {snippet!r}")

    if re.search(r"robot\.wheels\.set_velocity\(\s*(?!0(?:\.0+)?\s*,\s*0(?:\.0+)?\s*\))[^)]*\)", text):
        return fail("RAB communication test controller must keep Qupas stationary")

    return 0


def validate_crazyflie_controller():
    if not CRAZYFLIE_CONTROLLER.exists():
        return fail(f"missing {CRAZYFLIE_CONTROLLER.relative_to(ROOT)}")

    text = CRAZYFLIE_CONTROLLER.read_text(encoding="utf-8")
    required = [
        'require("constants")',
        'require("protocol")',
        'require("neighbor_table")',
        'constants.CRAZYFLIE_UID',
        'protocol.build_packet',
        'protocol.decode_packet',
        'neighbor_table.update_from_packet',
        'neighbor_table.mark_stale',
        'robot.range_and_bearing.set_data',
        'robot.quadrotor.set_linear_velocity(0.0, 0.0, 0.0)',
        'robot.quadrotor.set_rotational_speed(0.0)',
        'NEIGHBORS',
    ]
    for snippet in required:
        if snippet not in text:
            return fail(f"Crazyflie controller missing {snippet!r}")
    return 0


def validate_argos():
    if not ARGOS_FILE.exists():
        return fail(f"missing {ARGOS_FILE.relative_to(ROOT)}")

    tree = ET.parse(ARGOS_FILE)
    root = tree.getroot()

    experiment = root.find("./framework/experiment")
    if experiment is None or experiment.attrib.get("ticks_per_second") != "10":
        return fail("experiment must run at ticks_per_second='10'")

    controller = root.find(".//lua_controller[@id='qupa_phase2_rab_lua']")
    if controller is None:
        return fail("missing qupa_phase2_rab_lua controller")

    script = controller.find("./params")
    if script is None or script.attrib.get("script") != "controller/phase2/qupa/control_qupa_rab_test.lua":
        return fail("Qupa controller must use phase2 RAB test script")

    if controller.find("./actuators/range_and_bearing") is None:
        return fail("Qupa controller missing range_and_bearing actuator")
    rab_sensor = controller.find("./sensors/range_and_bearing")
    if rab_sensor is None or rab_sensor.attrib.get("medium") != "rab":
        return fail("Qupa controller missing range_and_bearing sensor on rab medium")

    crazy_controller = root.find(".//lua_controller[@id='crazyflie_phase2_rab_lua']")
    if crazy_controller is None:
        return fail("missing crazyflie_phase2_rab_lua controller")

    crazy_script = crazy_controller.find("./params")
    if crazy_script is None or crazy_script.attrib.get("script") != "controller/phase2/crazyflie/control_crazyflie_rab_test.lua":
        return fail("Crazyflie controller must use phase2 RAB test script")

    if crazy_controller.find("./actuators/range_and_bearing") is None:
        return fail("Crazyflie controller missing range_and_bearing actuator")
    crazy_rab_sensor = crazy_controller.find("./sensors/range_and_bearing")
    if crazy_rab_sensor is None or crazy_rab_sensor.attrib.get("medium") != "rab":
        return fail("Crazyflie controller missing range_and_bearing sensor on rab medium")

    medium = root.find("./media/range_and_bearing[@id='rab']")
    if medium is None:
        return fail("missing rab medium")

    qupas = root.findall("./arena/qupa")
    ids = {q.attrib.get("id", "") for q in qupas}
    markers = {q.attrib.get("marker_id", "") for q in qupas}
    if ids != EXPECTED_QUPAS:
        return fail(f"expected Qupas {sorted(EXPECTED_QUPAS)}, found {sorted(ids)}")
    if markers != EXPECTED_MARKERS:
        return fail(f"expected marker IDs {sorted(EXPECTED_MARKERS)}, found {sorted(markers)}")

    for qupa in qupas:
        if qupa.attrib.get("rab_range") != "3.0":
            return fail(f"{qupa.attrib.get('id')} must set rab_range='3.0'")
        if qupa.attrib.get("rab_data_size") != "10":
            return fail(f"{qupa.attrib.get('id')} must set rab_data_size='10'")
        controller_ref = qupa.find("./controller")
        if controller_ref is None or controller_ref.attrib.get("config") != "qupa_phase2_rab_lua":
            return fail(f"{qupa.attrib.get('id')} must use qupa_phase2_rab_lua")

    crazyflie = root.find("./arena/crazyflie[@id='cf200']")
    if crazyflie is None:
        return fail("missing Crazyflie entity cf200")
    crazy_ref = crazyflie.find("./controller")
    if crazy_ref is None or crazy_ref.attrib.get("config") != "crazyflie_phase2_rab_lua":
        return fail("cf200 must use crazyflie_phase2_rab_lua")
    if crazyflie.attrib.get("rab_range") != "3.0":
        return fail("cf200 must set rab_range='3.0'")
    if crazyflie.attrib.get("rab_data_size") != "10":
        return fail("cf200 must set rab_data_size='10'")

    return 0


def main():
    for validator in (validate_qupa_controller, validate_crazyflie_controller, validate_argos):
        result = validator()
        if result != 0:
            return result
    print("PASS: Phase 2 RAB ARGoS experiment is valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
