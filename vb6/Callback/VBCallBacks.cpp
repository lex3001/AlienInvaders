// VBCallBacks.cpp: implementation of the VBCallBacks class.
//
//////////////////////////////////////////////////////////////////////

#include "VBCallBacks.h"

#ifdef __cplusplus
extern "C"{
#endif 

int GenericCallBack(
	int (* fPtr) (int, int, int, int),
	int arg1,
	int arg2,
	int arg3,
	int arg4)
{
	return fPtr(arg1, arg2, arg3, arg4);
}

void SimpleCallBack(void (* fPtr) ())
{
	fPtr();
	return;
}

#ifdef __cplusplus
}
#endif 
