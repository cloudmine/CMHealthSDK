#import "CMHCareActivity.h"

@interface CMHCareActivity ()

@property (nonatomic, nonnull, readwrite) OCKCarePlanActivity *ckActivity;

@end

@implementation CMHCareActivity

#pragma mark Initialization

- (instancetype)initWithActivity:(nonnull OCKCarePlanActivity *)activity andUserId:(nonnull NSString *)cmhIdentifier;
{
    NSAssert(nil != activity, @"%@ cannot be initialized without an activity", [self class]);
    NSAssert(nil != cmhIdentifier, @"%@ cannot be initialized without a user object id", [self class]);
    
    NSString *cmhObjectId = [NSString stringWithFormat:@"%@-%@", activity.identifier, cmhIdentifier];
    
    self = [super initWithObjectId:cmhObjectId];
    if (nil == self) return nil;
    
    _ckActivity = activity;
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) { return nil; }
    
    _ckActivity = [aDecoder decodeObjectForKey:@"ckActivity"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.ckActivity forKey:@"ckActivity"];
}

@end