/* 
	lib_mysqludf_stat - a library of mysql udfs with statistical functions
	Copyright (C) 2007  Roland Bouman 
	web: http://www.xcdsql.org/MySQL/UDF/ 
	email: mysqludfs@gmail.com

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

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(WIN32)
#define DLLEXP __declspec(dllexport) 
#else
#define DLLEXP
#endif

#ifdef STANDARD
#include <string.h>
#include <stdlib.h>
#include <time.h>
#ifdef __WIN__
typedef unsigned __int64 ulonglong;
typedef __int64 longlong;
#else
typedef unsigned long long ulonglong;
typedef long long longlong;
#endif /*__WIN__*/
#else
#include <my_global.h>
#include <my_sys.h>
#endif
#include <mysql.h>
#include <m_ctype.h>
#include <m_string.h>
#include <stdlib.h>

#include <ctype.h>

#ifdef HAVE_DLOPEN

#define LIBVERSION "lib_mysqludf_stat version 0.0.3"

#ifdef	__cplusplus
extern "C" {
#endif

/**
 * lib_mysqludf_statistics_info
 */
DLLEXP 
my_bool lib_mysqludf_stat_info_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void lib_mysqludf_stat_info_deinit(
	UDF_INIT *initid
);

DLLEXP 
char* lib_mysqludf_stat_info(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char* result
,	unsigned long* length
,	char *is_null
,	char *error
);

/**
 * ACCUMULATE_INT
 */

DLLEXP 
my_bool stat_accum_int_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void stat_accum_int_deinit(
	UDF_INIT *initid
);

DLLEXP 
longlong stat_accum_int(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

/**
 * ACCUMULATE_DOUBLE
 */

DLLEXP 
my_bool stat_accum_double_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void stat_accum_double_deinit(
	UDF_INIT *initid
);

DLLEXP 
double stat_accum_double(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);
/**
 * PEARSON_SAMPLE
 * 			(http://en.wikipedia.org/wiki/Correlation#Pearson.27s_product-moment_coefficient)
 * 			sum_sq_x = 0
			sum_sq_y = 0
			sum_coproduct = 0
			mean_x = x[1]
			mean_y = y[1]
			for i in 2 to N:
			    sweep = (i - 1.0) / i
			    delta_x = x[i] - mean_x
			    delta_y = y[i] - mean_y
			    sum_sq_x += delta_x * delta_x * sweep
			    sum_sq_y += delta_y * delta_y * sweep
			    sum_coproduct += delta_x * delta_y * sweep
			    mean_x += delta_x / i
			    mean_y += delta_y / i 
			pop_sd_x = sqrt( sum_sq_x / N )
			pop_sd_y = sqrt( sum_sq_y / N )
			cov_x_y = sum_coproduct / N
			correlation = cov_x_y / (pop_sd_x * pop_sd_y)
 */

DLLEXP 
my_bool stat_pmcc_samp_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void stat_pmcc_samp_deinit(
	UDF_INIT *initid
);

DLLEXP 
double stat_pmcc_samp(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_pmcc_samp_reset(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_pmcc_samp_clear(
	UDF_INIT *initid
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_pmcc_samp_add(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

/**
 * POINT_BISERIAL_SAMPLE
 */
DLLEXP 
my_bool stat_ptbis_samp_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void stat_ptbis_samp_deinit(
	UDF_INIT *initid
);

DLLEXP 
double stat_ptbis_samp(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_ptbis_samp_reset(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_ptbis_samp_clear(
	UDF_INIT *initid
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_ptbis_samp_add(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

/**
 * int stat_abs_freq(value, series)
 * 
 * calculate absolute frequencies
DLLEXP 
my_bool stat_abs_freq_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
);

DLLEXP 
void stat_abs_freq_deinit(
	UDF_INIT *initid
);

DLLEXP 
my_ulonglong stat_abs_freq(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_abs_freq_reset(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_abs_freq_clear(
	UDF_INIT *initid
,	char *is_null
,	char *error
);

DLLEXP 
char* stat_abs_freq_add(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
);
 **/
 
#ifdef	__cplusplus
}
#endif

/****************************************
 * lib_mysqludf_stat_info
 * 
 * string lib_mysqludf_stat_info()
 * 
 * return version info
 ****************************************/
my_bool lib_mysqludf_stat_info_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=0){
		strcpy(
			message
		,	"No arguments allowed (udf: lib_mysqludf_stat_info)"
		);
		status = 1;
	} else {
		status = 0;
	}
	return status;
}
void lib_mysqludf_stat_info_deinit(
	UDF_INIT *initid
){
}
char* lib_mysqludf_stat_info(
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

/**
 * int stat_accum_int(i)
 * 
 * return the i added to stat_accum_int(i-1)  
 */
my_bool stat_accum_int_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly one argument (udf: accumulate_int)"
		);
		status = 1;
	} else if(!(initid->ptr = malloc(sizeof(longlong)))){
		initid->ptr = NULL;
		strcpy(
			message
		,	"Could not allocate memory (udf: accumulate_int)"
		);
		status = 1;
	} else {
		initid->maybe_null= 1;
		args->arg_type[0] = INT_RESULT;
		*((longlong *)initid->ptr) = 0;
		status = 0;
	}
	return status;
}
void stat_accum_int_deinit(
	UDF_INIT *initid
){
	if(initid->ptr!=NULL){
		free(initid->ptr);
	}
}
longlong stat_accum_int(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	if(args->args[0]!=NULL){
		*((longlong *)initid->ptr) += *((longlong *)args->args[0]); 
	} 
	return *((longlong *)initid->ptr);
}

/**
 * double stat_accum_double(double)
 * 
 */
my_bool stat_accum_double_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=1){
		strcpy(
			message
		,	"Expect exactly one argument (udf: stat_accum_double_init)"
		);
		status = 1;
	} else if(!(initid->ptr = malloc(sizeof(double)))){
		initid->ptr = NULL;
		strcpy(
			message
		,	"Could not allocate memory (udf: stat_accum_double_init)"
		);
		status = 1;
	} else {
		initid->maybe_null= 1;
		args->arg_type[0] = REAL_RESULT;
		*((double *)initid->ptr) = 0;
		status = 0;
	}
	return status;
}
void stat_accum_double_deinit(
	UDF_INIT *initid
){
	if(initid->ptr!=NULL){
		free(initid->ptr);
	}
}
double stat_accum_double(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	if(args->args[0]!=NULL){
		*((double *)initid->ptr) += *((double *)args->args[0]); 
	} 
	return *((double *)initid->ptr);
}

/**
 * PEARSON_SAMPLE
 */
typedef struct st_pearson {
	int unsigned n;
	double sum_sq_x;
	double sum_sq_y;
	double sum_coproduct;
	double mean_x;
	double mean_y;	
} PEARSON;
 
my_bool stat_pmcc_samp_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=2){
		strcpy(
			message
		,	"Expect exactly two arguments (udf: pearson_sample)"
		);
		status = 1;
	} else if(!(initid->ptr = malloc(sizeof(PEARSON)))){
		initid->ptr = NULL;
		strcpy(
			message
		,	"Could not allocate memory (udf: pearson_sample)"
		);
		status = 1;
	} else {
		initid->maybe_null= 1;
		initid->decimals= 4;
		args->arg_type[0] = REAL_RESULT;
		args->arg_type[1] = REAL_RESULT;
		status = 0;
	}
	return status;
}
void stat_pmcc_samp_deinit(
	UDF_INIT *initid
){
	if(initid->ptr!=NULL){
		free(initid->ptr);
	}
}
char* stat_pmcc_samp_reset(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	stat_pmcc_samp_clear(
		initid
	,	is_null
	,	error
	);
	stat_pmcc_samp_add(
		initid
	,	args
	,	is_null
	,	error
	);
	return 0;	//I hope this is what should be returned...
}
char* stat_pmcc_samp_clear(
	UDF_INIT *initid
,	char *is_null
,	char *error
){
	PEARSON* pearson_struct = (PEARSON *)initid->ptr;
	pearson_struct->n = 0;
	return 0;
}
char* stat_pmcc_samp_add(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	PEARSON* pearson_struct;
	double x;
	double y;
	if(	args->args[0]!=NULL
	&&	args->args[1]!=NULL
	){
		x = *((double *)args->args[0]);
		y = *((double *)args->args[1]);
		pearson_struct = (PEARSON *)initid->ptr;
		if ((++pearson_struct->n)==1){
 			pearson_struct->sum_sq_x = 0;
			pearson_struct->sum_sq_y = 0;
			pearson_struct->sum_coproduct = 0;
			pearson_struct->mean_x = x;
			pearson_struct->mean_y = y;
		} else {
		    double sweep = (pearson_struct->n - 1.0) / pearson_struct->n;
		    double delta_x = x - pearson_struct->mean_x;
		    double delta_y = y - pearson_struct->mean_y;
		    pearson_struct->sum_sq_x += delta_x * delta_x * sweep;
		    pearson_struct->sum_sq_y += delta_y * delta_y * sweep;
		    pearson_struct->sum_coproduct += delta_x * delta_y * sweep;
		    pearson_struct->mean_x += delta_x / pearson_struct->n;
		    pearson_struct->mean_y += delta_y / pearson_struct->n; 
		}
	}
	return 0;
}
double stat_pmcc_samp(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	PEARSON* pearson_struct = (PEARSON *)initid->ptr;
	double result; 
	if (pearson_struct->n==0){
		*is_null = 1;
	} else if (
		(result = 
			sqrt((double)pearson_struct->sum_sq_x / (double)pearson_struct->n)
		*	sqrt((double)pearson_struct->sum_sq_y / (double)pearson_struct->n)
		)==0
	){
		*is_null = 1;
	} else {
		result = 
			((double)pearson_struct->sum_coproduct/(double)pearson_struct->n)
		/	result
		;
	}
	return result;
}

/**
 * POINT_BISERIAL_SAMPLE
 */
typedef struct st_point_biserial_group{
	int unsigned n;
	double mean;
} POINT_BISERIAL_GROUP;

typedef struct st_point_biserial{
	double sum;
	POINT_BISERIAL_GROUP X;
	POINT_BISERIAL_GROUP X0;
	POINT_BISERIAL_GROUP X1;
} POINT_BISERIAL;

my_bool stat_ptbis_samp_init(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *message
){
	my_bool status;
	if(args->arg_count!=2){
		strcpy(
			message
		,	"Expect exactly two arguments (udf: point_biserial_sample)"
		);
		status = 1;
	} else if(!(initid->ptr = malloc(sizeof(POINT_BISERIAL)))){
		initid->ptr = NULL;
		strcpy(
			message
		,	"Could not allocate memory (udf: point_biserial_sample)"
		);
		status = 1;
	} else {
		initid->maybe_null= 1;
		initid->decimals= 4;
		args->arg_type[0] = REAL_RESULT;
		args->arg_type[1] = INT_RESULT;
		status = 0;
	}
	return status;
}
void stat_ptbis_samp_deinit(
	UDF_INIT *initid
){
	if(initid->ptr!=NULL){
		free(initid->ptr);
	}
}
char* stat_ptbis_samp_reset(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	stat_ptbis_samp_clear(
		initid
	,	is_null
	,	error
	);	
	stat_ptbis_samp_add(
		initid
	,	args
	,	is_null
	,	error
	);
	return 0;
}
char* stat_ptbis_samp_clear(
	UDF_INIT *initid
,	char *is_null
,	char *error
){
	POINT_BISERIAL* point_biserial_struct = (POINT_BISERIAL *)initid->ptr;

	point_biserial_struct->sum =0;
	point_biserial_struct->X.n =0;
	point_biserial_struct->X.mean =0;

	point_biserial_struct->X0.n = 0;
	point_biserial_struct->X0.mean = 0;

	point_biserial_struct->X1.n = 0;
	point_biserial_struct->X1.mean = 0;
	
	return 0;
}
char* stat_ptbis_samp_add(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	POINT_BISERIAL* point_biserial_struct;
	POINT_BISERIAL_GROUP* point_biserial_group_struct;
	double x;
	double delta;
	if(	args->args[0]!=NULL
	&&	args->args[1]!=NULL
	){
		point_biserial_struct = (POINT_BISERIAL *)initid->ptr;
		point_biserial_group_struct =  (*((longlong*)args->args[1])==0)
		?	&(point_biserial_struct->X0)
		:	&(point_biserial_struct->X1)
		;
		x = *((double *)args->args[0]);
		point_biserial_group_struct->n++;
		delta = x - point_biserial_group_struct->mean;
		point_biserial_group_struct->mean += delta/point_biserial_group_struct->n;
		
		point_biserial_group_struct = &point_biserial_struct->X;
		point_biserial_group_struct->n++;
		delta = x - point_biserial_group_struct->mean;
		point_biserial_group_struct->mean += delta/point_biserial_group_struct->n;
		
		point_biserial_struct->sum += delta*(x - point_biserial_group_struct->mean);
	}
	return 0; 
}
double stat_ptbis_samp(
	UDF_INIT *initid
,	UDF_ARGS *args
,	char *is_null
,	char *error
){
	POINT_BISERIAL* point_biserial_struct;
	POINT_BISERIAL_GROUP* X;
	POINT_BISERIAL_GROUP* X0;
	POINT_BISERIAL_GROUP* X1;
	double s;
	double result;

	point_biserial_struct = (POINT_BISERIAL *)initid->ptr;
	X  = &point_biserial_struct->X;

	if (X->n==1){
		*is_null = 1;
	} else if ((s = sqrt((double)point_biserial_struct->sum / (double)(X->n - 1)))==0){
		*is_null = 1;
	} else {
		X0 = &point_biserial_struct->X0;
		X1 = &point_biserial_struct->X1;
		result = 
			((X1->mean - X0->mean) / s)
		*	sqrt(
				(double)(X1->n * X0->n)
			/	(double)(X->n * (X->n -1))
			)
		;
		}	
	return result;
}


#endif /* HAVE_DLOPEN */

