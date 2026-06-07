<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

function kakiempat_community_v2_gallery_table_exists(PDO $pdo): bool
{
    return v2ApiTableExists($pdo, 'kakiempa_v2_pet_gallery');
}

function kakiempat_community_v2_list_gallery(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    if (!kakiempat_community_v2_gallery_table_exists($pdo)) {
        v2ApiRespondData(['items' => [], 'total' => 0]);
        return;
    }

    $limit = min(100, max(1, (int) ($_GET['limit'] ?? 50)));
    $stmt = $pdo->prepare(
        'SELECT g.id, g.owner_user_id, g.pet_id, g.caption, g.image_data,
                g.likes_count, g.created_at, u.name AS owner_name
         FROM kakiempa_v2_pet_gallery g
         INNER JOIN kakiempa_v2_users u ON u.id = g.owner_user_id
         ORDER BY g.created_at DESC
         LIMIT ?',
    );
    $stmt->bindValue(1, $limit, PDO::PARAM_INT);
    $stmt->execute();

    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $galleryId = (int) ($row['id'] ?? 0);
        $liked = false;
        if (v2ApiTableExists($pdo, 'kakiempa_v2_pet_gallery_likes')) {
            $likeStmt = $pdo->prepare(
                'SELECT 1 FROM kakiempa_v2_pet_gallery_likes
                 WHERE gallery_id = ? AND user_id = ? LIMIT 1',
            );
            $likeStmt->execute([$galleryId, $auth['user_id']]);
            $liked = (bool) $likeStmt->fetchColumn();
        }
        $items[] = [
            'id' => (string) $galleryId,
            'owner_user_id' => (string) ($row['owner_user_id'] ?? ''),
            'owner_name' => (string) ($row['owner_name'] ?? ''),
            'pet_id' => $row['pet_id'] !== null ? (string) $row['pet_id'] : null,
            'caption' => (string) ($row['caption'] ?? ''),
            'image_data' => (string) ($row['image_data'] ?? ''),
            'likes_count' => (int) ($row['likes_count'] ?? 0),
            'liked_by_me' => $liked,
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    v2ApiRespondData(['items' => $items, 'total' => count($items)]);
}

/** @param array<string, mixed> $body */
function kakiempat_community_v2_upload_gallery(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    if (!kakiempat_community_v2_gallery_table_exists($pdo)) {
        v2ApiFail('schema_missing', 'Galeri hewan belum tersedia. Jalankan migrasi 019.', 503);
    }

    $imageData = trim((string) ($body['image_data'] ?? ''));
    $caption = v2ApiSanitizeText((string) ($body['caption'] ?? ''), 512);
    $petId = isset($body['pet_id']) ? (int) $body['pet_id'] : null;

    if ($imageData === '' || strlen($imageData) < 100) {
        v2ApiFail('invalid_image', 'Foto wajib diunggah.', 400);
    }
    if (strlen($imageData) > 2_000_000) {
        v2ApiFail('image_too_large', 'Ukuran foto terlalu besar.', 413);
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_pet_gallery
            (owner_user_id, pet_id, caption, image_data)
         VALUES (?, ?, ?, ?)',
    )->execute([
        $auth['user_id'],
        $petId !== null && $petId > 0 ? $petId : null,
        $caption !== '' ? $caption : null,
        $imageData,
    ]);

    v2ApiRespondData([
        'id' => (string) $pdo->lastInsertId(),
        'message' => 'Foto hewan berhasil diunggah ke galeri.',
    ], 201);
}

/** @param array<string, mixed> $body */
function kakiempat_community_v2_like_gallery(array $body): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    if (!kakiempat_community_v2_gallery_table_exists($pdo)) {
        v2ApiFail('schema_missing', 'Galeri hewan belum tersedia.', 503);
    }

    $galleryId = (int) ($body['gallery_id'] ?? 0);
    if ($galleryId < 1) {
        v2ApiFail('invalid_gallery_id', 'gallery_id wajib.', 400);
    }

    $exists = $pdo->prepare('SELECT id FROM kakiempa_v2_pet_gallery WHERE id = ? LIMIT 1');
    $exists->execute([$galleryId]);
    if (!$exists->fetchColumn()) {
        v2ApiFail('gallery_not_found', 'Foto tidak ditemukan.', 404);
    }

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_pet_gallery_likes')) {
        v2ApiFail('schema_missing', 'Tabel like belum tersedia.', 503);
    }

    $check = $pdo->prepare(
        'SELECT 1 FROM kakiempa_v2_pet_gallery_likes
         WHERE gallery_id = ? AND user_id = ? LIMIT 1',
    );
    $check->execute([$galleryId, $auth['user_id']]);
    if ($check->fetchColumn()) {
        v2ApiRespondData([
            'gallery_id' => (string) $galleryId,
            'liked' => true,
            'message' => 'Sudah disukai sebelumnya.',
        ]);
        return;
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_pet_gallery_likes (gallery_id, user_id) VALUES (?, ?)',
    )->execute([$galleryId, $auth['user_id']]);
    $pdo->prepare(
        'UPDATE kakiempa_v2_pet_gallery SET likes_count = likes_count + 1 WHERE id = ?',
    )->execute([$galleryId]);

    $countStmt = $pdo->prepare('SELECT likes_count FROM kakiempa_v2_pet_gallery WHERE id = ?');
    $countStmt->execute([$galleryId]);

    v2ApiRespondData([
        'gallery_id' => (string) $galleryId,
        'liked' => true,
        'likes_count' => (int) ($countStmt->fetchColumn() ?: 0),
    ]);
}
