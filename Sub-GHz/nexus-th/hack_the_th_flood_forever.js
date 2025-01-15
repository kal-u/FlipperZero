// Import de modules
let eventLoop = require("event_loop");
let gui = require("gui");
let dialogView = require("gui/dialog");
let filePicker = require("gui/file_picker");
let submenuView = require("gui/submenu");
let notify = require("notification");
let subghz = require("subghz");



function sendSubGHzLoop(filePath) {

    views.helloDialog.set("text", "Envoi du fichier en boucle \n" + filePath + "\n\nFlood en cours ...");
    gui.viewDispatcher.switchTo(views.helloDialog);
    delay(2000);
    gui.viewDispatcher.switchTo(views.stop);

    // print("Envoi du fichier en boucle \n" + filePath + "\n\nAppuyez sur Back pour arreter.");

    let iteration = 1;
    // Boucle infinie
    while (true) {

        // iteration = iteration + 1;
        
	// Envoie du fichier Sub-GHz
        let result = subghz.transmitFile(filePath);

	// Led clignotante à chaque envoi
        notify.blink("cyan", "short");
	//if(iteration > 5) {
	//	break;
        //	eventLoop.stop();
	}//
    }
}

let views = {
    splash: dialogView.makeWith({
	text: "Hack the th\nFloooood !!!",
    }),
    helloDialog: dialogView.make(),
    menu: submenuView.makeWith({
        header: "Choisi ton destin",
        items: [
            "Choisir un fichier a envoyer",
            "Sortir",
        ],
    }),
    stop: submenuView.makeWith({
        header: "Arrete quand tu veux",
        items: [
            "STOP !!!",
        ],
    }),
};


// Ecran de demarrage
gui.viewDispatcher.switchTo(views.splash);
delay(2000);
gui.viewDispatcher.switchTo(views.menu);

// Traitement en fonction du choix du menu stop
eventLoop.subscribe(views.stop.chosen, function (_sub, index, gui, eventLoop, views) {
    if (index === 0) {
        eventLoop.stop();
        notify.success();
    }
    else {
        eventLoop.stop();
        notify.success();
   }
}, gui, eventLoop, views);

// Traitement en fonction du choix du menu
eventLoop.subscribe(views.menu.chosen, function (_sub, index, gui, eventLoop, views) {
    if (index === 0) {
        let path = filePicker.pickFile("/ext/subghz/", "sub");
        if (path) {
             views.helloDialog.set("text", "Fichier choisi:\n" + path);
        } else {
             views.helloDialog.set("text", "Aucun fichier choisi :(");
             break;
        }
        gui.viewDispatcher.switchTo(views.helloDialog);

        subghz.setup();

        // Lancer le flood
        sendSubGHzLoop(path);
        
        subghz.end();


    } else if (index === 1) {
        eventLoop.stop();
        notify.success();
    }
}, gui, eventLoop, views);




// Arrêter quand on appuie sur la touche 'back'
eventLoop.subscribe(gui.viewDispatcher.navigation, function (_sub, _, gui, views, eventLoop) {
    if (gui.viewDispatcher.currentView === views.stop) {
        eventLoop.stop();
        return;
    }
}, gui, views, eventLoop);

// Arrête si on appuie sur le bouton central
//eventLoop.subscribe(views.stop.input, function (_sub, button, gui, views) {
//    if (button === "center")
//        eventLoop.stop();
//}, gui, views);


eventLoop.run();        

