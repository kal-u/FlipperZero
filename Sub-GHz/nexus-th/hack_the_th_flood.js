// Importation des modules
let eventLoop = require("event_loop");
let gui = require("gui");
let dialogView = require("gui/dialog");
let filePicker = require("gui/file_picker");
let submenuView = require("gui/submenu");
let notify = require("notification");
let subghz = require("subghz");

// Fonction pour l'émission du signal en boucle
function txFile(_sub, _index, filePath) {
	
	// Send file Sub-GHz
	let result = subghz.transmitFile(filePath);

	
	// Blinking led
	notify.blink("cyan", "short");
	
	// loop
	eventLoop.subscribe(eventLoop.timer("oneshot",1), txFile, filePath);
}

// 
function sendSubGHzLoop(filePath) {
	views.helloDialog.set("text", "Envoi du fichier en boucle \n" + filePath + "\n\nFlood en cours ...");
	gui.viewDispatcher.switchTo(views.helloDialog);
	delay(2000);
	gui.viewDispatcher.switchTo(views.stop);
	
	// Infinite loop
	txFile(0,0,filePath);
}

let views = {
	splash: dialogView.makeWith({
	text: "Hack the th\nFloooood !!!",
	}),
	helloDialog: dialogView.make(),
	menu: submenuView.makeWith({
		header: "Choisi ton destin",
		items: [
			"Choisi un fichier à envoyer",
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


// Ecran d'accueil
gui.viewDispatcher.switchTo(views.splash);
delay(2000);
gui.viewDispatcher.switchTo(views.menu);

// Traitement du menu stop
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

// Traitement du premier menu
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

	} else if (index === 1) {
		eventLoop.stop();
		subghz.end();
		notify.success();
	}
}, gui, eventLoop, views);

// Arret quand on presse le bouton "back"
eventLoop.subscribe(gui.viewDispatcher.navigation, function (_sub, _, gui, views, eventLoop) {
	if (gui.viewDispatcher.currentView === views.stop) {
		eventLoop.stop();
		subghz.end();
		return;
	}
}, gui, views, eventLoop);

eventLoop.run();


