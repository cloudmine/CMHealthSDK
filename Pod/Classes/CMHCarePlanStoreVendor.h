#import <Foundation/Foundation.h>

@class CMHCarePlanStore;

@interface CMHCarePlanStoreVendor : NSObject

+ (nonnull instancetype)sharedVendor;

- (nonnull CMHCarePlanStore *)storeForCMHIdentifier:(nonnull NSString *)identifier atDirectory:(nonnull NSURL *)URL;
- (void)forgetStoreWithCMHIdentifier:(nonnull NSString *)cmhIdentifier;
- (void)forgetStores;

@end
