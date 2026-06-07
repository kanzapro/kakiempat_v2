# Audit 36 endpoint API v2 — E2E setup + verifikasi
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$WebhookSecret = 'KE_SECURE_NOTIF_TOKEN_2026_BYPASS'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$ownerPhone = "6289$($ts.ToString().Substring($ts.ToString().Length-9))"
$sitterPhone = "6288$($ts.ToString().Substring($ts.ToString().Length-9))"
$results = @()
$n = 0

function Add-Result($name, $ok, $http, $notes) {
    $script:n++
    $script:results += [PSCustomObject]@{
        Num = $n; Endpoint = $name; Status = $(if ($ok) { 'OK' } else { 'FAIL' })
        HTTP = $http; Notes = $notes
    }
}

function Invoke-Api {
    param(
        [string]$Name, [string]$Method = 'GET', [string]$Url,
        [hashtable]$Headers = @{}, [string]$Body = $null,
        [int[]]$OkCodes = @(200, 201), [switch]$AllowFail
    )
    try {
        $params = @{ Uri = $Url; Method = $Method; Headers = $Headers; UseBasicParsing = $true }
        if ($Body) { $params.Body = $Body }
        $r = Invoke-WebRequest @params
        $code = [int]$r.StatusCode
        $content = $r.Content
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $code = [int]$resp.StatusCode
            $sr = New-Object IO.StreamReader($resp.GetResponseStream())
            $content = $sr.ReadToEnd()
            $sr.Close()
        } else {
            $code = 0
            $content = $_.Exception.Message
        }
    }
    $ok = $OkCodes -contains $code
    if (-not $AllowFail -and -not $ok) {
        $snippet = if ($content.Length -gt 120) { $content.Substring(0, 120) + '...' } else { $content }
        Add-Result $Name $false $code $snippet
        return @{ ok = $false; code = $code; content = $content }
    }
    $snippet = if ($content.Length -gt 100) { $content.Substring(0, 100) + '...' } else { $content }
    Add-Result $Name $true $code $snippet
    return @{ ok = $true; code = $code; content = $content }
}

function Parse-Json($text) {
    try { return $text | ConvertFrom-Json } catch { return $null }
}

Write-Host "Owner: $ownerPhone | Sitter: $sitterPhone"

# 1 Health
Invoke-Api 'health.php' 'GET' "$Base/health.php"

# 2-4 Auth
$regO = Invoke-Api 'auth/register (owner)' 'POST' "$Base/auth_v2.php?action=register" @{
    'Content-Type' = 'application/json'
} "{`"phone`":`"$ownerPhone`",`"password`":`"TestApi!234`",`"name`":`"Owner Audit`",`"role`":`"owner`"}"

$regS = Invoke-Api 'auth/register (sitter)' 'POST' "$Base/auth_v2.php?action=register" @{
    'Content-Type' = 'application/json'
} "{`"phone`":`"$sitterPhone`",`"password`":`"TestApi!234`",`"name`":`"Sitter Audit`",`"role`":`"sitter`"}"

$loginO = Invoke-Api 'auth/login (owner)' 'POST' "$Base/auth_v2.php?action=login" @{
    'Content-Type' = 'application/json'
} "{`"phone`":`"$ownerPhone`",`"password`":`"TestApi!234`"}"
$ownerToken = (Parse-Json $loginO.content).token

$loginS = Invoke-Api 'auth/login (sitter)' 'POST' "$Base/auth_v2.php?action=login" @{
    'Content-Type' = 'application/json'
} "{`"phone`":`"$sitterPhone`",`"password`":`"TestApi!234`"}"
$sitterToken = (Parse-Json $loginS.content).token

$loginF = Invoke-Api 'auth/login (founder)' 'POST' "$Base/auth_v2.php?action=login" @{
    'Content-Type' = 'application/json'
} '{"phone":"6281248826888","password":"123456"}'
$founderToken = (Parse-Json $loginF.content).token

Invoke-Api 'auth/validate_token' 'GET' "$Base/auth_v2.php?action=validate_token" @{
    'Authorization' = "Bearer $ownerToken"
}

$OH = @{ 'Authorization' = "Bearer $ownerToken"; 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }
$SH = @{ 'Authorization' = "Bearer $sitterToken"; 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }
$FH = @{ 'Authorization' = "Bearer $founderToken"; 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }

