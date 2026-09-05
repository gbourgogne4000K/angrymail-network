import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Cadran numerique : heure au centre, anneau de progression des pas,
//! date en haut, trois indicateurs en bas.
class AuroraView extends WatchUi.WatchFace {

    private const COLOR_DIM = 0x555555;
    private const COLOR_TRACK = 0x2A2A2A;
    private const RING_PEN = 7;
    private const SECONDS_GAP = 5;

    private var _w as Number = 260;
    private var _h as Number = 260;
    private var _cx as Number = 130;
    private var _cy as Number = 130;
    private var _radius as Number = 130;

    private var _sleeping as Boolean = false;
    private var _partialSupported as Boolean = false;
    private var _burnInProtect as Boolean = false;

    private var _timeFont as Graphics.FontType = Graphics.FONT_NUMBER_THAI_HOT;
    private var _secFont as Graphics.FontType = Graphics.FONT_MEDIUM;

    // Zone redessinee seconde par seconde : [x, y, largeur, hauteur].
    private var _secClip as Array<Number>? = null;

    // Reglages utilisateur, relus a chaque changement.
    private var _accent as Number = 0x00AAFF;
    private var _showSeconds as Boolean = true;
    private var _showHeartRate as Boolean = true;
    private var _leftField as Number = 0;

    function initialize() {
        WatchFace.initialize();
        _partialSupported = (WatchUi.WatchFace has :onPartialUpdate);
        loadSettings();
    }

    //! Relit les proprietes de l'application (appele au demarrage et depuis
    //! AuroraApp.onSettingsChanged).
    function loadSettings() as Void {
        _accent = Settings.accent("AccentColor");
        _showSeconds = Settings.boolean("ShowSeconds", true);
        _showHeartRate = Settings.boolean("ShowHeartRate", true);
        _leftField = Settings.number("LeftField", 0);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = _w / 2;
        _cy = _h / 2;
        _radius = (_w < _h ? _w : _h) / 2;

        var deviceSettings = System.getDeviceSettings();
        if (deviceSettings has :requiresBurnInProtection) {
            var flag = deviceSettings.requiresBurnInProtection;
            if (flag instanceof Lang.Boolean) {
                _burnInProtect = flag;
            }
        }

        // Sur les petits boitiers (fenix 7S), la plus grosse police deborde :
        // on redescend d'un cran tant que "88:88" ne rentre pas.
        _timeFont = Graphics.FONT_NUMBER_THAI_HOT;
        if (dc.getTextWidthInPixels("88:88", _timeFont) > _w - 40) {
            _timeFont = Graphics.FONT_NUMBER_HOT;
        }
        if (dc.getTextWidthInPixels("88:88", _timeFont) > _w - 20) {
            _timeFont = Graphics.FONT_NUMBER_MEDIUM;
        }
        _secClip = null;
    }

    function onShow() as Void {
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (dc has :clearClip) {
            dc.clearClip();
        }
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var lowPower = _sleeping && _burnInProtect;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var activityInfo = ActivityMonitor.getInfo();

        if (!lowPower) {
            drawStepsRing(dc, activityInfo);
            drawStatusRow(dc);
        }
        drawDate(dc);
        drawTime(dc, lowPower);
        if (!lowPower) {
            drawBottomRow(dc, activityInfo);
        }
    }

