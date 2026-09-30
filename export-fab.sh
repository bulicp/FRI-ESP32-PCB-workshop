#!/usr/bin/env bash
# Uporaba: ./export-fab.sh priimek
set -euo pipefail
NAME=${1:?Podaj priimek}
PCB=FRI-ESP32-C3-MINI.kicad_pcb
SCH=FRI-ESP32-C3-MINI.kicad_sch
OUT=fab
rm -rf "$OUT" && mkdir -p "$OUT"

# 1) DRC (+ ujemanje s shemo) – ustavi se ob napakah
kicad-cli pcb drc --schematic-parity --severity-error --exit-code-violations \
  -o drc-report.rpt "$PCB"

# 2) Gerberji (+ .gbrjob se ustvari samodejno)
kicad-cli pcb export gerbers -o "$OUT/" \
  --layers "F.Cu,In1.Cu,In2.Cu,B.Cu,F.Mask,B.Mask,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,Edge.Cuts" \
  --subtract-soldermask "$PCB"

# 3) Vrtine: ločeno PTH/NPTH, v mm, z mapo vrtin
kicad-cli pcb export drill -o "$OUT/" --format excellon --excellon-units mm \
  --excellon-separate-th --generate-map --map-format gerberx2 "$PCB"

# 4) Pick-and-place za obe strani
kicad-cli pcb export pos -o "$OUT/${NAME}-pos.csv" \
  --format csv --units mm --side both --exclude-dnp "$PCB"

# 5) BOM
kicad-cli sch export bom -o "$OUT/${NAME}-bom.csv" \
  --fields 'Reference,Value,Footprint,${QUANTITY}' \
  --group-by 'Value,Footprint' --exclude-dnp "$SCH"

# 6) ZIP za oddajo
(cd "$OUT" && zip -q "../${NAME}-FRI-ESP32-C3-MINI-fab.zip" ./*)
echo "Datotek v fab/: $(ls "$OUT" | wc -l)"