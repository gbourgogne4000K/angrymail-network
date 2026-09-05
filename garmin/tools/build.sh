#!/usr/bin/env bash
# Compile les trois projets Connect IQ pour un ou plusieurs appareils.
#
#   CIQ_SDK=~/connectiq-sdk ./garmin/tools/build.sh              # fenix7
#   CIQ_SDK=~/connectiq-sdk ./garmin/tools/build.sh fenix7 fenix7x
#
# Variables :
#   CIQ_SDK  racine du SDK Connect IQ            (defaut: ~/connectiq-sdk)
#   CIQ_KEY  cle privee de developpeur           (defaut: ~/.garmin/developer_key)
#   OUT_DIR  dossier des .prg produits           (defaut: garmin/build)
set -euo pipefail

SDK="${CIQ_SDK:-$HOME/connectiq-sdk}"
KEY="${CIQ_KEY:-$HOME/.garmin/developer_key}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT_DIR:-$HERE/build}"
PROJECTS=(aurora-watchface interval-timer hr-zone-field)
DEVICES=("$@")
if [ ${#DEVICES[@]} -eq 0 ]; then
    DEVICES=(fenix7)
fi

if [ ! -x "$SDK/bin/monkeyc" ]; then
    echo "SDK introuvable : $SDK/bin/monkeyc (voir garmin/README.md)" >&2
    exit 1
fi
if [ ! -f "$KEY" ]; then
    echo "Cle developpeur introuvable : $KEY" >&2
    echo "Creer une cle :" >&2
    echo "  openssl genrsa -out /tmp/dev.pem 4096" >&2
    echo "  openssl pkcs8 -topk8 -inform PEM -outform DER -in /tmp/dev.pem -out $KEY -nocrypt" >&2
    exit 1
fi

mkdir -p "$OUT"
status=0
for device in "${DEVICES[@]}"; do
    for project in "${PROJECTS[@]}"; do
        target="$OUT/${project}-${device}.prg"
        printf '%-18s %-12s ' "$project" "$device"
        if (cd "$HERE/$project" && "$SDK/bin/monkeyc" \
                -f monkey.jungle -o "$target" -y "$KEY" -d "$device" \
                -w -l 3 -r) >/tmp/ciq-build.log 2>&1; then
            echo "OK  -> ${target#"$HERE"/}"
        else
            echo "ECHEC"
            grep -v '^Picked up' /tmp/ciq-build.log >&2 || true
            status=1
        fi
    done
done
exit $status
