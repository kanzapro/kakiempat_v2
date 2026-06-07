# E2E V2 full flow — 15 steps against https://api.kakiempat.com
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$rand = Get-Random -Minimum 100000 -Maximum 999999
$ownerPhone = ('6289{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), $rand).Substring(0, 13)
$sitterPhone = ('6288{0}{1}' -f $ts.ToString().Substring($ts.ToString().Length - 7), ($rand + 1)).Substring(0, 13)
$password = 'TestE2E!234'
$adminPhone = '6281248826888'
$adminPassword = '123456'

$steps = New-Object System.Collections.Generic.List[object]
$ids = @{
    owner_user_id = $null
    sitter_user_id = $null
    pet_id = $null
    request_id = $null
    offer_id = $null
    booking_id = $null
    withdrawal_id = $null
}
$tokens = @{ owner = $null; sitter = $null; admin = $null }
$passed = 0
$total = 15
$balanceBefore = 0

function Parse-Json($text) {
    try { return $text | ConvertFrom-Json } catch { return $null }
}

function Add-Step {
    param(
        [int]$Num, [string]$Name, [bool]$Ok,
        [int]$Http, [object]$Body, [string]$Notes = ''
    )
    $script:steps.Add([PSCustomObject]@{
        step = $Num
        name = $Name
        success = $Ok
        http_status = $Http
        response_body = $Body
        notes = $Notes
    }) | Out-Null
    if ($Ok) { $script:passed++ }
}

function Invoke-V2 {
    param(
        [int]$StepNum, [string]$StepName,
        [string]$Method = 'GET', [string]$Url,
        [hashtable]$Headers = @{}, [string]$Body = $null,
        [int[]]$OkCodes = @(200, 201),
        [scriptblock]$Validate = $null,
        [switch]$SkipCount
    )
    $rawContent = ''
    $code = 0
    try {
        $params = @{ Uri = $Url; Method = $Method; Headers = $Headers; UseBasicParsing = $true }
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = 'application/json'
        }
        $r = Invoke-WebRequest @params
        $code = [int]$r.StatusCode
        $rawContent = $r.Content
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $code = [int]$resp.StatusCode
            $sr = New-Object IO.StreamReader($resp.GetResponseStream())
            $rawContent = $sr.ReadToEnd()
            $sr.Close()
        } else {
            $rawContent = $_.Exception.Message
        }
    }
    $parsed = Parse-Json $rawContent
    $ok = ($OkCodes -contains $code)
    $notes = ''
    if ($ok -and $Validate) {
        $vr = & $Validate $parsed $rawContent
        if (-not $vr.ok) {
            $ok = $false
            $notes = $vr.notes
        }
    }
    if (-not $ok -and -not $notes) {
        $notes = if ($rawContent.Length -gt 200) { $rawContent.Substring(0, 200) + '...' } else { $rawContent }
    }
    $bodyOut = if ($parsed) { $parsed } else { $rawContent }
    if (-not $SkipCount) {
        Add-Step -Num $StepNum -Name $StepName -Ok $ok -Http $code -Body $bodyOut -Notes $notes
    }
    return @{ ok = $ok; code = $code; content = $rawContent; json = $parsed }
}

function Json-Body($obj) {
    return ($obj | ConvertTo-Json -Compress -Depth 6)
}

Write-Host "E2E V2 Full - Owner: $ownerPhone | Sitter: $sitterPhone"

# 1 Register owner
$r1 = Invoke-V2 1 'register_owner' 'POST' "$Base/auth_v2.php?action=register" @{} (Json-Body @{
    phone = $ownerPhone; password = $password; name = 'E2E Owner'; role = 'owner'
}) -Validate { param($j) @{ ok = ($null -ne $j.token); notes = 'missing token' } }
if ($r1.ok) { $tokens.owner = $r1.json.token; $ids.owner_user_id = $r1.json.user.id }

# 2 Register sitter
$r2 = Invoke-V2 2 'register_sitter' 'POST' "$Base/auth_v2.php?action=register" @{} (Json-Body @{
    phone = $sitterPhone; password = $password; name = 'E2E Sitter'; role = 'sitter'
}) -Validate { param($j) @{ ok = ($null -ne $j.token); notes = 'missing token' } }
if ($r2.ok) { $tokens.sitter = $r2.json.token; $ids.sitter_user_id = $r2.json.user.id }

$OH = @{ Authorization = "Bearer $($tokens.owner)"; Accept = 'application/json' }
$SH = @{ Authorization = "Bearer $($tokens.sitter)"; Accept = 'application/json' }

