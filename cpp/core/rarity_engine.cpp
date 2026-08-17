#include "rarity_engine.hpp"

#include <algorithm>
#include <cmath>

namespace tally {
namespace {
constexpr double clampFactor(double value) noexcept {
    return std::clamp(value, 0.0, 1.0);
}

constexpr RarityTier tierFor(const std::uint8_t score) noexcept {
    if (score >= 92) return RarityTier::singular;
    if (score >= 78) return RarityTier::exceptional;
    if (score >= 60) return RarityTier::rare;
    if (score >= 35) return RarityTier::notable;
    return RarityTier::frequent;
}
} // namespace

RarityResult RarityEngine::evaluate(const RarityFactors& value) noexcept {
    // Local context is deliberately strongest: an A330 at BNA should score
    // differently from the same airframe at SFO. Livery is next strongest so
    // one-of-one schemes remain valuable even on common aircraft.
    const auto weighted =
        clampFactor(value.typeScarcity) * 0.14 +
        clampFactor(value.liveryScarcity) * 0.25 +
        clampFactor(value.operatorScarcity) * 0.12 +
        clampFactor(value.localScarcity) * 0.31 +
        clampFactor(value.eventSignificance) * 0.12 +
        (value.firstPersonalSighting ? 0.06 : 0.0);

    const auto score = static_cast<std::uint8_t>(
        std::clamp(std::lround(weighted * 100.0), 0L, 100L)
    );
    return {score, tierFor(score)};
}

std::string_view RarityEngine::name(const RarityTier tier) noexcept {
    switch (tier) {
        case RarityTier::frequent: return "frequent";
        case RarityTier::notable: return "notable";
        case RarityTier::rare: return "rare";
        case RarityTier::exceptional: return "exceptional";
        case RarityTier::singular: return "singular";
    }
    return "frequent";
}
} // namespace tally

