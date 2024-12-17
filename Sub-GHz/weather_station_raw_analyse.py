import re
import sys
import os

# Clear de la console
def clear_console():
    os.system('cls' if os.name == 'nt' else 'clear')

clear_console()


# Affichage du banner
def print_banner(text, width=80, fill_char='*'):
    """
    Affiche un banner de texte centré sur plusieurs lignes.
    
    Args:
        text (str): Le texte à afficher dans le banner.
        width (int): La largeur du banner (par défaut 80).
        fill_char (str): Le caractère à utiliser pour remplir le banner (par défaut '*').
    """
    lines = text.split('\n')
    max_length = max(len(line) for line in lines)
    
    print(fill_char * (max_length+4))
    for line in lines:
        print(f"{fill_char} {line.center(max_length)} {fill_char}")
    print(fill_char * (max_length+4))

# Affichage du banner
print_banner("Script de d'analyse d'un fichier RAW .sub (Sub GHz)\nissu de la capture d'un signal d'un capteur \nde station météo utilisant le protocole Nexus-TH\npour Flipper Zero\npar Kalu", fill_char='#')
print()


# Fonction pour traiter les données RAW
def process_raw_data(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
        data = file.read()

    # Extraction des lignes contenant "RAW_Data"
    raw_lines = re.findall(r'RAW_Data: (.+)', data)

    # Fusionner toutes les lignes RAW_Data en une seule séquence
    raw_sequence = ' '.join(raw_lines)

    # Extraire les nombres négatifs
    negative_numbers = [int(num) for num in raw_sequence.split() if int(num) < 0]

    # Identifier les segments débutant et finissant par des nombres < -3900
    segments = []
    temp_segment = []
    in_segment = False

    for number in negative_numbers:
        if number < -3900:  # Marqueur de début ou de fin
            if in_segment and len(temp_segment) == 36:  # Fin de la séquence
                segments.append(temp_segment)
            temp_segment = []  # Réinitialiser la séquence temporaire
            in_segment = not in_segment  # Basculer l'état de séquence
        elif in_segment:
            temp_segment.append(number)

    # Transformer les segments en séquences binaires
    results = []
    for segment in segments:
        if len(segment) == 36:  # S'assurer que la longueur est correcte
            binary_sequence = [0 if num > -1100 else 1 for num in segment]
            
            # Analyser les données de la séquence
            battery_status = binary_sequence[8]  # 9ème chiffre
            channel_binary = binary_sequence[10:12]  # 11ème et 12ème chiffres
            channel = int(''.join(map(str, channel_binary)), 2)  # Convertir en décimal
            temp_binary = binary_sequence[12:24]  # 12 chiffres suivants
            temperature = int(''.join(map(str, temp_binary)), 2) / 10.0  # Valeur décimale
            humidity_binary = binary_sequence[28:36]  # 8 derniers chiffres
            humidity = int(''.join(map(str, humidity_binary)), 2)  # Valeur décimale

            # Ajouter les résultats
            results.append({
                "sequence": ''.join(map(str, binary_sequence)),
                "battery_status": "OK" if battery_status == 1 else "Batterie faible",
                "channel": f"CH{channel + 1}",
                "temperature": temperature,
                "humidity": humidity
            })

    return results

# Vérifier les arguments de la ligne de commande
if len(sys.argv) < 2:
    script_name = os.path.basename(sys.argv[0])
    print("\033[91mErreur: Veuillez fournir le chemin du fichier à analyser en argument.\033[0m")
    print(f"Usage: python {script_name} <file_path>")
    sys.exit(1)

# Chemin du fichier
file_path = sys.argv[1]

# Exécuter le traitement et afficher les résultats
try:
    results = process_raw_data(file_path)
    for i, result in enumerate(results):
        print()
        print(f"\033[96mSequence {i+1}: {result['sequence']}\033[0m")
        print(f"  Batterie: {result['battery_status']}")
        print(f"  Canal: {result['channel']}")
        print(f"  Température: {result['temperature']} °C")
        print(f"  Humidité: {result['humidity']}%")
except FileNotFoundError:
    print(f"\033[91mErreur: Le fichier spécifié '{file_path}' est introuvable.\033[0m")
except Exception as e:
    print(f"\033[91mErreur lors du traitement du fichier: {e}\033[0m")
