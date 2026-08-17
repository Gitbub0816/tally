#pragma once

#include <cstdint>
#include <string_view>
#include <vector>

namespace tally {

struct AircraftMesh {
    std::vector<float> positions;
    std::vector<float> normals;
    std::vector<float> texcoords;
    std::vector<std::uint32_t> fuselageIndices;
    std::vector<std::uint32_t> wingIndices;
    std::vector<std::uint32_t> engineIndices;
    std::vector<std::uint32_t> tailIndices;
};

class AircraftMeshFactory {
public:
    static AircraftMesh build(std::string_view model);
};

} // namespace tally
