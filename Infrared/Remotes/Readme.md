# Gen IR
Ce script a pour objectif de générer un fichier .ir utilisable par l'application Infrared du Flipper Zero

Le fichier généré permet de tester tous les signaux infrarouges pour un appareil afin de reproduire une télécommande et découvrir potentiellement des **fonctionnalités cachées**.

Vous trouverez dans ce dossier les fichier .ir pour 2 modèles distincts de TV SONY sur lesquelles j'ai pu découvrir des fonctions cachées.

Elles sont précédées par le caractère '*' dans chaque fichier.

Les fonctionnalitées cachées découvertes sont les suivantes :
- Power Off (uniquement c'est-à-dire sans Power On)
- Affichage de la date et de l'heure
- Mise en veille du téléviseur sans image
- Accès directe à des sources comme AV / AV1 / AV2 / AV3 / PC
- Mode son
- Mode image
- Son surround
- Mode scene
- Economie d'énergie
- Télétexte
- Test


### Disclaimer
Toutes les informations présentes ici sont exposées à titre informatif et éducatif.

Soyez prudents car le fait d'envoyer un signal non prévu à un appareil peut potentiellement provoquer une réaction inattendue.

Je ne pourrai pas être tenu responsable de dommages causés par l'utilisation des fichiers fournis.

Ces tests sont à réaliser uniquement sur des appareils qui vous appartiennent ou avec l'autorisation écrite du propriétaire.


### Matériel utilisé
[Flipper Zero](https://shop.flipperzero.one)

Téléviseur [SONY KD-49XH9505](https://www.sony.fr/electronics/support/televisions-projectors-lcd-tvs-android-/kd-49xh9505/specifications)

Téléviseur SONY Bravia KDL40EX501


### Analyse

Le Flipper permet d'agir en récepteur et en émetteur infrarouge.

L'apprentissage d'une nouvelle télécommande permet d'enregistrer dans un fichier .ir toutes les informations nécessaires à la reproduction des signaux correspondant à l'appui sur chaque touche de la télécommande du téléviseur.

Le fichier .ir généré permet de découvrir les éléments clés pour pouvoir générer tous les signaux possibles :

- Le type: parsed
- Le protocole : SIRC
- L'adresse : 01 00 00 00

Vient ensuite la commande qui peut-être générée afin de couvrir toutes les commandes possibles.

Attention, dans mon cas, le flipper zero n'accepte pas les commandes à partir de "80 00 00 00"



**Références :**

Github de Derek Jamison : https://github.com/jamisonderek/flipper-zero-tutorials/wiki/Infrared

Github de UberGuidoZ - Flipper IRDB : https://github.com/UberGuidoZ/Flipper-IRDB#contributing
