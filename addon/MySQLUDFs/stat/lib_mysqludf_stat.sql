/* 
	lib_mysqludf_statistics - a library of mysql udfs statistical functions
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

drop function lib_mysqludf_stat_info;
drop function stat_accum_int;
drop function stat_accum_double;
drop function stat_pmcc_samp;
drop function stat_ptbis_samp;
*/

create function lib_mysqludf_stat_info returns string soname 'stat.dll';
create function stat_accum_int returns int soname 'stat.dll';
create function stat_accum_double returns real soname 'stat.dll';
create aggregate function stat_pmcc_samp returns real soname 'stat.dll';
create aggregate function stat_ptbis_samp returns real soname 'stat.dll';