/* 
	lib_mysqludf_udf - a library for reporting internals from the udf interface.
	This is intended primarily for debugging purposes and discovery of undocumented behaviour
	
	Copyright (C) 2007  Roland Bouman 
	web: http://www.mysqludf.org/ 
	
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/
#include <windows.h>
#include <string.h>
#include <mysql.h>


#if defined(_WIN32) || defined(_WIN64)
#define DLLEXP __declspec(dllexport) 
#else
#define DLLEXP
#endif

#ifdef	__cplusplus
extern "C" {
#endif

#define LIBVERSION "lib_mysqludf_udf version 0.0.3"

DLLEXP 
my_bool lib_mysqludf_udf_info_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void lib_mysqludf_udf_info_deinit(
	UDF_INIT *initid
);

DLLEXP 
char* lib_mysqludf_udf_info(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long* length
,	char *is_null
,	char *error
);
/*
 * udf_arg_count
 * 
 * return the value of UDF_ARGS->arg_count
 * */
DLLEXP
my_bool udf_arg_count_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_count_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_count(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * udf_arg_type
 * 
 * return the value of UDF_ARGS->arg_type[0]
 * */
DLLEXP
my_bool udf_arg_type_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_type_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_type(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * udf_arg_value
 * 
 * return the value of UDF_ARGS->args[0]
 * */
DLLEXP
my_bool udf_arg_value_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_value_deinit(
	UDF_INIT *initid
);

DLLEXP
char* udf_arg_value(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long *length
,   char *is_null
,	char *error
);
              
/*
 * udf_arg_value_is_constant
 * 
 * returns 0 if the argument == NULL in the init function 
 * */
DLLEXP
my_bool udf_arg_value_is_constant_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_value_is_constant_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_value_is_constant(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * udf_arg_value_is_null
 * 
 * returns 1 if the argument == NULL in the main function 
 * */
DLLEXP
my_bool udf_arg_value_is_null_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_value_is_null_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_value_is_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);
/*
 * udf_arg_value_length
 * 
 * return the value of UDF_ARGS->lengths[0]
 * */
DLLEXP
my_bool udf_arg_value_length_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_value_length_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_value_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * udf_arg_maybe_null
 * 
 * return the value of UDF_ARGS->maybe_null[0]
 * */
DLLEXP
my_bool udf_arg_maybe_null_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_maybe_null_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_maybe_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * udf_arg_attribute
 * 
 * return the value of UDF_ARGS->attributes[0]
 * */
DLLEXP
my_bool udf_arg_attribute_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_attribute_deinit(
	UDF_INIT *initid
);

DLLEXP
char* udf_arg_attribute(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long *length
,   char *is_null
,	char *error
);

/*
 * udf_arg_attribute_length
 * 
 * return the value of UDF_ARGS->attribute_lengths[0]
 * */
DLLEXP
my_bool udf_arg_attribute_length_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_arg_attribute_length_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_arg_attribute_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

/*
 * 	INITID functions
 * 
 * */

DLLEXP
my_bool udf_initid_const_item_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_initid_const_item_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_initid_const_item(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

DLLEXP
my_bool udf_initid_maybe_null_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_initid_maybe_null_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_initid_maybe_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

DLLEXP
my_bool udf_initid_decimals_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_initid_decimals_deinit(
	UDF_INIT *initid
);

DLLEXP
double udf_initid_decimals(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

DLLEXP
my_bool udf_initid_max_length_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_initid_max_length_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_initid_max_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

DLLEXP
my_bool udf_initid_error_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP
void udf_initid_error_deinit(
	UDF_INIT *initid
);

DLLEXP
long long udf_initid_error(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
);

#ifdef	__cplusplus
}
#endif

/**
 * lib_mysqludf_udf_info
 */
my_bool lib_mysqludf_udf_info_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=0){
		strcpy(
			message
		,	"No arguments allowed (udf: lib_mysqludf_udf_info)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}
void lib_mysqludf_udf_info_deinit(
	UDF_INIT *initid
){
}
char* lib_mysqludf_udf_info(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long* length
,	char *is_null
,	char *error
){
	strcpy(result,LIBVERSION);
	*length = strlen(LIBVERSION);
	return result;
}

/*
 * udf_arg_count
 * 
 * return the value of UDF_ARGS->arg_count
 * */
my_bool udf_arg_count_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	return 0;
}

void udf_arg_count_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_count(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return args->arg_count;
}

/*
 * udf_arg_type
 * 
 * return the value of UDF_ARGS->arg_type[0]
 * */
my_bool udf_arg_type_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_type)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_type_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_type(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return args->arg_type[0];
}

/*
 * udf_arg_value_is_constant
 * 
 * returns 0 if the argument == NULL in the init function 
 * */
my_bool udf_arg_value_is_constant_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_value_is_constant)"
		);
		status = 1;
	} else {
		status = 0;
	}
	//if the value != NULL, we are dealing with a constant
	//in that case, we abuse the argument type to mark it as a constant
	//this will work as long as there is this limited set of types.
	if(args->args[0]!=NULL){
		args->arg_type[0] = 127 - args->arg_type[0]; 
	}
	return status;
}