# 5-7 Sitter
Invoke-Api 'sitter/get_profile' 'GET' "$Base/sitter_v2.php?action=get_profile" $SH
Invoke-Api 'sitter/save_profile' 'POST' "$Base/sitter_v2.php?action=save_profile" $SH `
    '{"bio":"Audit sitter","address":"Jl Sitter 1 Jakarta","services":["dog_walking"],"latitude":-6.2,"longitude":106.8}'
Invoke-Api 'sitter/submit_verification' 'POST' "$Base/sitter_v2.php?action=submit_verification" $SH '{}'

# 8-10 Owner
Invoke-Api 'owner/get_profile' 'GET' "$Base/owner_v2.php?action=get_profile" $OH
Invoke-Api 'owner/save_profile' 'POST' "$Base/owner_v2.php?action=save_profile" $OH `
    '{"address":"Jl Owner 1 Jakarta","latitude":-6.21,"longitude":106.81}'
$petR = Invoke-Api 'owner/add_pet' 'POST' "$Base/owner_v2.php?action=add_pet" $OH `
    '{"name":"Milo","species":"dog","breed":"Mix","notes":"Audit pet"}'
$petId = (Parse-Json $petR.content).data.pet.id
if (-not $petId) { throw 'add_pet did not return pet.id' }

# 11 Catalog (auth wajib di server)
Invoke-Api 'service/get_catalog' 'GET' "$Base/service_v2.php?action=get_catalog" $OH

# Admin approve sitter before marketplace
Invoke-Api 'admin/approve_sitter' 'POST' "$Base/admin_v2.php?action=approve_sitter" $FH `
    "{`"sitter_id`":`"$((Parse-Json $regS.content).user.id)`"}"

# 12-15 Marketplace
$reqR = Invoke-Api 'marketplace/create_request' 'POST' "$Base/marketplace_v2.php?action=create_request" $OH `
    "{`"service_code`":`"dog_walking`",`"date_label`":`"2026-06-15`",`"time_range`":`"09:00-11:00`",`"address`":`"Jl Owner 99`",`"pet_ids`":[`"$petId`"],`"price`":150000}"
$requestId = (Parse-Json $reqR.content).data.request_id

Invoke-Api 'marketplace/list_requests' 'GET' "$Base/marketplace_v2.php?action=list_requests" $SH

$offerR = Invoke-Api 'marketplace/create_offer' 'POST' "$Base/marketplace_v2.php?action=create_offer" $SH `
    "{`"request_id`":`"$requestId`",`"price`":150000,`"message`":`"Siap`"}"
$offerId = (Parse-Json $offerR.content).data.offer_id

$accR = Invoke-Api 'marketplace/accept_offer' 'POST' "$Base/marketplace_v2.php?action=accept_offer" $OH `
    "{`"offer_id`":`"$offerId`"}"
$bookingId = (Parse-Json $accR.content).data.booking_id

# Second booking for cancel test (after main flow payment would block — cancel before payment)
$req2 = Invoke-Api 'marketplace/create_request (cancel)' 'POST' "$Base/marketplace_v2.php?action=create_request" $OH `
    "{`"service_code`":`"dog_walking`",`"date_label`":`"2026-06-16`",`"time_range`":`"10:00-12:00`",`"address`":`"Jl Cancel Test`",`"pet_ids`":[`"$petId`"],`"price`":100000}"
$requestId2 = (Parse-Json $req2.content).data.request_id
$offer2 = Invoke-Api 'marketplace/create_offer (cancel)' 'POST' "$Base/marketplace_v2.php?action=create_offer" $SH `
    "{`"request_id`":`"$requestId2`",`"price`":100000}"
$offerId2 = (Parse-Json $offer2.content).data.offer_id
$acc2 = Invoke-Api 'marketplace/accept_offer (cancel)' 'POST' "$Base/marketplace_v2.php?action=accept_offer" $OH `
    "{`"offer_id`":`"$offerId2`"}"
$bookingCancelId = (Parse-Json $acc2.content).data.booking_id

Invoke-Api 'booking/cancel_booking' 'POST' "$Base/booking_v2.php?action=cancel_booking" $OH `
    "{`"booking_id`":`"$bookingCancelId`",`"reason`":`"Audit cancel`"}"

# 16 Payment (main booking)
$payAmt = (Parse-Json $accR.content).data.payment_amount
if (-not $payAmt) { $payAmt = 157500 }

Invoke-Api 'payment/submit_proof' 'POST' "$Base/payment_v2.php?action=submit_proof" $OH `
    "{`"booking_id`":`"$bookingId`",`"reference_code`":`"AUDIT-$ts`"}"

