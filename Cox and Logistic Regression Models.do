set more off
clear
use "\\FileSrv1\CMS_Caregiver\DATA\HCBS and SNF\data set.dta", clear

logit nh_hha hcbs_rate 
logit nh_hha high_generosity mod_generosity

logit nh_hha /*  
*/ hcbs_rate pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk

 
logit nh_hha /*  
*/ high_generosity mod_generosity pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk

logit nh_hha_60 hcbs_rate
logit nh_hha_60 high_generosity mod_generosity

logit nh_hha_60 /*  
*/ hcbs_rate pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk

logit nh_hha_60 /*  
*/ high_generosity mod_generosity pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk

stset days nh_hha


xi: stcox nh_hha /*  
*/ high_generosity mod_generosity pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk


stset days nh_hha_60 

xi: stcox nh_hha_60/*  
*/ high_generosity mod_generosity pcp_per_cap acute_hosp snf_cert /*
*/ nurse_beds age female black hispanic other_race /*
*/ pre_lt_hha  gov  fp tenure_years adl_sum p_sever_high p_sever_mid nutrition stable risk /*
*/ alone_0 pain1 pain2 ulcer2_up surg_wd_lesion lesion dyspenic respritory uti u_incntn bwl_incntn /*
*/ cog_fun_high depression_mid depression_high fall_risk
