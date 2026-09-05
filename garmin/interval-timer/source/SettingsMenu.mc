import Toybox.Lang;
import Toybox.WatchUi;

//! Reglages accessibles depuis la montre : chaque validation fait defiler la
//! liste des valeurs proposees. Les memes cles sont editables depuis Garmin
//! Connect (voir resources/settings/settings.xml).
class SettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => WatchUi.loadResource(Rez.Strings.MenuTitle) as String});
        addChoice(:work, Rez.Strings.MenuWork, seconds(IntervalConfig.work()));
        addChoice(:rest, Rez.Strings.MenuRest, seconds(IntervalConfig.rest()));
        addChoice(:rounds, Rez.Strings.MenuRounds, IntervalConfig.rounds().format("%d"));
        addChoice(:prep, Rez.Strings.MenuPrep, seconds(IntervalConfig.prep()));
        addChoice(:vibration, Rez.Strings.MenuVibrate, onOff(IntervalConfig.vibration()));
        addChoice(:tones, Rez.Strings.MenuTones, onOff(IntervalConfig.tones()));
    }

    private function addChoice(id as Symbol, label as ResourceId, value as String) as Void {
        addItem(new WatchUi.MenuItem(WatchUi.loadResource(label) as String, value, id, {}));
    }

    static function seconds(value as Number) as String {
        return Lang.format(WatchUi.loadResource(Rez.Strings.Seconds) as String, [value]);
    }

    static function onOff(value as Boolean) as String {
        var id = value ? Rez.Strings.On : Rez.Strings.Off;
        return WatchUi.loadResource(id) as String;
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize(menu as SettingsMenu) {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :work) {
            var value = IntervalConfig.nextChoice(IntervalConfig.WORK_CHOICES, IntervalConfig.work());
            IntervalConfig.store("WorkSeconds", value);
            item.setSubLabel(SettingsMenu.seconds(value));
        } else if (id == :rest) {
            var value = IntervalConfig.nextChoice(IntervalConfig.REST_CHOICES, IntervalConfig.rest());
            IntervalConfig.store("RestSeconds", value);
            item.setSubLabel(SettingsMenu.seconds(value));
        } else if (id == :prep) {
            var value = IntervalConfig.nextChoice(IntervalConfig.PREP_CHOICES, IntervalConfig.prep());
            IntervalConfig.store("PrepSeconds", value);
            item.setSubLabel(SettingsMenu.seconds(value));
        } else if (id == :rounds) {
            var value = IntervalConfig.rounds() + 1;
            if (value > 30) {
                value = 1;
            }
            IntervalConfig.store("Rounds", value);
            item.setSubLabel(value.format("%d"));
        } else if (id == :vibration) {
            var value = !IntervalConfig.vibration();
            IntervalConfig.store("UseVibration", value);
            item.setSubLabel(SettingsMenu.onOff(value));
        } else if (id == :tones) {
            var value = !IntervalConfig.tones();
            IntervalConfig.store("UseTones", value);
            item.setSubLabel(SettingsMenu.onOff(value));
        }
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
