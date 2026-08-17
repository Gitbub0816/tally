#include "rarity_engine.hpp"

#include <cassert>
#include <iostream>

int main() {
    using tally::RarityEngine;
    using tally::RarityFactors;
    using tally::RarityTier;

    const auto localA330 = RarityEngine::evaluate({.typeScarcity = 0.55, .localScarcity = 0.95, .firstPersonalSighting = true});
    const auto commonA330 = RarityEngine::evaluate({.typeScarcity = 0.55, .localScarcity = 0.12, .firstPersonalSighting = true});
    assert(localA330.score > commonA330.score);

    const auto oneOfOne = RarityEngine::evaluate({.typeScarcity = 1.0, .liveryScarcity = 1.0, .operatorScarcity = 1.0, .localScarcity = 1.0, .eventSignificance = 1.0, .firstPersonalSighting = true});
    assert(oneOfOne.tier == RarityTier::singular);

    const auto clamped = RarityEngine::evaluate({.typeScarcity = 5.0, .liveryScarcity = -2.0});
    assert(clamped.score <= 100);
    std::cout << "rarity engine tests passed\n";
}
