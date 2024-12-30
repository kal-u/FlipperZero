######################################
# Découverte de fonctions TV cachées #
#------------------------------------# 
# Script de génération de signaux    #
# infrarouges pour télécommande      #
# SONY mais peu être adapté à        #
# d'autres marques                   #
######################################

# Ouverture du fichier 'sony_remote_fuzz.ir' en mode écriture
with open('sony_remote_fuzz.ir', 'w') as f:
    # Définition des paramètres du protocole et de l'adresse
    protocol = "SIRC"  # Protocole utilisé
    address = "01 00 00 00"  # Adresse fixe en format hexadécimal

    # Plage des commandes (de 0x0000 à 0x00FF)
    cmd_min = 0x0000  # Valeur minimale
    cmd_max = 0x00FF  # Valeur maximale

    # Écriture de l'en-tête du fichier
    f.write("Filetype: IR signals file\nVersion: 1\n")

    # Boucle sur toutes les valeurs de commande dans la plage définie
    for i in range(cmd_min, cmd_max + 1):
        # Conversion de la commande actuelle en 4 octets hexadécimaux (avec remplissage)
        cmd_hex_1 = hex(i % 256)[2:].zfill(2).upper()
        cmd_hex_2 = hex((i >> 8) % 256)[2:].zfill(2).upper()
        cmd_hex_3 = hex((i >> 16) % 256)[2:].zfill(2).upper()
        cmd_hex_4 = hex((i >> 24) % 256)[2:].zfill(2).upper()

        # Génération de la chaîne de texte pour chaque commande
        cmd_str = (
            f"#\n"  # Commentaire pour séparer les commandes
            f"name: Cmd {cmd_hex_1} {cmd_hex_2} {cmd_hex_3} {cmd_hex_4}\n"  # Nom
            "type: parsed\n"  # Type de signal
            f"protocol: {protocol}\n"  # Protocole utilisé
            f"address: {address}\n"  # Adresse du signal
            f"command: {cmd_hex_1} {cmd_hex_2} {cmd_hex_3} {cmd_hex_4}\n"  # Commande
        )

        # Écriture de la commande dans le fichier
        f.write(cmd_str)