# 3 Sitter save_profile + submit_verification
$r3a = Invoke-V2 0 'sitter_save_profile' 'POST' "$Base/sitter_v2.php?action=save_profile" $SH (Json-Body @{
    bio = 'E2E sitter'; address = 'Jl Sitter E2E Jakarta'; services = @('dog_walking')
    latitude = -6.2; longitude = 106.8
}) -SkipCount
$r3b = Invoke-V2 0 'sitter_submit_verification' 'POST' "$Base/sitter_v2.php?action=submit_verification" $SH '{}' -SkipCount
$r3ok = $r3a.ok -and $r3b.ok
Add-Step 3 'sitter_onboarding' $r3ok $(if ($r3ok) { $r3b.code } else { $r3a.code }) @{
    save_profile = $r3a.json; submit_verification = $r3b.json
} $(if (-not $r3ok) { 'save_profile or submit_verification failed' } else { '' })

# 4 Admin approve_sitter
$loginA = Invoke-V2 0 'admin_login' 'POST' "$Base/auth_v2.php?action=login" @{} (Json-Body @{
    phone = $adminPhone; password = $adminPassword
}) -SkipCount
if ($loginA.ok) { $tokens.admin = $loginA.json.token }
$AH = @{ Authorization = "Bearer $($tokens.admin)"; Accept = 'application/json' }
$r4 = Invoke-V2 4 'admin_approve_sitter' 'POST' "$Base/admin_v2.php?action=approve_sitter" $AH (Json-Body @{
    sitter_id = "$($ids.sitter_user_id)"
})

# 5 Owner add_pet + save_profile
$r5a = Invoke-V2 0 'owner_add_pet' 'POST' "$Base/owner_v2.php?action=add_pet" $OH (Json-Body @{
    name = 'Buddy'; species = 'dog'; breed = 'Mix'; notes = 'E2E pet'
}) -SkipCount
if ($r5a.ok) { $ids.pet_id = $r5a.json.data.pet.id }
$r5b = Invoke-V2 0 'owner_save_profile' 'POST' "$Base/owner_v2.php?action=save_profile" $OH (Json-Body @{
    address = 'Jl Owner E2E Jakarta'; latitude = -6.21; longitude = 106.81
}) -SkipCount
$r5ok = $r5a.ok -and $r5b.ok -and $ids.pet_id
Add-Step 5 'owner_setup' $r5ok $(if ($r5ok) { $r5b.code } else { $r5a.code }) @{
    add_pet = $r5a.json; save_profile = $r5b.json; pet_id = $ids.pet_id
} $(if (-not $r5ok) { 'add_pet or save_profile failed' } else { '' })

# 6 Owner create_request
$r6 = Invoke-V2 6 'create_request' 'POST' "$Base/marketplace_v2.php?action=create_request" $OH (Json-Body @{
    service_type = 'dog_walking'
    date_label = 'Jun 15, 2026'
    time_range = '09:00-11:00'
    location = @{ address = 'Jl Owner E2E 99'; latitude = -6.21; longitude = 106.81 }
    pets = @("$($ids.pet_id)")
    price = 100000
}) -OkCodes @(200, 201) -Validate { param($j) @{ ok = ($null -ne $j.data.request_id); notes = 'missing request_id' } }
if ($r6.ok) { $ids.request_id = $r6.json.data.request_id }

# 7 Sitter list_requests + create_offer
$r7a = Invoke-V2 0 'list_requests' 'GET' "$Base/marketplace_v2.php?action=list_requests" $SH -SkipCount
$r7b = Invoke-V2 0 'create_offer' 'POST' "$Base/marketplace_v2.php?action=create_offer" $SH (Json-Body @{
    request_id = "$($ids.request_id)"; price = 90000; message = 'Siap jalan-jalan'
}) -OkCodes @(200, 201) -SkipCount
if ($r7b.ok) { $ids.offer_id = $r7b.json.data.offer_id }
$r7ok = $r7a.ok -and $r7b.ok -and $ids.offer_id
Add-Step 7 'sitter_list_and_offer' $r7ok $(if ($r7ok) { $r7b.code } else { $r7a.code }) @{
    list_requests = $r7a.json; create_offer = $r7b.json; offer_id = $ids.offer_id
} $(if (-not $r7ok) { 'list_requests or create_offer failed' } else { '' })

