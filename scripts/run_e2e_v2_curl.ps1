$ErrorActionPreference = 'Continue'
$Base = 'https://api.kakiempat.com'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0'
$rnd = Get-Random -Minimum 10000000 -Maximum 99999999
$ownerPhone = "6281$rnd"
$sitterPhone = "6282$rnd"
$password = 'TestE2E!234'
$adminPhone = '6281248826888'
$adminPassword = '123456'
$bodyDir = 'd:\Project_Flutter\kakiempat_v2\artifacts\_curl_bodies'
New-Item -ItemType Directory -Force -Path $bodyDir | Out-Null

$steps = New-Object System.Collections.Generic.List[object]
$ids = @{ owner_user_id=$null; sitter_user_id=$null; pet_id=$null; request_id=$null; offer_id=$null; booking_id=$null; withdrawal_id=$null }
$tokens = @{ owner=$null; sitter=$null; admin=$null }
$passed = 0; $total = 15
$bodyCounter = 0

function Snippet($text, [int]$MaxLen = 400) {
    if ($null -eq $text) { return '' }
    $t = ([string]$text -replace '\s+', ' ').Trim()
    if ($t.Length -gt $MaxLen) { return $t.Substring(0, $MaxLen) + '...' }
    return $t
}
function Is-ImunifyBlock($content) {
    return ([string]$content) -match 'Imunify360|bot-protection'
}
function Parse-Json($text) { try { return $text | ConvertFrom-Json } catch { return $null } }

function Add-Step {
    param([int]$Num,[string]$Name,[bool]$Ok,[int]$Http,[string]$SnippetText,[hashtable]$RefIds=@{})
    $obj = [ordered]@{ step=$Num; name=$Name; status=$(if($Ok){'ok'}else{'fail'}); success=$Ok; http_status=$Http; response_snippet=$SnippetText }
    foreach ($k in $RefIds.Keys) { if ($null -ne $RefIds[$k] -and "$($RefIds[$k])" -ne '') { $obj[$k]=$RefIds[$k] } }
    $script:steps.Add([PSCustomObject]$obj) | Out-Null
    if ($Ok) { $script:passed++ }
}

function Invoke-Curl {
    param([string]$Method='GET',[string]$Url,[string]$Token=$null,[string]$Body=$null,[int[]]$OkCodes=@(200,201))
    $tmp = $null
    $args = @(
        '-s','-S','-w',"`n%{http_code}",'-A',$UA,'-X',$Method,
        '-H','Accept: application/json',
        '-H','Accept-Language: id-ID,id;q=0.9,en;q=0.8',
        '-H','Referer: https://owner.kakiempat.com/'
    )
    if ($Token) { $args += @('-H',"Authorization: Bearer $Token") }
    if ($Body) {
        $script:bodyCounter++
        $tmp = Join-Path $bodyDir ("body_{0}.json" -f $script:bodyCounter)
        [System.IO.File]::WriteAllText($tmp, $Body, (New-Object System.Text.UTF8Encoding $false))
        $args += @('-H','Content-Type: application/json','--data-binary',"@$tmp")
    }
    $out = & curl.exe @args $Url 2>&1
    $joined = ($out | Out-String).TrimEnd()
    $lines = $joined -split "`n"
    $code = 0; $content = $joined
    if ($lines.Count -ge 1 -and $lines[-1].Trim() -match '^\d{3}$') {
        $code = [int]$lines[-1].Trim()
        $content = ($lines[0..($lines.Count-2)] -join "`n")
    }
    if (Is-ImunifyBlock $content) { $code = 403; $ok = $false }
    else { $ok = ($OkCodes -contains $code) }
    return @{ ok=$ok; code=$code; content=$content; json=(Parse-Json $content) }
}

function J($obj) { ($obj | ConvertTo-Json -Compress -Depth 8) }

Write-Host "E2E curl — Owner: $ownerPhone | Sitter: $sitterPhone"

