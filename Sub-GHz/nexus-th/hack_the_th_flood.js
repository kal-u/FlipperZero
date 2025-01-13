// Hack the th - Flood
// Auteur : Kalu
// Date : 13-01-2025
// Ce script permet l'envoi en continue du fichier .sub produit par mon script hack_the_th.py
// Cela permet de définir nos propres valeurs d'humidité et de température à la place
// d'un capteur déjà synchronisé avec sa station météo.
// Par défaut, l'envoi dure environ 2 min car la station météo accepte les mises à jour tous
// les 2 cycles de 57 secondes (soit environ 1 min 54 s).

// Import de modules
let notify = require("notification");
let subghz = require("subghz");

// Définition des variables
let iteration = 4; // Environ 2 min
let nb_send = 400; // Nombre d'envoi par transmit

subghz.setup();

print("C est parti !");

for (let i = 0; i < iteration; i++) {
    let result = subghz.transmitFile("/ext/subghz/th.sub",nb_send);
    if (result) { print("."); 
     } else { print("#"); }
    notify.blink("cyan", "short");
}

notify.success();
subghz.end();
print("Fin.");
