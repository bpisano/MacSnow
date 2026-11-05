//
//  Snow.metal
//  Snow
//
//  Created by Benjamin Pisano on 05/11/2026.
//

#include <metal_stdlib>
using namespace metal;

// Mirrors SnowFlake.swift, field for field.
struct SnowFlake {
    float born;
    float gone;
    float lane;
    float top;
    float speed;
    float bob;
    float tempo;
    float seed;
    float flutter;
    float windShare;
    float size;
    float opacity;
    float blur;
};

// Mirrors SnowUniforms.swift, field for field.
struct SnowUniforms {
    float width;
    float height;
    float now;
    float wind;
    float windSpeed;
    float scale;
};

// Mirrors SnowDriftUniforms.swift, field for field.
struct SnowDriftUniforms {
    float left;
    float top;
    float width;
    float columnWidth;
    float peak;
    uint columns;
    uint occluders;
    float offset;
};

// Mirrors SnowSprite.swift, field for field.
struct SnowSprite {
    float2 center;
    float size;
    float alpha;
    float lump;
    float turn;
};

struct FlakeSprite {
    float4 position [[position]];
    float pointSize [[point_size]];
    float2 streak;
    float radius;
    float blur;
    float opacity;
    float side;
    float pixel;
    float lump;
    float turn;
};

// Same path as SnowFlake.swift: its flutter waves and bob wave, one wave per vector lane.
constant float margin = 8.0;
constant float3 flutterPace = float3(1.0, 1.73, 2.91);
constant float3 flutterWeight = float3(0.58, 0.29, 0.13);
constant float3 flutterTwist = float3(1.0, 2.17, 3.61);
constant float3 flutterOffset = float3(0.0, 0.9, 2.6);
constant float bobPace = 0.55;
constant float bobTwist = 1.19;
constant float bobOffset = 4.1;

constant float shutter = 1.0 / 48.0;
constant float trailShade = 0.5;
constant float3 flakeCore = float3(0.94, 0.965, 1.0);
constant float3 flakeRim = float3(0.70, 0.76, 0.86);

constant float lumpDepth = 0.32;
constant float lumpCoarseCells = 6.0;
constant float lumpFineCells = 11.0;
constant float lumpCoarseShare = 0.65;
constant float grainBlur = 0.35;
constant float puffBlur = 1.0;
constant float lumpShadow = 0.72;
constant float3 lumpLight = float3(-0.45, 0.70, 0.55);

static float noise(float2 cell) {
    return fract(sin(dot(cell, float2(127.1, 311.7))) * 43758.5453);
}

// Value noise around a ring of `cells` cells, from 0 to 1, smooth and closed over a full turn.
static float ringNoise(float angle, float cells, float salt) {
    float around = fract(angle / (2.0 * M_PI_F)) * cells;
    float cell = floor(around);
    float blend = around - cell;
    float from = noise(float2(cell, salt));
    float to = noise(float2(fmod(cell + 1.0, cells), salt));
    return mix(from, to, blend * blend * (3.0 - 2.0 * blend));
}

// Radius change of a lumpy outline at `angle`, from -lumpDepth / 2 to lumpDepth / 2.
static float lumpiness(float angle) {
    float coarse = ringNoise(angle, lumpCoarseCells, 3.0);
    float fine = ringNoise(angle, lumpFineCells, 17.0);
    return lumpDepth * (mix(fine, coarse, lumpCoarseShare) - 0.5);
}

