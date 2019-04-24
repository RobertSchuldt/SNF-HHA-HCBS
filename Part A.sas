/**************************************************************************************************************************
SNF and HCBS programs project
Author: Robert Schuldt
Email :rschuldt@uams.edu

Project looking at HCBS and SNF alzheimer patients 
***************************************************************************************************************************/

libname snf '********************';
libname hha '*********************';

%include "E:\SAS Macros\infile macros\sort.sas";
/*Import and calculate the number of Alz patients for SNF*/
%macro imp(file, date);

proc import datafile = "********************************"
dbms = xlsx out = snf replace;

run;

data snf.snf_&date;
	set snf;
		
		total_alz = Distinct_Beneficiaries_Per_Provi*Percent_of_Beneficiaries_with_Al;
	run;

%mend;

%imp(SNF_2013 , 2013)
%imp(SNF_2014 , 2014)
%imp(SNF_2015 , 2015)
%imp(SNF_2016 , 2016)

/*Import and calculate the number of Alz patients for SNF*/
%macro imp_hha(file, date);


libname pos "************************";

proc import datafile = "************************************"
dbms = xlsx out = hha replace;

run;

data hha_&date;
	set hha;
	
		
		total_alz = Distinct_Beneficiaries__non_LUPA*Percent_of_Beneficiaries_with_Al;
		length PRVDR_NUM $ 6;
        PRVDR_NUM = Provider_ID;
		PRVDR_NUM = put(input(PRVDR_NUM, 6.),z6.);
	run;

data pos&date;
	set pos.pos_&date;
		where PRVDR_CTGRY_CD = "05";
		keep PRVDR_NUM GNRL_CNTL_TYPE_CD FIPS_STATE_CD FIPS_CNTY_CD nfp fp gov other;
		
		nfp = 0;
	if GNRL_CNTL_TYPE_CD = '01' or GNRL_CNTL_TYPE_CD =  '02' or GNRL_CNTL_TYPE_CD =  '03' then nfp = 1;
		fp = 0;
	if GNRL_CNTL_TYPE_CD = '04' then fp = 1;
		gov = 0;
	if GNRL_CNTL_TYPE_CD = '05' or GNRL_CNTL_TYPE_CD = '06' or GNRL_CNTL_TYPE_CD = '07' then gov = 1;
		other = 0;
	if GNRL_CNTL_TYPE_CD = '08' or GNRL_CNTL_TYPE_CD =  '09' or GNRL_CNTL_TYPE_CD =  '10' then other = 1;
		

		%sort(pos&date, PRVDR_NUM)
		%sort(hha_&date, PRVDR_NUM)

	data hhapos_&date;
	merge hha_&date  (in = a) pos&date (in=b);
	by PRVDR_NUM;
	if a;
	if b;
	run;

proc sql;
create table hha as 
select *,
	mean(case when fp = 1 then Percent_of_Beneficiaries_with_Al else . end) as mean_alz_fp,
	mean(case when nfp = 1 then Percent_of_Beneficiaries_with_Al else . end) as mean_alz_nfp,
	mean(case when gov = 1 then Percent_of_Beneficiaries_with_Al else . end) as mean_alz_gov
from hhapos_&date;
quit;

data hha.hha_&date;
	set hha;
	run;


%mend;

%imp_hha(HHA_2013 , 2013)
%imp_hha(HHA_2014 , 2014)
%imp_hha(HHA_2015 , 2015)
%imp_hha(HHA_2016 , 2016)
