import Toybox.Lang;
import Toybox.WatchUi;

//! START : demarre, met en pause, reprend.
//! RETOUR : arrete la seance en cours, ou quitte l'application depuis l'accueil.
//! MENU (appui long sur UP) : reglages.
class IntervalDelegate extends WatchUi.BehaviorDelegate {

    private var _session as IntervalSession;

    function initialize(session as IntervalSession) {
        BehaviorDelegate.initialize();
        _session = session;
    }

    function onSelect() as Boolean {
        if (_session.isRunning()) {
            _session.togglePause();
        } else {
            _session.start();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (_session.phase == PHASE_IDLE) {
            return false; // laisse le systeme fermer l'application
        }
        _session.stop();
        WatchUi.requestUpdate();
        return true;
    }

    function onMenu() as Boolean {
        // On ne change pas les reglages au milieu d'une seance.
        if (_session.isRunning()) {
            return true;
        }
        var menu = new SettingsMenu();
        WatchUi.pushView(menu, new SettingsMenuDelegate(menu), WatchUi.SLIDE_UP);
        return true;
    }
}
