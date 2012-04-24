//
//  JavascriptCore-dlsym.m
//  iPhoneTest
//
//  Created by Patrick Geiller on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JavascriptCore-dlsym.h"



//
// JSBase
//
JSValueRef (*_JSEvaluateScript)(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception);
JSValueRef JSEvaluateScript(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception)
{
	return	_JSEvaluateScript(ctx, script, thisObject, sourceURL, startingLineNumber, exception);
}

void (*_JSGarbageCollect)(JSContextRef ctx);
void JSGarbageCollect(JSContextRef ctx)
{
	return	_JSGarbageCollect(ctx);
}

bool (*_JSCheckScriptSyntax)(JSContextRef ctx, JSStringRef script, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception);
bool JSCheckScriptSyntax(JSContextRef ctx, JSStringRef script, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception)
{
	return _JSCheckScriptSyntax(ctx, script, sourceURL, startingLineNumber, exception);
}


//
// JSContextRef
//
JSGlobalContextRef (*_JSGlobalContextCreate)(JSClassRef globalObjectClass);
JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass)
{
	return	_JSGlobalContextCreate(globalObjectClass);
}

JSGlobalContextRef (*_JSGlobalContextRetain)(JSGlobalContextRef ctx);
JSGlobalContextRef JSGlobalContextRetain(JSGlobalContextRef ctx)
{
	return	_JSGlobalContextRetain(ctx);
}

void (*_JSGlobalContextRelease)(JSGlobalContextRef ctx);
void JSGlobalContextRelease(JSGlobalContextRef ctx)
{
	_JSGlobalContextRelease(ctx);
}

JSObjectRef (*_JSContextGetGlobalObject)(JSContextRef ctx);
JSObjectRef JSContextGetGlobalObject(JSContextRef ctx)
{
	return	_JSContextGetGlobalObject(ctx);
}


//
// JSObjectRef
//
JSClassRef (*_JSClassCreate)(const JSClassDefinition* definition);
JSClassRef JSClassCreate(const JSClassDefinition* definition)
{
	return	_JSClassCreate(definition);
}

JSClassRef (*_JSClassRetain)(JSClassRef jsClass);
JSClassRef JSClassRetain(JSClassRef jsClass)
{
	return	_JSClassRetain(jsClass);
}

void (*_JSClassRelease)(JSClassRef jsClass);
void JSClassRelease(JSClassRef jsClass)
{
	_JSClassRelease(jsClass);
}

JSObjectRef (*_JSObjectMake)(JSContextRef ctx, JSClassRef jsClass, void* data);
JSObjectRef JSObjectMake(JSContextRef ctx, JSClassRef jsClass, void* data)
{
	return	_JSObjectMake(ctx, jsClass, data);
}

JSObjectRef (*_JSObjectMakeFunctionWithCallback)(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction);
JSObjectRef JSObjectMakeFunctionWithCallback(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction)
{
	return	_JSObjectMakeFunctionWithCallback(ctx, name, callAsFunction);
}

JSObjectRef (*_JSObjectMakeConstructor)(JSContextRef ctx, JSClassRef jsClass, JSObjectCallAsConstructorCallback callAsConstructor);
JSObjectRef JSObjectMakeConstructor(JSContextRef ctx, JSClassRef jsClass, JSObjectCallAsConstructorCallback callAsConstructor)
{
	return	_JSObjectMakeConstructor(ctx, jsClass, callAsConstructor);
}

JSObjectRef (*_JSObjectMakeFunction)(JSContextRef ctx, JSStringRef name, unsigned parameterCount, const JSStringRef parameterNames[], JSStringRef body, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception);
JSObjectRef JSObjectMakeFunction(JSContextRef ctx, JSStringRef name, unsigned parameterCount, const JSStringRef parameterNames[], JSStringRef body, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception)
{
	return	_JSObjectMakeFunction(ctx, name, parameterCount, parameterNames, body, sourceURL, startingLineNumber, exception);
}

