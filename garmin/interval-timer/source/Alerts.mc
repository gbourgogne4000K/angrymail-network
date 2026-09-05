import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

//! Retours vibration / son. Tout est conditionne a la fois par les reglages de
//! l'application et par ceux de la montre (mode silencieux, vibration coupee).
module Alerts {

    //! Bip court des trois dernieres secondes d'une phase.
    function tick() as Void {
        vibrate(35, 40);
        tone(Attention.TONE_KEY);
    }

    //! Signal de changement de phase : plus long, et double pour la fin.
    function phaseChange(finished as Number) as Void {
        if (finished == PHASE_WORK) {
            vibrate(85, 400);
            tone(Attention.TONE_INTERVAL_ALERT);
        } else {
            vibrate(70, 250);
            tone(Attention.TONE_ALERT_HI);
        }
    }

    function finished() as Void {
        vibrate(100, 900);
        tone(Attention.TONE_LOUD_BEEP);
    }

    function vibrate(intensity as Number, durationMs as Number) as Void {
        if (!IntervalConfig.vibration()) {
            return;
        }
        if (!(Attention has :vibrate)) {
            return;
        }
        var settings = System.getDeviceSettings();
        if (settings has :vibrateOn && !settings.vibrateOn) {
            return;
        }
        Attention.vibrate([new Attention.VibeProfile(intensity, durationMs)]);
    }

    function tone(toneId as Attention.Tone) as Void {
        if (!IntervalConfig.tones()) {
            return;
        }
        if (!(Attention has :playTone)) {
            return;
        }
        var settings = System.getDeviceSettings();
        if (settings has :tonesOn && !settings.tonesOn) {
            return;
        }
        Attention.playTone(toneId);
    }
}
