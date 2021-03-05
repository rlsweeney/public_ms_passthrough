********************************************************************************
*RIVAL = Rship, NONRIVAL = none

global rlabel Rship

local Rpath Rship
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*  GET RIVALS FOR FP LEVEL REGS *
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use "${sampledir_channel}/rivalvars_fp_`Rpath'", clear
foreach v of varlist $rvarlist {
	rename `v' _Rival_`v'
}
save rdata, replace

use "${sampledir_channel}/regdata_fp", clear

merge m:1 FPid year month prod using rdata, keep(match) nogen 

save tempregdat_fp, replace

*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*  GET RIVALS FOR ST LEVEL REGS *
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

use "${sampledir_channel}/rivalvars_st_`Rpath'", clear
foreach v of varlist $rvarlist {
	rename `v' _Rival_`v'
}
save rdata, replace

use "${sampledir_channel}/regdata_st", clear

merge m:1 FPid year month prod state_abv using rdata, keep(match) nogen 

save tempregdat_st, replace