JSValueRef (*_JSObjectGetPrototype)(JSContextRef ctx, JSObjectRef object);
JSValueRef JSObjectGetPrototype(JSContextRef ctx, JSObjectRef object)
{
	return	_JSObjectGetPrototype(ctx, object);
}

void (*_JSObjectSetPrototype)(JSContextRef ctx, JSObjectRef object, JSValueRef value);
void JSObjectSetPrototype(JSContextRef ctx, JSObjectRef object, JSValueRef value)
{
	_JSObjectSetPrototype(ctx, object, value);
}

bool (*_JSObjectHasProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName);
bool JSObjectHasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName)
{
	return	_JSObjectHasProperty(ctx, object, propertyName);
}

JSValueRef (*_JSObjectGetProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception);
JSValueRef JSObjectGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception)
{
	return	_JSObjectGetProperty(ctx, object, propertyName, exception);
}

void (*_JSObjectSetProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception);
void JSObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception)
{
	_JSObjectSetProperty(ctx, object, propertyName, value, attributes, exception);
}

bool (*_JSObjectDeleteProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception);
bool JSObjectDeleteProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception)
{
	return	_JSObjectDeleteProperty(ctx, object, propertyName, exception);
}

JSValueRef (*_JSObjectGetPropertyAtIndex)(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef* exception);
JSValueRef JSObjectGetPropertyAtIndex(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef* exception)
{
	return	_JSObjectGetPropertyAtIndex(ctx, object, propertyIndex, exception);
}

void (*_JSObjectSetPropertyAtIndex)(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef value, JSValueRef* exception);
void JSObjectSetPropertyAtIndex(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef value, JSValueRef* exception)
{
	_JSObjectSetPropertyAtIndex(ctx, object, propertyIndex, value, exception);
}

void* (*_JSObjectGetPrivate)(JSObjectRef object);
void* JSObjectGetPrivate(JSObjectRef object)
{
	return	_JSObjectGetPrivate(object);
}

bool (*_JSObjectSetPrivate)(JSObjectRef object, void* data);
bool JSObjectSetPrivate(JSObjectRef object, void* data)
{
	return	_JSObjectSetPrivate(object, data);
}

bool (*_JSObjectIsFunction)(JSContextRef ctx, JSObjectRef object);
bool JSObjectIsFunction(JSContextRef ctx, JSObjectRef object)
{
	return	_JSObjectIsFunction(ctx, object);
}

JSValueRef (*_JSObjectCallAsFunction)(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
JSValueRef JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	return	_JSObjectCallAsFunction(ctx, object, thisObject, argumentCount, arguments, exception);
}

bool (*_JSObjectIsConstructor)(JSContextRef ctx, JSObjectRef object);
bool JSObjectIsConstructor(JSContextRef ctx, JSObjectRef object)
{
	return	_JSObjectIsConstructor(ctx, object);
}

