<?php
/**
 * Ekstrak www-deploy.zip (bundle identik release_v2) ke semua docroot web.
 * Upload ZIP + skrip ini ke public_html, lalu:
 *   deploy-release-v2-all-extract.php?run=1&key=<media/deploy secret>
 */
header('Content-Type: text/plain; charset=utf-8');
set_time_limit(900);

$root = __DIR__;
$zipName = 'www-deploy.zip';
$zipPath = $root . DIRECTORY_SEPARATOR . $zipName;

function fail(string $msg, int $code = 500): void
{
    http_response_code($code);
    echo "ERROR: $msg\n";
    exit;
}

function readKey(string $root): string
{
    $api = $root . '/api';
    foreach ([
        $root . '/.kakiempat_deploy_secret',
        $api . '/.kakiempat_deploy_secret',
        $root . '/.kakiempat_media_secret',
        $api . '/.kakiempat_media_secret',
    ] as $file) {
        if (is_readable($file)) {
            $v = trim((string) file_get_contents($file));
            if ($v !== '') {
                return $v;
            }
        }
    }
    $env = getenv('KAKIEMPAT_DEPLOY_SECRET');
    return is_string($env) ? trim($env) : '';
}

function removePath(string $path): void
{
    if (is_dir($path)) {
        $it = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($path, FilesystemIterator::SKIP_DOTS),
            RecursiveIteratorIterator::CHILD_FIRST
        );
        foreach ($it as $fi) {
            if ($fi->isDir()) {
                @rmdir($fi->getPathname());
            } else {
                @unlink($fi->getPathname());
            }
        }
        @rmdir($path);
        return;
    }
    if (is_file($path)) {
        @unlink($path);
    }
}

function clearDocrootExceptApi(string $dir): void
{
    if (!is_dir($dir)) {
        return;
    }
    foreach (scandir($dir) ?: [] as $name) {
        if ($name === '.' || $name === '..' || $name === 'api') {
            continue;
        }
        removePath($dir . DIRECTORY_SEPARATOR . $name);
    }
}

function clearFlutterArtifacts(string $dir): void
{
    $names = [
        'assets', 'canvaskit', 'icons', 'index.html', 'main.dart.js',
        'flutter.js', 'flutter_bootstrap.js', 'flutter_service_worker.js',
        'manifest.json', 'version.json', 'favicon.png', '.last_build_id',
        'flutter-assets', 'www-deploy.zip', 'owner-deploy.zip',
        'sitter-deploy.zip', 'admin-deploy.zip',
    ];
    foreach ($names as $name) {
        removePath($dir . DIRECTORY_SEPARATOR . $name);
    }
}

$expected = readKey($root);
$key = isset($_GET['key']) ? (string) $_GET['key'] : (isset($_POST['key']) ? (string) $_POST['key'] : '');
$run = isset($_GET['run']) && (string) $_GET['run'] === '1';

if (!$run) {
    echo "Upload $zipName + skrip ini ke public_html, lalu:\n";
    echo "  deploy-release-v2-all-extract.php?run=1&key=<secret>\n";
    exit;
}

if ($expected === '' || $key === '' || !hash_equals($expected, $key)) {
    fail('unauthorized', 401);
}

if (!is_readable($zipPath)) {
    fail("ZIP tidak ditemukan: $zipName");
}

if (!class_exists('ZipArchive')) {
    fail('ZipArchive tidak tersedia');
}

/** @var list<array{path:string,label:string,mode:string}> */
$targets = [
    ['path' => '/home/kakiempa/owner.kakiempat.com', 'label' => 'owner', 'mode' => 'full'],
    ['path' => '/home/kakiempa/sitter.kakiempat.com', 'label' => 'sitter', 'mode' => 'full'],
    ['path' => '/home/kakiempa/admin.kakiempat.com', 'label' => 'admin', 'mode' => 'full'],
    ['path' => '/home/kakiempa/www.kakiempat.com', 'label' => 'www', 'mode' => 'full'],
    ['path' => '/home/kakiempa/public_html', 'label' => 'public_html', 'mode' => 'flutter'],
];

$zip = new ZipArchive();
if ($zip->open($zipPath) !== true) {
    fail('cannot open zip');
}

foreach ($targets as $t) {
    $docroot = $t['path'];
    $label = $t['label'];
    if (!is_dir($docroot) && !@mkdir($docroot, 0755, true)) {
        echo "SKIP $label — docroot tidak ada: $docroot\n";
        continue;
    }
    if ($t['mode'] === 'flutter') {
        clearFlutterArtifacts($docroot);
    } else {
        clearDocrootExceptApi($docroot);
    }
    if (!$zip->extractTo($docroot)) {
        $zip->close();
        fail("extract failed untuk $label ($docroot)");
    }
    $main = $docroot . '/main.dart.js';
    $size = is_file($main) ? (int) filesize($main) : 0;
    echo "OK $label — diekstrak ke $docroot (main.dart.js $size bytes)\n";
}

$zip->close();
echo "\nDONE deploy-release-v2-all-extract\n";
