# Verify chat available immediately after accept_offer.
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$rand = Get-Random -Minimum 100000 -Maximum 999999
$ownerPhone = ('6289{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), $rand).Substring(0, 13)
$sitterPhone = ('6288{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), ($rand + 1)).Substring(0, 13)
$password = 'ChatE2E!234'

function Json-Body($obj) { $obj | ConvertTo-Json -Compress -Depth 6 }

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
            return @{ code = [int]$resp.StatusCode; json = ($raw | ConvertFrom-Json); raw = $raw }
        }
        throw
    }
}

Write-Host "Chat post-accept E2E owner=$ownerPhone sitter=$sitterPhone"

$regO = Invoke-Api -Method POST -Url "$Base/auth_v2.php?action=register" -Body (Json-Body @{
    phone = $ownerPhone; password = $password; name = 'Chat Owner'; role = 'owner'
})
if (-not $regO.json.token) { throw "register owner failed: $($regO.raw)" }

$regS = Invoke-Api -Method POST -Url "$Base/auth_v2.php?action=register" -Body (Json-Body @{
    phone = $sitterPhone; password = $password; name = 'Chat Sitter'; role = 'sitter'
})
if (-not $regS.json.token) { throw "register sitter failed: $($regS.raw)" }

$OH = @{ Authorization = "Bearer $($regO.json.token)"; Accept = 'application/json' }
$SH = @{ Authorization = "Bearer $($regS.json.token)"; Accept = 'application/json' }
$sitterId = "$($regS.json.user.id)"

Invoke-Api -Method POST -Url "$Base/sitter_v2.php?action=save_profile" -Headers $SH -Body (Json-Body @{
    bio = 'Chat E2E'; address = 'Jl Test'; services = @('dog_walking')
    latitude = -6.2; longitude = 106.8
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
    name = 'Max'; species = 'dog'; breed = 'Mix'
})
$petId = $petR.json.data.pet.id
Invoke-Api -Method POST -Url "$Base/owner_v2.php?action=save_profile" -Headers $OH -Body (Json-Body @{
    address = 'Jl Owner'; latitude = -6.21; longitude = 106.81
}) | Out-Null

$reqR = Invoke-Api -Method POST -Url "$Base/marketplace_v2.php?action=create_request" -Headers $OH -Body (Json-Body @{
    service_type = 'dog_walking'; date_label = 'Jun 20, 2026'; time_range = '10:00-12:00'
    location = @{ address = 'Jl Test 1'; latitude = -6.21; longitude = 106.81 }
    pets = @("$petId"); price = 80000
})
$requestId = $reqR.json.data.request_id

$offerR = Invoke-Api -Method POST -Url "$Base/marketplace_v2.php?action=create_offer" -Headers $SH -Body (Json-Body @{
    request_id = "$requestId"; price = 75000; message = 'Siap'
})
$offerId = $offerR.json.data.offer_id

$accR = Invoke-Api -Method POST -Url "$Base/marketplace_v2.php?action=accept_offer" -Headers $OH -Body (Json-Body @{
    offer_id = "$offerId"
})
$bookingId = $accR.json.data.booking_id
$chatReady = $accR.json.data.chat_ready
Write-Host "accept_offer booking_id=$bookingId chat_ready=$chatReady status=$($accR.json.data.status)"
if (-not $bookingId) { throw "accept_offer missing booking_id: $($accR.raw)" }

$sendO = Invoke-Api -Method POST -Url "$Base/chat_v2.php?action=send_message" -Headers $OH -Body (Json-Body @{
    booking_id = "$bookingId"; text = 'Halo sitter, booking sudah jadi!'
})
if ($sendO.code -notin 200, 201) { throw "owner send_message failed: $($sendO.raw)" }

$sendS = Invoke-Api -Method POST -Url "$Base/chat_v2.php?action=send_message" -Headers $SH -Body (Json-Body @{
    booking_id = "$bookingId"; text = 'Siap owner, saya siap chat!'
})
if ($sendS.code -notin 200, 201) { throw "sitter send_message failed: $($sendS.raw)" }

$msgsR = Invoke-Api -Url "$Base/chat_v2.php?action=get_messages&booking_id=$bookingId" -Headers $OH
$count = @($msgsR.json.data.messages).Count
$bookingHeader = $msgsR.json.data.booking
Write-Host "get_messages count=$count booking.status=$($bookingHeader.status)"

if ($count -lt 2) { throw "expected >=2 messages, got $count" }

$notifO = Invoke-Api -Url "$Base/notification_v2.php?action=get_notifications" -Headers $OH
$notifS = Invoke-Api -Url "$Base/notification_v2.php?action=get_notifications" -Headers $SH
$ownerTypes = @($notifO.json.data.notifications | ForEach-Object { $_.type })
$sitterTypes = @($notifS.json.data.notifications | ForEach-Object { $_.type })
Write-Host "owner notifications: $($ownerTypes -join ', ')"
Write-Host "sitter notifications: $($sitterTypes -join ', ')"

$ownerHasBookingCreated = 'booking_created' -in $ownerTypes
$sitterHasOfferAccepted = 'offer_accepted' -in $sitterTypes

Write-Host ''
Write-Host 'CHAT PASCA-TAWARAN AKTIF - Chat langsung tersedia setelah accept_offer' -ForegroundColor Green
Write-Host "booking_id=$bookingId messages=$count owner_booking_created=$ownerHasBookingCreated sitter_offer_accepted=$sitterHasOfferAccepted chat_ready_flag=$chatReady"
