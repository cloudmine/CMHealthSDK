#import <Foundation/Foundation.h>

/**
 *  Immutable "bag of data" for a given user. Developers should only
 *  consume these objects from the `CMHUser` isntance.
 *
 *  @see CMHUser class
 */
@interface CMHUserData : NSObject<NSCopying, NSMutableCopying>

/**
 *  Email address used to create the account. Never `nil`.
 */
@property (nonatomic, nonnull, readonly) NSString *email;

@property (nonatomic, nonnull, readonly) NSString *userId;

@property (nonatomic, readonly) BOOL isAdmin;

/**
 *  Family name, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *familyName;

/**
 *  Given name, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *givenName;

/**
 *  User's gender as a string, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *gender;

/**
 *  User's date of birth, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSDate *dateOfBirth;

/**
 * Dictionary saving any additional properties to the user's profile.
 * Use this to extend `CMHUserData` with data appropriate to your
 * domain.
 *
 * @warning Elements are restricted to JSON-COMPATIBLE TYPES ONLY
 */
@property (nonatomic, nonnull, readonly) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end