$r = Invoke-Curl POST "$Base/auth_v2.php?action=register" $null (J @{ phone=$ownerPhone; password=$password; name='E2E Owner'; role='owner' })
$ok = $r.ok -and $r.json.token; if ($ok) { $tokens.owner=$r.json.token; $ids.owner_user_id=$r.json.user.id }
Add-Step 1 'register_owner' $ok $r.code (Snippet $r.content)

Start-Sleep -Seconds 3
$r = Invoke-Curl POST "$Base/auth_v2.php?action=register" $null (J @{ phone=$sitterPhone; password=$password; name='E2E Sitter'; role='sitter' })
$ok = $r.ok -and $r.json.token; if ($ok) { $tokens.sitter=$r.json.token; $ids.sitter_user_id=$r.json.user.id }
Add-Step 2 'register_sitter' $ok $r.code (Snippet $r.content)

$r3a = Invoke-Curl POST "$Base/sitter_v2.php?action=save_profile" $tokens.sitter (J @{ bio='E2E sitter'; address='Jl Sitter E2E Jakarta'; services=@('dog_walking'); latitude=-6.2; longitude=106.8 })
$r3b = Invoke-Curl POST "$Base/sitter_v2.php?action=submit_verification" $tokens.sitter '{}'
$ok3 = $r3a.ok -and $r3b.ok
Add-Step 3 'sitter_save_profile_submit_verification' $ok3 $(if($ok3){$r3b.code}else{$r3a.code}) (Snippet ($r3a.content+' | '+$r3b.content)) @{ sitter_user_id=$ids.sitter_user_id }

$loginA = Invoke-Curl POST "$Base/auth_v2.php?action=login" $null (J @{ phone=$adminPhone; password=$adminPassword })
if ($loginA.ok) { $tokens.admin = $loginA.json.token }
$r = Invoke-Curl POST "$Base/admin_v2.php?action=approve_sitter" $tokens.admin (J @{ sitter_id="$($ids.sitter_user_id)" })
Add-Step 4 'admin_approve_sitter' ($r.ok -and $loginA.ok) $r.code (Snippet $r.content) @{ sitter_user_id=$ids.sitter_user_id }

$r5a = Invoke-Curl POST "$Base/owner_v2.php?action=add_pet" $tokens.owner (J @{ name='Buddy'; species='dog'; breed='Mix'; notes='E2E pet' })
if ($r5a.ok) { $ids.pet_id = $r5a.json.data.pet.id }
$r5b = Invoke-Curl POST "$Base/owner_v2.php?action=save_profile" $tokens.owner (J @{ address='Jl Owner E2E Jakarta'; latitude=-6.21; longitude=106.81 })
$ok5 = $r5a.ok -and $r5b.ok -and $ids.pet_id
Add-Step 5 'owner_add_pet_save_profile' $ok5 $(if($ok5){$r5b.code}else{$r5a.code}) (Snippet ($r5a.content+' | '+$r5b.content)) @{ pet_id=$ids.pet_id }

$r = Invoke-Curl POST "$Base/marketplace_v2.php?action=create_request" $tokens.owner (J @{ service_type='dog_walking'; date_label='Jun 15, 2026'; time_range='09:00-11:00'; location=@{ address='Jl Owner E2E 99'; latitude=-6.21; longitude=106.81 }; pets=@("$($ids.pet_id)"); price=100000 })
$ok6 = $r.ok -and $r.json.data.request_id; if ($ok6) { $ids.request_id = $r.json.data.request_id }
Add-Step 6 'create_request_dog_walking' $ok6 $r.code (Snippet $r.content) @{ request_id=$ids.request_id }

