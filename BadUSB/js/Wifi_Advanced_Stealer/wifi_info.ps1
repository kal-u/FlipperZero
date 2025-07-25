#
# Ce script est à lancer depuis une console Powershell lancée en Administrateur
#

# Chemin dans le registre vers les informations des profiles réseaux
$regProfilPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\"

# Chemin dans le registre vers les informations des réseaux non gérés par GPO
$regUnmanagedPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged'

# Initialisation du tableau de résultats
$results = @()

# Récupération de la liste des profils (SSID)
$wifiProfiles = netsh wlan show profiles | Select-String ':\s*(.+)$' | %{
	$_.Matches.Groups[1].Value
}


# Fonction de décodage de date
function decodeDate {
	param (
		$rawdate
    )
	
	# Chaque élément de 2 octets est au format little endian et correspond aux valeurs suivantes, dans l'ordre :
	# Année, Mois, Jour de la semaine, Jour, Heure, Minutes, Secondes, Millièmes
	# Exemple : E9 07 devient 07 E9 qui en décimal correspond à l'année 2025
	
	# Reconvertir chaque valeur décimale en hexadécimal, inverser chaque paire et convertir en décimal
	$decodedValues = @()
	for ($i = 0; $i -lt $rawdate.Length; $i += 2) {
		# Récupérer les 2 octets du tableau
		$bytePair = $rawdate[$i..($i+1)]

		# Reconvertir chaque octet en hexadécimal
		$hexPair = $bytePair | ForEach-Object { '{0:X2}' -f $_ }

		# Inverser les octets (Little-endian)
		$invertedHex = $hexPair[1] + $hexPair[0]  # Inversion des octets

		# Convertir la paire hexadécimale inversée en valeur décimale
		$decimalValue = [convert]::ToInt32($invertedHex, 16)

		# Ajouter la valeur décimale à la liste
		$decodedValues += $decimalValue
	}

	# Les 8 premiers éléments correspondent aux informations de date et d'heure
	$year = $decodedValues[0]       # Année
	$month = $decodedValues[1]      # Mois
	$weekday = $decodedValues[2]    # Jour de la semaine (peut être ignoré)
	$day = $decodedValues[3]        # Jour du mois
	$hour = $decodedValues[4]       # Heure
	$minute = $decodedValues[5]     # Minutes
	$second = $decodedValues[6]     # Secondes
	$millisecond = $decodedValues[7] # Millisecondes (ajuster si trop grand)

	# Vérifier et ajuster la valeur des millisecondes
	if ($millisecond -gt 999) {
		$millisecond = 999
	}

	# Créer un objet DateTime
	$dateTime = New-Object DateTime($year, $month, $day, $hour, $minute, $second, $millisecond)

	# Afficher la date dans le format français
	$formattedDate = $dateTime.ToString("dd/MM/yyyy HH:mm:ss")
	return $formattedDate
}


# Pour chaque profil Wifi
foreach ($profile in $wifiProfiles) {
	if ($profile.length -gt 1) {
		# Récupération du mot de passe Wifi
		$secret_key = ''
		(netsh wlan show profile name=$profile key=clear) | Select-String '(Contenu|Key).*:(.+)$' | %{
			$secret_key = $_.Matches.Groups[2].Value.Trim()
		}
		
		# Récupération de l'adresse MAC du point d'accès Wifi (BSSID)
		$subKeys = Get-ChildItem -Path $regUnmanagedPath
		foreach ($subKey in $subKeys) { 
			$description = Get-ItemProperty -Path $subKey.PSPath -Name 'Description' -ErrorAction SilentlyContinue
			if ($description -and $description.Description -like '*'+$profile+'*') {
				$defaultGatewayMac = Get-ItemProperty -Path $subKey.PSPath -Name 'DefaultGatewayMac' -ErrorAction SilentlyContinue
				if ($defaultGatewayMac) {
					$macHex = ($defaultGatewayMac.DefaultGatewayMac | %{ '{0:X2}' -f $_ }) -join ':'
				} 
			} 
		}
		
		# Récupération de la date de dernière connexion
		$subKeysProf = Get-ChildItem -Path $regProfilPath
		foreach ($subKeyProf in $subKeysProf) { 
			$elem = Get-ItemProperty -Path $subKeyProf.PSPath -Name 'Description' -ErrorAction SilentlyContinue
			if ($elem -and $elem.Description -like '*'+$profile+'*') {
				$LastDateConnectedRaw = ''
				$LastDateConnectedRaw = (Get-ItemProperty -Path $subKeyProf.PSPath -Name 'DateLastConnected' -ErrorAction SilentlyContinue).DateLastConnected
				if ($LastDateConnectedRaw) {
					$formattedDate = decodeDate($LastDateConnectedRaw)
				}
				$FirstDateConnectedRaw = (Get-ItemProperty -Path $subKeyProf.PSPath -Name 'DateCreated' -ErrorAction SilentlyContinue).DateCreated
				if ($FirstDateConnectedRaw) {
					$formattedDate2 = decodeDate($FirstDateConnectedRaw)
				}				
			} 
		}
		
		# Ajout au tableau des résultats
		$results += [PSCustomObject]@{
			SSID = $profile
			BSSID = $macHex
			Key = $secret_key
			LastConnected = $formattedDate
			FirstConnected = $formattedDate2
		} 
	} 
} 
$results | Format-Table -AutoSize


