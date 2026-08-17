#pragma once

#include <cstdint>
#include <string_view>

namespace tally {

struct RarityFactors {
    double typeScarcity{};
    double liveryScarcity{};
    double operatorScarcity{};
    double localScarcity{};
    double eventSignificance{};
    bool firstPersonalSighting{};
};

enum class RarityTier : std::uint8_t {
    frequent,
    notable,
    rare,
    exceptional,
    singular,
};

struct RarityResult {
    std::uint8_t score{};
    RarityTier tier{RarityTier::frequent};
};

class RarityEngine final {
public:
    [[nodiscard]] static RarityResult evaluate(const RarityFactors& factors) noexcept;
    [[nodiscard]] static std::string_view name(RarityTier tier) noexcept;
};

} // namespace tally