# 8 Owner accept_offer
$r8 = Invoke-V2 8 'accept_offer' 'POST' "$Base/marketplace_v2.php?action=accept_offer" $OH (Json-Body @{
    offer_id = "$($ids.offer_id)"
}) -Validate { param($j)
    $st = $j.data.status; $bid = $j.data.booking_id
    @{ ok = ($null -ne $bid -and $st -match 'awaitingPayment|pending'); notes = "status=$st booking_id=$bid" }
}
if ($r8.ok) { $ids.booking_id = $r8.json.data.booking_id }

# 9 Payment flow
$ref = "E2E-$ts"
$r9a = Invoke-V2 0 'submit_payment_proof' 'POST' "$Base/payment_v2.php?action=submit_proof" $OH (Json-Body @{
    booking_id = "$($ids.booking_id)"; reference_code = $ref
}) -SkipCount
$r9b = Invoke-V2 0 'admin_approve_payment' 'POST' "$Base/payment_v2.php?action=admin_approve" $AH (Json-Body @{
    booking_id = "$($ids.booking_id)"
}) -SkipCount
$bookingUrl = "$Base/booking_v2.php?action=get_booking" + '&booking_id=' + $ids.booking_id
$r9c = Invoke-V2 0 'verify_booking_paid' 'GET' $bookingUrl $OH -SkipCount -Validate { param($j)
    $st = $j.data.booking.status
    @{ ok = ($st -match '^PAID$|^paid$'); notes = "booking status=$st" }
}
$r9ok = $r9a.ok -and $r9b.ok -and $r9c.ok
Add-Step 9 'payment_to_paid' $r9ok $(if ($r9ok) { $r9c.code } else { $r9b.code }) @{
    submit_proof = $r9a.json; admin_approve = $r9b.json; booking = $r9c.json
} $(if (-not $r9ok) { 'payment submit/approve/PAID failed' } else { '' })

# 10 Booking lifecycle
$r10a = Invoke-V2 0 'sitter_confirm' 'POST' "$Base/booking_v2.php?action=sitter_confirm" $SH (Json-Body @{ booking_id = "$($ids.booking_id)" }) -SkipCount
$r10b = Invoke-V2 0 'sitter_en_route' 'POST' "$Base/booking_v2.php?action=sitter_en_route" $SH (Json-Body @{ booking_id = "$($ids.booking_id)" }) -SkipCount
$r10c = Invoke-V2 0 'start_booking' 'POST' "$Base/booking_v2.php?action=start_booking" $SH (Json-Body @{ booking_id = "$($ids.booking_id)" }) -SkipCount
$balResp = Invoke-V2 0 'balance_before' 'GET' "$Base/wallet_v2.php?action=get_balance" $SH -SkipCount
if ($balResp.ok) { $script:balanceBefore = [int]$balResp.json.data.balance }
$r10d = Invoke-V2 0 'complete_booking' 'POST' "$Base/booking_v2.php?action=complete_booking" $SH (Json-Body @{ booking_id = "$($ids.booking_id)" }) -SkipCount
$r10ok = $r10a.ok -and $r10b.ok -and $r10c.ok -and $r10d.ok
Add-Step 10 'booking_lifecycle' $r10ok $(if ($r10ok) { $r10d.code } else { $r10d.code }) @{
    sitter_confirm = $r10a.json; en_route = $r10b.json; start = $r10c.json; complete = $r10d.json
} $(if (-not $r10ok) { 'lifecycle step failed' } else { '' })

# 11 Wallet verification
$expectedNet = 82800
$expectedFee = 7200
$r11 = Invoke-V2 11 'wallet_verification' 'GET' "$Base/wallet_v2.php?action=get_ledger" $SH -Validate { param($j)
    $entries = $j.data.entries
    $income = 0; $fee = 0
    foreach ($e in $entries) {
        if ("$($e.booking_id)" -eq "$($ids.booking_id)") {
            if ($e.type -eq 'income') { $income = [int]$e.amount }
            if ($e.type -eq 'platform_fee') { $fee = [math]::Abs([int]$e.amount) }
        }
    }
    $netFromLedger = $income - $fee
    $balAfterResp = Invoke-WebRequest -Uri "$Base/wallet_v2.php?action=get_balance" -Headers $SH -UseBasicParsing
    $balAfter = [int](($balAfterResp.Content | ConvertFrom-Json).data.balance)
    $ok = ($income -eq 90000) -and ($fee -eq $expectedFee) -and ($netFromLedger -eq $expectedNet) -and ($balAfter -ge $expectedNet)
    @{ ok = $ok; notes = "income=$income fee=$fee net=$netFromLedger balance=$balAfter expected_net=$expectedNet" }
}