Invoke-Api 'payment/admin_approve' 'POST' "$Base/payment_v2.php?action=admin_approve" $FH `
    "{`"booking_id`":`"$bookingId`"}"

Invoke-Api 'payment_status.php?booking_id=1' 'GET' "$Base/payment_status.php?booking_id=1"

Invoke-Api 'payment_webhook.php' 'POST' "$Base/payment_webhook.php" @{
    'Content-Type' = 'application/json'
    'X-Payment-Webhook-Secret' = $WebhookSecret
} "{`"nominal`":$payAmt,`"bank_pengirim`":`"SeaBank`",`"nama_pengirim`":`"Audit`",`"timestamp`":`"2026-06-06T10:00:00Z`"}"

# 17-21 Booking lifecycle
Invoke-Api 'booking/sitter_confirm' 'POST' "$Base/booking_v2.php?action=sitter_confirm" $SH `
    "{`"booking_id`":`"$bookingId`"}"
Invoke-Api 'booking/sitter_en_route' 'POST' "$Base/booking_v2.php?action=sitter_en_route" $SH `
    "{`"booking_id`":`"$bookingId`"}"
Invoke-Api 'booking/start_booking' 'POST' "$Base/booking_v2.php?action=start_booking" $SH `
    "{`"booking_id`":`"$bookingId`"}"
Invoke-Api 'booking/complete_booking' 'POST' "$Base/booking_v2.php?action=complete_booking" $SH `
    "{`"booking_id`":`"$bookingId`"}"

# 22-24 Wallet (after complete_booking credits sitter)
Invoke-Api 'wallet/get_balance' 'GET' "$Base/wallet_v2.php?action=get_balance" $SH
Invoke-Api 'wallet/get_ledger' 'GET' "$Base/wallet_v2.php?action=get_ledger" $SH
$wdR = Invoke-Api 'wallet/request_withdrawal' 'POST' "$Base/wallet_v2.php?action=request_withdrawal" $SH `
    '{"amount":10000}'
$withdrawalId = (Parse-Json $wdR.content).data.withdrawal.id

# 25-27 Chat
Invoke-Api 'chat/send_message' 'POST' "$Base/chat_v2.php?action=send_message" $OH `
    "{`"booking_id`":`"$bookingId`",`"text`":`"Halo audit`"}"
Invoke-Api 'chat/get_messages' 'GET' "$Base/chat_v2.php?action=get_messages&booking_id=$bookingId" $OH
Invoke-Api 'chat/check_new_messages' 'GET' "$Base/chat_v2.php?action=check_new_messages&booking_id=$bookingId&since=2020-01-01T00:00:00Z" $SH

# 28-30 Notifications
Invoke-Api 'notification/check_new' 'GET' "$Base/notification_v2.php?action=check_new" $OH
$notifR = Invoke-Api 'notification/get_notifications' 'GET' "$Base/notification_v2.php?action=get_notifications" $OH
$notifId = (Parse-Json $notifR.content).data.notifications[0].id
if ($notifId) {
    Invoke-Api 'notification/mark_read' 'POST' "$Base/notification_v2.php?action=mark_read" $OH `
        "{`"notification_id`":`"$notifId`"}"
} else {
    Invoke-Api 'notification/mark_read' 'POST' "$Base/notification_v2.php?action=mark_read" $OH '{"mark_all":true}'
}

# 31-35 Admin
Invoke-Api 'admin/list_sitters' 'GET' "$Base/admin_v2.php?action=list_sitters" $FH
Invoke-Api 'admin/list_owners' 'GET' "$Base/admin_v2.php?action=list_owners" $FH
Invoke-Api 'admin/list_bookings' 'GET' "$Base/admin_v2.php?action=list_bookings" $FH
if ($withdrawalId) {
    Invoke-Api 'admin/approve_withdrawal' 'POST' "$Base/admin_v2.php?action=approve_withdrawal" $FH `
        "{`"withdrawal_id`":`"$withdrawalId`"}"
} else {
    Add-Result 'admin/approve_withdrawal' $false 0 'no withdrawal_id from wallet'
}

$pass = ($results | Where-Object { $_.Status -eq 'OK' }).Count
$total = $results.Count
Write-Host "`n=== RESULTS $pass/$total ==="
$results | Format-Table -AutoSize
$results | ConvertTo-Json -Depth 3 | Out-File (Join-Path $PSScriptRoot 'audit_api_v2_results.json') -Encoding utf8
