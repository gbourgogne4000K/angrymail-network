# Connect IQ pour Garmin fenix 7

Trois projets Connect IQ ecrits en Monkey C, cibles sur la famille fenix 7
(`fenix7`, `fenix7s`, `fenix7x` et les variantes Pro / Pro no-wifi) :

| Dossier | Type | Ce que ca fait |
|---|---|---|
| `aurora-watchface/` | cadran | Heure, date, anneau de progression des pas, frequence cardiaque, batterie, notifications. Couleur d'accent et champ de gauche configurables. |
| `interval-timer/` | application | Chronometre par intervalles (effort / recuperation / series) avec decompte, vibrations et bips. Reglable sur la montre ou depuis Garmin Connect. |
| `hr-zone-field/` | champ de donnees | Zone de frequence cardiaque pendant une activite : FC courante, zone 1-5, barre de progression dans la zone. |

Les trois compilent avec le type-checker strict (`-l 3`) pour les huit
identifiants d'appareil de la famille fenix 7.

## Ce qu'il faut pour compiler

1. **Le SDK Connect IQ** (Java 17+ requis) :
   <https://developer.garmin.com/connect-iq/sdk/>. La liste des versions
   telechargeables est aussi publiee en JSON :
   <https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json>.

2. **Une cle de developpeur** — un simple couple RSA, a generer une fois :

   ```bash
   mkdir -p ~/.garmin
   openssl genrsa -out /tmp/dev.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER \
       -in /tmp/dev.pem -out ~/.garmin/developer_key -nocrypt
   ```

   Garde ce fichier : c'est lui qui identifie tes applications sur la boutique
   Connect IQ. Ne le mets pas dans un depot Git.

3. **Les definitions d'appareils.** Normalement elles s'installent avec le SDK
   Manager (interface graphique, compte Garmin obligatoire). Pour compiler sans
   interface graphique — serveur, conteneur, CI — `tools/make_devices.py` les
   reconstruit a partir du catalogue deja present dans le SDK :

   ```bash
   python3 garmin/tools/make_devices.py --sdk ~/connectiq-sdk \
       fenix7 fenix7s fenix7x fenix7pro fenix7spro fenix7xpro
   ```

   Ces definitions suffisent a compiler et signer. Le **simulateur graphique**,
   lui, a besoin des polices et des images d'appareil que seul le SDK Manager
   telecharge.

## Compiler

```bash
CIQ_SDK=~/connectiq-sdk ./garmin/tools/build.sh fenix7
```

Les `.prg` signes arrivent dans `garmin/build/`. Ou, projet par projet :

```bash
cd garmin/aurora-watchface
~/connectiq-sdk/bin/monkeyc -f monkey.jungle -o aurora.prg \
    -y ~/.garmin/developer_key -d fenix7 -w -l 3 -r
```

`-r` produit une version release (sans symboles de debogage), `-l 3` active la
verification de types stricte.

## Installer sur la montre

1. Branche la fenix 7 en USB : elle se monte comme une cle USB.
2. Copie le `.prg` dans `GARMIN/APPS/` sur la montre.
3. Ejecte proprement, debranche. Le cadran apparait dans
   **Menu > Apparence > Cadran de montre**, l'application dans la liste des
   applications, le champ de donnees dans l'ecran de personnalisation d'un
   profil d'activite.

Les reglages (couleur d'accent, durees d'intervalle...) se modifient depuis
l'application **Connect IQ** du telephone, rubrique des applications
installees, ou directement dans le menu de l'application pour le chronometre.

## Tester dans le simulateur

Avec un SDK installe par le SDK Manager :

```bash
~/connectiq-sdk/bin/connectiq &                       # lance le simulateur
~/connectiq-sdk/bin/monkeydo garmin/build/aurora-watchface-fenix7.prg fenix7
```

## Publier sur la boutique Connect IQ

`monkeyc -e -o mon-app.iq ...` produit un paquet `.iq` multi-appareils, a
televerser sur <https://apps.garmin.com/developer/>. Il faut un compte
developpeur Garmin, une description, des captures d'ecran, et **la meme cle de
developpeur** pour chaque mise a jour.

## Limites connues

- Le code a ete verifie par le compilateur (type-checker strict, huit
  appareils) mais **n'a pas tourne** dans le simulateur ni sur une montre
  reelle : les definitions d'appareils generees ici ne permettent pas de lancer
  le simulateur. Le rendu exact (positions au pixel pres) est donc a valider
  chez toi.
- Le cadran laisse les secondes visibles en veille uniquement si la montre
  accepte les mises a jour partielles ; sur un ecran AMOLED
  (`requiresBurnInProtection`), elles sont masquees et l'affichage est allege.
- `System.getTimer()` repart de zero apres environ 24 jours d'allumage : une
  seance de chrono demarree pile a ce moment-la serait faussee.