JSObjectRef (*_JSObjectCallAsConstructor)(JSContextRef ctx, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
JSObjectRef JSObjectCallAsConstructor(JSContextRef ctx, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	return	_JSObjectCallAsConstructor(ctx, object, argumentCount, arguments, exception);
}

JSPropertyNameArrayRef (*_JSObjectCopyPropertyNames)(JSContextRef ctx, JSObjectRef object);
JSPropertyNameArrayRef JSObjectCopyPropertyNames(JSContextRef ctx, JSObjectRef object)
{
	return	_JSObjectCopyPropertyNames(ctx, object);
}

JSPropertyNameArrayRef (*_JSPropertyNameArrayRetain)(JSPropertyNameArrayRef array);
JSPropertyNameArrayRef JSPropertyNameArrayRetain(JSPropertyNameArrayRef array)
{
	return	_JSPropertyNameArrayRetain(array);
}

void (*_JSPropertyNameArrayRelease)(JSPropertyNameArrayRef array);
void JSPropertyNameArrayRelease(JSPropertyNameArrayRef array)
{
	_JSPropertyNameArrayRelease(array);
}

size_t (*_JSPropertyNameArrayGetCount)(JSPropertyNameArrayRef array);
size_t JSPropertyNameArrayGetCount(JSPropertyNameArrayRef array)
{
	return	_JSPropertyNameArrayGetCount(array);
}

JSStringRef (*_JSPropertyNameArrayGetNameAtIndex)(JSPropertyNameArrayRef array, size_t index);
JSStringRef JSPropertyNameArrayGetNameAtIndex(JSPropertyNameArrayRef array, size_t index)
{
	return	_JSPropertyNameArrayGetNameAtIndex(array, index);
}

void (*_JSPropertyNameAccumulatorAddName)(JSPropertyNameAccumulatorRef accumulator, JSStringRef propertyName);
void JSPropertyNameAccumulatorAddName(JSPropertyNameAccumulatorRef accumulator, JSStringRef propertyName)
{
	_JSPropertyNameAccumulatorAddName(accumulator, propertyName);
}


//
// JSStringRef
//
JSStringRef (*_JSStringCreateWithCharacters)(const JSChar* chars, size_t numChars);
JSStringRef JSStringCreateWithCharacters(const JSChar* chars, size_t numChars)
{
	return	_JSStringCreateWithCharacters(chars, numChars);
}

JSStringRef (*_JSStringCreateWithUTF8CString)(const char* string);
JSStringRef JSStringCreateWithUTF8CString(const char* string)
{
	return	_JSStringCreateWithUTF8CString(string);
}

JSStringRef (*_JSStringRetain)(JSStringRef string);
JSStringRef JSStringRetain(JSStringRef string)
{
	return	_JSStringRetain(string);
}

void (*_JSStringRelease)(JSStringRef string);
void JSStringRelease(JSStringRef string)
{
	_JSStringRelease(string);
}

size_t (*_JSStringGetLength)(JSStringRef string);
size_t JSStringGetLength(JSStringRef string)
{
	return	_JSStringGetLength(string);
}

const JSChar* (*_JSStringGetCharactersPtr)(JSStringRef string);
const JSChar* JSStringGetCharactersPtr(JSStringRef string)
{
	return	_JSStringGetCharactersPtr(string);
}

size_t (*_JSStringGetMaximumUTF8CStringSize)(JSStringRef string);
size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string)
{
	return	_JSStringGetMaximumUTF8CStringSize(string);
}

size_t (*_JSStringGetUTF8CString)(JSStringRef string, char* buffer, size_t bufferSize);
size_t JSStringGetUTF8CString(JSStringRef string, char* buffer, size_t bufferSize)
{
	return	_JSStringGetUTF8CString(string, buffer, bufferSize);
}


bool (*_JSStringIsEqual)(JSStringRef a, JSStringRef b);
bool JSStringIsEqual(JSStringRef a, JSStringRef b)
{
	return	_JSStringIsEqual(a, b);
}

bool (*_JSStringIsEqualToUTF8CString)(JSStringRef a, const char* b);
bool JSStringIsEqualToUTF8CString(JSStringRef a, const char* b)
{
	return	_JSStringIsEqualToUTF8CString(a, b);
}


//
// JSStringRefCF
//
JSStringRef (*_JSStringCreateWithCFString)(CFStringRef string);
JSStringRef JSStringCreateWithCFString(CFStringRef string)
{
	return	_JSStringCreateWithCFString(string);
}

CFStringRef (*_JSStringCopyCFString)(CFAllocatorRef alloc, JSStringRef string);
CFStringRef JSStringCopyCFString(CFAllocatorRef alloc, JSStringRef string)
{
	return	_JSStringCopyCFString(alloc, string);
}


//
// JSValueRef
//
JSType (*_JSValueGetType)(JSContextRef ctx, JSValueRef value);
JSType JSValueGetType(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueGetType(ctx, value);
}

bool (*_JSValueIsUndefined)(JSContextRef ctx, JSValueRef value);
bool JSValueIsUndefined(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsUndefined(ctx, value);
}

bool (*_JSValueIsNull)(JSContextRef ctx, JSValueRef value);
bool JSValueIsNull(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsNull(ctx, value);
}

bool (*_JSValueIsBoolean)(JSContextRef ctx, JSValueRef value);
bool JSValueIsBoolean(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsBoolean(ctx, value);
}

