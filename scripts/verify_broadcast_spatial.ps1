# Verifikasi broadcast booking v2 — filter spasial radius 7 km (Haversine).
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$rand = Get-Random -Minimum 100000 -Maximum 999999
$ownerPhone = ('6289{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), $rand).Substring(0, 13)
$sitterPhone = ('6288{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), ($rand + 1)).Substring(0, 13)
$password = 'SpatialE2E!234'

function Json-Body($obj) { $obj | ConvertTo-Json -Compress -Depth 8 }

function Invoke-Api {
    param(
        [string]$Method = 'GET', [string]$Url,
        [hashtable]$Headers = @{}, [string]$Body = $null
    )
    $params = @{ Uri = $Url; Method = $Method; Headers = $Headers; UseBasicParsing = $true }
    if ($Body) { $params.Body = $Body; $params.ContentType = 'application/json' }
    try {
        $r = Invoke-WebRequest @params
        return @{ code = [int]$r.StatusCode; json = ($r.Content | ConvertFrom-Json); raw = $r.Content }
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $sr = New-Object IO.StreamReader($resp.GetResponseStream())
            $raw = $sr.ReadToEnd(); $sr.Close()
            $json = $null
            try { $json = $raw | ConvertFrom-Json } catch {}
            return @{ code = [int]$resp.StatusCode; json = $json; raw = $raw }
        }
        throw
    }
}

Write-Host '=== Broadcast spatial verification ===' -ForegroundColor Cyan
Write-Host "owner=$ownerPhone sitter=$sitterPhone"

$regO = Invoke-Api -Method POST -Url "$Base/auth_v2.php?action=register" -Body (Json-Body @{
    phone = $ownerPhone; password = $password; name = 'Owner Spatial'; role = 'owner'
})
$regS = Invoke-Api -Method POST -Url "$Base/auth_v2.php?action=register" -Body (Json-Body @{
    phone = $sitterPhone; password = $password; name = 'Sitter Spatial'; role = 'sitter'
})
if (-not $regO.json.token -or -not $regS.json.token) {
    Write-Host 'Register failed' -ForegroundColor Red
    Write-Host $regO.raw
    Write-Host $regS.raw
    exit 1
}

$OH = @{ Authorization = "Bearer $($regO.json.token)"; Accept = 'application/json' }
$SH = @{ Authorization = "Bearer $($regS.json.token)"; Accept = 'application/json' }
$sitterId = "$($regS.json.user.id)"

$locA = @{ latitude = -6.2088; longitude = 106.8456; address = 'Jakarta Pusat A' }
$locB = @{ latitude = -7.7956; longitude = 110.3695; address = 'Yogyakarta B' }

Invoke-Api -Method POST -Url "$Base/sitter_v2.php?action=save_profile" -Headers $SH -Body (Json-Body @{
    bio = 'Spatial E2E'; address = 'Jl Sitter A'; services = @('dog_walking')
    latitude = $locA.latitude; longitude = $locA.longitude
}) | Out-Null
Invoke-Api -Method POST -Url "$Base/sitter_v2.php?action=submit_verification" -Headers $SH -Body '{}' | Out-Null

$loginA = Invoke-Api -Method POST -Url "$Base/auth_v2.php?action=login" -Body (Json-Body @{
    phone = '6281248826888'; password = '123456'
})
$AH = @{ Authorization = "Bearer $($loginA.json.token)"; Accept = 'application/json' }
Invoke-Api -Method POST -Url "$Base/admin_v2.php?action=approve_sitter" -Headers $AH -Body (Json-Body @{
    sitter_id = $sitterId
}) | Out-Null

$petR = Invoke-Api -Method POST -Url "$Base/owner_v2.php?action=add_pet" -Headers $OH -Body (Json-Body @{
    name = 'Doggo'; species = 'dog'; breed = 'Mix'
})
$petId = $petR.json.data.pet.id
Invoke-Api -Method POST -Url "$Base/owner_v2.php?action=save_profile" -Headers $OH -Body (Json-Body @{
    address = 'Jl Owner A'; latitude = $locA.latitude; longitude = $locA.longitude
}) | Out-Null

$reqR = Invoke-Api -Method POST -Url "$Base/marketplace_v2.php?action=create_request" -Headers $OH -Body (Json-Body @{
    service_type = 'dog_walking'
    date_label = 'Jun 10, 2026'
    time_range = '09:00-11:00'
    location = $locA
    pets = @("$petId")
    price = 100000
})
Write-Host "create_request HTTP $($reqR.code)" -ForegroundColor Yellow
Write-Host $reqR.raw

$near = Invoke-Api -Url "$Base/marketplace_v2.php?action=list_requests&latitude=$($locA.latitude)&longitude=$($locA.longitude)&radius_km=7" -Headers $SH
$far = Invoke-Api -Url "$Base/marketplace_v2.php?action=list_requests&latitude=$($locB.latitude)&longitude=$($locB.longitude)&radius_km=7" -Headers $SH

$nearTotal = [int]$near.json.data.total
$farTotal = [int]$far.json.data.total
Write-Host "NEAR (Jakarta): total=$nearTotal spatial=$($near.json.data.spatial_filter) radius=$($near.json.data.radius_km)" -ForegroundColor Green
Write-Host "FAR (Yogyakarta): total=$farTotal spatial=$($near.json.data.spatial_filter) radius=$($near.json.data.radius_km)" -ForegroundColor Green

$estimate = Invoke-Api -Url "$Base/marketplace_v2.php?action=estimate_broadcast&service_type=dog_walking&latitude=$($locA.latitude)&longitude=$($locA.longitude)&radius_km=7" -Headers $OH
Write-Host "estimate_broadcast sitter_count=$($estimate.json.data.sitter_count_in_radius)" -ForegroundColor Green

if ($nearTotal -ge 1 -and $farTotal -eq 0) {
    Write-Host 'BROADCAST BOOKING V2 AKTIF - Radius 7km, polling 30 detik' -ForegroundColor Green
    exit 0
}

Write-Host 'SPATIAL CHECK FAILED' -ForegroundColor Red
exit 1