# 12 Chat
$r12a = Invoke-V2 0 'chat_owner_send' 'POST' "$Base/chat_v2.php?action=send_message" $OH (Json-Body @{
    booking_id = "$($ids.booking_id)"; text = 'Halo dari owner E2E'
}) -SkipCount
$r12b = Invoke-V2 0 'chat_sitter_reply' 'POST' "$Base/chat_v2.php?action=send_message" $SH (Json-Body @{
    booking_id = "$($ids.booking_id)"; text = 'Halo dari sitter E2E'
}) -SkipCount
$chatUrl = "$Base/chat_v2.php?action=get_messages" + '&booking_id=' + $ids.booking_id
$r12c = Invoke-V2 0 'chat_get_messages' 'GET' $chatUrl $OH -SkipCount -Validate { param($j)
    $msgs = $j.data.messages
    $count = if ($msgs) { @($msgs).Count } else { 0 }
    @{ ok = ($count -ge 2); notes = "message_count=$count" }
}
$r12ok = $r12a.ok -and $r12b.ok -and $r12c.ok
Add-Step 12 'chat_flow' $r12ok $(if ($r12ok) { $r12c.code } else { $r12c.code }) @{
    owner_send = $r12a.json; sitter_reply = $r12b.json; messages = $r12c.json
} $(if (-not $r12ok) { 'chat failed' } else { '' })

# 13 Notifications
$r13a = Invoke-V2 0 'notif_owner' 'GET' "$Base/notification_v2.php?action=check_new" $OH -SkipCount
$r13b = Invoke-V2 0 'notif_sitter' 'GET' "$Base/notification_v2.php?action=check_new" $SH -SkipCount
$ownerUnread = if ($r13a.ok) { [int]$r13a.json.data.unread_count } else { 0 }
$sitterUnread = if ($r13b.ok) { [int]$r13b.json.data.unread_count } else { 0 }
$r13ok = $r13a.ok -and $r13b.ok -and ($ownerUnread -gt 0) -and ($sitterUnread -gt 0)
Add-Step 13 'notifications_check_new' $r13ok $(if ($r13ok) { 200 } else { 0 }) @{
    owner_unread = $ownerUnread; sitter_unread = $sitterUnread
    owner = $r13a.json; sitter = $r13b.json
} "owner_unread=$ownerUnread sitter_unread=$sitterUnread"

# 14 Wallet withdraw
$r14a = Invoke-V2 0 'get_balance' 'GET' "$Base/wallet_v2.php?action=get_balance" $SH -SkipCount
$r14b = Invoke-V2 0 'request_withdrawal' 'POST' "$Base/wallet_v2.php?action=request_withdrawal" $SH (Json-Body @{ amount = 10000 }) -SkipCount
if ($r14b.ok) { $ids.withdrawal_id = $r14b.json.data.withdrawal.id }
$r14ok = $r14a.ok -and $r14b.ok -and $ids.withdrawal_id
Add-Step 14 'wallet_balance_withdraw' $r14ok $(if ($r14ok) { $r14b.code } else { $r14a.code }) @{
    balance = $r14a.json; withdrawal = $r14b.json; withdrawal_id = $ids.withdrawal_id
} $(if (-not $r14ok) { 'wallet failed' } else { '' })

# 15 Admin approve withdrawal
$r15 = Invoke-V2 15 'admin_approve_withdrawal' 'POST' "$Base/admin_v2.php?action=approve_withdrawal" $AH (Json-Body @{
    withdrawal_id = "$($ids.withdrawal_id)"
})

$report = [PSCustomObject]@{
    run_at = (Get-Date).ToUniversalTime().ToString('o')
    api_base = $Base
    owner_phone = $ownerPhone
    sitter_phone = $sitterPhone
    ids = [PSCustomObject]$ids
    summary = "$passed/$total steps passed"
    passed = $passed
    total = $total
    steps = $steps
}

$outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$outFile = Join-Path $outDir 'e2e_v2_full.json'
$report | ConvertTo-Json -Depth 12 | Out-File $outFile -Encoding utf8

Write-Host ""
Write-Host ('=== E2E V2: ' + $passed + '/' + $total + ' langkah berhasil ===')
Write-Host ('Laporan: ' + $outFile)
$steps | Format-Table step, name, success, http_status, notes -AutoSize
