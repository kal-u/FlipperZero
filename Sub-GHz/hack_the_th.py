#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Dec 15 16:29:34 2024

@author: Kalu (Gabriel F.)
"""

import time
import os

def clear_console():
    """
    Efface le contenu de la console.
    """
    # Détecte le système d'exploitation et utilise la commande appropriée
    if os.name == 'nt':  # Windows
        os.system('cls')
    else:  # Unix/Linux/Mac
        os.system('clear')

# Utilisation de la fonction
clear_console()


# Affichage du banner
def print_banner(text, width=80, fill_char='*'):
    lines = text.split('\n')
    max_length = max(len(line) for line in lines)
    
    print(fill_char * (max_length+4))
    for line in lines:
        print(f"{fill_char} {line.center(max_length)} {fill_char}")
    print(fill_char * (max_length+4))

# Affichage du banner
print_banner("Script de generation d'un fichier .sub (Sub GHz)\npour Flipper Zero\npar Kalu", fill_char='#')
print()

# Fonction pour vérifier si l'identifiant est valide
def is_valid_sensor_id(sensor_id):
    if 0 <= int(sensor_id) <= 999:
        return True
    else:
        return False

# Fonction pour vérifier si l'état de la batterie est valide
def is_valid_battery_state(battery_state):
    if battery_state in ["0", "1"]:
        return True
    else:
        return False

# Fonction pour vérifier si le canal de la sonde est valide
def is_valid_sensor_channel(sensor_channel):
    if sensor_channel in ["1", "2", "3"]:
        return True
    else:
        return False

# Fonction pour vérifier si la température est valide
def is_valid_temperature(temperature):
    if 0 <= int(temperature) <= 99:
        return True
    else:
        return False

# Fonction pour vérifier si l'humidité est valide
def is_valid_humidity(humidity):
    if 0 <= int(humidity) <= 99:
        return True
    else:
        return False

# Fonction pour vérifier si le nom de fichier est valide
def is_valid_filename(filename):
    if filename.endswith(".sub"):
        return True
    else:
        return False

# Demander l'identifiant de la sonde à l'utilisateur
while True:
    sensor_id = input("Entrez l'identifiant de la sonde : ")
    if is_valid_sensor_id(sensor_id):
        sensor_id = int(sensor_id)
        break
    else:
        print("L'identifiant doit être un nombre de 3 chiffres maximum. Veuillez réessayer.")

# Demander l'état de la batterie à l'utilisateur
while True:
    battery_state = input("Entrez l'état de la batterie (0 pour faible, 1 pour OK) : ")
    if is_valid_battery_state(battery_state):
        battery_state = int(battery_state)
        break
    else:
        print("L'état de la batterie doit être 0 ou 1. Veuillez réessayer.")

# Demander le canal de la sonde de température à l'utilisateur
while True:
    sensor_channel = input("Entrez le canal de la sonde de température (1, 2 ou 3) : ")
    if is_valid_sensor_channel(sensor_channel):
        sensor_channel = int(sensor_channel)
        channel = sensor_channel - 1
        break
    else:
        print("Le canal de la sonde doit être 1, 2 ou 3. Veuillez réessayer.")

# Demander la température à l'utilisateur
while True:
    temperature = input("Entrez la température (entre 0 et 99 degrés) : ")
    if is_valid_temperature(temperature):
        temperature = int(temperature)
        temp = temperature * 10
        break
    else:
        print("La température doit être comprise entre 0 et 99 degrés. Veuillez réessayer.")

# Demander l'humidité à l'utilisateur
while True:
    humidity = input("Entrez le taux d'humidité (entre 0 et 99 %) : ")
    if is_valid_humidity(humidity):
        humidity = int(humidity)
        break
    else:
        print("Le taux d'humidité doit être compris entre 0 et 99 %. Veuillez réessayer.")

# Demander le nom de fichier à l'utilisateur
while True:
    filename = input("Entrez le nom du fichier (avec l'extension .sub) : ")
    if is_valid_filename(filename):
        break
    else:
        print("Le nom de fichier doit se terminer par .sub. Veuillez réessayer.")

# Calcul de la chaine héxadécimale pour les données à envoyer
binary_number = "00000000 00000000 00000000 0000"
binary_sensor_id = bin(sensor_id)[2:].zfill(8)
binary_battery_state = bin(battery_state)[2:].zfill(1)
binary_channel = bin(channel)[2:].zfill(2)
binary_temperature = bin(temp)[2:].zfill(12)
binary_humidity = bin(humidity)[2:].zfill(8)
binary_number = binary_number + str(binary_sensor_id) + str(binary_battery_state) + "0" + str(binary_channel) + str(binary_temperature) + "1111" + str(binary_humidity)
binary_number = binary_number.replace(" ", "")

# Conversion par groupe de 8 bits
hex_groups = [hex(int(binary_number[i:i+8], 2))[2:].zfill(2).upper() for i in range(0, len(binary_number), 8)]

# Affectation du résultat à la variable data
data = " ".join(hex_groups)



# Récupération du timestamp actuel
current_timestamp = time.time()

# Conversion du timestamp en structure de données
current_time = time.localtime(current_timestamp)

# Ajout de 1 heure
new_time = time.struct_time((
    current_time.tm_year,
    current_time.tm_mon,
    current_time.tm_mday,
    current_time.tm_hour + 1,
    current_time.tm_min,
    current_time.tm_sec,
    current_time.tm_wday,
    current_time.tm_yday,
    current_time.tm_isdst
))

# Conversion de la nouvelle structure de données en timestamp
new_timestamp = time.mktime(new_time)
ts = int(new_timestamp)


# Définir le contenu du fichier
content = """Filetype: Flipper SubGhz Key File
Version: 1
Frequency: 433920000
Preset: FuriHalSubGhzPresetOok650Async
Lat: 0.000000
Lon: 0.000000
Protocol: Nexus-TH
Id: {}
Bit: 36
Data: {}
Batt: {}
Hum: {}
Ts: {}
Ch: {}
Btn: 255
Temp: {}.000000
""".format(sensor_id, data, battery_state, humidity, ts, sensor_channel, temperature)

# Créer le fichier et y écrire le contenu
with open(filename, "w") as file:
    file.write(content)

print()
print(f"Le fichier \033[93m{filename}\033[0m a été créé avec succès.")
print()