bool (*_JSValueIsNumber)(JSContextRef ctx, JSValueRef value);
bool JSValueIsNumber(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsNumber(ctx, value);
}

bool (*_JSValueIsString)(JSContextRef ctx, JSValueRef value);
bool JSValueIsString(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsString(ctx, value);
}

bool (*_JSValueIsObject)(JSContextRef ctx, JSValueRef value);
bool JSValueIsObject(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueIsObject(ctx, value);
}

bool (*_JSValueIsObjectOfClass)(JSContextRef ctx, JSValueRef value, JSClassRef jsClass);
bool JSValueIsObjectOfClass(JSContextRef ctx, JSValueRef value, JSClassRef jsClass)
{
	return	_JSValueIsObjectOfClass(ctx, value, jsClass);
}

bool (*_JSValueIsEqual)(JSContextRef ctx, JSValueRef a, JSValueRef b, JSValueRef* exception);
bool JSValueIsEqual(JSContextRef ctx, JSValueRef a, JSValueRef b, JSValueRef* exception)
{
	return	_JSValueIsEqual(ctx, a, b, exception);
}

bool (*_JSValueIsStrictEqual)(JSContextRef ctx, JSValueRef a, JSValueRef b);
bool JSValueIsStrictEqual(JSContextRef ctx, JSValueRef a, JSValueRef b)
{
	return	_JSValueIsStrictEqual(ctx, a, b);
}

bool (*_JSValueIsInstanceOfConstructor)(JSContextRef ctx, JSValueRef value, JSObjectRef constructor, JSValueRef* exception);
bool JSValueIsInstanceOfConstructor(JSContextRef ctx, JSValueRef value, JSObjectRef constructor, JSValueRef* exception)
{
	return	_JSValueIsInstanceOfConstructor(ctx, value, constructor, exception);
}

JSValueRef (*_JSValueMakeUndefined)(JSContextRef ctx);
JSValueRef JSValueMakeUndefined(JSContextRef ctx)
{
	return	_JSValueMakeUndefined(ctx);
}

JSValueRef (*_JSValueMakeNull)(JSContextRef ctx);
JSValueRef JSValueMakeNull(JSContextRef ctx)
{
	return	_JSValueMakeNull(ctx);
}

JSValueRef (*_JSValueMakeBoolean)(JSContextRef ctx, bool boolean);
JSValueRef JSValueMakeBoolean(JSContextRef ctx, bool boolean)
{
	return	_JSValueMakeBoolean(ctx, boolean);
}

JSValueRef (*_JSValueMakeNumber)(JSContextRef ctx, double number);
JSValueRef JSValueMakeNumber(JSContextRef ctx, double number)
{
	return	_JSValueMakeNumber(ctx, number);
}

JSValueRef (*_JSValueMakeString)(JSContextRef ctx, JSStringRef string);
JSValueRef JSValueMakeString(JSContextRef ctx, JSStringRef string)
{
	return	_JSValueMakeString(ctx, string);
}

bool (*_JSValueToBoolean)(JSContextRef ctx, JSValueRef value);
bool JSValueToBoolean(JSContextRef ctx, JSValueRef value)
{
	return	_JSValueToBoolean(ctx, value);
}

double (*_JSValueToNumber)(JSContextRef ctx, JSValueRef value, JSValueRef* exception);
double JSValueToNumber(JSContextRef ctx, JSValueRef value, JSValueRef* exception)
{
	return	_JSValueToNumber(ctx, value, exception);
}

JSStringRef (*_JSValueToStringCopy)(JSContextRef ctx, JSValueRef value, JSValueRef* exception);
JSStringRef JSValueToStringCopy(JSContextRef ctx, JSValueRef value, JSValueRef* exception)
{
	return	_JSValueToStringCopy(ctx, value, exception);
}

JSObjectRef (*_JSValueToObject)(JSContextRef ctx, JSValueRef value, JSValueRef* exception);
JSObjectRef JSValueToObject(JSContextRef ctx, JSValueRef value, JSValueRef* exception)
{
	return	_JSValueToObject(ctx, value, exception);
}

