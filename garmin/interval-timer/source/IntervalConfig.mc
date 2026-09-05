import Toybox.Application;
import Toybox.Lang;

//! Reglages de la seance, stockes dans les proprietes de l'application.
//! Chaque lecture est bornee : une valeur absente ou aberrante ne peut pas
//! produire une seance impossible (0 serie, effort de 0 seconde...).
module IntervalConfig {

    const WORK_CHOICES = [15, 20, 30, 40, 45, 60, 90, 120, 180, 240] as Array<Number>;
    const REST_CHOICES = [0, 10, 15, 20, 30, 45, 60, 90, 120] as Array<Number>;
    const PREP_CHOICES = [0, 5, 10, 15, 30] as Array<Number>;

    function work() as Number {
        return clamp(number("WorkSeconds", 30), 5, 900);
    }

    function rest() as Number {
        return clamp(number("RestSeconds", 15), 0, 900);
    }

    function rounds() as Number {
        return clamp(number("Rounds", 8), 1, 99);
    }

    function prep() as Number {
        return clamp(number("PrepSeconds", 10), 0, 60);
    }

    function vibration() as Boolean {
        return boolean("UseVibration", true);
    }

    function tones() as Boolean {
        return boolean("UseTones", true);
    }

    function store(key as String, value as Application.PropertyValueType) as Void {
        if (Application has :Properties) {
            try {
                Application.Properties.setValue(key, value);
            } catch (e) {
                // Stockage plein ou propriete inconnue : on garde la valeur en
                // memoire pour la seance en cours plutot que de planter.
            }
        }
    }

    //! Valeur suivante dans une liste de choix (retour au debut apres la fin).
    function nextChoice(choices as Array<Number>, current as Number) as Number {
        for (var i = 0; i < choices.size(); i++) {
            if (choices[i] == current) {
                return choices[(i + 1) % choices.size()];
            }
        }
        // Valeur hors liste (reglee depuis le telephone) : on repart du premier
        // choix strictement superieur.
        for (var i = 0; i < choices.size(); i++) {
            if (choices[i] > current) {
                return choices[i];
            }
        }
        return choices[0];
    }

    function clamp(value as Number, low as Number, high as Number) as Number {
        if (value < low) {
            return low;
        }
        if (value > high) {
            return high;
        }
        return value;
    }

    function number(key as String, fallback as Number) as Number {
        var value = raw(key);
        if (value instanceof Lang.Number) {
            return value;
        }
        if (value instanceof Lang.Float || value instanceof Lang.Double) {
            return value.toNumber();
        }
        return fallback;
    }

    function boolean(key as String, fallback as Boolean) as Boolean {
        var value = raw(key);
        if (value instanceof Lang.Boolean) {
            return value;
        }
        return fallback;
    }

    function raw(key as String) as Lang.Object? {
        if (Application has :Properties) {
            try {
                return Application.Properties.getValue(key);
            } catch (e) {
                return null;
            }
        }
        return null;
    }
}
