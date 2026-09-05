#!/usr/bin/env python3
"""Genere des definitions d'appareils Connect IQ pour compiler en ligne de commande.

Le compilateur `monkeyc` cherche ses appareils dans
~/.Garmin/ConnectIQ/Devices/<id>/compiler.json. Normalement c'est le SDK
Manager (interface graphique, compte Garmin obligatoire) qui les installe.
Ce script reconstruit ces fichiers a partir du catalogue `devices.xml` deja
present dans le SDK (bin/monkeybrains.jar), ce qui permet de compiler sur un
serveur ou dans un conteneur, sans interface graphique.

    python3 garmin/tools/make_devices.py --sdk ~/connectiq-sdk fenix7 fenix7s

Sans argument, seul fenix7 est genere ; `ALL` genere tout le catalogue.
Limite connue : ces definitions suffisent a la compilation et a la signature,
pas au simulateur graphique (qui a besoin des polices et des images fournies
par le SDK Manager).
"""
import argparse
import json
import os
import xml.etree.ElementTree as ET
import zipfile

DEVICES_XML_IN_JAR = 'com/garmin/monkeybrains/devices/devices.xml'


def load_catalog(sdk_path):
    """Lit devices.xml depuis le jar du compilateur fourni avec le SDK."""
    jar = os.path.join(os.path.expanduser(sdk_path), 'bin', 'monkeybrains.jar')
    if not os.path.exists(jar):
        raise SystemExit("monkeybrains.jar introuvable dans %s/bin" % sdk_path)
    with zipfile.ZipFile(jar) as archive:
        return ET.fromstring(archive.read(DEVICES_XML_IN_JAR))

APPMAP = {
    'audio-content-provider-app': 'audioContentProvider',
    'background': 'background',
    'datafield': 'datafield',
    'glance': 'glance',
    'watch-app': 'watchApp',
    'watchface': 'watchFace',
    'widget': 'widget',
    'barrel': 'barrel',
}

def txt(e, tag, default=None):
    c = e.find(tag)
    return c.text.strip() if c is not None and c.text else default

def boolt(e, tag, default=False):
    v = txt(e, tag)
    return default if v is None else v.strip().upper() == 'TRUE'

def build(dev):
    did = dev.get('id')
    res = dev.find('resolution')
    li = dev.find('launcher_icon')
    ci = dev.find('complication_icon')
    pns = []
    for pn in dev.findall('./part_numbers/part_number'):
        langs = []
        for l in pn.findall('./languages/language'):
            langs.append({'code': (l.text or '').strip() or l.get('id') or l.get('code'), 'fontSet': l.get('font_set') or 'ww'})
        pns.append({
            'number': pn.get('number'),
            'firmwareVersion': int(pn.get('firmwareVersion') or 0),
            'connectIQVersion': pn.get('connectIQVersion') or '1.0.0',
            'languages': langs,
        })
    apps = []
    for a in dev.findall('./app_types/app'):
        apps.append({'type': APPMAP.get(a.get('id'), a.get('id')),
                     'memoryLimit': int(a.get('memory_limit')),
                     'prgLimit': int(a.get('prg_limit') or a.get('memory_limit')),
                     'fitSessionMemory': int(a.get('fit_session_memory') or 0)})
    d = {
        'deviceId': did,
        'displayName': dev.get('name'),
        'deviceFamily': dev.get('family'),
        'deviceVersion': pns[0]['connectIQVersion'],
        'worldWidePartNumber': dev.get('part_number'),
        'partNumbers': pns,
        'appTypes': apps,
        'resolution': {'width': int(res.get('width')), 'height': int(res.get('height'))},
        'launcherIcon': {'width': int(li.get('width')), 'height': int(li.get('height'))},
        'bitsPerPixel': int(txt(dev, 'bpp', '8')),
        'pixelFormat': txt(dev, 'pixel_format', 'DEFAULT'),
        'alphaBlendingSupport': boolt(dev, 'alpha_blending_support'),
        'gpuSupport': boolt(dev, 'gpu_support'),
        'screenRotationSupport': boolt(dev, 'screen_rotation_support'),
        'antiAliasedFontSupport': True,
        'enhancedGraphicSupport': boolt(dev, 'gpu_support'),
        'controlBarSupport': False,
        'exportSupport': True,
        'codePageSize': 8192,
        'imageFormats': ['default', 'png', 'jpg'],
        'supportedAPIAnnotations': [],
        'orientation': txt(dev, 'orientation', 'GFX_ORNTN_0'),
        'palette': {'isResourcePalette': False, 'colors': []},
    }
    if ci is not None:
        d['complicationIcon'] = {'width': int(ci.get('width')), 'height': int(ci.get('height'))}
    return d

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('devices', nargs='*', default=['fenix7'],
                        help="identifiants d'appareils, ou ALL pour tout le catalogue")
    parser.add_argument('--sdk', default='~/connectiq-sdk',
                        help='racine du SDK Connect IQ (defaut: ~/connectiq-sdk)')
    parser.add_argument('--out', default='~/.Garmin/ConnectIQ/Devices',
                        help='dossier de destination')
    args = parser.parse_args()

    root = load_catalog(args.sdk)
    out_dir = os.path.expanduser(args.out)
    wanted = args.devices or ['fenix7']
    want_all = wanted == ['ALL']
    written = 0

    for dev in root.iter('device'):
        if not (want_all or dev.get('id') in wanted):
            continue
        try:
            device = build(dev)
        except Exception as error:  # appareil incomplet dans le catalogue
            print('ignore %s (%s)' % (dev.get('id'), error))
            continue
        target = os.path.join(out_dir, dev.get('id'))
        os.makedirs(target, exist_ok=True)
        with open(os.path.join(target, 'compiler.json'), 'w') as handle:
            json.dump(device, handle, indent=2)
        with open(os.path.join(target, 'simulator.json'), 'w') as handle:
            json.dump({'fonts': {'fontSet': 'ww', 'fonts': []}, 'layouts': {}},
                      handle, indent=2)
        written += 1
        print('ecrit', target)

    if written == 0:
        raise SystemExit('aucun appareil genere : verifie les identifiants demandes')


if __name__ == '__main__':
    main()
