// Import modules
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

    let iteration = 1;
    // Infinite loop
    while (true) {

       
	// Send file Sub-GHz
        let result = subghz.transmitFile(filePath);

	// Blinking led
        notify.blink("cyan", "short");

    }
}

let views = {
    splash: dialogView.makeWith({
	text: "Hack the th\nFloooood !!!",
    }),
    helloDialog: dialogView.make(),
    menu: submenuView.makeWith({
        header: "Choose your destiny",
        items: [
            "Choose file to send",
            "Exit",
        ],
    }),
    stop: submenuView.makeWith({
        header: "Stop when you want",
        items: [
            "STOP !!!",
        ],
    }),
};


// Splash screen
gui.viewDispatcher.switchTo(views.splash);
delay(2000);
gui.viewDispatcher.switchTo(views.menu);

// Menu STOP processing
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

// Menu processing
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




// Stop when you press 'back' button
eventLoop.subscribe(gui.viewDispatcher.navigation, function (_sub, _, gui, views, eventLoop) {
    if (gui.viewDispatcher.currentView === views.stop) {
        eventLoop.stop();
        return;
    }
}, gui, views, eventLoop);

eventLoop.run();        