vertex FlakeSprite snowFlakeVertex(
    uint id [[vertex_id]],
    constant SnowFlake *flakes [[buffer(0)]],
    constant SnowUniforms &frame [[buffer(1)]]
) {
    SnowFlake flake = flakes[id];
    float age = frame.now - flake.born;
    float angle = flake.tempo * age;
    float3 flutterPhase = flutterPace * angle + flutterTwist * flake.seed + flutterOffset;
    float bobPhase = bobPace * angle + bobTwist * flake.seed + bobOffset;

    float across = flake.lane + flake.windShare * frame.wind + flake.flutter * dot(flutterWeight, sin(flutterPhase));
    float span = frame.width + 2.0 * margin;
    float2 head = float2(
        fract((across + margin) / span) * span - margin,
        flake.top - flake.speed * age + flake.bob * sin(bobPhase)
    );
    float2 velocity = float2(
        flake.windShare * frame.windSpeed
            + flake.flutter * flake.tempo * dot(flutterWeight * flutterPace, cos(flutterPhase)),
        flake.bob * flake.tempo * bobPace * cos(bobPhase) - flake.speed
    );

    float2 streak = velocity * shutter;
    float2 center = head - 0.5 * streak;
    float radius = 0.5 * flake.size;
    float pixel = 1.0 / frame.scale;
    float side = 2.0 * (radius + pixel) + length(streak);

    FlakeSprite sprite;
    sprite.position = float4(center / float2(frame.width, frame.height) * 2.0 - 1.0, 0.0, 1.0);
    sprite.pointSize = side * frame.scale;
    sprite.streak = streak;
    sprite.radius = radius;
    sprite.blur = flake.blur;
    sprite.opacity = flake.opacity;
    sprite.side = side;
    sprite.pixel = pixel;
    sprite.lump = 0.0;
    sprite.turn = 0.0;
    return sprite;
}

vertex FlakeSprite snowSpriteVertex(
    uint id [[vertex_id]],
    constant SnowSprite *sprites [[buffer(0)]],
    constant SnowUniforms &frame [[buffer(1)]]
) {
    SnowSprite source = sprites[id];
    float radius = 0.5 * source.size;
    float pixel = 1.0 / frame.scale;
    float side = 2.0 * (radius * (1.0 + 0.5 * lumpDepth * source.lump) + pixel);

    FlakeSprite sprite;
    sprite.position = float4(source.center / float2(frame.width, frame.height) * 2.0 - 1.0, 0.0, 1.0);
    sprite.pointSize = side * frame.scale;
    sprite.streak = float2(0.0);
    sprite.radius = radius;
    sprite.blur = mix(puffBlur, grainBlur, source.lump);
    sprite.opacity = source.alpha;
    sprite.side = side;
    sprite.pixel = pixel;
    sprite.lump = source.lump;
    sprite.turn = source.turn;
    return sprite;
}

// The sprite is an ellipse stretched along its streak, its head ahead, dimmer toward its tail.
fragment float4 snowFlakeFragment(
    FlakeSprite sprite [[stage_in]],
    float2 coord [[point_coord]]
) {
    float2 point = (coord - 0.5) * sprite.side * float2(1.0, -1.0);
    float travel = length(sprite.streak);
    float2 axis = travel > 0.0 ? sprite.streak / travel : float2(0.0, 1.0);
    float stretch = sprite.radius + 0.5 * travel;
    float2 local = float2(dot(point, axis), dot(point, float2(-axis.y, axis.x)));
    float outline = 1.0 + sprite.lump * lumpiness(atan2(point.y, point.x) + sprite.turn);
    float2 facing = local / float2(stretch, sprite.radius) / outline;
    float reach = length(facing);

    float feather = max(sprite.blur, sprite.pixel / sprite.radius);
    float inside = saturate((1.0 - reach) / feather);
    float coverage = inside * (2.0 - inside);
    float headward = saturate(0.5 + 0.5 * local.x / stretch);
    float alpha = sprite.opacity * coverage * sprite.radius / stretch * mix(trailShade, 1.0, headward);

    float3 color = mix(flakeCore, flakeRim, saturate(reach * reach));
    float3 normal = float3(facing, sqrt(saturate(1.0 - dot(facing, facing))));
    float light = saturate(dot(normal, normalize(lumpLight)));
    color *= mix(1.0, lumpShadow + (1.0 - lumpShadow) * light, sprite.lump);
    return float4(color * alpha, alpha);
}

struct DriftPixel {
    float4 position [[position]];
    float2 point;
};