void udf_arg_value_is_constant_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_value_is_constant(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	//if the type > 64, it means we assigned it a value
	//in the init function to mark it as constant.
	return (args->arg_type[0] > 64)?1:0;
}

/*
 * udf_arg_value_is_null
 * 
 * returns 1 if the argument == NULL in the main function 
 * */
my_bool udf_arg_value_is_null_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_value_is_null)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_value_is_null_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_value_is_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return (args->args[0] == NULL)?1:0;
}
/*
 * udf_arg_value
 * 
 * return the value of UDF_ARGS->args[0]
 * */
my_bool udf_arg_value_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_value)"
		);
		status = 1;
	} else {
		args->arg_type[0] = STRING_RESULT;
		status = 0;
	}
	return status;
}

void udf_arg_value_deinit(
	UDF_INIT *initid
){	
}

char* udf_arg_value(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long *length
,   char *is_null
,	char *error
){
	*length = args->lengths[0];
	return args->args[0];
}
              
/*
 * udf_arg_length
 * 
 * return the value of UDF_ARGS->lengths[0]
 * */
my_bool udf_arg_value_length_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_length)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_value_length_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_value_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return args->lengths[0];
}

/*
 * udf_arg_maybe_null
 * 
 * return the value of UDF_ARGS->maybe_null[0]
 * */
my_bool udf_arg_maybe_null_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_maybe_null)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_maybe_null_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_maybe_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return args->maybe_null[0];
}

/*
 * udf_arg_attribute
 * 
 * return the value of UDF_ARGS->attributes[0]
 * */
my_bool udf_arg_attribute_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_attribute)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_attribute_deinit(
	UDF_INIT *initid
){
}

char* udf_arg_attribute(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long *length
,   char *is_null
,	char *error
){
	*length = args->attribute_lengths[0];
	return args->attributes[0];
}

/*
 * udf_arg_attribute_length
 * 
 * return the value of UDF_ARGS->attribute_lengths[0]
 * */
my_bool udf_arg_attribute_length_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly 1 argument (udf: udf_arg_attribute_length)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}

void udf_arg_attribute_length_deinit(
	UDF_INIT *initid
){
}

long long udf_arg_attribute_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return args->attribute_lengths[0];
}

/*
 * udf_init_error
 * 
 * raise an error in the init function
 * */
my_bool udf_initid_error_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	char *msg; 	
	int unsigned msg_length;
	if(args->arg_count==0){
		msg = "";
		msg_length = 0;
	} else {
		args->arg_type[0] = STRING_RESULT;
		msg = args->args[0];
		msg_length = args->lengths[0]>255?255:args->lengths[0];  		
	}
	memcpy(
		message
	,	msg
	,	msg_length
	);
	message[msg_length] = '\0';
	return 1;
}

void udf_initid_error_deinit(
	UDF_INIT *initid
){
}

long long udf_initid_error(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return 0;
}

my_bool udf_initid_maybe_null_init(
		UDF_INIT *initid
	,	UDF_ARGS *args
	,	char *message
){
	return 0;
}

void udf_initid_maybe_null_deinit(
	UDF_INIT *initid
){
	
}

long long udf_initid_maybe_null(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return initid->maybe_null;
}

my_bool udf_initid_decimals_init(
		UDF_INIT *initid
	,	UDF_ARGS *args
	,	char *message
){
	return 0;
}

void udf_initid_decimals_deinit(
	UDF_INIT *initid
){
	
}

double udf_initid_decimals(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return (double)initid->decimals;
}

my_bool udf_initid_max_length_init(
		UDF_INIT *initid
	,	UDF_ARGS *args
	,	char *message
){
	return 0;
}

void udf_initid_max_length_deinit(
	UDF_INIT *initid
){
	
}

long long udf_initid_max_length(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return initid->max_length;
}

my_bool udf_initid_const_item_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	return 0;
}

void udf_initid_const_item_deinit(
	UDF_INIT *initid
){
	
}

long long udf_initid_const_item(
	UDF_INIT *initid
,	UDF_ARGS *args
,   char *is_null
,	char *error
){
	return initid->const_item;
}
