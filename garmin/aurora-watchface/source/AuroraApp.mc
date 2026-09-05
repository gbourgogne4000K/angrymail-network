import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Point d'entree du cadran Aurora.
class AuroraApp extends Application.AppBase {

    private var _view as AuroraView?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new AuroraView();
        return [_view];
    }

    //! Appele quand l'utilisateur modifie les reglages depuis Garmin Connect.
    function onSettingsChanged() as Void {
        var view = _view;
        if (view != null) {
            view.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}
