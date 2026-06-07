<?php
declare(strict_types=1);
header('Content-Type:application/json');
$s=trim((string)@file_get_contents(__DIR__.'/.git_deploy_secret'));
$p=trim((string)($_GET['secret']??$_SERVER['HTTP_X_DEPLOY_SECRET']??''));
if($s===''||$p===''||!hash_equals($s,$p)){http_response_code(403);echo'{"ok":false}';exit;}
$c=require __DIR__.'/.git_deploy_config.php';
$b=preg_replace('/[^a-zA-Z0-9_\-]/','',(string)($_GET['branch']??'main'))?:'main';
$r=$c['repo_path']??'/home/kakiempa/repo_kakiempat';
$a=($c['cpanel_user']??'kakiempa').':'.($c['cpanel_pass']??'');
$run=function(string $api,array $q)use($a):array{
  $ch=curl_init('https://127.0.0.1:2083/execute/'.$api.'?'.http_build_query($q));
  curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>1,CURLOPT_USERPWD=>$a,CURLOPT_TIMEOUT=>300,CURLOPT_SSL_VERIFYPEER=>0]);
  $body=(string)curl_exec($ch);$h=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);
  return['http'=>$h,'body'=>$body,'ok'=>$h===200&&str_contains($body,'"status":1')];
};
$pull=$run('VersionControl/update',['repository_root'=>$r,'branch'=>$b]);
$dep=$run('VersionControlDeployment/create',['repository_root'=>$r]);
$ok=$pull['ok']&&$dep['ok'];
http_response_code($ok?200:500);
echo json_encode(['ok'=>$ok,'pull'=>$pull,'deploy'=>$dep]);
