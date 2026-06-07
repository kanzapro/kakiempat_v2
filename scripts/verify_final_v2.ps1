# Verifikasi final V2 - API + domain smoke
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$rand = Get-Random -Minimum 100000 -Maximum 999999
$ownerPhone = ('6289{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), $rand).Substring(0, 13)
$sitterPhone = ('6288{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), ($rand + 1)).Substring(0, 13)
$pass = 'TestV2!234'
$founderPhone = '6281248826888'
$founderPass = '123456'
$results = @{}

function Invoke-Api {
    param([string]$Method='GET',[string]$Url,[hashtable]$Headers=@{},[string]$Body=$null)
    $p = @{ Uri=$Url; Method=$Method; Headers=$Headers; UseBasicParsing=$true }
    if ($Body) { $p.Body=$Body; $p.ContentType='application/json' }
    try {
        $r = Invoke-WebRequest @p
        return @{ code=[int]$r.StatusCode; content=$r.Content; json=($r.Content|ConvertFrom-Json) }
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $sr = New-Object IO.StreamReader($resp.GetResponseStream())
            $c = $sr.ReadToEnd(); $sr.Close()
            return @{ code=[int]$resp.StatusCode; content=$c; json=($c|ConvertFrom-Json) }
        }
        throw
    }
}

function Json-Body($obj) { return ($obj | ConvertTo-Json -Compress -Depth 8) }

# Health + new endpoints
$h = Invoke-Api GET "$Base/health.php"
$results.health = ($h.json.mysql_ok -eq $true)

$founder = Invoke-Api POST "$Base/auth_v2.php?action=login" @{} "{`"phone`":`"$founderPhone`",`"password`":`"$founderPass`"}"
$FT = @{ Authorization = "Bearer $($founder.json.token)"; Accept='application/json'; 'Content-Type'='application/json' }

$listMy = Invoke-Api GET "$Base/marketplace_v2.php?action=list_my_requests" $FT
$results.list_my_requests = ($listMy.code -eq 200 -and $listMy.json.ok -eq $true)

$badAction = Invoke-Api GET "$Base/marketplace_v2.php?action=zzz_invalid" $FT
$results.new_marketplace_routes = ($badAction.content -match 'list_my_requests|list_offers')

# Full integration mini-flow
$regO = Invoke-Api POST "$Base/auth_v2.php?action=register" @{} (Json-Body @{
    phone = $ownerPhone; password = $pass; name = 'Verify Owner'; role = 'owner'
})
$regS = Invoke-Api POST "$Base/auth_v2.php?action=register" @{} (Json-Body @{
    phone = $sitterPhone; password = $pass; name = 'Verify Sitter'; role = 'sitter'
})
if (-not $regO.json.token -or -not $regS.json.token) {
    throw "Register gagal owner=$($regO.content) sitter=$($regS.content)"
}
$OH = @{ Authorization = "Bearer $($regO.json.token)"; Accept='application/json'; 'Content-Type'='application/json' }
$SH = @{ Authorization = "Bearer $($regS.json.token)"; Accept='application/json'; 'Content-Type'='application/json' }

Invoke-Api POST "$Base/sitter_v2.php?action=save_profile" $SH "{`"bio`":`"v`",`"address`":`"Jakarta`",`"services`":[`"dog_walking`"],`"latitude`":-6.2,`"longitude`":106.8}" | Out-Null
Invoke-Api POST "$Base/sitter_v2.php?action=submit_verification" $SH '{}' | Out-Null
Invoke-Api POST "$Base/admin_v2.php?action=approve_sitter" $FT "{`"sitter_id`":`"$($regS.json.user.id)`"}" | Out-Null

Invoke-Api POST "$Base/owner_v2.php?action=save_profile" $OH '{"address":"Jakarta","latitude":-6.21,"longitude":106.81}' | Out-Null
$pet = Invoke-Api POST "$Base/owner_v2.php?action=add_pet" $OH '{"name":"Max","species":"dog"}'
$petId = $pet.json.data.pet.id

$req = Invoke-Api POST "$Base/marketplace_v2.php?action=create_request" $OH (Json-Body @{
    service_type = 'dog_walking'
    date_label = 'Jun 20, 2026'
    time_range = '10:00-12:00'
    location = @{ address = 'Jl Test' }
    pets = @("$petId")
    price = 100000
})
$requestId = $req.json.data.request_id
if (-not $requestId) { throw "create_request gagal: $($req.content)" }
$listMyAfter = Invoke-Api GET "$Base/marketplace_v2.php?action=list_my_requests" $OH
$hasRequest = ($listMyAfter.json.data.requests | Where-Object { "$($_.id)" -eq "$requestId" })
$results.owner_list_my_requests = ($null -ne $hasRequest)

