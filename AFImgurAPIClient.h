
#import "AFHTTPClient.h"

@interface AFImgurAPIClient : AFHTTPClient

+ (AFImgurAPIClient *)sharedClient;
- (void)albumImagesWithId:(NSString*)albumId
                  success:(void (^)(AFHTTPRequestOperation *operation, NSArray* images))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void)uploadImage:(UIImage *)image
           success:(void (^)(AFHTTPRequestOperation *operation, NSArray* images))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
          progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress;
@end
