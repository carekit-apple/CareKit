#import <Foundation/Foundation.h>


#if defined(__cplusplus)
#define OCK_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define OCK_EXTERN extern __attribute__((visibility("default")))
#endif


#define OCK_CLASS_AVAILABLE __attribute__((visibility("default")))
#define OCK_ENUM_AVAILABLE
#define OCK_AVAILABLE_DECL
