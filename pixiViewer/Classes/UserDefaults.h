#import <Foundation/Foundation.h>


#ifdef __cplusplus
extern "C" {
#endif
    
id UDObject(NSString *key);
NSInteger UDInt(NSString *key);
BOOL UDBool(NSString *key);
float UDFloat(NSString *key);
NSString *UDString(NSString *key);
NSData *UDData(NSString *key);
NSArray *UDArray(NSString *key);
NSDictionary *UDDictionary(NSString *key);
NSArray *UDStringArray(NSString *key);

id UDObjectWithDefault(NSString *key, id object);
NSInteger UDIntWithDefault(NSString *key, int i);
BOOL UDBoolWithDefault(NSString *key, BOOL b);
float UDFloatWithDefault(NSString *key, float f);
NSString *UDStringWithDefault(NSString *key, NSString *string);
NSData *UDDataWithDefault(NSString *key, NSData *data);
NSArray *UDArrayWithDefault(NSString *key, NSArray *array);
NSDictionary *UDDictionaryWithDefault(NSString *key, NSDictionary *dictionary);
NSArray *UDStringArrayWithDefault(NSString *key, NSArray *stringArray);

void UDSetObject(id object, NSString *key);
void UDSetInt(NSInteger i, NSString *key);
void UDSetBool(BOOL b, NSString *key);
void UDSetFloat(float f, NSString *key);
void UDSetString(NSString *string, NSString *key);
void UDSetData(NSData *data, NSString *key);
void UDSetArray(NSArray *array, NSString *key);
void UDSetDictionary(NSDictionary *dictionary, NSString *key);
void UDSetStringArray(NSArray *stringArray, NSString *key);

id UDConstObject(NSString *key);
int UDConstInteger(NSString *key);
BOOL UDConstBool(NSString *key);
float UDConstFloat(NSString *key);
NSString *UDConstString(NSString *key);
NSData *UDConstData(NSString *key);
NSArray *UDConstArray(NSString *key);
NSDictionary *UDConstDictionary(NSString *key);
NSArray *UDConstStringArray(NSString *key);
    
#ifdef __cplusplus
}
#endif