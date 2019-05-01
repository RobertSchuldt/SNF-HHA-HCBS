/*************************************************************************************************************************************

This project is adding in aspects of the PQI program provided by the AHRQ to determine preventable SNF admissions. This will be turned 
into an academic article. Increased efficiency of programming adapted into this iteration of the project. 

@author: Robert F Schuldt
@email: rschuldt@uams.edu

**************************************************************************************************************************************/
libname cms '\';
libname poster '\';
libname zip '\s';


/*Calling in my macro program for sorting*/
%include 'E:\SAS Macros\infile macros\sort.sas';


	data selected_variables (compress = yes);
		set poster.data_dementiasubset;
		drop nh_stay hosp_stay any_hosp_stay;
			where dementia = 1 or alzheimer = 1;
/* remove those patients with no cognitive difficulties*/
			if m1700_cog_function = "00" then delete;
		
/*Correct Medicare payment amount */
			if MDCR_PMT_AMT lt 0 then MDCR_PMT_AMT = 0;

/*Mark our SNF and Long term stays*/
	if SS_LS_SNF_IND_CD = "L" then long_stay = 1;
				else long_stay = 0;
	if SS_LS_SNF_IND_CD = "N" then snf_stay = 1;
				else snf_stay = 0;

			run;

	proc freq;
	table m1700_cog_function snf_stay long_stay;
	run;

	proc univariate;
	var MDCR_PMT_AMT;
	run;

	proc sql;
	create table sum_pats as
	select * ,
	sum(snf_stay) as total_pat_snf,
	sum(CASE WHEN snf_stay=1 THEN MDCR_PMT_AMT  ELSE 0 END) as total_snf_pay,
	sum(long_stay) as total_pat_long,
	sum(CASE WHEN long_stay=1 THEN MDCR_PMT_AMT  ELSE 0 END) as total_long_pay
	from selected_variables
	group by m1700_cog_function
	order by m1700_cog_function;
	quit;

data per_pat;
	set sum_pats;

	per_pat_snf = total_pat_snf/total_snf_pay;
	per_pat_long =total_pat_long/total_long_pay;
run;

proc freq;
table per_pat_long per_pat_snf ;
by m1700_cog_function;
run; 
/*Start work on the variable creation aspect of part B for regression analysis*/
proc contents data = per_pat;
run;

data part_b;
	set per_pat;
	adm_14 = ADMSN_DT + 14;
	if SS_LS_SNF_IND_CD = "S" and adm_14 <= M0030_SOC_DT
		then pre_hosp_hha = 1;
				else pre_hosp_hha = 0;

	if SS_LS_SNF_IND_CD = "L" or SS_LS_SNF_IND_CD = "N" and adm_14 <= M0030_SOC_DT
		then pre_lt_hha = 1;
				else pre_lt_hha = 0;
	days = 0;
	days = ADMSN_DT - M0030_SOC_DT;

	rename M0010_MEDICARE_ID = provider_id;	
run;
proc freq data = part_b;
table pre_lt_hha pre_hosp_hha;
run;
ods graphics on;
proc univariate data = part_b;
var MDCR_PMT_AMT;
histogram MDCR_PMT_AMT / kernel;
where nh_hha_60 = 1;
run;
/* now I need to bring in the POS file to grab data on ownership and tenure*/
libname pos '';
data pos;
	set pos.pos_2015;
			where PRVDR_CTGRY_SBTYP_CD = "01";

			keep GNRL_CNTL_TYPE_CD FIPS_STATE_CD FIPS_CNTY_CD  CRTFCTN_DT prvdr_num provider_id fips_agency nfp gov fp tenure_years;
			rename prvdr_num = provider_id;

	if GNRL_CNTL_TYPE_CD = '01' or GNRL_CNTL_TYPE_CD =  '02' or GNRL_CNTL_TYPE_CD =  '03' then nfp = 1;
		else nfp = 0;
	if GNRL_CNTL_TYPE_CD = '04' then fp = 1;
		else fp = 0;
	if GNRL_CNTL_TYPE_CD = '05' or GNRL_CNTL_TYPE_CD =  '06' or GNRL_CNTL_TYPE_CD =  '07' then gov = 1;
		else gov = 0;
			date_study = mdy(12,31,2015);

			tenure_years = date_study - CRTFCTN_DT;
			fips_agency = cats(FIPS_STATE_CD,FIPS_CNTY_CD);
run; 


%sort(pos, provider_id)
%sort(part_b, provider_id)

data pos_part_b;
	merge part_b (in = a) pos (in = b);
	by provider_id;
	if a;
	if b;
run;
proc freq data = pos_part_b;
table pre_lt_hha pre_hosp_hha;
run;
/*Now is the time to bring in the AHRF data so we can get local area stats*/

libname ahrf '';

data ahrf;
	set ahrf.ahrf_2017_2018;
	keep f1467515 f1198415 f0892515 f1321315 f1321715 f1118115 f00002 pcp_per_cap acute_hosp snf_cert nurse_beds;
	rename f00002 = fips_agency;
	
	pcp_per_cap = (f1467515/f1198415)*100;
	acute_hosp = (f0892515/f1198415)*100;
	snf_cert = (f1321715/f1198415)*100;
	nurse_beds = (f1118115/f1198415)*100;
run;

%sort(pos_part_b, fips_agency)
%sort(ahrf, fips_agency)

data ahrf_pos_b;
	merge pos_part_b (in = a) ahrf (in = b);
	by fips_agency;
	if a;
	if b;
run;
proc freq data = ahrf_pos_b;
table pre_lt_hha pre_hosp_hha;
run;

/* we lose 700 observations from this merge

NOTE: There were 13705 observations read from the data set WORK.POS_PART_B.
NOTE: There were 3230 observations read from the data set WORK.AHRF.
NOTE: The data set WORK.AHRF_POS_B has 12986 observations and 1043 variables.
NOTE: DATA statement used (Total process time):
      real time           0.07 seconds
      cpu time            0.07 seconds

*/

proc freq data = ahrf_pos_b;
title "Obs of outcomes";
table nh_hha nh_hha_60;
run;

proc surveylogistic data = ahrf_pos_b;
cluster provider_id;
model nh_hha (event = "1") = high_generosity mod_generosity  pcp_per_cap acute_hosp snf_cert nurse_beds age female black hispanic other_race 
pre_lt_hha pre_hosp_hha gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk alone_0 pain1 
pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn cog_fun_mild
cog_fun_high depression_mid depression_high fall_risk;
run;


proc surveylogistic data = ahrf_pos_b;
cluster provider_id;
model nh_hha_60 (event = "1") = high_generosity mod_generosity  pcp_per_cap acute_hosp snf_cert nurse_beds age female black hispanic other_race 
pre_lt_hha pre_hosp_hha gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk alone_0 pain1 
pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn cog_fun_mild
cog_fun_high depression_mid depression_high fall_risk;
run;
