#import "CMHUser.h"
#import <CloudMine/CloudMine.h>
#import "CMHUserData.h"
#import "CMHMutableUserData.h"
#import "CMHUserData_internal.h"
#import "CMHInternalUser.h"
#import "ORKResult+CMHealth.h"
#import "CMHOnboardingValidator.h"
#import "CMHConsent_internal.h"
#import "CMHErrorUtilities.h"
#import "CMHConstants_internal.h"
#import "CMHInternalProfile.h"
#import "CMHRegistrationData.h"

@interface CMHUser ()
@property (nonatomic, nullable, readwrite) CMHUserData *userData;
@end

@implementation CMHUser

+ (instancetype)currentUser
{
    static CMHUser *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [CMHUser new];
        _sharedInstance.userData = [CMHInternalUser.currentUser generateCurrentUserData];
        [CMStore defaultStore].user = [CMHInternalUser currentUser];
    });

    if (nil == _sharedInstance.userData && _sharedInstance.isLoggedIn) {
        [CMHInternalUser.currentUser loadProfileWithCompletion:^(NSError * _Nullable error) {
            if (nil != error) {
                return;
            }

            _sharedInstance.userData = [CMHInternalUser.currentUser generateCurrentUserData];
        }];
    }

    return _sharedInstance;
}

- (void)signUpWithRegistration:(ORKTaskResult *_Nullable)registrationResult andCompletion:(_Nullable CMHUserAuthCompletion)block
{
    self.userData = nil;
    NSError *regError = nil;

    CMHRegistrationData *regData = [CMHOnboardingValidator dataFromRegistrationResults:registrationResult error:&regError];

    if (nil != regError) {
        if (nil != block) {
            block(regError);
        }
        return;
    }

    [CMHInternalUser signupWithRegistration:regData andCompletion:^(NSError * _Nullable error) {
        if (nil == block) {
            return;
        }

        if (nil != error) {
            block(error);
            return;
        }

        self.userData = [CMHInternalUser.currentUser generateCurrentUserData];

        block(nil);
    }];
}

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block
{
    self.userData = nil;

    CMHRegistrationData *basicRegData = [[CMHRegistrationData alloc] initWithEmail:email
                                                                          password:password
                                                                            gender:nil
                                                                         birthdate:nil
                                                                         givenName:nil
                                                                        familyName:nil];

    [CMHInternalUser signupWithRegistration:basicRegData andCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = [CMHInternalUser.currentUser generateCurrentUserData];

        if (nil != block) {
            block(nil);
        }
    }];
}

- (void)uploadUserConsent:(ORKTaskResult *)consentResult withCompletion:(CMHUploadConsentCompletion)block
{
    [self uploadUserConsent:consentResult forStudyWithDescriptor:nil andCompletion:block];
}

- (void)uploadUserConsent:(ORKTaskResult *)consentResult forStudyWithDescriptor:(NSString *)descriptor andCompletion:(CMHUploadConsentCompletion)block
{
    NSError *consentError = nil;
    ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:consentResult error:&consentError];

    if (nil != consentError) {
        if (nil != block) {
            block(nil, consentError);
        }
        return;
    }

    if (![[CMHInternalUser currentUser] isLoggedIn]) {
        if (nil != block) {
            NSError *loggedOutError = [CMHErrorUtilities errorWithCode:CMHErrorUserNotLoggedIn localizedDescription:@"Must be logged in to upload consent"];
            block(nil, loggedOutError);
        }

        return;
    }

    [self conditionallySaveNameFromSignature:signature withCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            if (nil != block) {
                block(nil, error);
            }
            return;
        }

        NSData *signatureData = UIImageJPEGRepresentation(signature.signatureImage, 1.0);

        [[CMStore defaultStore] saveUserFileWithData:signatureData additionalOptions:nil callback:^(CMFileUploadResponse *fileResponse) {
            NSError *fileUploadError = [CMHErrorUtilities errorForFileKind:NSLocalizedString(@"signature", nil) uploadResponse:fileResponse];
            if (nil != fileUploadError) {
                if (nil != block) {
                    block(nil, fileUploadError);
                }
                return;
            }

            CMHConsent *consent = [[CMHConsent alloc] initWithConsentResult:consentResult
                                                  andSignatureImageFilename:fileResponse.key
                                                     forStudyWithDescriptor:descriptor];
            
            [consent saveWithUser:[CMHInternalUser currentUser] callback:^(CMObjectUploadResponse *response) {
                if (nil == block) {
                    return;
                }

                NSError *consentUploadError = [CMHErrorUtilities errorForKind:@"user consent" objectId:consent.objectId uploadResponse:response];
                if (nil != consentUploadError) {
                    block(nil, consentUploadError);
                    return;
                }

                block(consent, nil);
            }];
        }];
    }];
}