constant float3 surfaceColor = float3(0.985, 0.990, 1.0);
constant float3 deepColor = float3(0.560, 0.640, 0.780);
constant float3 sunDirection = float3(-0.36, 0.80, 0.48);
constant float3 frontFacing = float3(0.0, 0.3, 0.954);
constant float depthFalloff = 7.0;
constant float crustDepth = 2.5;
constant float crustGloss = 0.45;
constant float ambient = 0.62;
constant float grain = 0.06;
constant float glintShare = 0.006;
constant float glintRate = 0.35;
constant float glintWidth = 0.035;
constant float glintStrength = 0.9;
constant float glintDepth = 3.0;

// Snow height at x, linear between column centers, the end columns held flat past the edges.
// Same interpolation as SnowDrift.height(at:).
static float driftHeight(device const float *heights, constant SnowDriftUniforms &drift, float x) {
    float last = float(drift.columns - 1);
    float along = clamp((x - drift.left) / drift.columnWidth - 0.5, 0.0, last);
    uint column = uint(floor(along));
    uint next = min(column + 1, drift.columns - 1);
    return mix(heights[column], heights[next], along - float(column));
}

vertex DriftPixel snowDriftVertex(
    uint id [[vertex_id]],
    constant SnowUniforms &frame [[buffer(1)]],
    constant SnowDriftUniforms &drift [[buffer(2)]]
) {
    float pixel = 1.0 / frame.scale;
    float lean = abs(drift.offset);
    float2 corner = float2(float(id & 1), float(id >> 1));
    float2 point = float2(
        drift.left - lean + corner.x * (drift.width + 2.0 * lean),
        drift.top - pixel + corner.y * (drift.peak + 2.0 * pixel)
    );

    DriftPixel out;
    out.position = float4(point / float2(frame.width, frame.height) * 2.0 - 1.0, 0.0, 1.0);
    out.point = point;
    return out;
}

fragment float4 snowDriftFragment(
    DriftPixel in [[stage_in]],
    device const float *heights [[buffer(0)]],
    constant SnowUniforms &frame [[buffer(1)]],
    constant SnowDriftUniforms &drift [[buffer(2)]],
    constant float4 *occluders [[buffer(3)]]
) {
    for (uint index = 0; index < drift.occluders; index++) {
        float4 occluder = occluders[index];
        if (all(in.point >= occluder.xy) && all(in.point < occluder.zw)) {
            discard_fragment();
        }
    }

    float pixel = 1.0 / frame.scale;
    float above = in.point.y - drift.top;
    float x = in.point.x - drift.offset * saturate(above / max(drift.peak, pixel));
    float height = driftHeight(heights, drift, x);
    float depth = height - above;
    float coverage = saturate(depth / pixel + 0.5) * saturate(above / pixel + 0.5);
    if (coverage <= 0.0) {
        discard_fragment();
    }

    float reach = 0.5 * drift.columnWidth;
    float slope = (driftHeight(heights, drift, x + reach) - driftHeight(heights, drift, x - reach))
        / (2.0 * reach);
    float crust = 1.0 - smoothstep(0.0, crustDepth, depth);
    float3 normal = normalize(mix(frontFacing, normalize(float3(-slope, 1.0, 0.0)), crust));
    float light = saturate(dot(normal, normalize(sunDirection)));

    float3 color = mix(deepColor, surfaceColor, exp(-max(depth, 0.0) / depthFalloff));
    color *= ambient + (1.0 - ambient) * light;
    color = mix(color, surfaceColor, crustGloss * crust);

    float2 cell = floor((in.point - float2(drift.left, drift.top)) * frame.scale);
    color *= 1.0 + grain * (noise(cell) - 0.5);
    if (noise(cell + 91.0) > 1.0 - glintShare) {
        float cycle = fract(frame.now * glintRate + noise(cell + 13.0));
        float pulse = (cycle - 0.5) / glintWidth;
        color += glintStrength * exp(-pulse * pulse) * (1.0 - smoothstep(0.0, glintDepth, depth));
    }

    float alpha = coverage;
    return float4(saturate(color) * alpha, alpha);
}
