
#import "AFImgurAPIClient.h"
#import "AFJSONRequestOperation.h"


static NSString * apiKey = @"";

@implementation AFImgurAPIClient

NSString * const kAFImgurAPIBaseURLString = @"http://api.imgur.com/2/";

+ (AFImgurAPIClient *)sharedClient {
    static AFImgurAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFImgurAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFImgurAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (void)albumImagesWithId:(NSString*)albumId
                  success:(void (^)(AFHTTPRequestOperation *operation, NSArray* images))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString* path = [NSString stringWithFormat:@"album/%@.json",albumId];
    NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:nil];
    void (^successWrapper)(AFHTTPRequestOperation *_operation, NSArray* imageURLs) =
    ^(AFHTTPRequestOperation *_operation, id _responseObject)
	{
        NSDictionary* responseJSON = (NSDictionary*)_responseObject;
        NSArray *responseImages = responseJSON[@"album"][@"images"];
        NSMutableArray* imageURLs = [[NSMutableArray alloc] initWithCapacity:responseImages.count];
        for(NSDictionary* image in responseImages) {
            [imageURLs addObject:image[@"links"]];
        }
        success(_operation,imageURLs);
	};
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:successWrapper failure:failure];
    [self enqueueHTTPRequestOperation:operation];

}

-(void)uploadImage:(UIImage *)image
           success:(void (^)(AFHTTPRequestOperation *operation, NSArray* images))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
          progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
{
    NSData   *imageData  = UIImageJPEGRepresentation(image,1);
    NSString *base64JPEGImage   = [imageData base64EncodedString];
    NSDictionary *parameters = @{
        @"key": apiKey,
        @"image": base64JPEGImage,        
    };
    
    
    void (^successWrapper)(AFHTTPRequestOperation *_operation, id _responseObject) =
    ^(AFHTTPRequestOperation *_operation, id _responseObject)
    {
        NSError* error;
        error = [self checkResponseIsDictionary:_responseObject withKeyPath:@"upload.links.original"];
        if(error) {
            failure(_operation, error);
            return;
        }

        
        if(success)
            success(_operation,_responseObject);
    };
    
    void (^failureWrapper)(AFHTTPRequestOperation *_operation, NSError *_error) = ^(AFHTTPRequestOperation *_operation,  NSError *_error)
    {
        DLog(@"Imgur client error %@",_error);
        if(failure) failure(_operation,_error);
    };

    NSURLRequest *request = [self requestWithMethod:@"POST" path:@"upload.json" parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:successWrapper failure:failureWrapper];
    [self enqueueHTTPRequestOperation:operation];
    [operation setUploadProgressBlock:progress];

}


#pragma mark - Response validation

-(NSError*) checkResponseIsDictionary:(id)responseObject withKeyPath:(NSString*)keyPath
{
    if(![responseObject isKindOfClass:[NSDictionary class]]) {
        NSString* desc = [NSString stringWithFormat:@"Unknown response: %@",[responseObject description]];
        return [self errorWithDescription:desc];
    }
    if(keyPath && [(NSDictionary*)responseObject valueForKeyPath:keyPath] == nil) {
        NSString* desc = [NSString stringWithFormat:@"Unknown response: %@",[responseObject description]];
        return [self errorWithDescription:desc];
    }
    return nil;
}

-(NSError*) errorWithDescription:(NSString*)desc
{
    NSDictionary* userInfo = @{NSLocalizedDescriptionKey:desc};
    NSError* er = [NSError errorWithDomain:@"AFImgurAPIClient" code:999 userInfo:userInfo];
    return er;
}



@end