$offer = Invoke-Api POST "$Base/marketplace_v2.php?action=create_offer" $SH "{`"request_id`":`"$requestId`",`"price`":90000}"
$offerId = $offer.json.data.offer_id
$listOffers = Invoke-Api GET "$Base/marketplace_v2.php?action=list_offers&request_id=$requestId" $OH
$results.list_offers = ($listOffers.code -eq 200 -and ($listOffers.json.data.offers.Count -ge 1))

$acc = Invoke-Api POST "$Base/marketplace_v2.php?action=accept_offer" $OH "{`"offer_id`":`"$offerId`"}"
$bookingId = $acc.json.data.booking_id
$results.booking_created = ($acc.json.data.status -match 'awaitingPayment')

Invoke-Api POST "$Base/payment_v2.php?action=submit_proof" $OH "{`"booking_id`":`"$bookingId`",`"reference_code`":`"VF-$ts`"}" | Out-Null
Invoke-Api POST "$Base/payment_v2.php?action=admin_approve" $FT "{`"booking_id`":`"$bookingId`"}" | Out-Null
$bk = Invoke-Api GET "$Base/booking_v2.php?action=get_booking&booking_id=$bookingId" $OH
$results.payment_paid = ($bk.json.data.booking.status -match '^PAID$|^paid$')

Invoke-Api POST "$Base/booking_v2.php?action=sitter_confirm" $SH "{`"booking_id`":`"$bookingId`"}" | Out-Null
Invoke-Api POST "$Base/booking_v2.php?action=sitter_en_route" $SH "{`"booking_id`":`"$bookingId`"}" | Out-Null
Invoke-Api POST "$Base/booking_v2.php?action=start_booking" $SH "{`"booking_id`":`"$bookingId`"}" | Out-Null
Invoke-Api POST "$Base/booking_v2.php?action=complete_booking" $SH "{`"booking_id`":`"$bookingId`"}" | Out-Null
$bk2 = Invoke-Api GET "$Base/booking_v2.php?action=get_booking&booking_id=$bookingId" $OH
$results.booking_completed = ($bk2.json.data.booking.status -match 'completed')

$wal = Invoke-Api GET "$Base/wallet_v2.php?action=get_ledger" $SH
$income = ($wal.json.data.entries | Where-Object { "$($_.booking_id)" -eq "$bookingId" -and $_.type -eq 'income' }).amount
$results.wallet = ($income -eq 90000)

$wd = Invoke-Api POST "$Base/wallet_v2.php?action=request_withdrawal" $SH '{"amount":10000}'
$wid = $wd.json.data.withdrawal.id
Invoke-Api POST "$Base/admin_v2.php?action=approve_withdrawal" $FT "{`"withdrawal_id`":`"$wid`"}" | Out-Null
$results.withdrawal = ($wd.code -in 200,201)

Invoke-Api POST "$Base/chat_v2.php?action=send_message" $OH "{`"booking_id`":`"$bookingId`",`"text`":`"verify`"}" | Out-Null
Invoke-Api POST "$Base/chat_v2.php?action=send_message" $SH "{`"booking_id`":`"$bookingId`",`"text`":`"reply`"}" | Out-Null
$chat = Invoke-Api GET "$Base/chat_v2.php?action=get_messages&booking_id=$bookingId" $OH
$results.chat = (@($chat.json.data.messages).Count -ge 2)

$no = Invoke-Api GET "$Base/notification_v2.php?action=check_new" $OH
$ns = Invoke-Api GET "$Base/notification_v2.php?action=check_new" $SH
$results.notif = ([int]$no.json.data.unread_count -gt 0 -and [int]$ns.json.data.unread_count -gt 0)

# Domain HTTP checks
$domains = @{
    www = 'https://www.kakiempat.com'
    owner = 'https://owner.kakiempat.com'
    sitter = 'https://sitter.kakiempat.com'
    admin = 'https://admin.kakiempat.com'
    api = 'https://api.kakiempat.com/health.php'
}
$domainOk = @{}
foreach ($k in $domains.Keys) {
    try {
        $dr = Invoke-WebRequest -Uri $domains[$k] -UseBasicParsing -TimeoutSec 30
        $domainOk[$k] = ($dr.StatusCode -eq 200)
    } catch { $domainOk[$k] = $false }
}

$out = [PSCustomObject]@{
    run_at = (Get-Date).ToUniversalTime().ToString('o')
    api_checks = $results
    domains = $domainOk
    test_phones = @{ owner = $ownerPhone; sitter = $sitterPhone }
    ids = @{ request_id = $requestId; offer_id = $offerId; booking_id = $bookingId }
}
$outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$out | ConvertTo-Json -Depth 6 | Out-File (Join-Path $outDir 'verify_final_v2.json') -Encoding utf8
Write-Host ($out | ConvertTo-Json -Depth 6)