$r7a = Invoke-Curl GET "$Base/marketplace_v2.php?action=list_requests" $tokens.sitter
$r7b = Invoke-Curl POST "$Base/marketplace_v2.php?action=create_offer" $tokens.sitter (J @{ request_id="$($ids.request_id)"; price=90000; message='Siap jalan-jalan' })
$ok7 = $r7a.ok -and $r7b.ok -and $r7b.json.data.offer_id; if ($r7b.ok) { $ids.offer_id = $r7b.json.data.offer_id }
Add-Step 7 'list_requests_create_offer' $ok7 $(if($ok7){$r7b.code}else{$r7a.code}) (Snippet $r7b.content) @{ request_id=$ids.request_id; offer_id=$ids.offer_id }

$r = Invoke-Curl POST "$Base/marketplace_v2.php?action=accept_offer" $tokens.owner (J @{ offer_id="$($ids.offer_id)" })
$st = if ($r.json.data) { $r.json.data.status } else { '' }
$ok8 = $r.ok -and $r.json.data.booking_id -and ($st -match 'awaitingPayment|pending')
if ($ok8) { $ids.booking_id = $r.json.data.booking_id }
Add-Step 8 'accept_offer' $ok8 $r.code (Snippet $r.content) @{ offer_id=$ids.offer_id; booking_id=$ids.booking_id }

$ref = "E2E-$(Get-Date -Format 'yyyyMMddHHmmss')"
$r9a = Invoke-Curl POST "$Base/payment_v2.php?action=submit_proof" $tokens.owner (J @{ booking_id="$($ids.booking_id)"; reference_code=$ref })
$r9b = Invoke-Curl POST "$Base/payment_v2.php?action=admin_approve" $tokens.admin (J @{ booking_id="$($ids.booking_id)" })
$r9c = Invoke-Curl GET "$Base/booking_v2.php?action=get_booking&booking_id=$($ids.booking_id)" $tokens.owner
$bst = if ($r9c.json.data.booking) { $r9c.json.data.booking.status } else { '' }
$ok9 = $r9a.ok -and $r9b.ok -and $r9c.ok -and ($bst -match '^PAID$|^paid$')
Add-Step 9 'payment_proof_admin_approve_paid' $ok9 $(if($ok9){$r9c.code}else{$r9b.code}) (Snippet ($r9a.content+' | '+$r9b.content+' | status='+$bst)) @{ booking_id=$ids.booking_id }

$r10a = Invoke-Curl POST "$Base/booking_v2.php?action=sitter_confirm" $tokens.sitter (J @{ booking_id="$($ids.booking_id)" })
$r10b = Invoke-Curl POST "$Base/booking_v2.php?action=sitter_en_route" $tokens.sitter (J @{ booking_id="$($ids.booking_id)" })
$r10c = Invoke-Curl POST "$Base/booking_v2.php?action=start_booking" $tokens.sitter (J @{ booking_id="$($ids.booking_id)" })
$r10d = Invoke-Curl POST "$Base/booking_v2.php?action=complete_booking" $tokens.sitter (J @{ booking_id="$($ids.booking_id)" })
$ok10 = $r10a.ok -and $r10b.ok -and $r10c.ok -and $r10d.ok
Add-Step 10 'booking_lifecycle' $ok10 $(if($ok10){$r10d.code}else{$r10a.code}) (Snippet $r10d.content) @{ booking_id=$ids.booking_id }

$r = Invoke-Curl GET "$Base/wallet_v2.php?action=get_ledger" $tokens.sitter
$income=0; $fee=0
if ($r.json.data.entries) { foreach ($e in $r.json.data.entries) { if ("$($e.booking_id)" -eq "$($ids.booking_id)") { if ($e.type -eq 'income') { $income=[int]$e.amount }; if ($e.type -eq 'platform_fee') { $fee=[math]::Abs([int]$e.amount) } } } }
$balR = Invoke-Curl GET "$Base/wallet_v2.php?action=get_balance" $tokens.sitter
$bal = if ($balR.json.data) { [int]$balR.json.data.balance } else { 0 }
$ok11 = $r.ok -and ($income -eq 90000) -and ($fee -eq 7200) -and ($bal -eq 82800)
Add-Step 11 'wallet_verification' $ok11 $r.code (Snippet "balance=$bal income=$income fee=$fee expected_balance=82800 platform_fee=7200") @{ booking_id=$ids.booking_id }

