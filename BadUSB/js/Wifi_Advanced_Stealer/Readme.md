# Wifi Advanced Stealer

L'objectif de ce script est de sensibiliser les utilisateurs à la cybersécurité.

Cette démonstration permet d'expliquer que des mauvaises pratiques peuvent conduire à de la divulgation d'informations qui touche personnellement l'utilisateur.

Les mauvaises pratiques traitées sont les suivantes :
- Ne pas verrouiller sa session lors que l'on quitte son poste
- Utiliser son ordinateur Windows avec un compte qui possède les droits Administrateur
- Enregistrer les mots de passe dans son navigateur

Pour ne pas faire un script de plus qui vole seulement le mot de passe Wifi (qui a l'avantage de ne pas nécessite de droits Administrateur), je lance Powershell en Administrateur ce qui permet de récupérer le nom des réseaux Wifi (SSID), l'adresse MAC (BSSID) des points d'accès Wifi sur lesquels s'est connecté l'utilisateur ainsi que la date de première et de dernière connexion.

Cela permet ensuite de localiser où l'utilisateur s'est connecté grâce à des sites comme ![Wigle.net](https://wigle.net/) ou en utilisant les API Google sur l'outil ![Geowifi](https://github.com/GONZOsint/geowifi)

Avec la date de dernière connexion, pour un ordinateur de télétravail, on peut déduire assez facilement où habite l'utilisateur.
Et si on a son adresse, le nom de son réseau Wifi et son mot de passe, alors on a accès à son réseau domestique ce qui ouvre la porte à beaucoup d'options possibles pour un acteur malveillant.

Le script peut également lancer un script de vol de mot de passe stocker dans le navigateur Firefox (payload2.ps1).
On peut imaginer les ravages que cela peut occasioner pour l'utilisateur en fonction des comptes enregistrés.


## Disclaimer

Toutes les informations présentes ici sont exposées à titre informatif et éducatif.

L'utilisation du Flipper Zero pour ce type d'attaque risque fortement d'être détecté par l'agent EDR installé sur la machine cible.

Je ne pourrai pas être tenu responsable de dommages causés par l'utilisation des fichiers fournis.

Ces tests sont à réaliser uniquement sur des appareils qui vous appartiennent ou avec l'autorisation écrite du propriétaire.


## Matériel utilisé

Flipper Zero : https://shop.flipperzero.one/

Firmware : Momentum MNTM-008 (11-11-2024)

Ordinateur sous Windows 11
- Session ouverte
- Utilisateur connecté avec les droits administrateur
- Firefox 128.5.2esr (64 bits) installé


## Le script BadUSB

Ce script démontre ce qu'il est possible de faire avec le moteur javascript installé sur le Flipper Zero avec le firmware Momentum.

Le Flipper peut se faire passer pour un périphérique HID (Human Interface Devices) tel qu'un clavier ou une souris.

Dans notre cas, le script va émuler un clavier Logitech pour taper du texte comme le ferait un humain mais beaucoup plus rapidement.

Il peut également présenter un périphérique de stockage de masse, type clé USB, pour envoyer ou récupérer des fichiers ou répertoires.


Plusieurs variables peuvent être modifiées dans le script :
- *layout* => la langue du clavier (par défaut fr-FR pour le clavier français)
- *remove_artefacts* => pour supprimer les traces dans l'historique Powershell et dans la base de registre (par défaut à false pour faire des tests)
- *localTempFolder* et *localFileName* => Dossier et fichier local sur le PC cible pour enregistrer les informations
- *flipMassDir* => Emplacement sur le Flipper pour l'image de la clé USB et le fichier de résultat
- *lootFile* => Nom du fichier de résultat sur le Flipper
- *resultFolder* => Nom du répertoire sur le périphérique USB pour stocker les résultats
- *resultFileName* => Nom du fichier de résultats sur le périphérique USB
- *copyPayload* => Copie du payload complémentaire sur la machine cible (par défaut à true)
- *playPayload* => Exécution du payload powershell complémentaire sur la machine cible (par défaut à true)
- *payloadName* => Nom du payload (par défaut "payload.ps1" - script d'exemple). "payload2.ps1" récupère les mots de passe stockés dans Firefox


## Déroulement du script

Le script comporte plusieurs étapes :
- Création de l'image à présenter comme périphérique de stockage USB
- Si activé, copie du payload
- Présentation du Flipper comme un clavier Logitech
- Lancement d'une console Powershell en tant que Administrateur
- Exécution des commandes pour récupérer la date, le nom de la machine et les informations Wifi + le payload si activé
- Attente de détection du périphérique USB
- Si activé, copie et exécution du payload
- Récupération du fichier du résultat sur le périphérique USB
- Effacement des traces
- Ejection du périphérique USB
- Affichage du résultat directement sur le Flipper


## Remarques et optimisations
Une image de périphérique USB de plus de 2 Mo fait planter le Flipper avec la version du firmware utilisée.

Le script peut être plus rapide en utilisant des raccourcis de commandes Powershell même si je l'ai partiellement optimisé.

Il est possible d'ajouter de l'obfuscation pour éviter la détection par l'agent EDR

Il n'est pas possible pour le moment de changer le nom du périphérique de stockage de masse présenté "Flipper Mass Storage" ce qui est simple à détecter pour l'EDR.

Avec l'évolution du Javascript sur le Flipper, il sera possible demain de prévoir des menus pour choisir les différentes options.


## Références
- https://developer.flipper.net/flipperzero/doxygen/js.html
- https://github.com/jamisonderek/flipper-zero-tutorials/wiki/JavaScript
- https://github.com/Miiraak/FlipperZeroFR/tree/main/Info-Doc-Wiki/JavaScript



