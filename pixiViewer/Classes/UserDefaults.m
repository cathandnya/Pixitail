#import "UserDefaults.h"


id UDObject(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

NSInteger UDInt(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

BOOL UDBool(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

float UDFloat(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] floatForKey:key];
}

NSString *UDString(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

NSData *UDData(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] dataForKey:key];
}

NSArray *UDArray(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] arrayForKey:key];
}

NSDictionary *UDDictionary(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
}

NSArray *UDStringArray(NSString *key) {
	return [[NSUserDefaults standardUserDefaults] stringArrayForKey:key];
}

id UDObjectWithDefault(NSString *key, id object) {
	if (UDObject(key) == nil) {
		return object;
	}
	return UDObject(key);
}

NSInteger UDIntWithDefault(NSString *key, int i) {
	if (UDObject(key) == nil) {
		return i;
	}
	return UDInt(key);
}

BOOL UDBoolWithDefault(NSString *key, BOOL b) {
	if (UDObject(key) == nil) {
		return b;
	}
	return UDBool(key);
}

float UDFloatWithDefault(NSString *key, float f) {
	if (UDObject(key) == nil) {
		return f;
	}
	return UDFloat(key);
}

NSString *UDStringWithDefault(NSString *key, NSString *string) {
	if (UDObject(key) == nil) {
		return string;
	}
	return UDString(key);
}

NSData *UDDataWithDefault(NSString *key, NSData *data) {
	if (UDObject(key) == nil) {
		return data;
	}
	return UDData(key);
}

NSArray *UDArrayWithDefault(NSString *key, NSArray *array) {
	if (UDObject(key) == nil) {
		return array;
	}
	return UDArray(key);
}

NSDictionary *UDDictionaryWithDefault(NSString *key, NSDictionary *dictionary) {
	if (UDObject(key) == nil) {
		return dictionary;
	}
	return UDDictionary(key);
}

NSArray *UDStringArrayWithDefault(NSString *key, NSArray *stringArray) {
	if (UDObject(key) == nil) {
		return stringArray;
	}
	return UDStringArray(key);
}

void UDSetObject(id object, NSString *key) {
	if (object) {
		[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	}
}

void UDSetInt(NSInteger i, NSString *key) {
	[[NSUserDefaults standardUserDefaults] setInteger:i forKey:key];
}

void UDSetBool(BOOL b, NSString *key) {
	[[NSUserDefaults standardUserDefaults] setBool:b forKey:key];
}

void UDSetFloat(float f, NSString *key) {
	[[NSUserDefaults standardUserDefaults] setFloat:f forKey:key];
}

void UDSetString(NSString *string, NSString *key) {
	if (string) {
		[[NSUserDefaults standardUserDefaults] setObject:string forKey:key];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	}
}

void UDSetData(NSData *data, NSString *key) {
    UDSetObject(data, key);
}

void UDSetArray(NSArray *array, NSString *key) {
    UDSetObject(array, key);
}

void UDSetDictionary(NSDictionary *dictionary, NSString *key) {
    UDSetObject(dictionary, key);
}

void UDSetStringArray(NSArray *stringArray, NSString *key) {
    UDSetObject(stringArray, key);
}

static NSDictionary *info() {
    static NSDictionary *info = nil;
	if (info == nil) {
		info = [[[NSBundle mainBundle] localizedInfoDictionary] retain];
	}
	return info;
}

id UDConstObject(NSString *key) {
	return [info() objectForKey:key];
}

int UDConstInteger(NSString *key) {
	return [[info() objectForKey:key] intValue];
}

BOOL UDConstBool(NSString *key) {
	return [[info() objectForKey:key] boolValue];
}

float UDConstFloat(NSString *key) {
	return [[info() objectForKey:key] floatValue];
}

NSString *UDConstString(NSString *key) {
	return [info() objectForKey:key];
}

NSData *UDConstData(NSString *key) {
	return [info() objectForKey:key];
}

NSArray *UDConstArray(NSString *key) {
	return [info() objectForKey:key];
}

NSDictionary *UDConstDictionary(NSString *key) {
	return [info() objectForKey:key];
}

NSArray *UDConstStringArray(NSString *key) {
	return [info() objectForKey:key];
}


