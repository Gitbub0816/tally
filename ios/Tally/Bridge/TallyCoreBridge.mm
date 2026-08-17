#import "TallyCoreBridge.h"
#include "rarity_engine.hpp"

@implementation TLYRarityResult
- (instancetype)initWithScore:(NSInteger)score tier:(TLYRarityTier)tier {
    if ((self = [super init])) { _score = score; _tier = tier; }
    return self;
}
@end

@implementation TLYRarityEngine
+ (TLYRarityResult *)evaluateTypeScarcity:(double)typeScarcity
                           liveryScarcity:(double)liveryScarcity
                         operatorScarcity:(double)operatorScarcity
                            localScarcity:(double)localScarcity
                        eventSignificance:(double)eventSignificance
                    firstPersonalSighting:(BOOL)firstPersonalSighting {
    const auto result = tally::RarityEngine::evaluate({
        .typeScarcity = typeScarcity,
        .liveryScarcity = liveryScarcity,
        .operatorScarcity = operatorScarcity,
        .localScarcity = localScarcity,
        .eventSignificance = eventSignificance,
        .firstPersonalSighting = static_cast<bool>(firstPersonalSighting),
    });
    return [[TLYRarityResult alloc] initWithScore:result.score tier:static_cast<TLYRarityTier>(result.tier)];
}
@end

