* SUBCODE THAT CONSTRUCTS VARIABLES OF RIVALS UNDER DIFFERENT DEFINITIONS 

*merge in instruments
use "$generated_dir/fp_ref_crude_data", clear

keep FPid year month Pcru Z_* tax_cpg av_tax
rename FPid r_FPid 

global rvars Pcru Z_* tax_cpg av_tax

merge 1:m r_FPid year month using "${sampledir_channel}/all_pairs_instate_long_${stype}", nogen keep(match) 

drop if firm_id == r_firm_id // not including other FPs by same firm in any of these measures

drop if Sales == 0
save instdata, replace

/*CONSTRUCT DIFFERENT WEIGHTS

NOTATION
- R1 - indicator for rival
- R1av - indicator for rival on average 
- RQav - rival average sales
- N1 - indicator for non-rival
- N1av - indicator non-rival on average
- Nsh - nonrival inverse shipping costs
- Rmaxav - max of rivals on average
- Rship - All firms inverse shipping cost weighted
- Rdist - All firms inverse distance weighted
- R1ship - indicator for rival, inverse shipping weighted
- R1avship - indicator for rival on average , inverse shipping weighted
- R1avdist - indicator for rival on average , inverse distance weighted
- Nshav - nonrival average inverse shipping costs
- Ndistav - nonrival average inverse inverse costs
*/

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Rship - All firms inverse shipping cost weighted
use instdata, clear
gen wgt = 1/r_shipcost 
drop if r_ref_flag == 0
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_Rship", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_Rship", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Rdist - All firms inverse distance weighted
use instdata, clear
gen wgt = 1/r_linear_distance
drop if r_ref_flag == 0
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_Rdist", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_Rdist", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* Rmaxav - max of rivals on average
use instdata, clear
drop if r_Sales == 0

gegen r_npers = count(Pcru), by(FPid r_FPid year state_abv prod) 
gegen r_Pav = mean(Pcru), by(FPid r_FPid year state_abv prod) 

gegen av_r_npers = mean(r_npers), by(FPid year month state_abv prod) 
gen te = r_Pav if r_npers >= av_r_npers
gegen maxprice = max(te), by(FPid year month state_abv prod) 
keep if r_Pav == maxprice
drop te
save "${sampledir_channel}/rivalvars_st_Rmaxav", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_Rmaxav", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
* R1 - indicator for rival
use instdata, clear
drop if r_Sales == 0

gcollapse (mean) $rvars, by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_R1", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_R1", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*- Nsh - nonrival inverse shipping costs
use instdata, clear
gen wgt = cond(r_Sales == 0, 1/r_shipcost,0)
drop if wgt == 0 
drop if r_ref_flag == 0
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod)
save "${sampledir_channel}/rivalvars_st_Nsh", replace

use instdata, clear
gegen pairsum = sum(r_Sales), by(FPid r_FPid year month prod) 
drop if pairsum > 0 
drop if r_ref_flag == 0

*GET AVERAGE SHIPCOST FIRST
gcollapse (mean) r_shipcost $rvars [w= Sales], by(FPid r_FPid year month prod)
gen wgt = 1/r_shipcost

gcollapse (mean)  $rvars [w= wgt], by(FPid year month prod)

save "${sampledir_channel}/rivalvars_fp_Nsh", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*R1av - indicator for rival on average
use instdata, clear
drop if r_av_Sales == 0

gcollapse (mean) $rvars, by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_R1av", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_R1av", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*R1avdist - indicator for rival on average , inverse distance weighted
use instdata, clear
drop if r_av_Sales == 0
gen wgt = 1/r_linear_distance
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_R1avdist", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_R1avdist", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*R1ship - indicator for rival , inverse shipping cost weighted
use instdata, clear
drop if r_Sales == 0
gen wgt = 1/r_shipcost
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_R1ship", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_R1ship", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*R1avship - indicator for rival on average , inverse shipping cost weighted
use instdata, clear
drop if r_av_Sales == 0
gen wgt = 1/r_shipcost
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_R1avship", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_R1avship", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*Nshav - nonrival average inverse shipping costs
use instdata, clear
gen wgt = cond(r_av_Sales == 0, 1/r_shipcost,0)
drop if wgt == 0 
drop if r_ref_flag == 0
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod)
save "${sampledir_channel}/rivalvars_st_Nshav", replace

use instdata, clear
gegen pairsum = sum(r_av_Sales), by(FPid r_FPid year month prod) 
drop if pairsum > 0 
drop if r_ref_flag == 0

*GET AVERAGE SHIPCOST FIRST
gcollapse (mean) r_shipcost $rvars [w= Sales], by(FPid r_FPid year month prod)
gen wgt = 1/r_shipcost

gcollapse (mean)  $rvars [w= wgt], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_Nshav", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*Ndistav - nonrival average inverse distance
use instdata, clear
gen wgt = cond(r_av_Sales == 0, 1/r_linear_distance,0)
drop if wgt == 0 
drop if r_ref_flag == 0
gcollapse (mean)  $rvars [w= wgt], by(FPid year month state_abv prod)
save "${sampledir_channel}/rivalvars_st_Ndistav", replace

use instdata, clear
gegen pairsum = sum(r_av_Sales), by(FPid r_FPid year month prod) 
drop if pairsum > 0 
drop if r_ref_flag == 0

*GET AVERAGE SHIPCOST FIRST
gcollapse (mean) r_linear_distance $rvars [w= Sales], by(FPid r_FPid year month prod)
gen wgt = 1/r_linear_distance

gcollapse (mean)  $rvars [w= wgt], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_Ndistav", replace

* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*RQav - actual rival sales
use instdata, clear
gen wgt = r_av_Sales
drop if wgt == 0 
gcollapse (mean) $rvars [w= wgt], by(FPid year month state_abv prod Sales)
save "${sampledir_channel}/rivalvars_st_RQav", replace

gcollapse (mean)  $rvars [w= Sales], by(FPid year month prod)
save "${sampledir_channel}/rivalvars_fp_RQav", replace