    //! Mise a jour partielle : seules les secondes sont redessinees, dans un
    //! rectangle minimal pour rester dans le budget d'energie de la montre.
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        var clip = _secClip;
        if (!_showSeconds || _burnInProtect || clip == null) {
            return;
        }
        dc.setClip(clip[0], clip[1], clip[2], clip[3]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(clip[0], clip[1], _secFont,
            System.getClockTime().sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.clearClip();
    }

    // --- blocs de dessin -------------------------------------------------

    private function drawStepsRing(dc as Graphics.Dc, info as ActivityMonitor.Info) as Void {
        var radius = _radius - (RING_PEN / 2) - 1;
        dc.setPenWidth(RING_PEN);
        dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_cx, _cy, radius);

        var ratio = goalRatio(info);
        if (ratio <= 0.0) {
            return;
        }
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        if (ratio >= 0.999) {
            dc.drawCircle(_cx, _cy, radius);
            return;
        }
        // 90 deg = midi ; on avance dans le sens des aiguilles.
        var end = 90.0 - (359.0 * ratio);
        if (end < 0.0) {
            end += 360.0;
        }
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, end.toNumber());
    }

    private function goalRatio(info as ActivityMonitor.Info) as Float {
        var steps = info.steps;
        var goal = info.stepGoal;
        if (steps == null || goal == null || goal <= 0) {
            return 0.0;
        }
        var ratio = steps.toFloat() / goal.toFloat();
        return (ratio > 1.0) ? 1.0 : ratio;
    }

    //! Ligne du haut : notifications, alarme, etat du telephone.
    private function drawStatusRow(dc as Graphics.Dc) as Void {
        var settings = System.getDeviceSettings();
        var parts = [] as Array<String>;

        var notifications = settings.notificationCount;
        if (notifications != null && notifications > 0) {
            parts.add(Lang.format("$1$ msg", [notifications]));
        }
        var alarms = settings.alarmCount;
        if (alarms != null && alarms > 0) {
            parts.add(Lang.format("$1$ alr", [alarms]));
        }
        if (settings.phoneConnected) {
            parts.add("BT");
        }
        if (parts.size() == 0) {
            return;
        }

        var text = parts[0];
        for (var i = 1; i < parts.size(); i++) {
            text = text + "  " + parts[i];
        }
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.11).toNumber(), Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawDate(dc as Graphics.Dc) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var text = Lang.format("$1$ $2$ $3$", [now.day_of_week, now.day, now.month]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.20).toNumber(), Graphics.FONT_TINY, text.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawTime(dc as Graphics.Dc, lowPower as Boolean) as Void {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        var text = Lang.format("$1$:$2$", [hour.format("%02d"), clock.min.format("%02d")]);

        var timeWidth = dc.getTextWidthInPixels(text, _timeFont);
        var timeHeight = dc.getFontHeight(_timeFont);

        // La place des secondes est reservee meme quand elles ne sont pas
        // affichees, pour que l'heure ne saute pas en mode economie.
        var secWidth = 0;
        var secHeight = 0;
        if (_showSeconds && !_burnInProtect) {
            secWidth = dc.getTextWidthInPixels("88", _secFont) + SECONDS_GAP;
            secHeight = dc.getFontHeight(_secFont);
        }

        var left = _cx - ((timeWidth + secWidth) / 2);
        var top = _cy - (timeHeight / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, top, _timeFont, text, Graphics.TEXT_JUSTIFY_LEFT);

        if (secWidth == 0) {
            _secClip = null;
            return;
        }

        var secX = left + timeWidth + SECONDS_GAP;
        var secY = top + timeHeight - secHeight;
        _secClip = [secX, secY, secWidth, secHeight] as Array<Number>;

        // Hors mise a jour partielle on dessine les secondes ici ; en sommeil
        // sans support partiel, on laisse la place vide plutot que fausse.
        if (!lowPower && (!_sleeping || _partialSupported)) {
            dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
            dc.drawText(secX, secY, _secFont, clock.sec.format("%02d"),
                Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function drawBottomRow(dc as Graphics.Dc, info as ActivityMonitor.Info) as Void {
        var labelY = (_h * 0.685).toNumber();
        var valueY = labelY + dc.getFontHeight(Graphics.FONT_XTINY) - 2;

        drawCell(dc, (_w * 0.26).toNumber(), labelY, valueY,
            leftFieldLabel(), leftFieldValue(info), Graphics.COLOR_WHITE);

        var heartRate = currentHeartRate();
        if (_showHeartRate) {
            drawCell(dc, _cx, labelY, valueY, "FC",
                (heartRate == null) ? "--" : heartRate.format("%d"), _accent);
        }

        var battery = System.getSystemStats().battery;
        drawCell(dc, (_w * 0.74).toNumber(), labelY, valueY, "BAT",
            battery.format("%d") + "%", batteryColor(battery));
    }

    private function drawCell(dc as Graphics.Dc, x as Number, labelY as Number,
                              valueY as Number, label as String, value as String,
                              color as Number) as Void {
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, labelY, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, valueY, Graphics.FONT_TINY, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function batteryColor(battery as Float) as Number {
        if (battery <= 10.0) {
            return Graphics.COLOR_RED;
        }
        if (battery <= 25.0) {
            return Graphics.COLOR_ORANGE;
        }
        return Graphics.COLOR_WHITE;
    }

    //! FC courante : Activity d'abord (valeur instantanee), sinon le dernier
    //! echantillon de l'historique quand il est disponible.
    private function currentHeartRate() as Number? {
        var activity = Activity.getActivityInfo();
        if (activity != null && activity.currentHeartRate != null) {
            return activity.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var iterator = ActivityMonitor.getHeartRateHistory(1, true);
            if (iterator != null) {
                var sample = iterator.next();
                if (sample != null && sample.heartRate != null
                        && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate;
                }
            }
        }
        return null;
    }

    private function leftFieldLabel() as String {
        switch (_leftField) {
            case 1: return "KCAL";
            case 2: return "KM";
            case 3: return "ETAGES";
            case 4: return "ACTIF";
            default: return "PAS";
        }
    }

    private function leftFieldValue(info as ActivityMonitor.Info) as String {
        if (_leftField == 1) {
            var calories = info.calories;
            return (calories == null) ? "--" : calories.format("%d");
        }
        if (_leftField == 2) {
            var distance = info.distance;
            return (distance == null) ? "--" : (distance / 100000.0).format("%.2f");
        }
        if (_leftField == 3) {
            if (!(info has :floorsClimbed)) {
                return "--";
            }
            var floors = info.floorsClimbed;
            return (floors == null) ? "--" : floors.format("%d");
        }
        if (_leftField == 4) {
            if (!(info has :activeMinutesWeek)) {
                return "--";
            }
            var active = info.activeMinutesWeek;
            return (active == null) ? "--" : active.total.format("%d");
        }
        var steps = info.steps;
        return (steps == null) ? "--" : steps.format("%d");
    }
}