- (void)fetchUserConsentForStudyWithCompletion:(CMHFetchConsentCompletion)block
{
    [self fetchUserConsentForStudyWithDescriptor:nil andCompletion:block];
}

- (void)fetchUserConsentForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                 andCompletion:(_Nullable CMHFetchConsentCompletion)block
{
    if (nil == descriptor) {
        descriptor = @"";
    }

    NSString *queryString = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [CMHConsent class], CMHStudyDescriptorKey, descriptor];

    [[CMStore defaultStore] searchUserObjects:queryString
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
    {
        if (nil == block) {
            return;
        }

        NSError *error = [CMHErrorUtilities errorForKind:@"consent" fetchResponse:response];

        if (nil != error) {
            block(nil, error);
            return;
        }

        if (response.count == 0) {
            block(nil, nil);
            return;
        }

        CMHConsent *firstConsent = response.objects.firstObject;
        block(firstConsent, nil);
    }];
}

- (void)loginWithEmail:(NSString *_Nonnull)email
              password:(NSString *_Nonnull)password
         andCompletion:(_Nullable CMHUserAuthCompletion)block
{
    NSAssert(nil != email, @"CMHUser: Attempted to login with nil email");
    NSAssert(nil != password, @"CMHUser: Attempted to login with nil password");

    self.userData = nil;

    [CMHInternalUser loginAndLoadProfileWithEmail:email password:password andCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = [CMHInternalUser.currentUser generateCurrentUserData];

        if (nil != block) {
            block(nil);
        }
    }];
}

-(void)updateUserData:(CMHUserData *)userData
       withCompletion:(CMHUpdateUserDataCompletion)block
{
    NSAssert(nil != userData, @"Attempted to update user data without providing an instance of %@", [CMHUserData class]);
    
    if (![CMHInternalUser currentUser].isLoggedIn) {
        if (nil != block) {
            NSError *loggedOutError = [CMHErrorUtilities errorWithCode:CMHErrorUserNotLoggedIn localizedDescription:@"Must be logged in to update user data"];
            block(nil, loggedOutError);
        }
        
        return;
    }
    
    [[CMHInternalUser currentUser] updateProfileWithUserData:userData withCompletion:^(NSError *error) {
        if (nil != error) {
            if (nil != block) {
                block(nil, error);
            }
            return;
        }
        
        self.userData = [CMHInternalUser.currentUser generateCurrentUserData];
        
        if (nil != block) {
            block(self.userData, nil);
        }
    }];
}

- (void)resetPasswordForAccountWithEmail:(NSString *_Nonnull)email
                          withCompletion:(_Nullable CMHResetPasswordCompletion)block
{
     NSAssert(nil != email, @"CMHUser: Attempted to reset password for account with nil email");

    CMUser *resetUser = [[CMUser alloc] initWithEmail:email andPassword:@""];
    [resetUser resetForgottenPasswordWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        if (nil == block) {
            return;
        }

        NSError *resetError = [CMHErrorUtilities errorForAccountResult:resultCode];
        block(resetError);
    }];
}

- (void)logoutWithCompletion:(_Nullable CMHUserLogoutCompletion)block
{
    [[CMHInternalUser currentUser] logoutWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHErrorUtilities errorForAccountResult:resultCode];
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = nil;

        if (nil != block) {
            block(nil);
        }
    }];
}

- (BOOL)isLoggedIn
{
    return nil != [CMHInternalUser currentUser] && [CMHInternalUser currentUser].isLoggedIn;
}

# pragma mark Private

- (void)conditionallySaveNameFromSignature:(ORKConsentSignature *_Nonnull)signature withCompletion:(void (^)(NSError *error))block
{
    if ( [CMHInternalUser currentUser].hasName) {
        block(nil);
        return;
    }
    
    CMHMutableUserData *mutableUserData = [self.userData mutableCopy];
    mutableUserData.familyName = signature.familyName;
    mutableUserData.givenName = signature.givenName;
    
    [self updateUserData:[mutableUserData copy] withCompletion:^(CMHUserData * _Nullable userData, NSError * _Nullable error) {
        if (nil == userData) {
            if (nil != block) {
                block(error);
            }
            return;
        }
        
        block(nil);
    }];
}

@end
