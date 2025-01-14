# Hack the Th
Ce repo a pour objectif d'expliquer et de démontrer comment modifier les valeurs affichées par une station météo utilisant le protocole de communication radio Nexus.

Pour cela, il faut capturer un échange entre une sonde et une station météo au format RAW. Analyser ce fichier pour déterminer l'identifiant de la sonde et le canal utilisé.

Puis, générer un fichier .sub utilisable par l'application Sub GHz du Flipper Zero.

Enfin, on utilise un script pour envoyer en boucle le fichier .sub afin que nos valeurs soient prises en compte par la station météo.

Vous trouverez ci-dessous après le Disclaimer toute l'analyse et des images de démonstration à la fin de ce Readme.

### Disclaimer
Toutes les informations présentes ici sont exposées à titre informatif et éducatif.

Pour rappel, il est illégal de pratiquer ce type d'activités sur des équipements

dont vous n'êtes pas le propriétaire ou des équipements appartenant à autrui 

sans autorisation écrite du propriétaire. 


### Matériel utilisé
Flipper Zero : https://www.amazon.fr/dp/B0BFXKSFNT

Station Météo LIORQUE : https://www.amazon.fr/dp/B0CCXT1XZK


### Analyse

Le Flipper permet d'observer que la communication entre la sonde extérieure et la station météo s'effectue sur la **fréquence 433,92 MHz**

La fréquence de communication est toutes les **56,75 secondes**.

Le protocole utilisé est **Nexus**.

De la documentation du produit, on apprend que la station météo est en attente d'une transmission d'une sonde **pendant les 3 premières minutes**.

Pendant cette période de 3 minutes, nos trames sont prises en compte instantanément.
Passé ce délai, on constate que la station semble observer le cycle suivant : 1 minute et 53 secondes sans écoute (sans doute pour éviter les interférences) puis **1 seconde d'écoute**. 

*Si on souhaite, basculer sur un autre canal après les 3 minutes initiales (au démarrage de la station météo), ou resynchroniser une sonde, il faut rester appuyé quelques secondes sur le bouton Channel de la station météo.*

Le cadencement avec la sonde est très précis. Si on souhaite pousser nos valeurs plutôt que celle d'une sonde, il faut arriver à envoyer le signal pendant la seconde d'écoute de la station météo et avant la sonde (ou isoler la sonde si c'est possible).

C'est pour cela que j'ai créé le script **hack_the_th_flood.js** (à placer dans le dossier SD Card/apps/Scripts/).

Ce script permet l'envoi en continue du fichier .sub produit par mon script hack_the_th.py

Cela permet de définir nos propres valeurs d'humidité et de température à la place d'un capteur déjà synchronisé avec sa station météo.

Par défaut, l'envoi dure environ 2 min car la station météo accepte les mises à jour tous les 2 cycles de 57 secondes (soit environ 1 min 54 s).


## Détails de la trame

Il s'agit d'une trame de **36 bits**


La signification des bits:

|     Nombre de Bits    	| 8  |     1     | 1 |  2  |    12     |  4  |     8     |
|-------------------------|----|----------|---|-------|-------------|------|----------|
|    Signification        | ID | Batterie | 0 | Canal | Température | 1111 | Humidité |

>ID – ID unique; Certains capteurs changent d'identifiant lorsque l'on change la batterie.

>Batterie – indicateur de batterie faible; 1 – batterie ok, 0 – batterie faible

>Un bit sépare le bit qui indique l'état de la batterie et les 2 bits qui indiquent le canal (ce bit est toujours à 0 sauf lorsqu'on appuie sur le TX d'une sonde où il est à 1 avec pour impact de générer un bip côté station météo en plus de la mise à jour des informations)

>Canal - numéro de canal, 0 – premier canal (CH1), 1 – (CH2), 2 - (CH3)

>Température – Température en degré Celcius (la valeur peut être négative); Valeur à diviser par 10 (ex: 48 donne 4.8°C).

>Humidité – Taux d'humidité; Valeur entière (ex: 80 pour 80%)


**Références :**
>Description du protocole - Receive weather station data with Arduino : https://www.onetransistor.eu/2024/01/receive-lpd433-weather-unit-nexus.html

>Manuel de ma station météo : https://www.usermanual.wiki./YuanGuangHao-Electronics/YGH6208

>La chaine Youtube de Kanjian : https://www.youtube.com/@kanjian_fr


## weather_station_raw_analyse.py
Ce script python, à exécuter sur PC, a pour objectif d'analyser un fichier RAW .sub (produit par l'application Sub GHz / Read RAW) lors de la capture d'un signal envoyé par un capteur de station météo utilisant le protocole Nexus-TH.
Les informations a conservé pour la suite sont l'identifiant de la sonde et le canal.
Recommandation : pour capturer un fichier exploitable sans trop d'interférences, il faut positionner le "RSSI Threshold" autour de  -70.0

## hack_the_th.py
Ce script python, à exécuter sur PC, a pour objectif de forger un fichier .sub à partir de :
- l'identifiant de la sonde et du canal récupérés précédemment
- les valeurs de température, d'humidité et d'état de la batterie souhaitées

## hack_the_th.js
Ce script js à placer sur le Flipper Zero dans le dossier *SD Card/apps/Scripts/* permet d'envoyer en boucler le fichier .sub forgé précédemment pour forcer la station météo à prendre en compte nos valeurs à la place de celle de la sonde déjà connectée à la station météo.
Remarque : Le script ne dure que 2 minutes mais il serait tout à fait possible de faire une boucle infinie.




## Exemple d'utilisation en 4 étapes

### 1- Capturer un échange entre la station météo et une sonde/capteur de température et d'humidité au format RAW
![Capturer](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/images/capturer.png)

### 2- Analyser la capture
*Script weather_station_raw_analyse.py*

![Analyser](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/images/analyser.png)

### 3- Forger un fichier .sub avec les valeurs souhaitées
*hack_the_th.py*
![Forger](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/images/forger.png)

### 4- Flooder la station météo avec le fichier forgé
*hack_the_th_flood.js*

![Flooder](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/images/flood.png)

### 5- Constater le changement sur la station météo
![Constater](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/images/constater.png)

## Vidéo de démonstration
https://github.com/user-attachments/assets/0a989f33-e855-4c69-8b46-989f96cb61b0
