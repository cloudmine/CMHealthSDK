#import "CMHInternalProfile.h"

@implementation CMHInternalProfile

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    _email = [aDecoder decodeObjectForKey:@"email"];
    _givenName = [aDecoder decodeObjectForKey:@"givenName"];
    _familyName = [aDecoder decodeObjectForKey:@"familyName"];
    _gender = [aDecoder decodeObjectForKey:@"gender"];
    _dateOfBirth = [aDecoder decodeObjectForKey:@"dateOfBirth"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.email forKey:@"email"];

    if (nil != self.givenName) {
        [aCoder encodeObject:self.givenName forKey:@"givenName"];
    }

    if (nil != self.familyName) {
        [aCoder encodeObject:self.familyName forKey:@"familyName"];
    }

    if (nil != self.gender) {
        [aCoder encodeObject:self.gender forKey:@"gender"];
    }

    if (nil != self.dateOfBirth) {
        [aCoder encodeObject:self.dateOfBirth forKey:@"dateOfBirth"];
    }
}

@end
