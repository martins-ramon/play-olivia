#!/usr/bin/env python3
"""Read devicectl output and resolve its device UUID to Xcode's hardware UDID."""
import json
import sys

with open(sys.argv[1]) as handle:
    devices = json.load(handle).get("result", {}).get("devices", [])

# Xcode 27 also reports simulators through CoreDevice. This installer targets
# physical iPads only; older Xcode versions may omit the reality field.
devices = [device for device in devices
           if device.get("hardwareProperties", {}).get("reality") != "simulated"]

if len(sys.argv) == 2:
    print("\nIdentificadores físicos para instalação:")
    for device in devices:
        properties = device.get("deviceProperties", {})
        hardware = device.get("hardwareProperties", {})
        print(f"{properties.get('name', 'Dispositivo')} — {hardware.get('udid', 'UDID indisponível')}")
    if not devices:
        print("Nenhum dispositivo encontrado. Conecte, desbloqueie e pareie o iPad no Xcode.")
    sys.exit(0)

requested = sys.argv[2]
matches = [device for device in devices if requested in (
    device.get("identifier"), device.get("hardwareProperties", {}).get("udid"))]
if len(matches) != 1:
    sys.exit("iPad não identificado de forma única. Use --list, conecte/desbloqueie o iPad e copie seu identificador.")
hardware = matches[0].get("hardwareProperties", {})
product = hardware.get("productType", "")
if product and not product.startswith("iPad"):
    sys.exit(f"O dispositivo selecionado não é um iPad ({product}). Confira o identificador.")
udid = hardware.get("udid")
if not udid:
    sys.exit("O Xcode não informou o UDID do iPad. Conclua seu pareamento no Xcode e tente novamente.")
print(udid)
