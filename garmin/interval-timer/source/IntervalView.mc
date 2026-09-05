import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

//! Ecran principal : anneau de progression de la phase, decompte au centre,
//! serie en cours et temps total en bas.
class IntervalView extends WatchUi.View {

    private const RING_PEN = 10;
    private const COLOR_DIM = 0x555555;
    private const COLOR_TRACK = 0x2A2A2A;

    private var _session as IntervalSession;
    private var _timer as Timer.Timer?;
    private var _lastBeepSecond as Number = -1;

    private var _w as Number = 260;
    private var _h as Number = 260;
    private var _cx as Number = 130;
    private var _cy as Number = 130;
    private var _radius as Number = 130;
    private var _bigFont as Graphics.FontType = Graphics.FONT_NUMBER_THAI_HOT;

    function initialize(session as IntervalSession) {
        View.initialize();
        _session = session;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = _w / 2;
        _cy = _h / 2;
        _radius = (_w < _h ? _w : _h) / 2;
        _bigFont = Graphics.FONT_NUMBER_THAI_HOT;
        if (dc.getTextWidthInPixels("88:88", _bigFont) > _w - 60) {
            _bigFont = Graphics.FONT_NUMBER_HOT;
        }
    }

    function onShow() as Void {
        // 100 ms : assez fin pour que le decompte ne saute pas une seconde,
        // assez lent pour ne pas vider la batterie.
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 100, true);
        _timer = timer;
    }

    function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        var finished = _session.update();
        if (finished != PHASE_IDLE) {
            _lastBeepSecond = -1;
            if (_session.phase == PHASE_DONE) {
                Alerts.finished();
            } else {
                Alerts.phaseChange(finished);
            }
        } else if (_session.isRunning() && !_session.paused) {
            var left = _session.remainingSeconds();
            if (left <= 3 && left > 0 && left != _lastBeepSecond) {
                _lastBeepSecond = left;
                Alerts.tick();
            }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var color = phaseColor();
        drawRing(dc, color);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.20).toNumber(), Graphics.FONT_SMALL, phaseLabel(),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, _cy, _bigFont, centerText(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawFooter(dc);
    }

    private function drawRing(dc as Graphics.Dc, color as Number) as Void {
        var radius = _radius - (RING_PEN / 2) - 1;
        dc.setPenWidth(RING_PEN);
        dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_cx, _cy, radius);

        var ratio = _session.progress();
        if (ratio <= 0.0) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (ratio >= 0.999) {
            dc.drawCircle(_cx, _cy, radius);
            return;
        }
        var end = 90.0 - (359.0 * ratio);
        if (end < 0.0) {
            end += 360.0;
        }
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, end.toNumber());
    }

    private function drawFooter(dc as Graphics.Dc) as Void {
        var topY = (_h * 0.68).toNumber();
        var lineH = dc.getFontHeight(Graphics.FONT_XTINY);

        if (_session.phase == PHASE_IDLE) {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_cx, topY, Graphics.FONT_XTINY, text(Rez.Strings.HintStart),
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_cx, topY + lineH, Graphics.FONT_XTINY, text(Rez.Strings.HintMenu),
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, topY, Graphics.FONT_TINY,
            Lang.format(text(Rez.Strings.RoundLabel), [_session.round, _session.rounds]),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, topY + dc.getFontHeight(Graphics.FONT_TINY), Graphics.FONT_XTINY,
            text(Rez.Strings.TotalLabel) + " " + clock(_session.elapsedSeconds()),
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function centerText() as String {
        if (_session.phase == PHASE_IDLE) {
            return clock(_session.plannedSeconds());
        }
        if (_session.phase == PHASE_DONE) {
            return clock(_session.elapsedSeconds());
        }
        return clock(_session.remainingSeconds());
    }

    private function phaseLabel() as String {
        if (_session.paused) {
            return text(Rez.Strings.Paused);
        }
        switch (_session.phase) {
            case PHASE_PREP: return text(Rez.Strings.PhasePrep);
            case PHASE_WORK: return text(Rez.Strings.PhaseWork);
            case PHASE_REST: return text(Rez.Strings.PhaseRest);
            case PHASE_DONE: return text(Rez.Strings.PhaseDone);
            default: return text(Rez.Strings.PhaseReady);
        }
    }

    private function phaseColor() as Number {
        if (_session.paused) {
            return COLOR_DIM;
        }
        switch (_session.phase) {
            case PHASE_PREP: return Graphics.COLOR_YELLOW;
            case PHASE_WORK: return 0xFF5500;
            case PHASE_REST: return 0x00AAFF;
            case PHASE_DONE: return Graphics.COLOR_GREEN;
            default: return Graphics.COLOR_WHITE;
        }
    }

    //! Formate des secondes en M:SS (ou H:MM:SS au-dela d'une heure).
    private function clock(totalSeconds as Number) as String {
        var seconds = (totalSeconds > 0) ? totalSeconds : 0;
        var hours = seconds / 3600;
        var minutes = (seconds % 3600) / 60;
        var rest = seconds % 60;
        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$",
                [hours, minutes.format("%02d"), rest.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [minutes, rest.format("%02d")]);
    }

    private function text(resource as ResourceId) as String {
        return WatchUi.loadResource(resource) as String;
    }
}