void (*_JSValueProtect)(JSContextRef ctx, JSValueRef value);
void JSValueProtect(JSContextRef ctx, JSValueRef value)
{
	_JSValueProtect(ctx, value);
}

void (*_JSValueUnprotect)(JSContextRef ctx, JSValueRef value);
void JSValueUnprotect(JSContextRef ctx, JSValueRef value)
{
	_JSValueUnprotect(ctx, value);
}








#include <dlfcn.h>
@implementation JSCocoaSymbolFetcher
+ (void)populateJavascriptCoreSymbols
{
#define SYM_ORDER RTLD_DEFAULT

	_JSEvaluateScript = dlsym(SYM_ORDER, "JSEvaluateScript");
	if (_JSEvaluateScript == JSEvaluateScript) {
		_JSEvaluateScript = NULL;
		NSLog(@"JSCocoa Symbol population failed. Try switching SYM_ORDER to RTLD_NEXT");
		return;
	}
	_JSCheckScriptSyntax = dlsym(SYM_ORDER, "JSCheckScriptSyntax");
	_JSGarbageCollect = dlsym(SYM_ORDER, "JSGarbageCollect");
	_JSGlobalContextCreate = dlsym(SYM_ORDER, "JSGlobalContextCreate");
	_JSGlobalContextRetain = dlsym(SYM_ORDER, "JSGlobalContextRetain");
	_JSGlobalContextRelease = dlsym(SYM_ORDER, "JSGlobalContextRelease");
	_JSContextGetGlobalObject = dlsym(SYM_ORDER, "JSContextGetGlobalObject");
	_JSClassCreate = dlsym(SYM_ORDER, "JSClassCreate");
	_JSClassRetain = dlsym(SYM_ORDER, "JSClassRetain");
	_JSClassRelease = dlsym(SYM_ORDER, "JSClassRelease");
	_JSObjectMake = dlsym(SYM_ORDER, "JSObjectMake");
	_JSObjectMakeFunctionWithCallback = dlsym(SYM_ORDER, "JSObjectMakeFunctionWithCallback");
	_JSObjectMakeConstructor = dlsym(SYM_ORDER, "JSObjectMakeConstructor");
	_JSObjectMakeFunction = dlsym(SYM_ORDER, "JSObjectMakeFunction");
	_JSObjectGetPrototype = dlsym(SYM_ORDER, "JSObjectGetPrototype");
	_JSObjectSetPrototype = dlsym(SYM_ORDER, "JSObjectSetPrototype");
	_JSObjectHasProperty = dlsym(SYM_ORDER, "JSObjectHasProperty");
	_JSObjectGetProperty = dlsym(SYM_ORDER, "JSObjectGetProperty");
	_JSObjectSetProperty = dlsym(SYM_ORDER, "JSObjectSetProperty");
	_JSObjectDeleteProperty = dlsym(SYM_ORDER, "JSObjectDeleteProperty");
	_JSObjectGetPropertyAtIndex = dlsym(SYM_ORDER, "JSObjectGetPropertyAtIndex");
	_JSObjectSetPropertyAtIndex = dlsym(SYM_ORDER, "JSObjectSetPropertyAtIndex");
	_JSObjectGetPrivate = dlsym(SYM_ORDER, "JSObjectGetPrivate");
	_JSObjectSetPrivate = dlsym(SYM_ORDER, "JSObjectSetPrivate");
	_JSObjectIsFunction = dlsym(SYM_ORDER, "JSObjectIsFunction");
	_JSObjectCallAsFunction = dlsym(SYM_ORDER, "JSObjectCallAsFunction");
	_JSObjectIsConstructor = dlsym(SYM_ORDER, "JSObjectIsConstructor");
	_JSObjectCallAsConstructor = dlsym(SYM_ORDER, "JSObjectCallAsConstructor");
	_JSObjectCopyPropertyNames = dlsym(SYM_ORDER, "JSObjectCopyPropertyNames");
	_JSPropertyNameArrayRetain = dlsym(SYM_ORDER, "JSPropertyNameArrayRetain");
	_JSPropertyNameArrayRelease = dlsym(SYM_ORDER, "JSPropertyNameArrayRelease");
	_JSPropertyNameArrayGetCount = dlsym(SYM_ORDER, "JSPropertyNameArrayGetCount");
	_JSPropertyNameArrayGetNameAtIndex = dlsym(SYM_ORDER, "JSPropertyNameArrayGetNameAtIndex");
	_JSPropertyNameAccumulatorAddName = dlsym(SYM_ORDER, "JSPropertyNameAccumulatorAddName");
	_JSStringCreateWithCharacters = dlsym(SYM_ORDER, "JSStringCreateWithCharacters");
	_JSStringCreateWithUTF8CString = dlsym(SYM_ORDER, "JSStringCreateWithUTF8CString");
	_JSStringRetain = dlsym(SYM_ORDER, "JSStringRetain");
	_JSStringRelease = dlsym(SYM_ORDER, "JSStringRelease");
	_JSStringGetLength = dlsym(SYM_ORDER, "JSStringGetLength");
	_JSStringGetCharactersPtr = dlsym(SYM_ORDER, "JSStringGetCharactersPtr");
	_JSStringGetMaximumUTF8CStringSize = dlsym(SYM_ORDER, "JSStringGetMaximumUTF8CStringSize");
	_JSStringGetUTF8CString = dlsym(SYM_ORDER, "JSStringGetUTF8CString");
	_JSStringIsEqual = dlsym(SYM_ORDER, "JSStringIsEqual");
	_JSStringIsEqualToUTF8CString = dlsym(SYM_ORDER, "JSStringIsEqualToUTF8CString");
	_JSStringCreateWithCFString = dlsym(SYM_ORDER, "JSStringCreateWithCFString");
	_JSStringCopyCFString = dlsym(SYM_ORDER, "JSStringCopyCFString");
	_JSValueGetType = dlsym(SYM_ORDER, "JSValueGetType");
	_JSValueIsUndefined = dlsym(SYM_ORDER, "JSValueIsUndefined");
	_JSValueIsNull = dlsym(SYM_ORDER, "JSValueIsNull");
	_JSValueIsBoolean = dlsym(SYM_ORDER, "JSValueIsBoolean");
	_JSValueIsNumber = dlsym(SYM_ORDER, "JSValueIsNumber");
	_JSValueIsString = dlsym(SYM_ORDER, "JSValueIsString");
	_JSValueIsObject = dlsym(SYM_ORDER, "JSValueIsObject");
	_JSValueIsObjectOfClass = dlsym(SYM_ORDER, "JSValueIsObjectOfClass");
	_JSValueIsEqual = dlsym(SYM_ORDER, "JSValueIsEqual");
	_JSValueIsStrictEqual = dlsym(SYM_ORDER, "JSValueIsStrictEqual");
	_JSValueIsInstanceOfConstructor = dlsym(SYM_ORDER, "JSValueIsInstanceOfConstructor");
	_JSValueMakeUndefined = dlsym(SYM_ORDER, "JSValueMakeUndefined");
	_JSValueMakeNull = dlsym(SYM_ORDER, "JSValueMakeNull");
	_JSValueMakeBoolean = dlsym(SYM_ORDER, "JSValueMakeBoolean");
	_JSValueMakeNumber = dlsym(SYM_ORDER, "JSValueMakeNumber");
	_JSValueMakeString = dlsym(SYM_ORDER, "JSValueMakeString");
	_JSValueToBoolean = dlsym(SYM_ORDER, "JSValueToBoolean");
	_JSValueToNumber = dlsym(SYM_ORDER, "JSValueToNumber");
	_JSValueToStringCopy = dlsym(SYM_ORDER, "JSValueToStringCopy");
	_JSValueToObject = dlsym(SYM_ORDER, "JSValueToObject");
	_JSValueProtect = dlsym(SYM_ORDER, "JSValueProtect");
	_JSValueUnprotect = dlsym(SYM_ORDER, "JSValueUnprotect");
}
@end
