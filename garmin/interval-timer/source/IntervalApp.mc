import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Chronometre par intervalles (fractionne / Tabata) pour fenix 7.
class IntervalApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var session = new IntervalSession();
        return [new IntervalView(session), new IntervalDelegate(session)];
    }

    //! Les reglages modifies depuis Garmin Connect ne prennent effet qu'a la
    //! prochaine serie : on ne coupe jamais une seance en cours.
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