$r12a = Invoke-Curl POST "$Base/chat_v2.php?action=send_message" $tokens.owner (J @{ booking_id="$($ids.booking_id)"; text='Halo dari owner E2E' })
$r12b = Invoke-Curl POST "$Base/chat_v2.php?action=send_message" $tokens.sitter (J @{ booking_id="$($ids.booking_id)"; text='Halo dari sitter E2E' })
$r12c = Invoke-Curl GET "$Base/chat_v2.php?action=get_messages&booking_id=$($ids.booking_id)" $tokens.owner
$cnt = if ($r12c.json.data.messages) { @($r12c.json.data.messages).Count } else { 0 }
$ok12 = $r12a.ok -and $r12b.ok -and $r12c.ok -and ($cnt -ge 2)
Add-Step 12 'chat_send_reply_get_messages' $ok12 $r12c.code (Snippet $r12c.content) @{ booking_id=$ids.booking_id }

$r13a = Invoke-Curl GET "$Base/notification_v2.php?action=check_new" $tokens.owner
$r13b = Invoke-Curl GET "$Base/notification_v2.php?action=check_new" $tokens.sitter
$ou = if ($r13a.json.data) { [int]$r13a.json.data.unread_count } else { 0 }
$su = if ($r13b.json.data) { [int]$r13b.json.data.unread_count } else { 0 }
$ok13 = $r13a.ok -and $r13b.ok -and ($ou -gt 0) -and ($su -gt 0)
$snip13 = "owner_unread=$ou sitter_unread=$su | owner=$(Snippet $r13a.content -MaxLen 200) | sitter=$(Snippet $r13b.content -MaxLen 200)"
Add-Step 13 'notifications_check_new' $ok13 $(if($r13a.ok){$r13a.code}else{0}) (Snippet $snip13) @{}

$r14a = Invoke-Curl GET "$Base/wallet_v2.php?action=get_balance" $tokens.sitter
$r14b = Invoke-Curl POST "$Base/wallet_v2.php?action=request_withdrawal" $tokens.sitter (J @{ amount=10000 })
if ($r14b.ok) { $ids.withdrawal_id = $r14b.json.data.withdrawal.id }
$ok14 = $r14a.ok -and $r14b.ok -and $ids.withdrawal_id
Add-Step 14 'wallet_get_balance_request_withdrawal' $ok14 $(if($ok14){$r14b.code}else{$r14a.code}) (Snippet ($r14a.content+' | '+$r14b.content)) @{ withdrawal_id=$ids.withdrawal_id }

$r = Invoke-Curl POST "$Base/admin_v2.php?action=approve_withdrawal" $tokens.admin (J @{ withdrawal_id="$($ids.withdrawal_id)" })
Add-Step 15 'admin_approve_withdrawal' $r.ok $r.code (Snippet $r.content) @{ withdrawal_id=$ids.withdrawal_id }

$report = [ordered]@{
    run_at = (Get-Date).ToUniversalTime().ToString('o')
    api_base = $Base
    user_agent = $UA
    owner_phone = $ownerPhone
    sitter_phone = $sitterPhone
    ids = [PSCustomObject]$ids
    summary = "$passed/$total steps passed"
    passed = $passed
    total = $total
    steps = $steps
}
$outFile = 'd:\Project_Flutter\kakiempat_v2\artifacts\e2e_v2_full.json'
($report | ConvertTo-Json -Depth 12) | Set-Content $outFile -Encoding utf8
Write-Host "=== E2E V2: $passed/$total ==="
Write-Host "Saved: $outFile"
