*GET FPid
gen str6 tf = string(firm_id,"%06.0f")
gen FPid=  tf + "-" + string(ref_padd)
drop tf
