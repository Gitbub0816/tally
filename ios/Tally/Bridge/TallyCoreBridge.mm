#import "TallyCoreBridge.h"
#include "rarity_engine.hpp"
#include "aircraft_mesh.hpp"

@implementation TLYRarityResult
- (instancetype)initWithScore:(NSInteger)score tier:(TLYRarityTier)tier {
    if ((self = [super init])) { _score = score; _tier = tier; }
    return self;
}
@end

@implementation TLYAircraftMeshFactory
+ (NSDictionary<NSString *, id> *)meshForModel:(NSString *)model {
    const auto mesh = tally::AircraftMeshFactory::build([model UTF8String]);
    auto floats = [](const std::vector<float>& values) {
        return [NSData dataWithBytes:values.data() length:values.size() * sizeof(float)];
    };
    auto indices = [](const std::vector<std::uint32_t>& values) {
        return [NSData dataWithBytes:values.data() length:values.size() * sizeof(std::uint32_t)];
    };
    return @{
        @"positions": floats(mesh.positions), @"normals": floats(mesh.normals), @"texcoords": floats(mesh.texcoords),
        @"vertexCount": @(mesh.positions.size() / 3),
        @"fuselage": indices(mesh.fuselageIndices), @"fuselageCount": @(mesh.fuselageIndices.size()),
        @"wings": indices(mesh.wingIndices), @"wingsCount": @(mesh.wingIndices.size()),
        @"engines": indices(mesh.engineIndices), @"enginesCount": @(mesh.engineIndices.size()),
        @"tail": indices(mesh.tailIndices), @"tailCount": @(mesh.tailIndices.size())
    };
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
