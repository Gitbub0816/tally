#include "aircraft_mesh.hpp"

#include <algorithm>
#include <cmath>
#include <string>

namespace tally {
namespace {
constexpr float pi = 3.14159265358979323846f;

struct Params { float length, radius, span, engineRadius, engineLength; bool hump; };

Params params(std::string_view model) {
    if (model.find("747") != std::string_view::npos) return {5.3f, .34f, 4.65f, .20f, .58f, true};
    if (model.find("787") != std::string_view::npos) return {5.0f, .31f, 4.55f, .22f, .62f, false};
    if (model.find("A350") != std::string_view::npos) return {5.15f, .32f, 4.75f, .22f, .64f, false};
    if (model.find("A220") != std::string_view::npos) return {3.75f, .23f, 3.25f, .145f, .42f, false};
    if (model.find("A320") != std::string_view::npos) return {3.9f, .235f, 3.35f, .15f, .43f, false};
    return {4.15f, .235f, 3.45f, .145f, .44f, false};
}

std::uint32_t vertex(AircraftMesh& mesh, float x, float y, float z, float nx, float ny, float nz, float u, float v) {
    mesh.positions.insert(mesh.positions.end(), {x, y, z});
    mesh.normals.insert(mesh.normals.end(), {nx, ny, nz});
    mesh.texcoords.insert(mesh.texcoords.end(), {u, v});
    return static_cast<std::uint32_t>(mesh.positions.size() / 3 - 1);
}

void quad(std::vector<std::uint32_t>& out, std::uint32_t a, std::uint32_t b, std::uint32_t c, std::uint32_t d) {
    out.insert(out.end(), {a, b, c, a, c, d});
}

void addFuselage(AircraftMesh& mesh, const Params& p, float yOffset = 0, float xStart = 0, float lengthScale = 1, float radiusScale = 1) {
    constexpr int rings = 26, sides = 24;
    const auto start = static_cast<std::uint32_t>(mesh.positions.size() / 3);
    for (int i = 0; i <= rings; ++i) {
        const float t = static_cast<float>(i) / rings;
        const float profile = std::pow(std::max(0.0f, std::sin(pi * t)), .38f);
        const float x = (t - .5f) * p.length * lengthScale + xStart;
        for (int s = 0; s <= sides; ++s) {
            const float a = 2 * pi * static_cast<float>(s) / sides;
            const float ny = std::sin(a), nz = std::cos(a);
            vertex(mesh, x, yOffset + ny * p.radius * radiusScale * profile, nz * p.radius * radiusScale * profile,
                   0, ny, nz, t, static_cast<float>(s) / sides);
        }
    }
    for (int i = 0; i < rings; ++i) for (int s = 0; s < sides; ++s) {
        const auto a = start + i * (sides + 1) + s;
        const auto b = a + sides + 1;
        quad(mesh.fuselageIndices, a, b, b + 1, a + 1);
    }
}

void addWing(AircraftMesh& mesh, const Params& p, float side) {
    const float zRoot = side * p.radius * .45f, zTip = side * p.span * .5f, y = -.035f;
    const auto a = vertex(mesh, -p.length * .12f, y, zRoot, 0, 1, 0, 0, 0);
    const auto b = vertex(mesh,  p.length * .20f, y, zRoot, 0, 1, 0, 1, 0);
    const auto c = vertex(mesh,  p.length * .34f, y, zTip, 0, 1, 0, 1, 1);
    const auto d = vertex(mesh,  p.length * .08f, y, zTip, 0, 1, 0, 0, 1);
    quad(mesh.wingIndices, a, b, c, d);
}

void addTail(AircraftMesh& mesh, const Params& p) {
    const float x = p.length * .35f;
    auto a = vertex(mesh, x, .05f, 0, 0, 0, 1, 0, 0);
    auto b = vertex(mesh, p.length * .48f, .05f, 0, 0, 0, 1, 1, 0);
    auto c = vertex(mesh, p.length * .44f, p.radius * 2.45f, 0, 0, 0, 1, 1, 1);
    auto d = vertex(mesh, p.length * .30f, p.radius * .75f, 0, 0, 0, 1, 0, 1);
    quad(mesh.tailIndices, a, b, c, d);
    for (float side : {-1.0f, 1.0f}) {
        const float root = side * p.radius * .35f, tip = side * p.span * .20f;
        a = vertex(mesh, p.length * .34f, .04f, root, 0, 1, 0, 0, 0);
        b = vertex(mesh, p.length * .47f, .04f, root, 0, 1, 0, 1, 0);
        c = vertex(mesh, p.length * .47f, .04f, tip, 0, 1, 0, 1, 1);
        d = vertex(mesh, p.length * .37f, .04f, tip, 0, 1, 0, 0, 1);
        quad(mesh.tailIndices, a, b, c, d);
    }
}

void addEngine(AircraftMesh& mesh, const Params& p, float side) {
    constexpr int rings = 8, sides = 18;
    const auto start = static_cast<std::uint32_t>(mesh.positions.size() / 3);
    const float centerX = -p.length * .03f, centerY = -p.radius * 1.45f, centerZ = side * p.span * .225f;
    for (int i = 0; i <= rings; ++i) {
        const float t = static_cast<float>(i) / rings;
        for (int s = 0; s <= sides; ++s) {
            const float a = 2 * pi * static_cast<float>(s) / sides;
            const float ny = std::sin(a), nz = std::cos(a);
            vertex(mesh, centerX + (t - .5f) * p.engineLength, centerY + ny * p.engineRadius, centerZ + nz * p.engineRadius,
                   0, ny, nz, t, static_cast<float>(s) / sides);
        }
    }
    for (int i = 0; i < rings; ++i) for (int s = 0; s < sides; ++s) {
        const auto a = start + i * (sides + 1) + s;
        const auto b = a + sides + 1;
        quad(mesh.engineIndices, a, b, b + 1, a + 1);
    }
}
} // namespace

AircraftMesh AircraftMeshFactory::build(std::string_view model) {
    AircraftMesh mesh;
    const auto p = params(model);
    addFuselage(mesh, p);
    if (p.hump) addFuselage(mesh, p, p.radius * .43f, -p.length * .14f, .43f, .58f);
    addWing(mesh, p, -1); addWing(mesh, p, 1);
    addTail(mesh, p);
    addEngine(mesh, p, -1); addEngine(mesh, p, 1);
    return mesh;
}

} // namespace tally
