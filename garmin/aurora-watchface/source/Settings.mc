import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;

//! Lecture defensive des proprietes : si une cle manque (premiere installation,
//! reglage supprime), on retombe toujours sur une valeur par defaut utilisable.
module Settings {

    //! Palette proposee dans les reglages (index = valeur stockee).
    const ACCENTS = [
        0xFFFFFF, // 0 blanc
        0x00AAFF, // 1 bleu
        0xFF5500, // 2 orange
        0x00FF00, // 3 vert
        0xFF0000, // 4 rouge
        0xFFAA00, // 5 ambre
        0xFF00FF, // 6 magenta
        0x55AAAA  // 7 sarcelle
    ];

    function number(key as String, fallback as Number) as Number {
        var value = raw(key);
        if (value instanceof Lang.Number) {
            return value;
        }
        if (value instanceof Lang.Float || value instanceof Lang.Double) {
            return value.toNumber();
        }
        if (value instanceof Lang.String) {
            var parsed = value.toNumber();
            if (parsed != null) {
                return parsed;
            }
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

    //! Couleur d'accent choisie, bornee a la palette connue.
    function accent(key as String) as Number {
        var index = number(key, 1);
        if (index < 0 || index >= ACCENTS.size()) {
            index = 1;
        }
        return ACCENTS[index];
    }

    function raw(key as String) as Lang.Object? {
        // Properties n'existe qu'a partir de l'API 2.4 ; le `has` evite un crash
        // si le cadran est charge sur une montre plus ancienne.
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
