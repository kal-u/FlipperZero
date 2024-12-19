## NF-S32-002
Cet article a pour but d'expliquer comment créer un fichier .sub pour Flipper Zero afin de déclencher les systèmes sonores d'assistance aux personnes aveugles ou malvoyantes sur la voie publique.
Il se base sur l'analyse de la norme AFNOR NF-S32-002

### Disclaimer
Toutes les informations présentes ici sont exposées à titre informatif et éducatif.

Il est illégal d'utiliser ces informations à des fins malveillantes ou pour nuire à autrui.


### Matériel utilisé

Flipper Zero : https://shop.flipperzero.one/


### Analyse

L'analyse est basée sur le document de la norme AFNOR NF-S32-002 disponible gratuitement sur le lien suivants -> https://www.boutique.afnor.org/fr-fr/norme/nf-s32002/dispositifs-repetiteurs-de-feux-de-circulation-a-lusage-des-personnes-aveug/fa125183/650

Cette norme régit toutes les règles et le fonctionnement de ces dispositifs sonores et tactiles à l'usage des personnes non voyantes et malvoyantes.

Ce qui nous intéresse ici est le protocole de commande radio.

La fréquence d'émission du signal doit être centrée sur **868,3 MHz** avec une modulation d'amplitude.

Le protocole est constitué d'un en-tête comprenant :
* un préambule de 2 périodes de signal carré (durée totale 830 micro secondes)
* une synchronisation

puis un code unique et fixe codé sur 24 bits qui est **00A833**
Chaque caractère de ce code est codé sur 4 bits.
Les bits de poids faible sont envoyés en premier ce qui donne un code émis **338A00*

Vous trouverez sur les schémas ci-dessous, tous les éléments pour la génération du fichier RAW qui permet de déclencher l'activation du dispositif sonore.

![Description du protocole](https://github.com/kal-u/FlipperZero/blob/main/Sub-GHz/nf-s32002/protocole.jpeg)

Vous retrouverez dans le fichier **Activation dispositifs sonores nf-s32002.sub**, les éléments suivants :
* Préambule : 207 -208 207 -208 
* Synchronisation : 625 -312 313 -208 207 
* Code
	**3** : -500 500 -250 250 -250 250 
	**3** : -500 500 -250 250 -250 250 
	**8** : -250 250 -250 250 -250 250 -500 
	**A** : 250 -250 500 -250 250 -500
	**0** : 250 -250 250 -250 250 -250 250 -250 
	**0** : 250 -250 250 -250 250 -250 250 -250


*Les nombres positifs représentent le temps en microsecondes à l'état haut et les nombres négatifs à l'état bas.*

* Le "1" est un état haut ou bas de 500 ms

* Le "0" est un enchainement d'un état bas et haut de 250 ms
