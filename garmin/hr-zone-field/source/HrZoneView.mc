import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

//! Champ de donnees : frequence cardiaque, zone courante (1 a 5) et barre de
//! progression dans la zone. Les zones proviennent du profil utilisateur de la
//! montre, donc de tes propres reglages Garmin Connect.
class HrZoneView extends WatchUi.DataField {

    //! Bornes des zones : [Z1min, Z2min, Z3min, Z4min, Z5min, FCmax].
    private var _zones as Array<Number>?;
    private var _sport as UserProfile.SportHrZone?;

    private var _heartRate as Number? = null;
    private var _zone as Number = 0;
    private var _zoneProgress as Float = 0.0;

    private var _compact as Boolean = false;

    function initialize() {
        DataField.initialize();
        loadZones();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // En affichage 3 ou 4 champs il n'y a la place que pour la valeur.
        _compact = dc.getHeight() < 90;
    }

    //! Appele une fois par seconde par le systeme pendant l'activite.
    function compute(info as Activity.Info) as Void {
        // Le sport peut changer (multisport, transition) : les zones aussi.
        var sport = UserProfile.getCurrentSport();
        if (sport != _sport) {
            loadZones();
        }

        var heartRate = info.currentHeartRate;
        _heartRate = heartRate;
        if (heartRate == null) {
            _zone = 0;
            _zoneProgress = 0.0;
            return;
        }
        updateZone(heartRate);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var background = getBackgroundColor();
        var foreground = (background == Graphics.COLOR_BLACK)
            ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(background, background);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var value = (_heartRate == null) ? "--" : _heartRate.format("%d");

        if (_compact) {
            drawBar(dc, 0, height - 6, width, 6);
            dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, (height - 6) / 2, Graphics.FONT_NUMBER_MEDIUM, value,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var labelY = (height * 0.10).toNumber();
        dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, labelY, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.FieldLabel) as String,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(width / 2, height / 2, Graphics.FONT_NUMBER_THAI_HOT, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var barHeight = 10;
        var barY = height - barHeight - (height * 0.14).toNumber();
        drawBar(dc, (width * 0.12).toNumber(), barY, (width * 0.76).toNumber(), barHeight);

        if (_zone > 0) {
            dc.setColor(zoneColor(_zone), Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, barY + barHeight + 2, Graphics.FONT_XTINY,
                Lang.format(WatchUi.loadResource(Rez.Strings.ZoneShort) as String, [_zone]),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Cinq segments : les zones passees sont pleines, la zone courante se
    //! remplit progressivement.
    private function drawBar(dc as Graphics.Dc, x as Number, y as Number,
                             width as Number, height as Number) as Void {
        var gap = 2;
        var segment = (width - (gap * 4)) / 5;
        for (var i = 1; i <= 5; i++) {
            var left = x + ((i - 1) * (segment + gap));
            dc.setColor(0x2A2A2A, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left, y, segment, height);
            if (_zone < i) {
                continue;
            }
            var fill = (_zone == i) ? (segment * _zoneProgress).toNumber() : segment;
            if (fill < 2) {
                fill = 2;
            }
            dc.setColor(zoneColor(i), Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left, y, fill, height);
        }
    }

    private function updateZone(heartRate as Number) as Void {
        var zones = _zones;
        if (zones == null || zones.size() < 6) {
            _zone = 0;
            _zoneProgress = 0.0;
            return;
        }
        if (heartRate < zones[0]) {
            _zone = 0;
            _zoneProgress = 0.0;
            return;
        }
        for (var i = 5; i >= 1; i--) {
            if (heartRate >= zones[i - 1]) {
                _zone = i;
                var low = zones[i - 1];
                var high = zones[i];
                if (high <= low) {
                    _zoneProgress = 1.0;
                } else {
                    var ratio = (heartRate - low).toFloat() / (high - low).toFloat();
                    _zoneProgress = (ratio > 1.0) ? 1.0 : ratio;
                }
                return;
            }
        }
        _zone = 0;
        _zoneProgress = 0.0;
    }

    private function loadZones() as Void {
        var sport = UserProfile.getCurrentSport();
        _sport = sport;
        var zones = UserProfile.getHeartRateZones(sport);
        _zones = zones;
    }

    private function zoneColor(zone as Number) as Number {
        switch (zone) {
            case 1: return 0x00AAFF;
            case 2: return 0x00AA00;
            case 3: return 0x00FF00;
            case 4: return 0xFFAA00;
            case 5: return 0xFF0000;
            default: return 0x555555;
        }
    }
}
