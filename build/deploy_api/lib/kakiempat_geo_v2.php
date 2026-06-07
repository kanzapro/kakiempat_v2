<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @return array{min_lat: float, max_lat: float, min_lng: float, max_lng: float} */
function kakiempat_geo_v2_bounding_box(float $latitude, float $longitude, float $radiusKm): array
{
    $latDelta = $radiusKm / 111.0;
    $cosLat = cos(deg2rad($latitude));
    $lngDelta = $radiusKm / (111.0 * max(abs($cosLat), 0.0001));

    return [
        'min_lat' => $latitude - $latDelta,
        'max_lat' => $latitude + $latDelta,
        'min_lng' => $longitude - $lngDelta,
        'max_lng' => $longitude + $lngDelta,
    ];
}

function kakiempat_geo_v2_sql_json_latitude(string $jsonColumn): string
{
    return "COALESCE(
        CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT({$jsonColumn}, '$.latitude')), 'null') AS DECIMAL(10,7)),
        CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT({$jsonColumn}, '$.lat')), 'null') AS DECIMAL(10,7))
    )";
}

function kakiempat_geo_v2_sql_json_longitude(string $jsonColumn): string
{
    return "COALESCE(
        CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT({$jsonColumn}, '$.longitude')), 'null') AS DECIMAL(10,7)),
        CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT({$jsonColumn}, '$.lng')), 'null') AS DECIMAL(10,7)),
        CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT({$jsonColumn}, '$.lon')), 'null') AS DECIMAL(10,7))
    )";
}

function kakiempat_geo_v2_sql_haversine_km(
    string $latSql,
    string $lngSql,
    string $originLatParam,
    string $originLngParam,
    string $originLatParamRepeat,
): string {
    return "(6371 * ACOS(LEAST(1, GREATEST(-1,
        COS(RADIANS({$originLatParam})) * COS(RADIANS({$latSql})) *
        COS(RADIANS({$lngSql}) - RADIANS({$originLngParam})) +
        SIN(RADIANS({$originLatParamRepeat})) * SIN(RADIANS({$latSql}))
    ))))";
}

function kakiempat_geo_v2_has_indexed_coords(PDO $pdo, string $table): bool
{
    return v2ApiColumnExists($pdo, $table, 'latitude')
        && v2ApiColumnExists($pdo, $table, 'longitude');
}

/** @return array{lat_sql: string, lng_sql: string, use_bbox: bool} */
function kakiempat_geo_v2_resolve_coord_sql(
    PDO $pdo,
    string $table,
    string $tableAlias,
    string $jsonColumn,
): array {
    $jsonLat = kakiempat_geo_v2_sql_json_latitude("{$tableAlias}.{$jsonColumn}");
    $jsonLng = kakiempat_geo_v2_sql_json_longitude("{$tableAlias}.{$jsonColumn}");

    if (!kakiempat_geo_v2_has_indexed_coords($pdo, $table)) {
        return [
            'lat_sql' => $jsonLat,
            'lng_sql' => $jsonLng,
            'use_bbox' => false,
        ];
    }

    return [
        'lat_sql' => "COALESCE({$tableAlias}.latitude, {$jsonLat})",
        'lng_sql' => "COALESCE({$tableAlias}.longitude, {$jsonLng})",
        'use_bbox' => true,
    ];
}
