#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLYRarityTier) {
    TLYRarityTierFrequent,
    TLYRarityTierNotable,
    TLYRarityTierRare,
    TLYRarityTierExceptional,
    TLYRarityTierSingular,
};

@interface TLYRarityResult : NSObject
@property(nonatomic, readonly) NSInteger score;
@property(nonatomic, readonly) TLYRarityTier tier;
- (instancetype)initWithScore:(NSInteger)score tier:(TLYRarityTier)tier;
@end

@interface TLYRarityEngine : NSObject
+ (TLYRarityResult *)evaluateTypeScarcity:(double)typeScarcity
                           liveryScarcity:(double)liveryScarcity
                         operatorScarcity:(double)operatorScarcity
                            localScarcity:(double)localScarcity
                        eventSignificance:(double)eventSignificance
                    firstPersonalSighting:(BOOL)firstPersonalSighting;
@end

@interface TLYAircraftMeshFactory : NSObject
+ (NSDictionary<NSString *, id> *)meshForModel:(NSString *)model;
@end

NS_ASSUME_NONNULL_END
