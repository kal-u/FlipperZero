# Hack the Th
Ce script a pour objectif de générer un fichier .sub utilisable par l'application Sub GHz du Flipper Zero
pour simuler l'envoi d'information d'une sonde pour station météo utilisant le protocole Nexus-TH.

## Weather station raw analyse
Ce script a pour objectif d'analyser un fichier RAW .sub (produit par l'application Sub GHz / Read RAW) lors de la capture d'un signal envoyé par un capteur de station météo utilisant le protocole Nexus-TH.
Recommandation : pour capturer un fichier exploitable sans trop d'interférences, il faut positionner le "RSSI Threshold" autour de  -70.0

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

Le protocole utilisé est **Nexus-TH**.

De la documentation du produit, on apprend que la station météo est en attente d'une transmission d'une sonde **pendant les 3 premières minutes**.

Pendant cette période de 3 minutes, nos trames sont prises en compte instantanément.
Passé ce délai, on constate que la station semble observer le cycle suivant : 56 secondes sans écoute (sans doute pour éviter les interférences) puis **1 seconde d'écoute**. 

Le cadencement avec la sonde est très précis. Si on souhaite pousser nos valeurs plutôt que celle d'une sonde, il faut arriver à envoyer le signal pendant la seconde d'écoute  de la station météo et avant la sonde (ou isoler la sonde si c'est possible).

Si on souhaite, basculer sur un autre canal après les 3 minutes initiales (au démarrage de la station météo), ou resynchroniser une sonde, il faut rester appuyer quelques secondes sur le bouton Channel de la station météo.

Il s'agit d'une trame de **36 bits**


La signification des bits:

|     Nombre de Bits    	| 8  |     1     | 1 |  2  |    12     |  4  |     8     |
|-------------------------|----|----------|---|-------|-------------|------|----------|
|    Signification        | ID | Batterie | 0 | Canal | Température | 1111 | Humidité |

>ID – ID unique; Certains capteurs changent d'identifiant lorsque l'on change la batterie.

>Batterie – indicateur de batterie faible; 1 – batterie ok, 0 – batterie faible

>Un bit sépare le bit qui indique l'état de la batterie et les 2 bits qui indiquent le canal (ce bit est toujours à 0 sauf lorsqu'on appuie sur le TX d'une sonde où il est à 1 avec pour impact de générer un son côté station météo en plus de la mise à jour des informations)

>Canal - numéro de canal, 0 – premier canal (CH1), 1 – (CH2), 2 - (CH3)

>Température – Température en degré Celcius (la valeur peut être négative); Valeur à diviser par 10 (ex: 48 donne 4.8°C).

>Humidité – Taux d'humidité; Valeur entière (ex: 80 pour 80%)


**Références :**
>Description du protocole - Receive weather station data with Arduino : https://www.onetransistor.eu/2024/01/receive-lpd433-weather-unit-nexus.html

>Manuel de ma station météo : https://www.usermanual.wiki./YuanGuangHao-Electronics/YGH6208

>La chaine Youtube de Kanjian : https://www.youtube.com/@kanjian_fr

### Exemple d'utilisation du script hack_the_th.py
```
####################################################
# Script de generation d'un fichier .sub (Sub GHz) #
#                pour Flipper Zero                 #
#                     par Kalu                     #
####################################################

Entrez l'identifiant de la sonde (un nombre de 2 chiffres) : 40
Entrez l'état de la batterie (0 pour faible, 1 pour OK) : 1
Entrez le canal de la sonde de température (1, 2 ou 3) : 2
Entrez la température (entre 0 et 99 degrés) : 37
Entrez l'humidité (entre 0 et 99 %) : 32
Entrez le nom du fichier (avec l'extension .sub) : th.sub

Le fichier th.sub a été créé avec succès.
```

![Envoi du fichier th.sub](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nexus-th/flipper_subGHz_Nexus-TH.png)



https://github.com/user-attachments/assets/0a989f33-e855-4c69-8b46-989f96cb61b0



### Exemple d'utilisation du script weather_station_raw_analyse.py

![Exécution du script weather_station_raw_analyse.py](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/weather_station_raw_analyse.png)
