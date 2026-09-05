import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Champ de donnees affichant la zone de frequence cardiaque pendant l'activite.
class HrZoneApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new HrZoneView()];
    }
}
