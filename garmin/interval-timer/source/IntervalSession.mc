import Toybox.Lang;
import Toybox.System;

enum {
    PHASE_IDLE,
    PHASE_PREP,
    PHASE_WORK,
    PHASE_REST,
    PHASE_DONE
}

//! Machine a etats de la seance. Le temps de reference est System.getTimer()
//! (millisecondes depuis le demarrage de la montre) : le decompte reste juste
//! meme si un tick d'affichage est retarde.
class IntervalSession {

    public var phase as Number = PHASE_IDLE;
    public var round as Number = 0;
    public var rounds as Number = 1;
    public var paused as Boolean = false;

    private var _workMs as Number = 30000;
    private var _restMs as Number = 15000;
    private var _phaseMs as Number = 1;
    private var _endMs as Number = 0;
    private var _pausedRemainingMs as Number = 0;
    private var _elapsedBeforePhaseMs as Number = 0;

    function initialize() {
    }

    function isRunning() as Boolean {
        return phase == PHASE_PREP || phase == PHASE_WORK || phase == PHASE_REST;
    }

    //! Demarre une nouvelle seance avec les reglages courants.
    function start() as Void {
        rounds = IntervalConfig.rounds();
        _workMs = IntervalConfig.work() * 1000;
        _restMs = IntervalConfig.rest() * 1000;
        round = 1;
        paused = false;
        _elapsedBeforePhaseMs = 0;

        var prepMs = IntervalConfig.prep() * 1000;
        if (prepMs > 0) {
            enter(PHASE_PREP, prepMs);
        } else {
            enter(PHASE_WORK, _workMs);
        }
    }

    function stop() as Void {
        phase = PHASE_IDLE;
        paused = false;
        round = 0;
        _elapsedBeforePhaseMs = 0;
    }

    function togglePause() as Void {
        if (!isRunning()) {
            return;
        }
        if (paused) {
            paused = false;
            _endMs = System.getTimer() + _pausedRemainingMs;
        } else {
            paused = true;
            _pausedRemainingMs = remainingMs();
        }
    }

    //! Avance l'horloge. Renvoie la phase qui vient de se terminer, ou
    //! PHASE_IDLE si rien n'a change : l'appelant declenche l'alerte.
    function update() as Number {
        if (!isRunning() || paused) {
            return PHASE_IDLE;
        }
        if (remainingMs() > 0) {
            return PHASE_IDLE;
        }

        var finished = phase;
        _elapsedBeforePhaseMs += _phaseMs;

        if (phase == PHASE_PREP) {
            enter(PHASE_WORK, _workMs);
        } else if (phase == PHASE_WORK) {
            if (round >= rounds) {
                phase = PHASE_DONE;
            } else if (_restMs > 0) {
                enter(PHASE_REST, _restMs);
            } else {
                round += 1;
                enter(PHASE_WORK, _workMs);
            }
        } else if (phase == PHASE_REST) {
            round += 1;
            enter(PHASE_WORK, _workMs);
        }
        return finished;
    }

    function remainingMs() as Number {
        if (!isRunning()) {
            return 0;
        }
        if (paused) {
            return _pausedRemainingMs;
        }
        var left = _endMs - System.getTimer();
        return (left > 0) ? left : 0;
    }

    function remainingSeconds() as Number {
        // Arrondi au superieur : l'affichage passe a 0 quand la phase se termine.
        return (remainingMs() + 999) / 1000;
    }

    //! Avancement de la phase en cours, entre 0.0 et 1.0.
    function progress() as Float {
        if (!isRunning() || _phaseMs <= 0) {
            return 0.0;
        }
        var done = _phaseMs - remainingMs();
        var ratio = done.toFloat() / _phaseMs.toFloat();
        if (ratio < 0.0) {
            return 0.0;
        }
        return (ratio > 1.0) ? 1.0 : ratio;
    }

    function elapsedSeconds() as Number {
        var current = 0;
        if (isRunning()) {
            current = _phaseMs - remainingMs();
        }
        return (_elapsedBeforePhaseMs + current) / 1000;
    }

    //! Duree totale planifiee, utilisee pour l'ecran d'accueil.
    function plannedSeconds() as Number {
        var work = IntervalConfig.work();
        var rest = IntervalConfig.rest();
        var count = IntervalConfig.rounds();
        return IntervalConfig.prep() + (work * count) + (rest * (count - 1));
    }

    private function enter(next as Number, durationMs as Number) as Void {
        phase = next;
        _phaseMs = (durationMs > 0) ? durationMs : 1;
        _endMs = System.getTimer() + _phaseMs;
        _pausedRemainingMs = _phaseMs;
    }
}
